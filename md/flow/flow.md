# 项目核心流程文档

## 0. 一句话总览

`WW2Tactics` 的主链路是：玩家在 SwiftUI 地图上选择单位和目标，`GameState` 根据 `GameModels` 执行移动、攻击、补给、AI、目标和胜负规则，`ContentView` 将状态渲染为 EasyTech 风格的大地图战棋界面，测试层用 XCTest 和 smoke test 锁住核心规则；协作链路默认由 Agent B 在 `main` 提交并推送到 `origin/main`，GitHub Actions 生成未加密 CI 结果包，Agent C 下载结果包后验收；未来可由 Agent X 围绕人工总目标拆分多轮，并按 Agent A -> Agent B -> Agent C 循环调度。

## 1. 当前核心数据流

```text
用户输入 / 快捷按钮
  -> ContentView 地图格和 HUD 事件
  -> GameState handleTap / handlePrimaryAction / handleSecondaryAction / executeFocusedCommand / focusEnemyThreatCountermeasure
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
- 定义地图命令提示 `MapActionHint`、执行预览 `MapCommandPreview`、路线步骤预览 `RouteStepPreview`、移动后攻击预判 `PostMoveAttackPreview`、移动后火力暴露预览 `PostMoveFireExposurePreview`、OBJ 据点推进计划摘要 `ObjectiveAdvancePreview`、安全接敌候选 `SafeEngagementOption`、敌方威胁意图预判 `EnemyThreatIntentPreview`、敌方意图反制建议 `EnemyThreatCountermeasurePreview`、反制建议收益解释 `EnemyThreatCountermeasureBenefitMetric`、反制建议排序解释 `EnemyThreatCountermeasurePriorityFactor`、反制建议相邻对比 `EnemyThreatCountermeasureComparisonPreview`、反制建议执行前后预计对照 `EnemyThreatCountermeasureImpactComparison`、反制建议地图标记 `EnemyThreatCountermeasureMapMarker`、反制建议执行桥接预览 `EnemyThreatCountermeasureExecutionPreview`、普通攻击后的 `CombatResultSummary`、战术命令后的 `TacticalCommandResultSummary`、据点占领后的 `ObjectiveCaptureResultSummary`、部署后的 `DeploymentResultSummary`、整补后的 `ReinforcementResultSummary` 和敌方回合后的 `AIPhaseSummary`。
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
- 管理当前战役、选中单位、焦点坐标、安全接敌候选焦点、当前阵营、回合、消息、战报、最新普通攻击结果、最新战术命令结果、最新据点占领结果、最新部署结果、最新整补结果、最新 AI 回合摘要、胜负、指令点。
- 处理移动、攻击、反击、攻击后战损摘要、补给、士气、控制区、战术命令、战术命令结果摘要、增援、部署结果摘要、整补、整补结果摘要、据点占领、据点占领结果摘要、目标推进、目标推进计划摘要、AI 行动、AI 回合摘要、威胁覆盖、路线步骤情报、移动后攻击预判、移动后火力暴露预览、安全接敌候选、敌方威胁意图预判、敌方意图反制建议、反制建议相邻排序对比、反制建议执行前后预计对照、当前反制建议地图标记派生和当前反制建议执行入口桥接派生。

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
- 显示 MOVE、ATK、POS、NEXT、OBJ、CAP、THR、INT、补给线、控制区、攻击覆盖等标记。

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
7. `move(unitID:to:)` 更新单位位置、消耗移动、清理防御姿态、更新据点控制；若真实占领或夺取据点，写入 `latestObjectiveCaptureResult`。
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
4. 侧栏安全接敌候选点击只调用 `focusSafeEngagementOption(_:)` / `focusSafeEngagement(targetID:destination:)`，由 `GameState` 基于当前单位和目标敌军重新查候选路线，避免 UI 使用过期路线。
5. 点选安全候选只切换 `focusedSafeEngagementDestination` 和当前 POS 预览路线，不消耗行动、不移动单位、不自动攻击、不生成结果摘要。
6. 地图显示 `POS`、路线步序/风险和终点风险短码；安全候选聚焦后，路线和火力风险切到被点选的攻击位。
7. 右键敌军或执行按钮移动到当前预览的攻击位。
8. 移动后聚焦敌军，提示继续点按或右键攻击；POS 本身不直接执行攻击。

### 3.5 OBJ 目标推进

1. `objectiveAdvancePlans(for:)` 选择未占据、未归属己方的据点，并按当前距离、是否直达、剩余距离、路线消耗、步数和名称稳定排序。
2. `objectiveAdvancePreviews(for:limit:)` 将同一套计划转换为最多 3 条 `ObjectiveAdvancePreview`，附带路线、距离变化、直达/推进状态和终点火力风险；首项必须与 OBJ 快捷目标一致。
3. 侧栏目标计划行点击只调用 `focusObjectiveAdvancePreview(_:)` / `focusObjectiveAdvanceTarget(coordinate:)`，由 `GameState` 重新查当前计划，避免 UI 使用过期路线。
4. `focusNearestObjectiveTarget` 复用同一套计划首项；候选计划点击也复用同一私有聚焦 helper。若可直达，聚焦据点并设置 `guidedObjectiveCoordinate`。
5. 若不可直达，聚焦本回合推进格，同时保留最终目标据点。
6. 点选计划只更新 `focusedCoordinate`、`guidedObjectiveCoordinate` 和消息，不消耗行动、不移动单位、不生成结果摘要；右键或执行按钮才通过既有 MOVE 链执行。
7. 普通聚焦、攻击、待命、回合切换等应清理目标引导，避免状态残留。
8. 只有单位实际进入中立或敌方据点并改变归属时，才生成据点占领结果；远距离 OBJ 中继推进不会生成虚假占领摘要。

### 3.6 THR 敌火覆盖

1. `threateningEnemies(against:at:)` 查询某坐标被哪些敌军射程覆盖。
2. `threatenedTiles(for:)` 生成阵营威胁地图。
3. `threatenedReachableTiles(for:)` 标记选中单位可达但危险的格子。
4. MOVE/POS 聚焦时，`PostMoveFireExposurePreview` 将敌火覆盖转换为风险等级、潜在伤害和预计剩余耐久；这是纯预览，不触发反应射击或真实伤害。
5. `ContentView` 在 HUD 显示 THR 数量，在地图显示 THR 和 SAFE/LOW/MED/HIGH/CRIT 风险标记。

### 3.7 回合和 AI

1. 玩家结束回合调用 `endTurn()`。
2. 轴心国重置行动、获得指令点，`beginAIPhaseRecording(for: .axis)` 采样 AI 行动前的指令点、单位 HP/存活和据点归属。
3. 执行 `runAxisAI()`；AI 优先整补/增援/战术命令，然后移动接敌或攻击。成功整补、部署、战术命令、攻击和移动会在规则成功路径记录动作计数。
4. `finishAIPhaseRecording()` 用前后状态差异生成 `latestAIPhaseSummary`：指令点变化、动作计数、占点、歼灭、己方损失、对敌伤害和己方承伤。被动据点休整、预览和失败动作不计入主动动作。
5. 盟军新回合重置行动、获得指令点，自动选择可行动单位；AI 回合摘要保留在侧栏，直到重开/切战役或下一次 AI 回合覆盖。

### 3.8 战术命令结果

1. `tacticalCommandPreview` 只计算火炮弹幕和突破突击的执行前结果，不写回战役状态。
2. `useTacticalCommand` 成功执行后扣除指令点、写入伤害、消耗防御姿态、更新施放者行动状态、授予经验、降低目标士气并写入战术状态。
3. `latestTacticalCommandResult` 记录施放者/目标 HP、经验、士气、军衔前后、命令类型、伤害、指令点消耗、士气损失、状态效果、无反击、击毁和防御姿态消耗。
4. 普通攻击、战术命令、据点占领、部署和整补结果互斥展示：战术命令写入 `latestTacticalCommandResult` 时清理其他结果摘要。
5. AI 使用战术命令时也通过同一 `useTacticalCommand` 路径写入结果摘要。

### 3.9 据点占领结果

1. `updateObjectiveControl()` 是据点归属变化的唯一落点。
2. 占领中立或敌方据点时，`applyObjectiveCaptureReward()` 发放指令点、经验和士气奖励，并写入 `latestObjectiveCaptureResult`。
3. 据点占领结果记录据点名、坐标、占领单位、原归属、新归属、奖励值和占领后的据点进度。
4. 据点占领结果与普通攻击结果、战术命令结果、部署结果、整补结果互斥展示；新的攻击、战术命令、部署或整补会清理旧占领结果，新的占领会清理旧战斗/战术/后勤结果。
5. `ContentView` 在侧栏战报前显示占领结果卡，并在最新占领据点显示 `CAP` 地图标记。

### 3.10 后勤结果

1. `deploy(kind:at:)` 是部署增援的成功落点；部署前校验胜负、指令点和合法部署点，失败只更新提示，不生成或清理真实结果摘要。
2. 成功部署会扣除指令点、新建已行动单位、选中新单位、聚焦部署坐标，并写入 `latestDeploymentResult`，记录来源据点、新单位 ID/名称/兵种/阵营、坐标、消耗和部署后剩余指令点。
3. `reinforce(unitID:)` 是主动整补的成功落点；只允许受损单位在己方据点且指令点足够时执行，失败只更新提示，不生成或清理真实结果摘要。
4. 成功整补会记录 HP 前后、恢复量、消耗和剩余指令点，重置该单位战术状态与防御姿态，并写入 `latestReinforcementResult`。
5. 普通攻击、战术命令、据点占领、部署和整补结果五者互斥；任一成功结果会清理其他旧结果，确保侧栏只显示最近一次真实结果。
6. AI 整补和部署复用同一路径，因此敌方回合的最新后勤动作也会生成同一类摘要；据点被动休整不写入主动整补摘要。

### 3.11 AI 回合摘要

1. `AIPhaseSummary` 是敌方回合总览模型，记录阵营、回合、AI 开始/结束指令点、主动整补、部署、战术命令、攻击、移动、占点、歼灭、损失、对敌伤害和己方承伤。
2. `latestAIPhaseSummary` 只由 `GameState` 在 `endTurn()` 包裹 `runAxisAI()` 时生成；玩家聚焦、预览和失败命令不会生成摘要。
3. 摘要的动作计数来自真实成功路径，战损和占点来自 AI phase 前后状态差异，避免 `ContentView` 二次推导规则。
4. 侧栏展示顺序仍以普通攻击、战术命令、据点占领、部署、整补等单项结果卡优先，其后显示 AI 回合摘要卡，再显示 battleLog。
5. `loadScenario()`、重开和切换战役会清理 `latestAIPhaseSummary` 以及内部 AI phase 记录器。

### 3.12 敌方威胁意图预判

1. `EnemyThreatIntentPreview` 是玩家回合的只读态势预判模型，区分直接攻击、机动接敌攻击和据点占领三类威胁。
2. `enemyThreatIntentPreviews(from:against:limit:)` 默认评估轴心国对盟军的威胁，返回稳定排序且去重后的最多 `limit` 条结果；`visibleEnemyThreatIntentPreviews` 供 `ContentView` 展示。
3. 直接攻击用敌方当前位置复用 `combatPreview(attacker:defender:)`，记录预计伤害、目标剩余 HP 和击毁判断。
4. 机动接敌攻击使用只读预测路线 helper，把敌方单位按下一回合可行动状态计算可达攻击位，再用临时位置复用 `combatPreview`；该路径不修改 `activeFaction`。
5. 据点占领威胁只针对目标阵营拥有且未被占据的据点，记录目标据点、当前归属、路线终点和消耗，不生成虚假伤害。
6. 预判查询不调用 `move`、`attack`、`deploy`、`reinforce`、`useTacticalCommand`、`appendLog` 或任何写状态方法，不改变单位行动状态、地图归属、消息、战报、指令点或 `latest*Result`。
7. `ContentView` 在侧栏战报前显示“敌方意图”面板，并在目标坐标显示 `INT` 地图标记；UI 只展示 `GameState` 已生成的字段，不计算威胁评分或战斗结果。

### 3.13 敌方意图反制建议

1. `EnemyThreatCountermeasurePreview` 是 `EnemyThreatIntentPreview` 的只读下游预览，给玩家提供抢先打击、撤出危险区、据点防守和整补支撑建议。
2. `enemyThreatCountermeasurePreviews(for:limit:)` 接收敌方意图列表或默认使用 `visibleEnemyThreatIntentPreviews`，生成稳定排序且去重后的最多 `limit` 条建议；`visibleEnemyThreatCountermeasurePreviews` 供 `ContentView` 展示。
3. 抢先打击只考虑当前可攻击威胁来源的己方单位，复用 `combatPreview(attacker:defender:)` 记录预计伤害、敌军剩余 HP、是否击毁和己方反击后 HP。
4. 撤出危险区只针对攻击类威胁，复用当前玩家可用 `movementRoutes(for:)` 与 `fireExposurePreview(for:at:)`，选择能降低威胁来源射程或提高预计剩余耐久的目的格。
5. 据点防守只针对据点占领威胁，建议己方单位进驻目标据点或移动到相邻封堵格，路线消耗来自 `movementRoutes(for:)`。
6. 整补支撑只针对受威胁、受损且满足 `canReinforce(_:)` 的己方单位，计算预计恢复量和整补后耐久，但不调用真实 `reinforce`。
7. 反制建议查询不调用 `move`、`attack`、`deploy`、`reinforce`、`useTacticalCommand`、`advanceTurn`、`performAIPhase` 或任何写状态方法，不改变 `activeFaction`、HP、位置、行动状态、据点归属、指令点、战报、消息或 `latest*Result`。
8. `focusEnemyThreatCountermeasure(_:)` 是反制建议的点选入口。它会重新校验当前单位、目标、路线或整补条件，然后只更新 `selectedUnitID`、`focusedCoordinate`、`guidedObjectiveCoordinate`、安全接敌焦点和 `message`。
9. 抢先打击聚焦执行单位和威胁来源敌军；撤出危险区聚焦执行单位和撤退目的格；据点防守聚焦防守目的格并保留被威胁据点引导；整补支撑聚焦受威胁单位当前位置。
10. 反制建议点选不调用真实移动、攻击、整补、部署、战术命令或 AI 方法，不改变 HP、位置、行动状态、据点归属、指令点、战报、胜负或 `latest*Result`。
11. `focusedEnemyThreatCountermeasureMapMarkers` 只对当前点选且仍可匹配的反制建议输出地图标记，区分 ACT 执行单位、SRC 威胁来源、CTR 反制目标和 TGT 受威胁目标；普通聚焦、行动执行、重开或切战役会清理旧反制聚焦。
12. `EnemyThreatCountermeasurePreview.benefitMetrics` 和 `benefitSummary` 从已有建议字段派生只读收益解释，覆盖战果、生存、守点、恢复、路线和优先值；它们不重新计算战斗、路线、整补或排序。
13. `EnemyThreatCountermeasurePreview.priorityFactors` 和 `prioritySummary` 从既有排序字段派生只读排序依据，覆盖可执行、击毁、优先值、路线、执行单位、目标和坐标；它们不改变 `enemyThreatCountermeasureSort`、score 公式或建议顺序。
14. `enemyThreatCountermeasureComparisonPreviews(for:limit:)` 基于已排序反制建议生成相邻对比，按 `enemyThreatCountermeasureSort` 的维度顺序解释首条为何领先下一条；`limit: 0` 或 `limit: 1` 不生成虚假对比。
15. `EnemyThreatCountermeasurePreview.impactComparisons` 由 `GameState` 构造建议时填充，`impactSummary` 由 `GameModels` 从对照数组派生，记录当前威胁后果、采纳建议后的预计状态和改善值；它们不调用真实执行方法，不改变单位、据点、指令点或战报。
16. `focusedEnemyThreatCountermeasureExecutionPreview` 只对当前点选且仍可匹配的反制建议输出下一步入口：抢先打击桥接到现有地图 ATK/执行按钮，撤出危险区和据点防守桥接到现有地图 MOVE/执行按钮，整补支撑桥接到既有单位详情整补按钮；失效时返回不可用说明或空预览。
17. 执行桥接预览复用 `mapCommandPreview(for:)`、`movementRoute(for:to:)`、`combatPreview(attacker:defender:)` 和 `canReinforce(_:)` 重新校验当前状态，不调用 `move`、`attack`、`reinforce` 或 `executeFocusedCommand()`。
18. `ContentView` 在“敌方意图”面板下方显示“反制建议”面板；建议行使用 `Button` 点选聚焦，行内显示结构化收益解释、排序依据和执行前后预计对照，面板显示首选相邻对比，地图显示反制聚焦标记，列表下方显示只读“下一步”入口提示并提供无障碍说明；UI 只展示 `GameState`/`GameModels` 字段，不计算路线、评分、战斗、整补结果、排序结果、前后对照、标记有效性或入口可执行性。

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

- 移动、攻击、补给、士气、AI、目标推进、目标推进计划摘要和候选预览、安全接敌候选点选预览、敌方威胁意图预判、敌方意图反制建议、反制建议收益解释、排序对比解释、执行前后预计对照、反制建议点选聚焦、地图标记和执行入口桥接预览、部署/整补结果摘要、AI 回合行动摘要：`GameStateTests.swift` + `RulesSmokeTest.swift`。
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
- 战斗动画、战斗结果回放动效、更多战术命令结果细节。
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
