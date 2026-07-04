# 项目版本更新记录

本文记录 `WW2Tactics` 的正式版本、重要维护事项、关键决策和遗留问题。这里不是流水账，只记录会影响后续 Agent 判断的事实。

## 维护规则

- 每完成一个正式版本或重要任务后追加记录。
- 记录必须包含：版本/任务名、日期、核心变更、关键文件、验证结果、遗留事项。
- 文档整理、目录迁移、回滚、打捞等不伪装成新功能版本，可写入“历史维护记录”。
- 若核心逻辑、测试规范或项目行为变化，必须同步更新本日志。

## 当前状态

- 项目为 SwiftUI iOS 原型，主目录是 `WW2Tactics/`。
- 目标体验是 EasyTech 风格二战回合制战棋：大地图、多据点、单位移动、攻击判定、将领、地形、补给、士气、AI 回合。
- 当前源码已包含阿登 22x14 大地图、诺曼底战役、MOVE/ATK/POS/NEXT/OBJ/THR 地图反馈、规则 smoke test 和 XCTest。
- 当前协作规范已切换为 `AGENTS.md + update_log.md + md/prompt + md/test + md/flow` 的多 Agent 工作流。
- 当前默认协作流程已升级为 `main` 直推、GitHub Actions 云端重验证、未加密 CI 结果包、Agent C 下载核对结果包后验收。
- 当前文档已支持未来 `agentx:` 主控循环：Agent X 接收总目标、拆分轮次并调度 Agent A -> Agent B -> Agent C，不跳过云端 artifact 验收。
- 近期规划已进入 `v1（地图操作体验）`：v1.5 正在推进据点目标计划摘要，已持续增强路线预判、火力风险、战斗/战术/据点结果反馈和 OBJ 操作可读性。

## 历史记录

### v0.1 / 初始 SwiftUI 战棋原型

日期：2026-06-27 前后

核心变更：

- 建立 `WW2Tactics` SwiftUI iOS 工程。
- 实现二战战役、六边形大地图、单位、地形、移动、攻击、AI、补给、士气、指令点、增援、战术命令、地图交互和侧栏。
- 建立 `WW2TacticsTests` 和 `Tools/RulesSmokeTest.swift`。

关键文件：

- `WW2Tactics/WW2Tactics/GameModels.swift`
- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`

验证结果：

- README 记录了 smoke test、SwiftUI typecheck、XCTest 源码级 typecheck、`xcodebuild build-for-testing` 的命令。
- 实际运行 XCTest 依赖可用 iOS Simulator runtime 和 CoreSimulatorService。

遗留事项：

- 真实美术资产、战斗动画、更多战役、存档、完整 AI 和生产队列仍未完成。

### v0.2 / THR 敌火覆盖与目标引导强化

日期：2026-06-27 前后

核心变更：

- 增加据点目标引导 `guidedObjectiveCoordinate` / `guidedObjectiveTile`。
- 增加敌火覆盖查询：`threateningEnemies(against:at:)`、`threatenedTiles(for:)`、`threatenedReachableTiles(for:)`。
- 地图和 HUD 显示 `THR` 危险移动格。
- 补充 XCTest 和 smoke test 断言。

关键文件：

- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`

验证结果：

- 待后续 Agent 按 `md/test/test.md` 重新运行 smoke/typecheck 并记录当前机器结果。

遗留事项：

- 需要继续增强地图操作手感、威胁可读性和战斗前后反馈。

### v0.3 / 建立多 Agent 协作和文档体系

日期：2026-06-28

核心变更：

- 将单一 `AGENT.md` 思路升级为 `AGENTS.md` 多 Agent 入口规则。
- 新增 `update_log.md`、`md/prompt/README.md`、`md/test/test.md`、`md/flow/flow.md`、`md/flow/flowchart.md`。
- 明确 Agent A/B/C 循环：目标分析与提示词、实现与测试、验收与核心逻辑更新。

关键文件：

- `AGENTS.md`
- `update_log.md`
- `md/prompt/README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`

验证结果：

- 已运行 `git diff --check`，通过。

遗留事项：

- 后续正式功能迭代应先由 Agent A 在 `md/prompt/` 写版本化实现提示词，再交给 Agent B。

### v0.4 / 规范 Agent C 验收提交流程

