# 项目核心流程文档

## 0. 一句话总览

`WW2Tactics` 的主链路是：玩家在 SwiftUI 地图上选择单位和目标，`GameState` 根据 `GameModels` 执行移动、攻击、补给、AI、目标和胜负规则，`ContentView` 将状态渲染为 EasyTech 风格的大地图战棋界面，测试层用 XCTest 和 smoke test 锁住核心规则；协作链路默认由 Agent B 在 `main` 提交并推送到 `origin/main`，GitHub Actions 生成未加密 CI 结果包，Agent C 下载结果包后验收；未来可由 Agent X 围绕人工总目标拆分多轮，并按 Agent A -> Agent B -> Agent C 循环调度。

## 1. 当前核心数据流

```text
用户输入 / 快捷按钮
  -> ContentView 地图格和 HUD 事件
  -> GameState handleTap / handlePrimaryAction / handleSecondaryAction / executeFocusedCommand
  -> GameModels 中的 Scenario / BattleUnit / TerrainTile / HexCoordinate / MapCommandPreview
  -> GameState 规则判定与状态更新
  -> @Published 状态变化
  -> ContentView 重新渲染地图、侧栏、HUD、图例、战斗结果、战报
  -> GameStateTests / RulesSmokeTest 验证行为
```

## 2. 核心模块

### 2.1 `GameModels.swift`

职责：

- 定义阵营、兵种、地形、士气、战术状态、单位、地图格、战役。
- 定义地图命令提示 `MapActionHint`、执行预览 `MapCommandPreview`、路线步骤预览 `RouteStepPreview`、移动后攻击预判 `PostMoveAttackPreview`、移动后火力暴露预览 `PostMoveFireExposurePreview`、安全接敌候选 `SafeEngagementOption` 和普通攻击后的 `CombatResultSummary`。
- 生成阿登反击战、诺曼底突破等战役初始数据。

输入：

- 静态规则常量。
- 战役构造函数。

输出：

- `Scenario`、`BattleUnit`、`TerrainTile` 等规则层对象。

禁止：

- 不在这里写 UI。
- 不在这里执行回合状态变更。

### 2.2 `GameState.swift`

职责：

- 项目核心状态机。
- 管理当前战役、选中单位、焦点坐标、当前阵营、回合、消息、战报、最新普通攻击结果、胜负、指令点。
- 处理移动、攻击、反击、攻击后战损摘要、补给、士气、控制区、战术命令、增援、据点占领、目标推进、AI 行动、威胁覆盖、路线步骤情报、移动后攻击预判、移动后火力暴露预览和安全接敌候选。

输入：

- `ContentView` 发来的用户意图。
- 当前 `Scenario` 和单位状态。

输出：

- `@Published` 状态。
- 地图命令预览。
- 战报和消息。
- 胜负与评价。

禁止：

- 不写 SwiftUI 视图。
- 不把规则结果交给 View 再二次判定。

### 2.3 `ContentView.swift`

职责：

- 渲染 SwiftUI App 主界面。
- 提供顶部状态栏、战区地图、地图工具栏、HUD、侧栏、图例、编队条、战报。
- 将地图左键/点按/右键转换为 `GameState` 方法调用。
- 显示 MOVE、ATK、POS、NEXT、OBJ、THR、补给线、控制区、攻击覆盖等标记。

输入：

- `@EnvironmentObject GameState`。
- 用户手势和按钮点击。

输出：

- 视觉地图和 UI。
- 调用 `GameState` 的意图方法。

禁止：

- 不直接修改核心规则。
- 不绕过 `GameState` 消耗行动。

### 2.4 测试层

职责：

- `GameStateTests.swift` 用 XCTest 覆盖规则、交互链、边界状态。
- `RulesSmokeTest.swift` 用命令行可执行程序快速覆盖主链路。

禁止：

- 不用视觉细节代替规则断言。
- 不伪造测试结果。

## 3. 当前核心执行流

### 3.1 选择和聚焦

1. 玩家左键或点按地图格。
2. `ContentView.HexInputReader` 调用 `GameState.handleTap` 或 `handlePrimaryAction`。
3. 若点己方单位，`selectedUnitID` 更新。
4. 若点空格或敌军，更新 `focusedCoordinate` 并生成预览消息。
5. 聚焦本身不能消耗移动或攻击。

### 3.2 移动

