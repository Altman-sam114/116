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
- 近期规划已进入 `v1（地图操作体验）`：v1.18 正在推进反制建议执行回放，已持续增强路线预判、火力风险、战斗/战术/据点/后勤/敌方回合结果反馈、敌方意图预判和 OBJ/POS/反制建议操作可读性。

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
- GitHub Actions `WW2Tactics CI Results` run `28705723080` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.5-main-b0b03ac-run28705723080-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28705723080/`，目录大小 `1.5M`。
- Manifest `commitSha=b0b03ac71c632ab13018aa096b2de24e0d22a1ad`、`branch=main`、`runId=28705723080`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 目标计划摘要仍是静态列表，不提供一键切换第二/第三目标执行。
- 本轮不改变移动路径搜索、OBJ 排序、据点奖励、胜负条件或 AI 决策。

### v1.6 / 目标计划候选预览

日期：2026-07-04

核心变更：

- `GameState` 新增 `focusObjectiveAdvancePreview(_:)` 和 `focusObjectiveAdvanceTarget(coordinate:)`，目标计划行点击时由规则层重新查当前计划，避免 UI 使用过期路线。
- `focusNearestObjectiveTarget()` 和候选计划点击共用同一私有聚焦 helper，确保 OBJ 首项和侧栏候选计划行为一致。
- 侧栏目标计划行改为可点选 Button，点击后只投射路线、目的格、最终目标和火力风险到地图预览，并用“当前”标记展示聚焦态。
- 点选目标计划不移动单位、不消耗行动、不生成战斗/战术/占领结果；实际移动仍通过右键或执行按钮的既有 MOVE 链路。
- 补充 XCTest 和规则 smoke test，覆盖第二候选聚焦、远距候选聚焦、执行链路、过期/不可推进候选清理旧目标引导。

关键文件：

- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1（地图操作体验）/v1.6（目标计划候选预览）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28706972544` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.6-main-2857c0f-run28706972544-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28706972544/`，目录大小 `1.6M`。
- Manifest `commitSha=2857c0f751da0ae509f89a2d66e027e77cc80a7f`、`branch=main`、`runId=28706972544`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 目标计划候选仍是预览入口，不提供一键直接执行第二/第三目标。
- 本轮不改变移动路径搜索、OBJ 排序、据点奖励、胜负条件或 AI 决策。

### v1.7 / 安全接敌候选点选预览

日期：2026-07-04

核心变更：

- `GameState` 新增 `focusSafeEngagementOption(_:)` 和 `focusSafeEngagement(targetID:destination:)`，安全接敌候选点击时由规则层按当前单位和目标敌军重新查候选路线，避免 UI 使用过期路线。
- 新增安全接敌焦点状态，`focusedAttackPositionRoute`、路线步序和终点火力风险可切换到被点选的安全攻击位，同时默认 POS 路线和右键敌军行为保持不变。
- 侧栏新增“安全接敌”候选面板，展示目的坐标、风险短码、潜在承伤、移动消耗和主要敌火来源；点击候选只切换地图预览，不移动、不攻击、不生成结果摘要。
- 补充 XCTest 和规则 smoke test，覆盖安全候选聚焦、预览/执行分离、执行后回到目标敌军、不可用候选不保留过期可执行路线。

关键文件：

- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1（地图操作体验）/v1.7（安全接敌候选点选预览）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28710035720` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.7-main-1b856ba-run28710035720-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28710035720/`，目录大小 `1.6M`。
- Manifest `commitSha=1b856ba4f333a2b0140f0d71cc9f3eb63cd64509`、`branch=main`、`runId=28710035720`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 安全接敌候选仍是预览入口，不提供一键直接移动或攻击。
- 本轮不改变安全候选排序、默认 POS 路线、移动/攻击数值、胜负条件或 AI 决策。

### v1.8 / 整补与增援结果摘要

日期：2026-07-04

核心变更：

- 新增 `DeploymentResultSummary` 和 `ReinforcementResultSummary`，记录部署来源据点、新单位、部署坐标、主动整补 HP 前后、恢复量、指令点消耗和剩余指令点。
- `GameState` 新增 `latestDeploymentResult` 和 `latestReinforcementResult`，成功部署或整补通过规则层写入摘要；失败部署/整补只更新提示，不生成或清理既有真实结果。
- 普通攻击、战术命令、据点占领、部署和整补结果五者互斥展示，成功写入任一结果时清理其他旧结果。
- AI 后勤动作复用部署/整补路径，因此轴心国回合的主动部署或整补也会生成后勤结果摘要；据点被动休整不写入主动整补摘要。
- 侧栏战报前新增部署结果卡和整补结果卡，展示单位、坐标、指令点消耗、剩余指令点和 HP 恢复等关键字段。
- 补充 XCTest 和规则 smoke test，覆盖部署摘要、整补摘要、失败不写虚假摘要、结果互斥、AI 部署摘要和 smoke 字段断言。

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
- `md/prompt/v1（地图操作体验）/v1.8（整补与增援结果摘要）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28711364587` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.8-main-b1ad492-run28711364587-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28711364587/`，目录大小 `1.7M`。
- Manifest `commitSha=b1ad492e7f4b6d263db0d181e18ca90b332d4bd1`、`branch=main`、`runId=28711364587`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 后勤结果摘要仍是静态回放，不包含动画、音效或真实美术资产。
- 本轮不改变部署地点算法、部署成本、整补成本、恢复量、AI 后勤优先级或胜负条件。