日期：2026-06-29

核心变更：

- 明确 Agent C 最终验收通过后自动按版本号创建 git 提交。
- 明确验收不通过时必须退回 Agent B，并指出问题、缺失测试和修复点。
- 规范版本提交信息格式：`vN.x: 简要说明本版本做了什么`。
- 更新 Agent 迭代流程图，加入“验收是否通过”和“版本提交”节点。

关键文件：

- `AGENTS.md`
- `md/flow/flowchart.md`
- `update_log.md`
- `md/prompt/v0（项目管理）/v0.4（规范AgentC验收提交）.md`

验证结果：

- 已运行 `git diff --check`，通过。

遗留事项：

- 本次只更新文档规范，不执行实际 git commit；该本地验收后提交规则已在 v0.5 被 `main` 直推和云端结果包验收流程取代。

### v0.5 / 升级 main 直推云端验证流程

日期：2026-07-03

核心变更：

- 将默认协作制度从本地验证和本地验收提交升级为 `main` 直推、GitHub Actions 云端重验证、Agent C 下载未加密结果包验收。
- 增加 `agenta` / `a:`、`agentb` / `b:`、`agentc` / `c:` 角色召唤和最终回复身份标识规则。
- 明确 Agent B 默认流程：同步 `origin/main`、在 `main` 小步实现、本地轻量检查、提交并 `git push origin main`。
- 明确 Agent C 默认流程：只验收 `origin/main` 最新 commit 对应的 manifest、JUnit、日志、`.xcresult` 和 artifact。
- 新增 GitHub Actions CI 结果包 workflow，生成 manifest、failure summary、JUnit、规则 smoke 日志、Xcode build 日志和 `.xcresult`。

关键文件：

- `AGENTS.md`
- `WW2Tactics/README.md`
- `md/prompt/README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `.github/workflows/ci-results.yml`

验证结果：

- 本轮是流程制度和 CI 骨架变更，不改 Swift 业务逻辑。
- 本地轻量检查和云端试跑结果以本轮最终交付记录为准。

遗留事项：

- 当前本地仓库若未配置 `origin/main`，无法完成真实 main push、Actions run 和 artifact 下载；需要配置 GitHub 远端和权限后补跑。

### v0.5 / 引入 Agent X 循环迭代文档基线

日期：2026-07-04

核心变更：

- 新增 Agent X 召唤、职责、循环判断和停止条件。
- 将现有 Agent A/B/C 云端验证流程扩展为可被 Agent X 多轮调度。
- 更新 flow、flowchart、test、prompt README 和 README 中的协作说明。
- 明确本轮只做文档准备，不启动真实自动循环。

关键文件：

- `AGENTS.md`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `update_log.md`
- `md/prompt/v0（协作自动化）/v0.5（引入AgentX循环迭代）.md`

验证结果：

- `git diff --check` 通过。

遗留事项：

- 后续人工可用 `agentx:` 提供总目标 X，启动 Agent X 主控循环。
- Agent X 真正执行循环时，仍必须经过 Agent A 提示词、Agent B 实现 push、Agent C 云端 artifact 验收。

### v1.0 / 路线与战斗预判强化

日期：2026-07-03

核心变更：

- 新增 `RouteStepPreview` 和 `PostMoveAttackPreview`，由 `GameState` 生成可测试的路线步骤、控制区、敌火来源和移动后攻击预判。
- MOVE/POS 聚焦路线在地图上显示步序、每步消耗和路线风险；HUD/侧栏显示路线总消耗、控制区额外消耗、受威胁步数和威胁来源。
- MOVE 目的地显示移动后最佳攻击目标、预计伤害、反击、目标剩余耐久和击毁判断；POS 接敌只显示移动后进射程，不自动攻击。
- 补充 XCTest 和规则 smoke test 断言，覆盖路线步骤预览、控制区/敌火风险、移动后攻击预判与 `combatPreview` 一致性。

关键文件：

- `WW2Tactics/WW2Tactics/GameModels.swift`
- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译命令：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28671787823` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.0-main-24bdac8-run28671787823-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28671787823/` 并核对 `ci-artifact-manifest.json`、`ci-failure-summary.md`、`junit.xml`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult`。
- Manifest `commitSha=24bdac828154453d8b85ab64f8d87abf4b657c97` 与 `origin/main` 当时最新功能提交一致；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮仍未加入战斗动画、真实美术、更多战役、存档或完整生产队列。
- 路线风险目前显示结构化威胁来源摘要，未来可继续扩展为更细的火力强度、撤退建议或多路线比较。

