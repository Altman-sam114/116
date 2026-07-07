# 项目核心流程文档

## 0. 一句话总览

`WW2Tactics` 的主链路是：玩家在 SwiftUI 地图上选择单位和目标，`GameState` 根据 `GameModels` 执行移动、攻击、补给、AI、目标和胜负规则，`ContentView` 将状态渲染为 EasyTech 风格的大地图战棋界面，测试层用 XCTest 和 smoke test 锁住核心规则；协作链路默认由 Agent B 在 `main` 提交并推送到 `origin/main`，GitHub Actions 生成未加密 CI 结果包，Agent C 下载结果包后验收；未来可由 Agent X 围绕人工总目标拆分多轮，并按 Agent A -> Agent B -> Agent C 循环调度。

## 1. 当前核心数据流

```text
用户输入 / 快捷按钮
  -> ContentView 地图格和 HUD 事件
  -> GameState handleTap / handlePrimaryAction / handleSecondaryAction / executeFocusedCommand / focusEnemyThreatCountermeasure / focusBattlefieldSituationPrimaryTarget / focusBattlefieldSituationObjectivePressure / focusBattlefieldSituationObjectivePressureReplayTarget / focusBattlefieldSituationResponseTarget / focusPreviousBattlefieldSituationResponse / focusNextBattlefieldSituationResponse / focusBattlefieldSituationReplayTarget / focusAIPhaseTimelineEvent / focusPreviousAIPhaseTimelineEvent / focusNextAIPhaseTimelineEvent / toggleAIPhaseTimelinePlayback / advanceAIPhaseTimelinePlayback
  -> GameModels 中的 Scenario / BattleUnit / TerrainTile / HexCoordinate / MapCommandPreview / BattlefieldSituationSummary / BattlefieldSituationObjectivePressure / BattlefieldSituationObjectivePressureMapMarker / BattlefieldSituationResponseSummary / BattlefieldSituationResponseHistoryEntry / BattlefieldSituationResponseMapMarker / BattlefieldSituationReplayTarget
  -> GameState 规则判定与状态更新
  -> @Published 状态变化
  -> ContentView 重新渲染地图、侧栏、HUD、图例、战斗结果、战报
  -> GameStateTests / RulesSmokeTest 验证行为
```

## 2. 核心模块

### 2.1 `GameModels.swift`

职责：

