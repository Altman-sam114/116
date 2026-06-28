# 项目核心流程文档

## 0. 一句话总览

`WW2Tactics` 的主链路是：玩家在 SwiftUI 地图上选择单位和目标，`GameState` 根据 `GameModels` 执行移动、攻击、补给、AI、目标和胜负规则，`ContentView` 将状态渲染为 EasyTech 风格的大地图战棋界面，测试层用 XCTest 和 smoke test 锁住核心规则。

## 1. 当前核心数据流

```text
用户输入 / 快捷按钮
  -> ContentView 地图格和 HUD 事件
  -> GameState handleTap / handlePrimaryAction / handleSecondaryAction / executeFocusedCommand
  -> GameModels 中的 Scenario / BattleUnit / TerrainTile / HexCoordinate / MapCommandPreview
  -> GameState 规则判定与状态更新
  -> @Published 状态变化
  -> ContentView 重新渲染地图、侧栏、HUD、图例、战报
  -> GameStateTests / RulesSmokeTest 验证行为
```

## 2. 核心模块

### 2.1 `GameModels.swift`

职责：

- 定义阵营、兵种、地形、士气、战术状态、单位、地图格、战役。
- 定义地图命令提示 `MapActionHint` 和执行预览 `MapCommandPreview`。
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
- 管理当前战役、选中单位、焦点坐标、当前阵营、回合、消息、战报、胜负、指令点。
- 处理移动、攻击、反击、补给、士气、控制区、战术命令、增援、据点占领、目标推进、AI 行动、威胁覆盖。

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
2. 地图显示 `MOVE` 标记和移动消耗。
3. 右键或执行按钮触发 `executeMapCommand(.move)`。
4. `move(unitID:to:)` 更新单位位置、消耗移动、清理防御姿态、更新据点控制。
5. 若移动后有可攻击目标，聚焦 NEXT 目标。

### 3.3 攻击

1. `attackCoverageTiles` 和 `attackableTiles` 判断射程覆盖与有效目标。
2. `combatPreview` 计算伤害、反击、地形、兵种克制、夹击、将领协同、击毁结果。
3. 地图显示 `ATK`、伤害或 `KILL`。
4. 右键或执行按钮触发 `attack(attackerID:targetID:)`。
5. 攻击更新 HP、经验、士气、行动状态、战报、胜负。

### 3.4 接敌 POS

1. 敌军射程外但存在可进入攻击位时，`attackPositionRoutes` 返回路线。
2. 地图显示 `POS`。
3. 右键敌军或执行按钮移动到攻击位。
4. 移动后聚焦敌军，提示继续点按或右键攻击。

### 3.5 OBJ 目标推进

1. `focusNearestObjectiveTarget` 选择最近未占据、未归属己方的据点。
2. 若可直达，聚焦据点并设置 `guidedObjectiveCoordinate`。
3. 若不可直达，聚焦本回合推进格，同时保留最终目标据点。
4. 普通聚焦、攻击、待命、回合切换等应清理目标引导，避免状态残留。

### 3.6 THR 敌火覆盖

1. `threateningEnemies(against:at:)` 查询某坐标被哪些敌军射程覆盖。
2. `threatenedTiles(for:)` 生成阵营威胁地图。
3. `threatenedReachableTiles(for:)` 标记选中单位可达但危险的格子。
4. `ContentView` 在 HUD 显示 THR 数量，在地图显示 THR 标记。

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
- 文档-only 修改：`git diff --check`。

## 7. 已确认铁律

- 聚焦不能执行命令。
- 右键/执行按钮才执行 MOVE、ATK、POS。
- 非法命令只提示，不消耗行动。
- 核心规则不能写进 View。
- 用户可见功能变化必须更新 README。
- 核心流程变化必须更新 `md/flow`。
- 测试命令和结果必须真实记录。

## 8. 未来扩展点

- 地图拖动/缩放手感、路线箭头、危险格更细粒度显示。
- 战斗动画、战损弹窗、攻击前后对比。
- 更完整 AI：据点优先级、补给、撤退、集中火力。
- 更多战役、国家、科技、生产队列。
- 保存进度和战役进度界面。
- 真实地图贴图、单位立绘、将领头像。

## 9. 不允许破坏的行为

- 选中己方单位后，地图必须显示可移动/可攻击/可接敌反馈。
- 据点条和敌军条只能聚焦，不得误触发攻击。
- 移动后若出现 NEXT 目标，应自动聚焦并可继续攻击。
- OBJ 引导必须在普通聚焦或行动后按规则清理。
- THR 只提示危险，不应阻止合法移动，除非未来规则明确改变。