1. 选中单位后，`movementRoutes(for:)` 基于地形、占位、敌方控制区和有效移动力计算可达路线。
2. `routeStepPreviews(for:route:)` 从既有路线派生逐步路线情报：步序、坐标、实际进入消耗、控制区额外消耗、敌火威胁来源和终点标记。
3. `postMoveAttackPreviews(for:to:)` 只对合法 MOVE 目的地生成移动后攻击预判，用临时 attacker 位置复用 `combatPreview`，不写回战役状态。
4. `fireExposurePreview(for:at:)` 对合法 MOVE 目的地用临时移动后的单位复用 `combatPreview(enemy, movedUnit)`，估算敌火来源、潜在伤害、HP 后果和风险等级，不写回战役状态。
5. 地图显示 `MOVE` 标记、步序/消耗、路线风险、终点火力风险和移动后可攻击目标。
6. 右键或执行按钮触发 `executeMapCommand(.move)`。
7. `move(unitID:to:)` 更新单位位置、消耗移动、清理防御姿态、更新据点控制。
8. 若移动后有可攻击目标，聚焦 NEXT 目标。

### 3.3 攻击

1. `attackCoverageTiles` 和 `attackableTiles` 判断射程覆盖与有效目标。
2. `combatPreview` 计算伤害、反击、地形、兵种克制、夹击、将领协同、击毁结果。
3. 地图显示 `ATK`、伤害或 `KILL`。
4. 右键或执行按钮触发 `attack(attackerID:targetID:)`。
5. 攻击更新 HP、经验、士气、行动状态、战报、胜负。
6. `latestCombatResult` 记录本次普通攻击的双方 HP 前后、伤害、反击、击毁、机动追击、夹击、防御姿态消耗、经验/士气/军衔变化；聚焦、`combatPreview`、MOVE/POS 预览不会写入该结果。

### 3.4 接敌 POS

1. 敌军射程外但存在可进入攻击位时，`attackPositionRoutes` 返回路线。
2. `focusedRouteStepPreviews` 对推荐 `focusedAttackPositionRoute` 同样生成路线风险，展示到攻击位的消耗、控制区和敌火来源。
3. `focusedFireExposurePreview` 对推荐攻击位估算潜在承伤；`focusedSafeEngagementOptions` 从所有攻击位中按风险、潜在伤害、路线消耗和坐标稳定排序，给出更安全接敌建议，但不改变默认 POS 执行目的地。
4. 地图显示 `POS`、路线步序/风险和终点风险短码。
5. 右键敌军或执行按钮移动到攻击位。
6. 移动后聚焦敌军，提示继续点按或右键攻击；POS 本身不直接执行攻击。

### 3.5 OBJ 目标推进

1. `focusNearestObjectiveTarget` 选择最近未占据、未归属己方的据点。
2. 若可直达，聚焦据点并设置 `guidedObjectiveCoordinate`。
3. 若不可直达，聚焦本回合推进格，同时保留最终目标据点。
4. 普通聚焦、攻击、待命、回合切换等应清理目标引导，避免状态残留。

### 3.6 THR 敌火覆盖

1. `threateningEnemies(against:at:)` 查询某坐标被哪些敌军射程覆盖。
2. `threatenedTiles(for:)` 生成阵营威胁地图。
3. `threatenedReachableTiles(for:)` 标记选中单位可达但危险的格子。
4. MOVE/POS 聚焦时，`PostMoveFireExposurePreview` 将敌火覆盖转换为风险等级、潜在伤害和预计剩余耐久；这是纯预览，不触发反应射击或真实伤害。
5. `ContentView` 在 HUD 显示 THR 数量，在地图显示 THR 和 SAFE/LOW/MED/HIGH/CRIT 风险标记。

### 3.7 回合和 AI

1. 玩家结束回合调用 `endTurn()`。
2. 轴心国重置行动、获得指令点，执行 `runAxisAI()`。
3. AI 优先整补/增援/战术命令，然后移动接敌或攻击。
4. 盟军新回合重置行动、获得指令点，自动选择可行动单位。

## 4. 架构边界

- 规则状态必须从 `GameState` 发起和落地。
- `ContentView` 只能展示状态和转发用户意图。
- `GameModels` 只定义数据和静态规则，不执行业务流程。
- 测试必须优先断言 `GameState` 行为。
- README 面向使用者；`md/flow` 面向 Agent 和维护者。

## 5. 用户入口

- Xcode 打开 `WW2Tactics.xcodeproj` 运行。
- 主 UI 入口：`WW2TacticsApp` 注入 `GameState`，显示 `ContentView`。
- 地图入口：`BattlefieldView` -> `MapCommandCenter` -> `HexMapView` -> `HexTileView`。
- 侧栏入口：`InspectorPanel` 显示单位、地形、战报和预测。

## 6. 测试映射

- 移动、攻击、补给、士气、AI、目标推进：`GameStateTests.swift` + `RulesSmokeTest.swift`。
- SwiftUI 编译：iPhone Simulator SDK typecheck。
- Xcode 集成：`xcodebuild build-for-testing`。
- 文档-only 修改：本地 `git diff --check`，云端 workflow 仍生成可验收结果包。
- workflow 修改：本地 YAML 解析，云端上传 manifest、failure summary、JUnit、构建日志、smoke 日志和 `.xcresult`。