- 定义阵营、兵种、地形、士气、战术状态、单位、地图格、战役。
- 定义地图命令提示 `MapActionHint`、执行预览 `MapCommandPreview`、路线步骤预览 `RouteStepPreview`、移动后攻击预判 `PostMoveAttackPreview`、移动后火力暴露预览 `PostMoveFireExposurePreview`、OBJ 据点推进计划摘要 `ObjectiveAdvancePreview`、安全接敌候选 `SafeEngagementOption`、安全接敌路径风险对比 `SafeEngagementComparisonPreview`、敌方威胁意图预判 `EnemyThreatIntentPreview`、敌方意图反制建议 `EnemyThreatCountermeasurePreview`、据点防守取舍解释 `EnemyThreatObjectiveDefenseTradeoff`、反制建议收益解释 `EnemyThreatCountermeasureBenefitMetric`、反制建议排序解释 `EnemyThreatCountermeasurePriorityFactor`、反制建议相邻对比 `EnemyThreatCountermeasureComparisonPreview`、反制建议执行前后预计对照 `EnemyThreatCountermeasureImpactComparison`、反制建议地图标记 `EnemyThreatCountermeasureMapMarker`、反制建议执行桥接预览 `EnemyThreatCountermeasureExecutionPreview`、反制建议执行回放 `EnemyThreatCountermeasureExecutionResultSummary`、反制建议敌方回合复核 `EnemyThreatCountermeasureFollowUpSummary` 及其复核结论等级/定位目标/据点防守细分 `EnemyThreatObjectiveDefenseFollowUpDetail`/关联 AI 行动 `EnemyThreatCountermeasureFollowUpAIEvent`、玩家回合战线态势汇总 `BattlefieldSituationSummary` 及其据点防守压力 `BattlefieldSituationObjectivePressure`、压力态势对照 `BattlefieldSituationObjectivePressureComparison`、威胁来源坐标和压力地图标记 `BattlefieldSituationObjectivePressureMapMarker`、首要定位目标和下一步提示、战线态势执行反馈/敌方回合影响/普通行动态势响应 `BattlefieldSituationResponseSummary`、最近态势响应历史条目 `BattlefieldSituationResponseHistoryEntry`、战线态势响应地图标记 `BattlefieldSituationResponseMapMarker`、战线态势关联 AI 复盘目标 `BattlefieldSituationReplayTarget`、普通攻击后的 `CombatResultSummary`、战术命令后的 `TacticalCommandResultSummary`、据点占领后的 `ObjectiveCaptureResultSummary`、部署后的 `DeploymentResultSummary`、整补后的 `ReinforcementResultSummary`、敌方回合行动时间线 `AIPhaseTimelineEvent`、敌方回合复盘播放速度 `AIPhaseTimelinePlaybackPace`、敌方回合地图复盘标记 `AIPhaseMapMarker`、敌方回合后的 `AIPhaseSummary` 和纯派生复盘结论 `AIPhaseReplayConclusion`。
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
- 管理当前战役、选中单位、焦点坐标、安全接敌候选焦点、当前阵营、回合、消息、战报、最新普通攻击结果、最新战术命令结果、最新据点占领结果、最新部署结果、最新整补结果、最新反制建议执行回放、最新反制建议敌方回合复核、最近 5 条态势响应历史、当前查看响应 order、最新 AI 回合摘要及其行动时间线、AI 复盘播放状态和速度、胜负、指令点。
- 处理移动、攻击、反击、攻击后战损摘要、补给、士气、控制区、战术命令、战术命令结果摘要、增援、部署结果摘要、整补、整补结果摘要、据点占领、据点占领结果摘要、目标推进、目标推进计划摘要、AI 行动、AI 回合摘要和行动时间线、AI 行动地图复盘标记派生、当前 AI 复盘事件选中 order、上一条/下一条复盘导航、播放/暂停/速度控制及其地图标记派生、威胁覆盖、路线步骤情报、移动后攻击预判、移动后火力暴露预览、安全接敌候选、安全接敌路径风险对比、敌方威胁意图预判、敌方意图反制建议、战线态势汇总和据点防守压力列表、据点压力地图标记、压力行当前态、压力态势对照和压力复盘线索、首要目标定位、下一步提示、执行反馈、敌方回合影响、普通行动态势响应、态势响应历史追加/裁剪/连续查看、态势响应地图标记、态势响应定位入口和 AI 关键复盘目标派生、反制建议相邻排序对比、反制建议执行前后预计对照、当前反制建议地图标记派生、当前反制建议执行入口桥接派生、最近一次反制建议执行回放、敌方回合后复核、据点防守复核细分、关联 AI 行动和复核目标定位。

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
- 显示 MOVE、ATK、POS、NEXT、OBJ、CAP、THR、INT、AI 复盘、战线态势汇总、据点压力行当前态、据点压力态势对照、据点压力地图标记、据点压力复盘线索、态势响应地图标记、态势响应定位入口、态势响应上一条/下一条历史查看、首要定位入口、下一步提示、执行反馈、普通行动态势响应、敌方回合影响和关联 AI 复盘入口、补给线、控制区、攻击覆盖等标记。

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
4. `focusedSafeEngagementComparisons` 以未切换安全候选前的默认 POS 首选路线为稳定参考，把候选路线与默认路线的风险等级、潜在承伤、最高单源伤害、敌火来源数量、移动力消耗、控制区惩罚和路线受威胁步数做成纯派生对比；即使当前已点选某安全候选，对比参考也不漂移成“候选和自己比”。
5. 侧栏安全接敌候选点击只调用 `focusSafeEngagementOption(_:)` / `focusSafeEngagement(targetID:destination:)`，由 `GameState` 基于当前单位和目标敌军重新查候选路线，避免 UI 使用过期路线。
6. 点选安全候选只切换 `focusedSafeEngagementDestination` 和当前 POS 预览路线，不消耗行动、不移动单位、不自动攻击、不生成结果摘要。
7. 地图显示 `POS`、路线步序/风险和终点风险短码；安全候选聚焦后，路线和火力风险切到被点选的攻击位，候选行继续显示相对默认 POS 路线的风险/承伤/移动代价对比。
7. 右键敌军或执行按钮移动到当前预览的攻击位。
8. 移动后聚焦敌军，提示继续点按或右键攻击；POS 本身不直接执行攻击。

### 3.5 OBJ 目标推进