### v1.9 / AI 回合行动摘要

日期：2026-07-04

核心变更：

- 新增 `AIPhaseSummary`，记录 AI 回合的阵营、回合、AI 开始/结束指令点、主动整补、部署、战术命令、攻击、移动、占点、歼灭、损失、对敌伤害和己方承伤。
- `GameState` 新增 `latestAIPhaseSummary` 和私有 AI phase 采样/计数器；`endTurn()` 在轴心国获得收入后采样 baseline，`runAxisAI()` 成功动作路径计数，AI 完成后用前后状态差异生成摘要。
- 被动据点休整、玩家预览、聚焦和失败命令不会生成或计入 AI 回合摘要；重开/切战役会清理摘要和内部记录器。
- 侧栏在普通攻击、战术命令、据点占领、部署、整补等单项结果卡之后显示 AI 回合摘要卡，再显示 battleLog，避免遮挡最新单项结果。
- 补充 XCTest 和规则 smoke test，覆盖 AI 战术命令、全速接敌后攻击、部署、主动整补、占点、歼灭、损失、重开/切战役清理以及玩家预览/失败操作不生成摘要。

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
- `md/prompt/v1（地图操作体验）/v1.9（AI回合行动摘要）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28712667425` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.9-main-041cf6b-run28712667425-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28712667425/`，目录大小 `1.7M`。
- Manifest `commitSha=041cf6b3933726854a8e8225e95afd3676622e35`、`branch=main`、`runId=28712667425`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- AI 回合摘要仍是静态总览卡，不包含逐行动时间线、动画、音效或真实美术资产。
- 本轮不改变 AI 优先级、路径选择、攻击目标选择、战斗数值、部署/整补成本、胜负条件或回合流程。

### v1.10 / 敌方威胁意图预判

日期：2026-07-05

核心变更：

- 新增 `EnemyThreatIntentKind` 和 `EnemyThreatIntentPreview`，把敌方下一回合的直接攻击、机动接敌攻击和据点占领风险转换为结构化预判。
- `GameState` 新增 `enemyThreatIntentPreviews(from:against:limit:)` 和 `visibleEnemyThreatIntentPreviews`，默认给玩家回合展示轴心国威胁盟军的最多 3 条意图。
- 敌方预判使用只读预测路线 helper，按下一回合可行动状态评估轴心单位，不修改 `activeFaction`、单位行动状态、据点归属、消息、战报或任何 `latest*Result`。
- 侧栏新增“敌方意图”面板，地图目标格新增 `INT` 标记，图例同步说明；UI 只展示 `GameState` 生成的字段，不计算规则。
- 补充 XCTest 和规则 smoke test，覆盖直接攻击、接敌攻击、据点占领、`limit` 前缀和查询无副作用。

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
- `md/prompt/v1（地图操作体验）/v1.10（敌方威胁意图预判）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28715553215` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.10-main-754649b-run28715553215-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28715553215/`，目录大小 `1.8M`。
- Manifest `commitSha=754649b58460942e69bb8650c32e4b3921e878b9`、`branch=main`、`runId=28715553215`、`runAttempt=1` 与 `origin/main` 功能提交一致；`git ls-remote` 曾因网络连接 github.com 超时失败，随后用 GitHub API `heads/main` 核对远端 SHA 一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 敌方意图预判是静态摘要，不包含逐行动时间线、概率 AI、动画、音效或真实美术资产。
- 本轮不改变 AI 优先级、路径选择、攻击目标选择、战术命令、后勤策略、战斗数值、胜负条件或回合流程。