## 7. 云端协作执行流

### 7.1 Agent X 主控循环阶段

1. 人工用 `agentx`、`x:` 或 `X:` 提供总目标 X、限制、验收标准和优先级。
2. Agent X 不直接替代 Agent A/B/C，而是把总目标拆成多个小轮次。
3. 每轮开始时，Agent X 明确本轮目标、非目标、边界、验证要求和预期产物。
4. Agent X 调度 Agent A 写版本化提示词，再调度 Agent B 实现、轻量检查、提交并 `git push origin main`。
5. GitHub Actions 生成未加密 CI 结果包后，Agent X 必须等待 Agent C 下载并核对 artifact。
6. Agent X 只基于 Agent C 对最新 `origin/main` commit、workflow run、run attempt 和 artifact 的结论判断下一步。
7. 通过时，Agent X 判断总目标是否完成；未完成则拆分下一轮目标并回到 Agent A。
8. 不通过时，Agent X 默认退回 Agent B 在 `main` 上追加修复 commit，不得伪装本轮完成。
9. 遇到连续阻塞、连续无有效 diff、同因 CI 连续失败、账号权限密钥需求、无法判断归属的工作区冲突或人工要求停止时，Agent X 暂停并交还人工决策。

### 7.2 Agent A 提示词阶段

1. 人工用 `agenta`、`a:` 或 `A:` 召唤 Agent A。
2. Agent A 阅读入口文档、测试规范、核心流程和相关源码。
3. Agent A 写入 `md/prompt/vN（阶段）/vN.x（任务）.md`。
4. 提示词必须写清 `main` 直推、云端验证、CI artifact、Agent C 下载核对和失败后追加修复 commit 要求。

### 7.3 Agent B main 直推阶段

1. Agent B 基于最新 `origin/main` 切到本地 `main`。
2. Agent B 小步实现、补测试和同步文档。
3. Agent B 本地只跑轻量检查；除非人工明确要求，不默认本机完整 build。
4. Agent B 用 `vN.x: 简要说明` 提交本轮相关文件。
5. Agent B 直接 `git push origin main` 触发 GitHub Actions。
6. GitHub Actions 运行静态检查、规则 smoke test、Xcode build-for-testing，并上传未加密 CI 结果包。

### 7.4 Agent C 结果包验收阶段

1. Agent C 确认 `origin/main` 最新 commit。
2. Agent C 用 `gh auth login` 后下载 artifact 到 `/private/tmp/ww2tactics-c-review-<run_id>/`。
3. Agent C 核对 `ci-artifact-manifest.json` 中的 `branch`、`commitSha`、`runId`、`runAttempt`。
4. Agent C 检查 `ci-failure-summary.md`、`junit.xml`、`xcodebuild.log`、`rules-smoke.log` 和 `.xcresult`。
5. 通过时，Agent C 确认 `origin/main` 最新 run 通过并输出验收结论。
6. 不通过时，Agent C 写清退回清单；Agent B 在 `main` 上追加修复 commit，再次 push 触发新 run。

### 7.5 当前远端约束

- 默认流程要求存在 `origin/main` 和 GitHub Actions 权限。
- 若本地仓库没有配置远端或没有权限下载 artifact，Agent 必须在 push 或验收前停止并说明阻塞。
- 不能把旧结果包、旧 output 或 checkout 自带报告当作本轮云端结果。

## 8. 已确认铁律

- 聚焦不能执行命令。
- 右键/执行按钮才执行 MOVE、ATK、POS。
- 非法命令只提示，不消耗行动。
- 核心规则不能写进 View。
- 用户可见功能变化必须更新 README。
- 核心流程变化必须更新 `md/flow`。
- 测试命令和结果必须真实记录。
- `main` 是唯一默认提交、推送和云端验证分支。
- Agent C 只验收 `origin/main` 最新 commit 对应的未加密 CI 结果包。
- Agent X 只能调度 A/B/C 多轮推进，不能跳过 Agent C artifact 验收或无限循环。

## 9. 未来扩展点

- 地图拖动/缩放手感、路线箭头、危险格更细粒度显示。
- 战斗动画、战斗结果回放动效、更多战术命令结果摘要。
- 更完整 AI：据点优先级、补给、撤退、集中火力。
- 更多战役、国家、科技、生产队列。
- 保存进度和战役进度界面。
- 真实地图贴图、单位立绘、将领头像。

## 10. 不允许破坏的行为

- 选中己方单位后，地图必须显示可移动/可攻击/可接敌反馈。
- 据点条和敌军条只能聚焦，不得误触发攻击。
- 移动后若出现 NEXT 目标，应自动聚焦并可继续攻击。
- OBJ 引导必须在普通聚焦或行动后按规则清理。
- THR 只提示危险，不应阻止合法移动，除非未来规则明确改变。