1. `objectiveAdvancePlans(for:)` 选择未占据、未归属己方的据点，并按当前距离、是否直达、剩余距离、路线消耗、步数和名称稳定排序。
2. `objectiveAdvancePreviews(for:limit:)` 将同一套计划转换为最多 3 条 `ObjectiveAdvancePreview`，附带路线、距离变化、直达/推进状态、终点火力风险和优先级解释；首项必须与 OBJ 快捷目标一致。
3. `ObjectiveAdvancePreview` 的优先级解释从已有字段纯派生，说明据点归属、本回合可占/可夺或推进几格、当前距离到剩余距离、路线消耗、步数、控制区惩罚和终点风险；它不改变 `objectiveAdvancePlanSort`，也不新增据点评分。
4. 侧栏目标计划行点击只调用 `focusObjectiveAdvancePreview(_:)` / `focusObjectiveAdvanceTarget(coordinate:)`，由 `GameState` 重新查当前计划，避免 UI 使用过期路线。
5. `focusNearestObjectiveTarget` 复用同一套计划首项；候选计划点击也复用同一私有聚焦 helper。若可直达，聚焦据点并设置 `guidedObjectiveCoordinate`。
6. 若不可直达，聚焦本回合推进格，同时保留最终目标据点。
7. 点选计划只更新 `focusedCoordinate`、`guidedObjectiveCoordinate` 和消息，不消耗行动、不移动单位、不生成结果摘要；右键或执行按钮才通过既有 MOVE 链执行。
8. 普通聚焦、攻击、待命、回合切换等应清理目标引导，避免状态残留。
9. 只有单位实际进入中立或敌方据点并改变归属时，才生成据点占领结果；远距离 OBJ 中继推进不会生成虚假占领摘要。

### 3.6 THR 敌火覆盖

1. `threateningEnemies(against:at:)` 查询某坐标被哪些敌军射程覆盖。
2. `threatenedTiles(for:)` 生成阵营威胁地图。
3. `threatenedReachableTiles(for:)` 标记选中单位可达但危险的格子。
4. MOVE/POS 聚焦时，`PostMoveFireExposurePreview` 将敌火覆盖转换为风险等级、潜在伤害和预计剩余耐久；这是纯预览，不触发反应射击或真实伤害。
5. `ContentView` 在 HUD 显示 THR 数量，在地图显示 THR 和 SAFE/LOW/MED/HIGH/CRIT 风险标记。

### 3.7 回合和 AI

1. 玩家结束回合调用 `endTurn()`。
2. 轴心国重置行动、获得指令点，`beginAIPhaseRecording(for: .axis)` 采样 AI 行动前的指令点、单位 HP/存活和据点归属。
3. 执行 `runAxisAI()`；AI 优先整补/增援，随后按可击毁攻击、战术命令、直取可达非己方据点、普通攻击、推进接敌的顺序行动。推进接敌后会先尝试普通攻击；若普通攻击不可用但战术命令可用，移动后的火炮等单位会继续执行战术压制。成功整补、部署、战术命令、攻击和移动会在规则成功路径记录动作计数，并追加结构化 `AIPhaseTimelineEvent`。
4. `finishAIPhaseRecording()` 用前后状态差异生成 `latestAIPhaseSummary`：指令点变化、动作计数、占点、歼灭、己方损失、对敌伤害、己方承伤和真实成功动作时间线。被动据点休整、预览和失败动作不计入主动动作，也不会生成时间线事件。
5. 若玩家回合结束前存在最近一次反制建议执行回放，`GameState` 会在清理即时回放前保存单位 HP/位置、威胁来源和据点归属基线，并在 `finishAIPhaseRecording()` 后、盟军新回合休整前发布 `latestEnemyThreatCountermeasureFollowUpResult`；据点防守复核会额外记录进驻/封堵动作、守点位置、威胁来源是否仍压迫据点、防守单位状态，并从同一 `AIPhaseSummary.timeline` 保守关联最多 3 条真实 AI 行动。
6. 盟军新回合重置行动、获得指令点，自动选择可行动单位；AI 回合摘要、行动时间线、由时间线派生的地图复盘标记和反制建议敌方回合复核保留在侧栏/地图，点选时间线、使用上一条/下一条或播放 tick 后还会保留当前复盘事件 order 和对应标记强调；复盘播放状态会在播放到末尾、手动暂停、重开/切战役或下一次 AI 回合开始时清理，其他复盘状态直到重开/切战役、下一次 AI 回合开始清理、下一次 AI 回合无基线清理或新的反制执行覆盖。

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

### 3.11 AI 回合摘要和行动时间线