### v1.1 / 火力风险与安全接敌建议

日期：2026-07-04

核心变更：

- 新增 `FireRiskLevel`、`FireExposureSourcePreview`、`PostMoveFireExposurePreview` 和 `SafeEngagementOption`，把 MOVE/POS 终点敌火覆盖转换为潜在承伤、预计剩余耐久、击毁风险和 SAFE/LOW/MED/HIGH/CRIT 风险等级。
- `GameState` 新增 `fireExposurePreview(for:at:)`、`focusedFireExposurePreview` 和 `focusedSafeEngagementOptions`，复用 `combatPreview(enemy, movedUnit)` 做纯预览，不写回战役状态。
- POS 接敌保留原默认攻击位执行语义，同时给出更安全攻击位建议。
- `ContentView` 在地图、内联命令预览、侧栏命令预览、图例和无障碍文案中显示火力风险短码、潜在伤害、预计 HP 和主要敌火来源。
- 补充 XCTest 和规则 smoke test，覆盖火力暴露来源、伤害一致性、无风险/致命风险、安全接敌排序和不改变默认 POS 执行。

关键文件：

- `WW2Tactics/WW2Tactics/GameModels.swift`
- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v1（地图操作体验）/v1.1（火力风险与安全接敌建议）.md`

验证结果：

- 规则 smoke 编译：通过。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过。
- `GameStateTests.swift` 源码级 typecheck：通过。
- GitHub Actions `WW2Tactics CI Results` run `28701311907` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.1-main-8200be0-run28701311907-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28701311907/`，目录大小 `1.4M`。
- Manifest `commitSha=8200be034dff8b659ec0e70e30785b717f85a949`、`branch=main`、`runId=28701311907`、`runAttempt=1` 与 `origin/main` 当时最新功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 火力暴露仍是静态风险估算，不代表敌军一定会攻击，也不触发反应射击。
- 安全接敌建议只展示更低风险候选，尚未提供一键切换到安全路线的执行模式。

### v1.2 / 战斗结果回放与战损对比

日期：2026-07-04

核心变更：

- 新增 `CombatantResultSnapshot` 和 `CombatResultSummary`，用结构化字段记录普通攻击执行后的双方 HP、经验、士气、军衔、击毁、反击、夹击、防御姿态消耗和机动追击结果。
- `GameState` 新增 `latestCombatResult`，只在真实普通攻击结算后写入，`combatPreview`、MOVE/POS 预览和火力暴露预览不会生成虚假结果；重开或切换战役会清空旧结果。
- 侧栏战报前新增紧凑战斗结果面板，展示攻击/防守双方 HP 前后对比、伤害、实际反击、夹击、击毁/追击、经验、晋升和士气变化。
- 补充 XCTest 和规则 smoke test，覆盖普通攻击结果摘要、实际反击、攻击者被反击击毁、机动追击、预览不写入结果和重开清理结果。

关键文件：

- `WW2Tactics/WW2Tactics/GameModels.swift`
- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v1（地图操作体验）/v1.2（战斗结果回放与战损对比）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28702891688` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.2-main-48248b3-run28702891688-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28702891688/`，目录大小 `1.4M`。
- Manifest `commitSha=48248b35b35ba143d7e882026b55839c617939ec`、`branch=main`、`runId=28702891688`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮只记录普通攻击结果，不包含火炮弹幕、突破突击等战术命令的结果摘要。
- 战斗结果面板是静态回放，不包含动画、音效或美术资产。

### v1.3 / 战术命令结果摘要与战报强化

日期：2026-07-04

核心变更：

