# 项目流程图

本文用 Mermaid 图把当前真实逻辑画出来。每张图前都有读图说明，方便人工快速理解。

## 1. 核心逻辑图

读图说明：这张图从玩家输入开始，看状态如何进入 `GameState`，再如何通过规则更新并回到 SwiftUI 界面。左侧是用户入口，中间是规则状态机，右侧是渲染和测试。

```mermaid
flowchart TD
  U["用户操作：左键 / 点按 / 右键 / 快捷按钮"] --> V["SwiftUI 表现层：ContentView 根编排 + BattlefieldChrome HUD + BattlefieldMap input + BattlefieldUnitViews"]
  V --> VD["只读视觉派生：连续地貌邻接 / 四类单位剪影 / 阵营底座 / HP / 将领徽章"]
  VD --> V
  V --> I["输入转发：handleTap / handlePrimaryAction / handleSecondaryAction / executeFocusedCommand / focusObjectiveAdvanceTarget / focusEnemyThreatCountermeasure / focusBattlefieldSituationPrimaryTarget / focusBattlefieldSituationObjectivePressure / focusBattlefieldSituationObjectivePressureReplayTarget / focusBattlefieldSituationResponseTarget / focusPreviousBattlefieldSituationResponse / focusNextBattlefieldSituationResponse / focusBattlefieldSituationReplayTarget / focusAIPhaseTimelineEvent / focusPreviousAIPhaseTimelineEvent / focusNextAIPhaseTimelineEvent / toggleAIPhaseTimelinePlayback / advanceAIPhaseTimelinePlayback"]
  I --> S["GameState：核心状态机"]
  M["GameModels：Scenario、BattleUnit、TerrainTile、HexCoordinate、CommandPreview、ObjectiveAdvancePreview、SafeEngagementComparisonPreview、EnemyThreatIntentPreview、EnemyThreatCountermeasurePreview、BattlefieldSituationSummary/ObjectivePressure/ObjectivePressureSource/ObjectivePressureComparison/ObjectivePressureEnemyPhaseImpact/ObjectivePressureMapMarker/FocusTarget/ActionHint/ResponseSummary/ResponseHistoryEntry/ResponseMapMarker/ReplayTarget/ReplayTargetSource、BenefitMetric、PriorityFactor、ComparisonPreview、ImpactComparison、EnemyThreatCountermeasureExecutionPreview、ExecutionResultSummary、FollowUpSummary/ObjectiveDefenseFollowUpDetail、Deployment/ReinforcementResultSummary、AIPhaseTimelineEvent、AIPhaseMapMarker、AIPhaseSummary、AIPhaseReplayConclusion"] --> S
  S --> R["规则判定：移动、攻击、战术命令、部署、整补、补给、控制区、士气、AI、AI回合摘要、AI行动时间线、AI地图复盘标记、AI时间线点选定位、AI复盘选中态、上一条/下一条复盘导航、播放/暂停/速度控制、OBJ计划、THR、安全接敌路径对比、敌方意图、反制建议、战线态势首要定位/压力行当前态/压力来源标识/压力态势对照/压力敌方回合影响/复盘影响来源筛选/响应历史导航/响应定位/下一步提示/执行反馈/普通行动响应/敌方回合影响/AI关键复盘定位、排序对比、执行前后对照、执行入口桥接、执行回放、敌方回合复核、据点防守复核细分、关联AI行动、复核等级、复核目标定位"]
  R --> W["状态写回：单位位置、HP、行动状态、据点归属、目标引导、焦点坐标、消息、攻击/战术/占领/后勤结果、反制回放、敌方回合复核、据点防守复核细分、关联AI行动、最近5条态势响应历史、当前响应order、AI回合摘要、行动时间线、当前复盘order、播放状态/速度、战报、胜负"]
  R --> EI["只读预判：EnemyThreatIntentPreview 直接攻击 / 接敌攻击 / 据点威胁"]
  EI --> EC["只读建议：EnemyThreatCountermeasurePreview 抢先打击 / 撤退 / 守点 / 整补"]
  EC --> BM["只读收益：战果 / 生存 / 守点 / 恢复 / 路线 / 优先值"]
  BM --> DT["据点防守取舍：进驻 / 封堵 / 路线 / 优先值"]
  DT --> PC["只读排序：可执行 / 击毁 / 优先值 / 路线 / 相邻对比"]
  PC --> IP["只读对照：当前 / 采纳 / 改善"]
  IP --> EB["只读入口：ATK / MOVE / 整补按钮提示"]
  EC --> BS["只读态势：指令 / 待命 / 据点 / 威胁 / 反制 / 首要建议"]
  EB --> XR["真实执行后回放：预计 / 实际 / 结果"]
  XR --> BR["态势响应反馈快照：敌方回合影响 / 最近反制执行 / 据点占领结果 / 普通攻击 / 战术命令 / 部署 / 整补"]
  XR --> FV["敌方回合后复核：HP / 位置 / 据点 / 威胁源 / 守点进驻或封堵 / 关联AI行动 / 奏效等级 / 定位目标"]
  FV --> BR
  CAP["据点占领结果：奖励 / 归属 / 进度"] --> BR
  ORD["普通成功行动结果：攻击 / 战术命令 / 部署 / 整补"] --> BR
  BR --> BRH["最近5条态势响应历史：追加 / 裁剪 / 当前查看order"]
  BRH --> BRM["态势响应地图标记：当前查看响应合法坐标 -> RSP/ATK/CMD/DEP/REP/CAP/CTR/AI"]
  BRM --> BRF["响应定位入口：focusBattlefieldSituationResponseTarget -> focusedCoordinate"]
  BRH --> BRN["响应上一条/下一条：只切换当前响应和焦点，不执行命令"]
  W --> P["@Published 状态变化"]
  P --> V
  EI --> V
  EC --> V
  BS --> V
  BR --> V
  BRM --> V
  BRF --> V
  BRH --> V
  BRN --> V
  BM --> V
  DT --> V
  PC --> V
  IP --> V
  EB --> V
  XR --> V
  FV --> V
  S --> T["测试层：GameStateTests / RulesSmokeTest"]
```