### v1.11 / 敌方意图反制建议

日期：2026-07-05

核心变更：

- 新增 `EnemyThreatCountermeasureKind` 和 `EnemyThreatCountermeasurePreview`，把敌方意图下游的抢先打击、撤出危险区、据点防守和整补支撑转为结构化只读建议。
- `GameState` 新增 `enemyThreatCountermeasurePreviews(for:limit:)` 和 `visibleEnemyThreatCountermeasurePreviews`，基于敌方意图生成最多 3 条稳定排序的应对建议。
- 反制建议复用现有只读规则：抢先打击复用 `combatPreview`，撤退复用玩家移动路线和火力暴露预览，据点防守复用移动路线，整补支撑复用 `canReinforce`/恢复量计算；查询不调用真实移动、攻击、整补或 AI 方法。
- 侧栏“敌方意图”面板下新增“反制建议”面板，显示建议类型、执行单位、目标/目的地、路线消耗、预计效果和理由；UI 只消费 `GameState` 字段。
- 补充 XCTest 和规则 smoke test，覆盖抢先打击、撤退、据点防守、整补、`limit` 前缀和查询无副作用。

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
- `md/prompt/v1（地图操作体验）/v1.11（敌方意图反制建议）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28726166516` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.11-main-57b32fc-run28726166516-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28726166516/`，目录大小 `2.0M`。
- Manifest `commitSha=57b32fc9962c9bd7a64b00e8b673e9fac9ea0595`、`branch=main`、`runId=28726166516`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 反制建议是静态参谋提示，不会自动执行命令，不包含动画、音效、概率 AI、逐行动时间线或真实美术资产。
- 本轮不改变 AI 优先级、敌方意图预判、战斗数值、移动规则、部署/整补成本、胜负条件或回合流程。

### v1.12 / 反制建议点选聚焦

日期：2026-07-05

核心变更：

- `GameState` 新增 `focusEnemyThreatCountermeasure(_:)` 和 `isEnemyThreatCountermeasureFocused(_:)`，让反制建议能像 OBJ 目标计划和安全接敌候选一样点选后切换地图预览。
- 抢先打击会选中执行单位并聚焦威胁来源敌军；撤出危险区会选中被威胁单位并聚焦撤退目的格；据点防守会选中执行单位、聚焦防守格并保留被威胁据点引导；整补支撑会选中受威胁单位并聚焦当前位置。
- 聚焦入口会重新校验单位、路线、敌军或整补条件；过期建议只提示原因，不执行命令。
- `ContentView` 将反制建议行改为 `Button`，加入当前预览状态、无障碍 label/hint，并保持 UI 只调用 `GameState` 聚焦方法。
- 补充 XCTest 和规则 smoke test，覆盖四类建议点选、过期建议和无副作用。

关键文件：

- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1（地图操作体验）/v1.12（反制建议点选聚焦）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28726677459` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.12-main-8b92d36-run28726677459-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28726677459/`，目录大小 `2.0M`。
- Manifest `commitSha=8b92d3648f73199a61a3e024c48166291e620c4a`、`branch=main`、`runId=28726677459`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 反制建议点选仍只是预览聚焦，不会自动执行移动、攻击、整补或战术命令。
- 本轮不改变 AI、战斗数值、移动规则、敌方意图/反制建议生成算法、整补成本、胜负条件或回合流程。

### v1.13 / 反制建议地图聚焦标记

日期：2026-07-05

核心变更：

- 新增 `EnemyThreatCountermeasureMapMarkerRole` 和 `EnemyThreatCountermeasureMapMarker`，把当前点选的反制建议投射为 ACT 执行单位、SRC 威胁来源、CTR 反制目标和 TGT 受威胁目标。
- `GameState` 新增 `focusedEnemyThreatCountermeasureMapMarkers`，保存被点选建议快照并在读取时重新校验单位、敌军、路线或整补条件；普通聚焦、真实移动、重开和切战役会清理旧反制聚焦。
- `ContentView` 在地图格显示反制聚焦标记、边框强化和无障碍说明，图例新增“反制聚焦”；UI 只消费 `GameState` 标记，不计算建议有效性。
- 补充 XCTest 和规则 smoke test，覆盖抢先打击、撤退、据点防守、整补四类建议的 ACT/SRC/CTR/TGT 标记，以及普通聚焦和过期建议不残留标记。

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
- `md/prompt/v1（地图操作体验）/v1.13（反制建议地图聚焦标记）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28728890148` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.13-main-c4e9a8e-run28728890148-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28728890148/`，目录大小 `2.1M`。
- Manifest `commitSha=c4e9a8e3e95a5e13e5e1499c3ff60c70fc25abde`、`branch=main`、`runId=28728890148`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 反制建议地图标记仍是只读态势辅助，不会自动执行移动、攻击、整补或战术命令。
- 本轮不改变 AI、战斗数值、移动规则、敌方意图/反制建议生成算法、整补成本、胜负条件或回合流程。