1. `AIPhaseSummary` 是敌方回合总览模型，记录阵营、回合、AI 开始/结束指令点、主动整补、部署、战术命令、攻击、移动、占点、歼灭、损失、对敌伤害、己方承伤和 `timeline`。
2. `latestAIPhaseSummary` 只由 `GameState` 在 `endTurn()` 包裹 `runAxisAI()` 时生成；玩家聚焦、预览和失败命令不会生成摘要。
3. `AIPhaseTimelineEvent` 记录真实成功动作的顺序号、阵营、回合、动作类型、行动单位、目标单位、起终点、战术命令、部署兵种、据点、伤害、反击、恢复、指令点消耗/奖励、剩余指令点、击毁和占点标记。
4. 摘要的动作计数来自真实成功路径，战损和占点来自 AI phase 前后状态差异；占点作为结果事件写入时间线，但不增加 `totalActions`。
5. `AIPhaseSummary.replayConclusion` 是纯派生战果结论，不新增 `@Published` 状态。它按占点、火力/击毁/战术命令、后勤、机动、低强度的优先级归类为夺点突破、火力压制、后勤整备、机动推进或低强度回合，并固定输出伤害、占点、后勤和指令点指标。
6. `AIPhaseReplayKeyEvent` 从时间线纯派生最多 3 条关键事件，优先占点，其次击毁、高伤害、战术命令和后勤；同优先级按原始 order 稳定排序。结论区关键事件按钮只把 key event 的 `order` 转发给 `focusAIPhaseTimelineEvent(order:)`，不自行查坐标、marker 或重新排序。
7. 移动导致占点时，时间线顺序为移动事件先写入，再由 `updateObjectiveControl()` 写入占点事件；直取据点场景形成 `move -> objectiveCapture`，机动追击场景可形成 `attack -> move -> objectiveCapture`，移动后火炮弹幕场景可形成 `move -> tacticalCommand`。
8. `latestAIPhaseMapMarkers` 是从 `latestAIPhaseSummary.timeline` 纯派生的只读地图复盘标记，不新增独立 `@Published` 状态。移动输出起点/终点，攻击和战术命令输出行动单位/目标，部署和整补输出目的坐标，占点输出据点坐标；缺少坐标的事件会被容忍，不由 View 反推。
9. `focusedAIPhaseTimelineEventOrder` 记录当前成功点选的 AI 时间线顺序号；`focusedAIPhaseMapMarkers` 从 `latestAIPhaseMapMarkers` 按该 order 过滤派生，不存第二份 marker。
10. `focusAIPhaseTimelineEvent(order:)` 是侧栏时间线点选定位入口。它只从最新 `AIPhaseSummary.timeline` 查找事件，按 `event.to ?? event.from` 选择定位坐标，校验坐标仍在当前地图后更新 `focusedCoordinate`、`focusedAIPhaseTimelineEventOrder` 和 `message`，并清理 OBJ/SAFE/反制等临时引导。
11. `focusPreviousAIPhaseTimelineEvent()` / `focusNextAIPhaseTimelineEvent()` 是连续复盘入口。它们从最新 timeline 和当前 order 选择相邻事件；无当前 order 时 next 从第一条开始、previous 从最后一条开始；到达首尾边界时只写边界提示并保留旧焦点和旧 order。
12. `toggleAIPhaseTimelinePlayback()` / `pauseAIPhaseTimelinePlayback()` / `setAIPhaseTimelinePlaybackPace(_:)` / `advanceAIPhaseTimelinePlayback()` 是自动复盘入口。播放可用性来自 `GameState.canPlayAIPhaseTimeline`；无当前 order 时第一次 tick 聚焦第一条，有当前 order 时 tick 聚焦下一条，到最后一条后自动暂停并保留最后焦点、order 和 marker 强调；已在最后一条时播放只写提示不启动。
13. 点选、连续切换或自动播放 AI 时间线不会调用移动、攻击、战术命令、部署、整补或 AI 方法，不改变单位 HP/位置、行动状态、据点归属、指令点、AI summary、timeline 或 `latestAIPhaseMapMarkers`；无 summary、无事件、无坐标或坐标不在当前地图时只写提示并保留旧焦点和旧复盘选中 order，播放路径会同时暂停。
14. 侧栏展示顺序仍以普通攻击、战术命令、据点占领、部署、整补等单项结果卡优先，其后显示 AI 回合摘要卡、复盘结论和最多 5 条行动时间线，再显示 battleLog；地图将同坐标 AI 复盘标记聚合成紧凑徽标，并把复盘内容加入 tile 无障碍文案。结论关键事件、时间线行、播放/暂停、速度菜单和上一条/下一条按钮使用 `Button` / `Menu` 转发到 `GameState`，当前结论关键事件和当前时间线行共享 `focusedAIPhaseTimelineEventOrder` 选中态，地图自动滚动复用 `focusedCoordinate` 监听链，并把当前事件 marker 强调为当前 AI 复盘。
15. `loadScenario()`、重开和切换战役会清理 `latestAIPhaseSummary`、当前复盘选中 order、复盘播放状态、内部 AI phase 记录器和 timeline 缓冲；复盘标记随 summary 变空而变空。下一次 AI 回合开始记录时也会清理旧复盘选中 order 和播放状态，避免跨回合残留。

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
13. `EnemyThreatCountermeasurePreview.objectiveDefenseTradeoff` 只对 `.objectiveDefense` 从 `destination`、`threatTargetCoordinate`、`targetName`、`routeCost`、`score` 和 objective impact 纯派生进驻/封堵取舍说明；非守点建议返回空。它不参与 `enemyThreatCountermeasureSort`、不改 score、不新增 `@Published` 状态，也不调用移动、攻击、整补、部署或 AI。
14. `EnemyThreatCountermeasurePreview.priorityFactors` 和 `prioritySummary` 从既有排序字段派生只读排序依据，覆盖可执行、击毁、优先值、路线、执行单位、目标和坐标；它们不改变 `enemyThreatCountermeasureSort`、score 公式或建议顺序。
15. `enemyThreatCountermeasureComparisonPreviews(for:limit:)` 基于已排序反制建议生成相邻对比，按 `enemyThreatCountermeasureSort` 的维度顺序解释首条为何领先下一条；`limit: 0` 或 `limit: 1` 不生成虚假对比。
16. `EnemyThreatCountermeasurePreview.impactComparisons` 由 `GameState` 构造建议时填充，`impactSummary` 由 `GameModels` 从对照数组派生，记录当前威胁后果、采纳建议后的预计状态和改善值；它们不调用真实执行方法，不改变单位、据点、指令点或战报。
17. `focusedEnemyThreatCountermeasureExecutionPreview` 只对当前点选且仍可匹配的反制建议输出下一步入口：抢先打击桥接到现有地图 ATK/执行按钮，撤出危险区和据点防守桥接到现有地图 MOVE/执行按钮，整补支撑桥接到既有单位详情整补按钮；失效时返回不可用说明或空预览。
18. 执行桥接预览复用 `mapCommandPreview(for:)`、`movementRoute(for:to:)`、`combatPreview(attacker:defender:)` 和 `canReinforce(_:)` 重新校验当前状态，不调用 `move`、`attack`、`reinforce` 或 `executeFocusedCommand()`。
19. `latestEnemyThreatCountermeasureExecutionResult` 只在当前点选反制建议经既有 ATK、MOVE 或整补入口真实成功执行后写入：抢先打击读取 `latestCombatResult`，撤出危险区和据点防守读取执行后的单位位置/HP/据点关系，整补支撑读取 `latestReinforcementResult`。
20. 执行回放只比较“预计 / 实际 / 结果”，不会重新计算或改变战斗、移动、整补、AI、排序、score 或胜负规则；预览、点选建议、普通聚焦和过期建议不生成回放。
21. `endTurn()` 会在清理 `latestEnemyThreatCountermeasureExecutionResult` 前捕获复核基线，保存执行回放、执行单位、受威胁单位、威胁来源、据点归属和执行后坐标；即时回放仍按回合切换语义清空。
22. `latestEnemyThreatCountermeasureFollowUpResult` 只在敌方 AI 阶段完成后由 `GameState` 发布，基于真实 post-AI 状态对比 HP、位置、威胁源存活、据点归属和 AI 总览；`.objectiveDefense` 会追加“守点位置”“威胁来源”对照和 `objectiveDefenseDetail`，说明进驻/封堵是否奏效、据点是否守住、防守单位是否受损、威胁源是否仍压迫据点；同时 `relatedAIEvents` 从真实 timeline 按据点坐标、防守单位、威胁来源和目标单位匹配最多 3 条事件，只表达关联，不模拟 AI，也不精确归因逐行动 attacker/target。
23. `EnemyThreatCountermeasureFollowUpSummary.outcomeLevel` 对据点防守优先读取结构化 `objectiveDefenseDetail.result`，其他反制仍从既有复核结论和 comparisons 纯派生奏效、部分奏效或失败；`focusTargets` 从执行单位、威胁来源和受威胁目标/据点字段纯派生定位入口，不新增 `@Published` 状态。
24. `focusEnemyThreatCountermeasureFollowUpTarget(_:)` 是复核卡定位入口。它只接受当前最新复核 summary 中仍存在的目标，重新定位单位或坐标后更新 `focusedCoordinate` 和 `message`；目标过期或坐标不可用时只写提示，不调用移动、攻击、整补、部署、战术命令或 AI 方法，也不改变单位、据点、指令点、AI summary、follow-up summary、战报或胜负。
25. `loadScenario()`、重开、切战役、下一次无基线回合切换、新的反制执行回放和新的无关普通移动、攻击、整补、部署、战术命令或占点成功路径会清理旧回放或旧复核，避免侧栏显示过期结果。
26. `ContentView` 在“敌方意图”面板下方显示“反制建议”面板；建议行使用 `Button` 点选聚焦，行内显示结构化收益解释、据点防守取舍、排序依据和执行前后预计对照，面板显示首选相邻对比，地图显示反制聚焦标记，列表下方显示只读“下一步”入口提示，真实执行后显示最近一次反制回放，敌方回合后显示复核卡、复核等级、据点防守复核细分、关联 AI 行动和定位按钮并提供无障碍说明；关联 AI 行动按钮只转发 order 到 `focusAIPhaseTimelineEvent(order:)`；UI 只展示 `GameState`/`GameModels` 字段，不计算路线、评分、战斗、整补结果、排序结果、前后对照、回放结果、敌方回合复核、复核等级、守点细分、关联行动、定位有效性或入口可执行性。