## 2. 地图命令执行流

读图说明：这张图展示地图交互的安全边界。聚焦只看信息，不消耗行动；右键或执行按钮才会进入实际命令执行。

```mermaid
flowchart TD
  A["玩家点地图格"] --> B{"是否己方单位？"}
  B -->|是| C["选择单位 selectedUnitID"]
  B -->|否| D["更新 focusedCoordinate"]
  D --> E["生成地图预览 MapCommandPreview"]
  E --> R["路线情报：RouteStepPreview / PostMoveAttackPreview"]
  R --> X["火力风险：PostMoveFireExposurePreview / SafeEngagementOption"]
  X --> SC["安全接敌对比：默认POS vs 候选，承伤 / 风险 / 移动 / 控区 / 路线暴露"]
  SC --> SP["点击安全接敌候选：GameState 重新查候选并聚焦 POS 路线"]
  SP --> OP["OBJ计划摘要：ObjectiveAdvancePreview 最多 3 条"]
  OP --> OPR["优先级解释：归属 / 可占可夺或推进 / 距离 / 路线代价 / 终点风险"]
  OPR --> OC["点击目标计划：GameState 重新查计划并聚焦路线"]
  OC --> CM["点击反制建议：GameState 重新校验并聚焦单位、敌军或目的格"]
  CM --> MK["地图反制标记：ACT 执行 / SRC 威胁 / CTR 目标 / TGT 受威胁"]
  MK --> PR["排序对比提示：首选依据 / 优先值 / 路线差异，不执行"]
  PR --> IP["执行前后对照：当前 / 采纳 / 改善，不执行"]
  IP --> EB["执行入口提示：ATK / MOVE / 整补，不执行"]
  EB --> F{"输入类型"}
  F -->|左键/主点按聚焦| G["只显示预览消息，不消耗行动"]
  F -->|右键/执行按钮| H{"预览是否可执行？"}
  H -->|MOVE| I["move：移动、消耗移动、更新据点、必要时写入 CAP 结果"]
  H -->|ATK| J["attack：伤害、反击、经验、士气、latestCombatResult、战报"]
  H -->|POS| K["移动到攻击位并聚焦目标"]
  H -->|不可执行| L["提示原因，不消耗行动"]
  I --> RR["若匹配当前反制建议：写入 MOVE 反制回放"]
  J --> RR2["若匹配当前反制建议：写入 ATK 反制回放"]
  I --> M{"移动后是否有 NEXT 目标？"}
  M -->|是| N["自动聚焦可攻击目标"]
  M -->|否| O["保持移动后状态"]
```

## 3. 规则状态图