### v1.14 / 反制建议执行桥接预览

日期：2026-07-05

核心变更：

- 新增 `EnemyThreatCountermeasureExecutionKind` 和 `EnemyThreatCountermeasureExecutionPreview`，把当前点选的反制建议桥接到既有执行入口。
- `GameState` 新增 `focusedEnemyThreatCountermeasureExecutionPreview`，在反制建议仍被聚焦时重新校验当前状态：抢先打击指向地图 ATK/执行按钮，撤出危险区和据点防守指向地图 MOVE/执行按钮，整补支撑指向单位详情整补按钮。
- 桥接预览复用 `mapCommandPreview(for:)`、`movementRoute(for:to:)`、`combatPreview(attacker:defender:)` 和 `canReinforce(_:)`，不调用真实移动、攻击、整补或执行命令。
- `ContentView` 在反制建议列表下方显示只读“下一步”提示，展示 ATK、MOVE 或整补入口，并在无障碍 hint 中说明不会执行命令。
- 补充 XCTest 和规则 smoke test，覆盖四类反制建议的执行桥接预览，以及普通聚焦、过期建议不保留可执行桥接预览。

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
- `md/prompt/v1（地图操作体验）/v1.14（反制建议执行桥接预览）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28730060970` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.14-main-dde4c3e-run28730060970-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28730060970/`，目录大小 `2.1M`。
- Manifest `commitSha=dde4c3e4a201f92ac7c1ac29696bbd0f46da1486`、`branch=main`、`runId=28730060970`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 执行桥接预览仍是只读入口提示，不会让反制建议行直接执行移动、攻击或整补。
- 本轮不改变 AI、战斗数值、移动规则、敌方意图/反制建议生成算法、整补成本、胜负条件或回合流程。

### v1.15 / 反制建议收益解释

日期：2026-07-05

核心变更：

- 新增 `EnemyThreatCountermeasureBenefitKind` 和 `EnemyThreatCountermeasureBenefitMetric`，把反制建议已有字段派生为战果、生存、守点、恢复、路线和优先值等结构化收益解释。
- `EnemyThreatCountermeasurePreview` 新增 `benefitMetrics` 和 `benefitSummary` computed properties，复用既有 `projectedDamage`、`projectedEnemyHPAfterDamage`、`projectedFriendlyHPAfterAction`、`projectedRecoveredHP`、`destination`、`routeCost` 和 `score`，不重新计算规则。
- `ContentView` 在反制建议行内显示紧凑收益指标，并把收益摘要加入无障碍 label；建议行仍只负责聚焦，不执行移动、攻击或整补。
- 补充 XCTest 和规则 smoke test，覆盖抢先打击、撤出危险区、据点防守、整补支撑四类建议的收益解释。

关键文件：

- `WW2Tactics/WW2Tactics/GameModels.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1（地图操作体验）/v1.15（反制建议收益解释）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28730693977` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.15-main-7ba95fb-run28730693977-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28730693977/`，目录大小 `2.1M`。
- Manifest `commitSha=7ba95fb4b62ac12b1c79c60ca689f325f0df41f2`、`branch=main`、`runId=28730693977`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 收益解释是只读扫描辅助，不改变反制建议排序、score 公式或执行桥接。
- 本轮不改变 AI、战斗数值、移动规则、敌方意图/反制建议生成算法、整补成本、胜负条件或回合流程。

### v1.16 / 反制建议排序对比解释

日期：2026-07-05

核心变更：