- 新增 `TacticalCommandResultSummary`，复用 `CombatantResultSnapshot` 记录火炮弹幕和突破突击执行后的施放者/目标 HP、经验、士气和军衔前后状态。
- `GameState` 新增 `latestTacticalCommandResult`，战术命令成功执行后记录命令、伤害、指令点消耗、士气损失、状态效果、无反击、击毁和防御姿态消耗；失败命令不生成虚假摘要。
- 普通攻击结果和战术命令结果互斥展示，避免侧栏显示过期的另一类结果。
- 侧栏战报前新增战术命令结果面板，展示 BRG/BRK、双方 HP 前后、伤害、指令点、士气/状态、无反击、防御姿态消耗和击毁。
- 战术命令战报文本补充 HP 前后、无反击、指令点消耗、士气/状态和防御姿态消耗。
- 补充 XCTest 和规则 smoke test，覆盖火炮弹幕、突破突击、失败命令、结果互斥和 AI 战术命令摘要。

关键文件：

- `WW2Tactics/WW2Tactics/GameModels.swift`
- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v1（地图操作体验）/v1.3（战术命令结果摘要与战报强化）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28703732223` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.3-main-47eb01a-run28703732223-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28703732223/`，目录大小 `1.5M`。
- Manifest `commitSha=47eb01a8a8b42e949faf15347fddd8dcf56405aa`、`branch=main`、`runId=28703732223`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 战术命令结果仍是静态回放，不包含动画、音效或美术资产。
- 本轮不改变战术命令数值、AI 决策或普通攻击规则。

### v1.4 / 据点占领结果摘要与 CAP 反馈

日期：2026-07-04

核心变更：

- 新增 `ObjectiveCaptureResultSummary`，记录真实占领/夺取据点后的据点名、坐标、占领单位、原归属、新归属、奖励值和占领后据点进度。
- `GameState` 新增 `latestObjectiveCaptureResult`，只在据点归属真实变化时写入；远距离 OBJ 中继推进、普通聚焦和预览不会生成虚假摘要。
- 普通攻击结果、战术命令结果和据点占领结果互斥展示，避免侧栏显示过期的另一类结果。
- 侧栏战报前新增据点占领结果卡，地图在最新占领据点显示 `CAP` 短码。
- 补充 XCTest 和规则 smoke test，覆盖敌方/中立据点占领摘要、奖励和进度字段、OBJ 直取、远距离推进不生成摘要、重开/切战役/后续攻击和战术命令清理旧摘要。

关键文件：

- `WW2Tactics/WW2Tactics/GameModels.swift`
- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v1（地图操作体验）/v1.4（据点占领结果摘要与CAP反馈）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28704699981` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.4-main-7b5fbc6-run28704699981-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28704699981/`，目录大小 `1.5M`。
- Manifest `commitSha=7b5fbc695bc467613782130dcdad6aad3aa0cab3`、`branch=main`、`runId=28704699981`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 据点占领结果仍是静态回放，不包含动画、音效或真实美术资产。
- 本轮不改变据点奖励数值、胜负条件、AI 决策或 OBJ 目标排序。

### v1.5 / 据点推进计划摘要

日期：2026-07-04

核心变更：

- 新增 `ObjectiveAdvancePreview`，把已有 OBJ 目标推进计划转换为可测试、可展示的结构化摘要。
- `GameState` 新增 `objectiveAdvancePreviews(for:limit:)` 和 `focusedObjectiveAdvancePreviews`，复用现有 `objectiveAdvancePlans(for:)` 排序，默认返回最多 3 条候选目标，首项与 OBJ 快捷按钮一致。
- 多目标计划生成复用同一次 `movementRoutes(for:)` 结果，避免侧栏预览每个据点重复计算可达路线。
- 目标计划摘要包含目标名、坐标、归属、路线、是否本回合可直达、当前/剩余距离和路线终点火力风险。
- 侧栏选中单位后显示“目标计划”面板，标注 OBJ 首选目标，并展示目的格、距离变化、移动消耗、控制区惩罚和火力风险短码。
- 补充 XCTest 和规则 smoke test，覆盖直达占领计划、远距推进计划、被占据目标过滤、最多 3 条预览、limit 参数、终点敌火风险传播和首项匹配 OBJ 快捷目标。

关键文件：

- `WW2Tactics/WW2Tactics/GameModels.swift`
- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1（地图操作体验）/v1.5（据点推进计划摘要）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions run、artifact 和 manifest 核对：待本轮 Agent B push 后由 Agent C 下载并补记。

遗留事项：

- 目标计划摘要仍是静态列表，不提供一键切换第二/第三目标执行。
- 本轮不改变移动路径搜索、OBJ 排序、据点奖励、胜负条件或 AI 决策。