读图说明：这张图展示 `GameState` 内部主要规则之间的关系。移动、攻击、补给和 AI 都会影响战役状态，最后统一进入胜负检查。

```mermaid
flowchart LR
  S["Scenario 当前战役"] --> U["units 单位列表"]
  S --> T["tiles 地图格和据点"]
  U --> MV["movementRoutes 可达路线"]
  T --> MV
  U --> AT["attackableTiles / combatPreview 攻击预测"]
  T --> AT
  U --> SUP["supplyLine / supplyState 补给"]
  T --> SUP
  U --> LOG["deploy / reinforce 主动后勤"]
  T --> LOG
  U --> ZOC["enemyControlZoneTiles 控制区"]
  U --> THR["threatenedReachableTiles 敌火覆盖"]
  U --> INT["EnemyThreatIntentPreview 敌方威胁意图"]
  INT --> CTR["EnemyThreatCountermeasurePreview 反制建议"]
  CTR --> BS["BattlefieldSituationSummary 战线态势汇总"]
  BS --> BOP["BattlefieldSituationObjectivePressure 据点防守压力：来源 / 据点 / 归属 / 威胁来源 / 占点风险 / 推荐入口 / 态势对照 / 复盘线索"]
  BOP --> BOPM["ObjectivePressureMapMarker：PRS 受压据点 / SRC 威胁来源 / DEF 守点目的格"]
  BOP --> BOPS["压力来源：NOW 当前威胁 / CHK 回合复核，当前威胁优先排序"]
  BOP --> BOPC2["压力态势对照：当前守势/敌控/中立 + 应对入口，只读派生"]
  BOP --> BOPE["压力敌方回合影响：匹配守点follow-up + 据点前后对比，只读派生"]
  BS --> BFT["BattlefieldSituationFocusTarget 首要定位目标"]
  BFT --> BAH["BattlefieldSituationActionHint 下一步入口提示"]
  BS --> BRS["BattlefieldSituationResponseSummary 当前查看响应 / 普通行动反馈 / 敌方回合影响"]
  BRS --> BRH2["BattlefieldSituationResponseHistoryEntry 最近5条 / 当前order / 位置文本"]
  BRS --> BRM2["BattlefieldSituationResponseMapMarker：响应坐标 / 短码 / 图标 / 无障碍摘要"]
  CTR --> BM2["BenefitMetric 收益解释"]
  CTR --> DT2["ObjectiveDefenseTradeoff 进驻/封堵取舍解释"]
  CTR --> PF["PriorityFactor / ComparisonPreview 排序对比解释"]
  CTR --> IP2["ImpactComparison 执行前后预计对照"]
  CTR --> EBP["EnemyThreatCountermeasureExecutionPreview 执行入口桥接"]
  CTR --> ERP["ExecutionResultSummary 真实执行回放"]
  ERP --> BRS
  ERP --> FUP["FollowUpSummary 敌方回合复核 / 据点防守细分 / 关联AI行动 / 结论等级 / 定位目标"]
  FUP --> BRS
  MV --> RP["RouteStepPreview 步序、消耗、控制区、敌火"]
  MV --> PM["PostMoveAttackPreview 移动后伤害、反击、击毁"]
  MV --> FP["PostMoveFireExposurePreview 潜在承伤、HP 后果、风险等级"]
  MV --> OP["ObjectiveAdvancePreview 据点推进计划 + 优先级解释"]
  MV --> SE["SafeEngagementOption 安全接敌候选"]
  SE --> SEC["SafeEngagementComparisonPreview 默认POS vs 候选路径风险对比"]
  MV --> INT
  AT --> PM
  AT --> FP
  AT --> INT
  AT --> CTR
  MV --> CTR
  LOG --> CTR
  CMD --> EBP
  LOG --> EBP
  MV --> CMD["MapCommandPreview"]
  AT --> CMD
  RP --> CMD
  PM --> CMD
  FP --> CMD
  OP --> CMD
  SE --> CMD
  SEC --> CMD
  CMD --> EX["executeMapCommand"]
  EX --> RES["更新单位、据点、消息、攻击/战术/占领/后勤结果、战报"]
  LOG --> RES
  RES --> CMR["latestEnemyThreatCountermeasureExecutionResult 预计/实际/结果"]
  RES --> OCR["latestObjectiveCaptureResult 据点奖励/进度"]
  CMR --> BRS
  OCR --> BRS
  RES --> WIN["checkVictory / checkTurnLimit"]
  RES --> AI["runAxisAI：后勤 -> 可击毁 -> 战术 -> 直取据点 -> 普通攻击/推进 -> 移动后攻击/战术"]
  AI --> AIS["AIPhaseSummary：动作计数、指令点、占点、歼灭、伤害、行动时间线"]
  AIS --> AIC["AIPhaseReplayConclusion：战果分类 / 指标 / 最多3条关键事件"]
  AIS --> TL["AIPhaseTimelineEvent：整补 / 部署 / 战术 / 攻击 / 移动 / 占点"]
  TL --> AIM["latestAIPhaseMapMarkers：起点 / 终点 / 行动单位 / 目标 / 据点"]
  AIS --> BSR["BattlefieldSituationReplayTarget：压力关联 / 响应坐标 / 全局关键事件 + order / 标题 / 坐标"]
  AIS --> FUR["latestEnemyThreatCountermeasureFollowUpResult HP/位置/据点/威胁源复核"]
  FUR --> BRS
  AIS --> RES
  TL --> UIA["侧栏AI摘要：复盘结论关键事件 + 最多5条行动时间线"]
  AIC --> UIA
  UIA --> AIP["播放/暂停/速度：GameState 管理播放状态，SwiftUI timer 只触发 tick"]
  AIP --> AIN["播放tick或上一条/下一条按钮：GameState 选择目标order或边界提示，不执行命令"]
  UIA --> AIF["点选结论关键事件或时间线：focusAIPhaseTimelineEvent 更新 focusedCoordinate / focusedAIPhaseTimelineEventOrder / message，不执行命令"]
  AIN --> AIF
  AIF --> AIO["focusedAIPhaseMapMarkers：按当前order过滤复盘标记"]
  AIM --> UIM["地图AI复盘标记 / tile无障碍文案"]
  AIO --> UIM2["当前复盘行选中态 / 地图标记强调 / 当前AI复盘无障碍文案"]
  AIF --> UIM2
  INT --> UI["侧栏敌方意图面板 / 地图 INT 标记"]
  CTR --> UI2["侧栏反制建议面板 / 地图 ACT-SRC-CTR-TGT 标记"]
  BM2 --> UI2
  DT2 --> UI2
  PF --> UI2
  IP2 --> UI2
  EBP --> UI2
  FUP --> FLOC["复核定位按钮：执行单位 / 威胁来源 / 受威胁目标"]
  FLOC --> UI2
  CMR --> UI2
  FUR --> UI2
  BS --> UI3["侧栏战线态势：指令 / 待命 / 据点 / 威胁 / 反制 / 受威胁据点 / 据点压力 / 压力行当前态 / 压力来源标识 / 压力态势对照 / 压力敌方回合影响 / 压力复盘线索 / 复盘影响来源 / 首要建议 / 执行反馈 / 敌方回合影响 / 响应历史 / 响应定位 / 复盘影响"]
  THEME["BattlefieldTheme / TacticalSurface / 地图材质：顶栏 / 地图容器 / HUD / 状态芯片 / 侧栏 / 地形格 / 单位棋子统一视觉基线，只影响表现层"] --> UI3
  THEME --> UIM
  THEME --> UIM3
  THEME --> UIM4
  BOP --> UI3
  BOPS --> UI3
  BOPC2 --> UI3
  BOP --> BOPF["压力行定位：focusBattlefieldSituationObjectivePressure 重新校验压力id，复用反制聚焦或定位据点，不执行命令"]
  BOPF --> BOPC["压力行当前态：isBattlefieldSituationObjectivePressureFocused 从当前压力id和最新压力列表派生"]
  BOPC --> UI3
  BOPE --> UI3
  BOP --> BOPR["压力复盘线索：从最新AI时间线保守匹配威胁来源或受压据点"]
  BOPR --> BOPRF["线索按钮：focusBattlefieldSituationObjectivePressureReplayTarget -> focusAIPhaseTimelineEvent"]
  BOPRF --> AIF
  BOPR --> UI3
  BOPM --> UIM4["地图压力标记：PRS/SRC/DEF 只展示当前压力，不执行命令"]
  BFT --> UI3
  BAH --> UI3
  BRS --> UI3
  BRH2 --> UI3
  BRM2 --> UIM3["地图态势响应标记 / tile无障碍文案"]
  BRM2 --> BRF2["响应定位按钮：focusBattlefieldSituationResponseTarget 只切换焦点和消息，不执行命令"]
  BRH2 --> BRN2["响应历史按钮：上一条 / 下一条，只切换当前响应和焦点，不执行命令"]
  BSR --> UI3
  UI3 --> BFF["定位按钮：focusBattlefieldSituationPrimaryTarget，只切换选择 / 焦点 / 引导 / 消息；下一步提示不执行命令"]
  UI3 --> BOPF
  UI3 --> UIM4
  UI3 --> BRF2
  UI3 --> BRN2
  UI3 --> BFR["复盘影响按钮：PRS/RSP/KEY 来源筛选后 focusBattlefieldSituationReplayTarget -> focusAIPhaseTimelineEvent，只切换AI复盘焦点和地图标记强调"]
  UI3 --> OBR["普通行动响应：ATK/CMD/DEP/REP 徽标展示战斗、战术、部署或整补结果，不执行命令"]
  BRF2 --> UIM3
  UIM3 --> OBR2["地图响应标记：只展示当前查看响应，不执行命令"]
```