- `EnemyThreatCountermeasurePreview` 新增 `priorityFactors` 和 `prioritySummary`，从可执行性、击毁判定、优先值、路线、执行单位、目标和坐标等既有字段派生只读排序依据。
- `GameState` 新增 `enemyThreatCountermeasureComparisonPreviews(for:limit:)`，并让排序函数与对比解释共用同一套排序判定 helper，按既有维度顺序生成首选与下一条建议的相邻对比解释。
- `ContentView` 在反制建议面板显示“首选依据”，并在建议行展示每条建议的优先级摘要；点选仍只聚焦预览，不执行移动、攻击或整补。
- 补充 XCTest 和规则 smoke test，覆盖排序依据、相邻对比、limit 边界、可执行/击毁/优先值/路线等关键排序分支和只读无副作用。

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
- `md/prompt/v1（地图操作体验）/v1.16（反制建议排序对比解释）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28732044437` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.16-main-553298d-run28732044437-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28732044437/`，目录大小 `2.2M`。
- Manifest `commitSha=553298d1cc822006bb44846fb4b8960a2f174dbd`、`branch=main`、`runId=28732044437`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 排序对比解释是只读参谋提示，不改变反制建议排序、score 公式或执行桥接。
- 本轮不改变 AI、战斗数值、移动规则、敌方意图/反制建议生成算法、整补成本、胜负条件或回合流程。

### v1.17 / 反制建议执行前后对照

日期：2026-07-05

核心变更：

- 新增 `EnemyThreatCountermeasureImpactKind` 和 `EnemyThreatCountermeasureImpactComparison`，让反制建议携带“当前 / 采纳 / 改善”的执行前后预计对照。
- `GameState` 在抢先打击、撤出危险区、据点防守和整补支撑四类建议构造时填充只读对照：威胁伤害、撤退后生存、守点动作、整补后承受威胁预计 HP 和路线信息。
- 整补支撑的主对照优先展示“当前威胁后 HP -> 整补后再承受威胁 HP”，避免把承受威胁前的整补 HP 误读为最终结果。
- `ContentView` 在反制建议行显示紧凑的当前/采纳/改善指标，并把完整 `impactSummary` 加入行内摘要和无障碍 label；UI 只展示 `GameState`/`GameModels` 字段，不计算战斗、路线、整补或排序。
- 补充 XCTest 和规则 smoke test，覆盖四类反制建议的非空对照、抢先打击当前威胁文案、撤退 HP 改善、据点守点动作、整补后承受威胁 HP 改善和只读无副作用。

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
- `md/prompt/v1（地图操作体验）/v1.17（反制建议执行前后对照）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28733176273` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.17-main-337c55f-run28733176273-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28733176273/`，目录大小 `2.3M`。
- Manifest `commitSha=337c55f734c551ec43b11025791444b5c2dd32f1`、`branch=main`、`runId=28733176273`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 执行前后对照是预计参谋提示，不代表真实执行后的记录；真实执行后的反制结果回放可作为后续 v1.18 方向。
- 本轮不改变 AI、战斗数值、移动规则、敌方意图/反制建议生成算法、整补成本、胜负条件、排序或执行桥接语义。

### v1.18 / 反制建议执行回放

日期：2026-07-05

核心变更：

- 新增 `EnemyThreatCountermeasureExecutionResultKind`、`EnemyThreatCountermeasureExecutionResultComparison` 和 `EnemyThreatCountermeasureExecutionResultSummary`，记录反制建议真实执行后的预计、实际和结果说明。
- `GameState` 新增 `latestEnemyThreatCountermeasureExecutionResult`，在当前聚焦反制建议通过既有 ATK、MOVE 或整补入口成功执行后发布回放；抢先打击读取 `latestCombatResult`，撤退和守点读取移动后单位/据点状态，整补读取 `latestReinforcementResult`。
- 普通聚焦、预览和点选建议不生成回放；重开、切战役、回合切换和无关普通移动、攻击、整补、部署、战术命令或占点成功路径会清理旧回放。
- `ContentView` 在结果区域显示“反制回放”卡片，列出建议类型、执行单位、目标、坐标、前三项预计/实际对照和无障碍说明；UI 只展示 `GameState`/`GameModels` 字段。
- 补充 XCTest 和规则 smoke test，覆盖抢先打击、撤退、据点防守、整补支撑四类执行回放，以及普通行动不生成或清理、重开/切战役清理边界。

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
- `md/prompt/v1（地图操作体验）/v1.18（反制建议执行回放）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions 结果：待 Agent B push 后由 Agent C 下载 artifact 核对。

遗留事项：

- 执行回放只记录玩家采纳建议后走既有入口产生的最近一次结果，不新增一键执行、动画、音效或自动战术代理。
- 本轮不改变 AI、战斗数值、移动规则、敌方意图/反制建议生成算法、整补成本、胜负条件、排序或执行桥接语义。