### 3.14 战线态势汇总

1. `BattlefieldSituationSummary` 是当前行动阵营的只读玩家回合态势模型，汇总指令点、待命部队、据点进度、敌方意图数量、攻击威胁数量、据点威胁数量、可执行反制数量、受威胁据点、据点防守压力、首要建议、首要定位目标、下一步提示和可定位的 AI 关键复盘事件。
2. `GameState.battlefieldSituationSummary` 是 computed property，不新增 `@Published` 状态；它复用 `enemyThreatIntentPreviews(from:against:limit:)`、`enemyThreatCountermeasurePreviews(for:limit:)`、`readyUnits`、`objectiveTiles` 和 `activeCommandPoints` 纯派生。
3. `BattlefieldSituationObjectivePressure` 从同一批 `.objectiveCapture` 敌方意图、同 threatID 的反制建议和最新 AI 时间线纯派生，按据点坐标聚合威胁来源数量、当前归属、首要占点风险、推荐反制入口、可执行性、态势对照和可选复盘线索；它不调用移动、攻击、整补、部署、战术命令或 AI，也不改变敌方意图排序、反制 score、AI 时间线或守点规则。
4. 首要建议优先级为：已胜负结算、存在可执行反制、存在受威胁据点、仍有待命单位且据点未全控、仍有待命单位但战线稳定、暂无待命单位可结束回合。
5. 态势汇总查询不调用移动、攻击、战术命令、部署、整补、AI、日志写入或任何真实执行方法，不改变单位 HP/位置、行动状态、据点归属、指令点、战报、结果摘要、AI 摘要或胜负。
6. `BattlefieldSituationFocusTarget` 从同一批态势输入纯派生，优先定位可执行反制，其次受威胁据点，其次选中/待命单位的首个 OBJ 推进计划，最后定位第一支待命单位；没有可行动目标或战役已结算时为空。
7. `BattlefieldSituationActionHint` 挂在首要定位目标和据点防守压力上，同步说明定位后的下一步入口：抢先打击为 ATK，撤退和据点防守为 MOVE，整补支撑为整补按钮，OBJ 推进为 MOVE，待命单位为选择后查看入口，单纯受威胁据点为防守查看提示。
8. action hint 是只读解释，不依赖 SwiftUI 焦点现场重算，不调用真实命令，也不替代 `EnemyThreatCountermeasureExecutionPreview`；反制目标定位后，既有执行桥接预览仍负责重新校验当前状态。
9. `focusBattlefieldSituationPrimaryTarget()` 每次点击都重新读取最新 `battlefieldSituationSummary.primaryFocusTarget`，再复用 `focusEnemyThreatCountermeasure(_:)`、`focusObjectiveAdvancePreview(_:)` 或既有选择/聚焦逻辑；它只更新选择、焦点、目标引导和消息，不消耗行动、不执行攻击/移动/整补/部署/回合推进。
10. `focusBattlefieldSituationObjectivePressure(id:)` 每次点击都重新读取最新压力列表并按 id 校验。若压力仍有关联反制，复用 `focusEnemyThreatCountermeasure(_:)` 定位执行单位、目的格和守点引导；若无反制，则只聚焦受威胁据点并设置目标引导。过期 id、战役结算或坐标失效只写提示，不使用旧对象继续定位。
11. `BattlefieldSituationObjectivePressure.threatSourceCoordinates` 从同一压力分组内敌方威胁的 `enemyUnitID` 回查当前单位位置，过滤失效坐标，去重并稳定排序；它只解释来源位置，不改变威胁排序、反制建议或 AI。
12. `focusedBattlefieldSituationObjectivePressureMapMarkers` 从当前压力 id 和最新压力列表纯派生，不新增 `@Published` marker 数组。它对受压据点输出 PRS 标记，对威胁来源输出 SRC 标记；若有不同于据点坐标的守点目的格，则输出 DEF 标记。普通聚焦、选择单位、直接点选普通反制、重开和切战役会清理当前压力 id，避免旧压力标记残留。
13. `isBattlefieldSituationObjectivePressureFocused(id:)` 只读判断给定压力 id 是否等于当前压力 id，且仍存在于最新 `battlefieldSituationSummary.objectivePressures`。它和 PRS/SRC/DEF marker 使用同一个 `GameState` 当前压力 id，不在 SwiftUI 中保存独立选中状态。
14. `BattlefieldSituationObjectivePressure.comparison` 是压力行的只读态势对照，从据点归属、威胁来源数量、路线状态、action hint、匹配反制和 replay target 派生当前守势/敌控/中立争夺、当前详情、应对标题和应对详情；它不模拟未来敌方行动，也不改变 pressure id。
15. `BattlefieldSituationObjectivePressure.replayTarget` 从最新 `AIPhaseSummary.timeline` 保守匹配当前压力的威胁来源单位或受压据点坐标，只输出 1 条可定位 `BattlefieldSituationReplayTarget`。匹配优先威胁来源单位，再按据点坐标，事件类型按占点、移动、攻击、战术命令等稳定排序；无匹配、无 AI summary、无坐标或坐标失效时为空，不回退到全局关键事件。
16. `focusedBattlefieldSituationObjectivePressureReplayTarget` 从当前压力 id 和最新压力列表纯派生，不新增 `@Published` 状态。`focusBattlefieldSituationObjectivePressureReplayTarget()` 每次点击重新校验当前压力和 replay target，有目标时复用 `focusAIPhaseTimelineEvent(order:)` 移交到 AI 复盘焦点，无目标或过期时只写提示。
17. 据点压力定位只更新选择、焦点、目标引导、反制聚焦、当前压力 id 和消息；据点压力复盘线索只切换 AI 复盘焦点和地图复盘标记强调；据点压力态势对照只展示结构化文案。三者都不调用移动、攻击、整补、部署、战术命令、回合推进或 AI，不改变单位 HP/位置、行动状态、据点归属、指令点、战报、latest result、AI summary 或胜负。
18. `BattlefieldSituationResponseSummary` 是态势响应的只读展示模型；反制 follow-up、反制执行、据点占领、普通战斗、战术命令、部署和整补的真实成功发布点会把当前响应快照追加为 `BattlefieldSituationResponseHistoryEntry`，最近历史最多保留 5 条，最新响应默认成为当前查看项。
19. `GameState.battlefieldSituationResponseSummary` 从当前查看的历史条目派生，不再从 `latest*Result` 读取时即时拼装旧响应；内部 `latestBattlefieldSituationResponseSummary` 只供真实成功发布点生成快照。读取 summary 不追加历史，不调用移动、攻击、战术命令、部署、整补、AI、日志写入或任何真实执行方法。
20. 敌方回合影响响应显示复核等级、反制类型、执行单位、目标、结论、首条敌方回合前后对比和复核坐标；据点防守响应首条结果仍以据点归属为准，细分进驻/封堵、守点位置、威胁来源和关联 AI 行动只作为复核 detail 展示；它不重新模拟 AI，也不精确归因逐个 AI 行动。无反制 baseline 的敌方回合不会伪造 follow-up 响应；若 AI 真实占点触发既有占点结果，仍可显示占点响应。
21. 反制执行响应显示建议类型、执行单位、入口类型、首条预计/实际对照和执行坐标；占点响应显示占领/夺取据点、归属变化、奖励和据点进度；普通战斗响应显示攻击单位、目标、伤害、反击、目标 HP、防御姿态、追击和夹击影响；战术命令响应显示命令名、施放者、目标、伤害、指令点消耗、士气/状态和无反击；部署响应显示来源据点、新单位、部署坐标和剩余指令点；整补响应显示单位、HP 恢复和指令点消耗。普通移动、预览聚焦或失败命令不会伪造态势响应或追加历史。
22. `focusedBattlefieldSituationResponseOrder` 记录当前查看的历史响应；`focusPreviousBattlefieldSituationResponse()` 和 `focusNextBattlefieldSituationResponse()` 只在最近 5 条历史内切换当前查看项，更新焦点坐标和消息，不能执行命令，也不能改变单位、据点、指令点、战报、AI 摘要、latest result 或历史内容。边界处只写提示并保留旧选中项。
23. `BattlefieldSituationResponseMapMarker` 是当前查看响应的只读地图投影；`GameState.battlefieldSituationResponseMapMarker` 只在响应坐标存在且仍属于当前地图时输出 marker，复用 response kind 的短码和图标，不新增第二份 marker 状态，不改变焦点、消息、单位、据点、指令点、战报、AI 摘要或 latest result。
24. `focusBattlefieldSituationResponseTarget()` 每次点击都重新读取当前查看响应的 `battlefieldSituationResponseMapMarker`；有合法 marker 时只更新 `focusedCoordinate` 和消息，无 marker 或坐标失效时只写提示。它不执行移动、攻击、战术命令、部署、整补、回合推进或 AI，也不清理 OBJ/SAFE/反制引导，不改变 response、marker、history、latest result、单位、据点、指令点、战报或胜负。
25. `loadScenario()`、重开和切换战役会清空态势响应历史、当前查看 order 和历史序号，避免旧响应坐标污染新场景；普通移动和失败命令不清空历史，只是不追加新响应。
26. `BattlefieldSituationReplayTarget` 从最新 `AIPhaseSummary.replayConclusion.keyEvents.first` 或单条据点压力的保守 timeline 匹配纯派生，并用同一 summary 的 timeline 按 order 回查定位坐标；只有 `event.to ?? event.from` 存在且仍在当前地图内时才输出目标。它不新增 `@Published` 状态，不改变 AI summary、timeline、关键事件排序或地图 marker。
27. `focusBattlefieldSituationReplayTarget()` 每次点击都重新读取最新 `battlefieldSituationSummary.replayTarget`，有目标时只调用既有 `focusAIPhaseTimelineEvent(order:)`，无目标时只写提示；它不直接设置坐标、不过滤 marker、不执行移动、攻击、战术命令、部署、整补或 AI。
28. `ContentView` 在侧栏靠前显示“战线态势”卡，展示 summary 的等级、指标、受威胁据点、据点防守压力、压力态势对照、建议说明、态势响应反馈/敌方回合影响、响应历史位置、上一条/下一条响应按钮、响应定位按钮、“复盘影响”按钮、首要“定位”按钮和下一步入口提示；据点压力行是按钮，但只把压力 id 转发给 `GameState`，并通过 `isBattlefieldSituationObjectivePressureFocused(id:)` 展示当前态。当前压力若有 replay target，压力列表下方显示独立“复盘线索”按钮，避免嵌套在压力行按钮内。地图格展示当前压力派生的 PRS/SRC/DEF marker 和当前查看响应派生的态势响应 marker，并把压力摘要和响应摘要加入 tile 无障碍文案。UI 不重新计算威胁、反制、据点压力、压力态势对照、OBJ 计划、待命单位、入口类型、执行反馈、复核影响、AI timeline、关键事件坐标、压力选中、压力复盘线索、威胁来源或地图 marker。

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

- 移动、攻击、补给、士气、AI、目标推进、目标推进计划摘要、优先级解释和候选预览、安全接敌候选点选预览、安全接敌路径风险对比、敌方威胁意图预判、敌方意图反制建议、反制建议收益解释、据点防守取舍解释、排序对比解释、执行前后预计对照、反制建议点选聚焦、地图标记、执行入口桥接预览、执行回放、敌方回合复核、据点防守复核细分、关联 AI 行动、复核等级和复核目标定位、战线态势汇总、据点防守压力列表、据点压力定位入口、据点压力行当前态、据点压力态势对照、据点压力威胁来源和地图标记、据点压力复盘线索、首要定位、下一步提示、执行反馈、普通行动态势响应、态势响应历史追加/裁剪/连续查看、态势响应地图标记、态势响应定位入口、敌方回合影响和 AI 关键复盘联动定位、部署/整补结果摘要、AI 直取据点优先、AI 移动后火炮弹幕、AI 回合行动摘要、行动时间线、AI 时间线点选定位、复盘事件选中态、上一条/下一条连续查看、自动播放控制和地图复盘标记强调：`GameStateTests.swift` + `RulesSmokeTest.swift`。
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