## 4. Agent X 主控迭代流程图

读图说明：这张图展示未来人工可用 `agentx:` 提供总目标，由 Agent X 拆分轮次并调度 A/B/C。每轮仍必须经过 Agent A 写提示词、Agent B 在 `main` 实现并直推、GitHub Actions 生成 artifact、Agent C 下载并核对结果包；Agent X 只能根据 Agent C 结论决定继续、退回、暂停或完成。

```mermaid
flowchart TD
  H["人工提供总目标 X、限制、验收标准"] --> X["Agent X：拆分本轮目标和停止条件"]
  X --> A["Agent A：分析本轮目标并写实现提示词"]
  A --> P["md/prompt/vN（阶段）/vN.x（任务）.md"]
  P --> S["Agent B：同步 origin/main 并确认位于 main"]
  S --> B["Agent B：实现、补测试、轻量检查、更新文档"]
  B --> M["main commit：vN.x: 简要说明"]
  M --> U["git push origin main"]
  U --> G["GitHub Actions：静态检查、smoke、Xcode build"]
  G --> Q["未加密 CI artifact：manifest、failure summary、JUnit、log、xcresult"]
  Q --> C["Agent C：下载 artifact 并核对 origin/main 最新 commit"]
  C --> D{"Agent C 验收是否通过？"}
  D -->|不通过| BX["Agent X：退回 Agent B 修复"]
  BX --> R["Agent B：main 追加修复 commit"]
  R --> U
  D -->|通过| J["Agent X：判断总目标进度"]
  J -->|继续下一轮| X
  J -->|需要人工确认| W["暂停：等待人工决策"]
  J -->|总目标完成| F["完成：输出 commit、run、artifact 和剩余风险"]
  J -->|触发停止条件| W
```

## 5. 云端结果包验收流

读图说明：这张图展示 Agent C 的验收对象不是 Agent B 的文字汇报，而是 `origin/main` 最新 run 上传的未加密 artifact。manifest 中的 commit 和 run 信息必须与远端最新状态一致。

```mermaid
flowchart TD
  O["origin/main 最新 commit"] --> R["GitHub Actions run"]
  R --> A["artifact：ww2tactics-ci-vX.Y-main-<sha>-run<id>-attempt<n>"]
  A --> M["ci-artifact-manifest.json"]
  A --> F["ci-failure-summary.md"]
  A --> J["junit.xml"]
  A --> L["xcodebuild.log / rules-smoke.log"]
  A --> X["WW2Tactics.xcresult"]
  C["Agent C：gh auth login"] --> D["下载到 /private/tmp/ww2tactics-c-review-<run_id>/"]
  D --> M
  D --> F
  D --> J
  D --> L
  D --> X
  M --> V{"branch、commitSha、runId、runAttempt 是否匹配？"}
  V -->|否| N["不通过：不能验收旧 run 或旧 artifact"]
  V -->|是| T{"日志、JUnit、summary 是否通过？"}
  T -->|否| B["退回 Agent B：main 追加修复 commit"]
  B --> O
  T -->|是| Y["通过：确认 main 最新 run"]
```

## 地图标记表现（v1.61）

`HexTileView` 将态势/复盘短码收入统一顶/底栈（各最多 2 个 + `+N`），MOVE/ATK/POS 等命令标记固定角落；布局由 View 纯派生，不改变 `GameState` marker 生成与聚焦规则。

## 命令预览呈现（v1.62）

`InlineMapCommandPreview` 与 `FocusedCommandPreviewPanel` 共用 `MapCommandPreviewChrome` 只读 helper 生成图标、色阶、路线/火力/接敌摘要；预览数据仍来自 `GameState.focusedCommandPreview`，不在 View 中重算规则。

## 结果卡视觉（v1.63）

战术命令、据点占领、增援部署与整补结果卡使用与 `CombatResultSummaryView` 同族的标题/结论胶囊/叙述/指标/细节行与渐变底；数据仍来自既有 `latest*Result` 字段。

## 反制回放视觉（v1.64）

`EnemyThreatCountermeasureExecutionResultSummaryView` 与 `EnemyThreatCountermeasureFollowUpSummaryView` 使用与战斗/后勤结果卡同族的标题/结论胶囊/叙述/主体块/指标/细节行；定位按钮与关联 AI 行动仍只转发 `GameState`，不执行命令。

## 地图 HUD 密度（v1.65）

`StatusStrip`、`MapCampaignHUD`、`MapActionHUD` 与快捷命令按钮改为更紧凑布局；工具栏副标题改为缩放/焦点摘要，避免与消息条重复。所有数值与命令仍来自 `GameState`。

## 侧栏与触控（v1.66）

`InspectorPanel` 以分区标题组织主操作、战线态势、执行结果、敌情与反制、战报；编队条、定位条、战术条图标按钮、部署与单位详情主按钮放大触控目标。内容与 action 仍只转发 `GameState`。

## 图例与编队条（v1.67）

`MapLegendView` 与 `ForceRibbon` 使用统一指挥台背板、标题条与阵营标签；`UnitRibbonButton` 选中态使用阵营色强调。图例条目与编队数据来源不变。

## 窄屏布局（v1.68）

`ContentView` 按宽度断点切换并排 inspector 与上下堆叠；地图宽度较窄时 `MapCampaignHUD`/`MapActionHUD` 改为紧凑叠放，减少互相挤压。规则与命令入口不变。

## 动态字体与基础面板（v1.69）

`VictoryPanel`、`ScenarioPanel`、`TileDetail`、`BattleLogView` 对齐指挥台卡片样式；正文使用语义字体并配合 `lineLimit`/`minimumScaleFactor`。数据仍来自 `GameState`。

## 单位详情与战术条（v1.70）

`UnitDetail` 以状态/作战方案/指挥分区组织侧栏单位面板；`TacticalOrderStrip` 与 `ReinforcementDock` 使用统一指挥台背板。命令与数据仍来自 `GameState`。

## 状态面板（v1.71）

`SupplyPanel`、`MoralePanel`、`ExperiencePanel`、`ThreatSummary`、`StatRows` 与 `ActionBadge` 使用统一指挥台卡片样式与可缩放文案。状态数值仍来自 `GameState`。

## 作战规划面板（v1.72）

`ObjectiveAdvancePlanPanel`、`SafeEngagementOptionsPanel`、`TacticalCommandGroup` 与 `CommanderView` 使用统一指挥台卡片样式；点选仍只聚焦或调用既有 `GameState` 战术入口。

## 敌情与反制面板（v1.73）

`EnemyThreatIntentPanel` 与 `EnemyThreatCountermeasurePanel` 使用统一指挥台渐变卡片；行组件强化当前预览态。威胁/反制数据与聚焦入口仍来自 `GameState`。

## 反制下一步反馈（v1.74）

`EnemyThreatCountermeasureExecutionHint` 突出可执行/不可执行与入口说明；`EnemyThreatCountermeasureFollowUpAIEventRow` 提高触控高度。提示与定位仍只转发 `GameState`，不会自动执行命令。

## 态势响应与 AI 回放反馈（v1.75）

`BattlefieldSituationResponseCard` 使用指挥台渐变卡片并强化结果胶囊；`AIPhaseReplayControls` 与 `AIPhaseCurrentTimelineEventView` 突出播放态与当前事件。行为仍只调用既有 `GameState` 导航/播放入口。

## 据点压力与复盘入口（v1.76）

`BattlefieldSituationObjectivePressureRow` 与 `BattlefieldSituationReplayTargetButton` 使用更强的指挥台卡片与当前态反馈。定位/复盘仍只转发 `GameState`。
