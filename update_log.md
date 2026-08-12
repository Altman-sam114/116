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
- 近期规划已进入 `v2（六角格战争界面）`：v2.0 建立连续六角格战区、具象单位视觉和拆分后的 SwiftUI 表现层基座，规则状态机保持不变。

## 历史记录

### v2.42 / 战区账本材质统一

日期：2026-08-12

核心变更：

- `BattlefieldTheme` 新增只供顶栏与地图覆盖层调用的 War Ledger token 及 `WarLedgerSurface`；它统一深色底材、蚀刻细边、静态内高光、细分隔和受控阴影，不改通用 `TacticalSurface`、地貌、单位或侧栏。
- `TopCommandBar` 将 `CommandTitle`、`CampaignPicker`、完整六项真实 `StatusChip` 字段和 `EndTurnButton` 收为连续账本带；每个字段仍保留短可视值与完整 VoiceOver，战役选择、结束回合/winner 禁用与 44pt action 不变。
- `MapHudBackground` 与 66pt `ObjectiveJumpDock` 复用地图覆盖账本底材；v2.41 的完整 AL/OBJ/AX 数组、edge fade/chevron、section-local stable id/focus scroll、72/84pt、48/50pt、44pt 与 Reduce Motion 保持，fade 改用同族底材衔接。

关键文件：

- `WW2Tactics/WW2Tactics/BattlefieldChrome.swift`
- `WW2Tactics/WW2Tactics/BattlefieldTheme.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v2（六角格战争界面）/v2.42（战区账本材质统一）.md`

验证依据与结果：

- 本轮基于已由 Agent C 验收的 `origin/main` commit `d903c9fc8912860fb4e3c1c08e1aaeb3a7a4005b`、workflow run `31580545970`、attempt `1` 与 artifact `ww2tactics-ci-v2.41-main-d903c9f-run31580545970-attempt1` 实现；该基线不是 v2.42 验收证据。
- 人工要求全部交给 GitHub Actions：本地不运行 Swift、swiftc typecheck、RulesSmokeTest、XCTest、Xcode build、模拟器、截图或 Playwright；提交前仅运行 Git/文本轻量检查与提交范围核对。
- v2.42 功能提交为 `fdea706efbf5c9477253a30757c6410cbae76220`，对应 workflow run `31582167151`、attempt `1`；artifact 为 `ww2tactics-ci-v2.42-main-fdea706-run31582167151-attempt1`，digest 为 `sha256:e136ad4a0ca77b7cd1a6afbf40904b80be7a873ed3eee18b735330ac6f71fb15`。Agent C 已使用 `Altman-sam114` 下载到 `/private/tmp/ww2tactics-c-review-31582167151/`，`du -sh` 为 `9.5M`，并确认 `origin/main`、workflow head SHA、manifest 的 branch、commit SHA、run id 与 run attempt 全部精确匹配。
- Agent C 已核对 static checks、RulesSmokeTest、Xcode `build-for-testing` 与 regular screenshot 均成功，JUnit 为 4/4；`WW2Tactics.xcresult`、failure summary、static/rules/Xcode/screenshot 日志齐全。PNG 为 `2064x2752`、`5,770,761` bytes，实看为非黑屏且六角地图、连续 War Ledger 顶栏、地图 HUD、单一 AL/OBJ/AX rail、道路、补给、单位、暖金 selected、HIT/RET 与交战结论清晰。manifest 标记 XCTest 为 skipped；AppIntents metadata warning 为非致命警告，不影响构建、截图或验收。

遗留事项：

- v2.42 已完成 Agent C 的精确云端 artifact 验收。当前 workflow 仅生成 regular PNG；compact、窄宽度、xxxLarge Dynamic Type、不同焦点与 Reduce Motion 仍只具源码审查证据，regular 截图不能作为其实际设备证据。

### v2.41 / 轨道滚动提示

日期：2026-08-12

核心变更：

- `ObjectiveJumpStrip` 继续从完整的友军、既有排序的据点、敌军数组构造 `AL / OBJ / AX` 三段；每个 item 额外使用单位 UUID 或据点坐标作为 section-local 稳定滚动 id，不改变数组、排序、友军 `select(unitID:)`、敌军 `focus(unitID:)` 或据点 `focus(coordinate:)`。
- `ObjectiveJumpSection` 在表现层本地测量自己的 viewport、完整内容宽度与横向 minX，以 epsilon 派生真实 overflow 和当前 leading/trailing 隐藏内容。只有对应方向仍有项目时才显示低对比深色 edge fade 与 chevron；提示层关闭 hit testing，滚动和 Button 命中不受影响。
- 既有 `focusedUnit` 或 `focusedCoordinate` 变化仅会让包含稳定 id 的那一段 `ScrollViewReader` 滚到中间；失效焦点或空数组不滚动。普通模式使用短促滚动动画，Reduce Motion 直接定位且保留静态 cue/fade；72/84pt 宽、48/50pt 高、44pt 命中区、短可视大字号与完整 VoiceOver 不变。

关键文件：

- `WW2Tactics/WW2Tactics/BattlefieldChrome.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v2（六角格战争界面）/v2.41（轨道滚动提示）.md`

验证依据与结果：

- 本轮基于已由 Agent C 复核的 `origin/main` commit `14ba8ef01404f06b10ac2d665d9482af7e6ead7f`、workflow run `31301750449`、attempt `1` 和其 v2.40 artifact 实现；该基线不是 v2.41 的验收证据。
- 人工要求全部交给 GitHub Actions：本地未运行 Swift、swiftc typecheck、RulesSmokeTest、XCTest、Xcode build、模拟器或截图；提交前只运行 Git/文本轻量检查与提交范围核对。
- v2.41 修复最终 commit 为 `3d5687c9d0aa827139ec1eb5400f9a2ca44e3640`，对应 workflow run `31579557207`、attempt `1`；artifact 为 `ww2tactics-ci-v2.41-main-3d5687c-run31579557207-attempt1`，digest 为 `sha256:ce585264bd6a2c27d140746faebb0e2f46ecd4987e8d36064842251062895baf`。Agent C 以 `Altman-sam114` 下载到 `/private/tmp/ww2tactics-c-review-31579557207/`，并确认 artifact manifest 的 `branch=main`、commit SHA、run id 和 run attempt 与 `origin/main` 及 workflow 一致。
- 该 run 的 static checks、RulesSmokeTest、Xcode `build-for-testing` 和 `selected-combat-impact-steady` regular screenshot 均成功；JUnit 为 4/4（4 tests、0 failures），`WW2Tactics.xcresult` 与主构建/规则/截图日志齐全。regular PNG 为 `2064x2752`、约 `5.7M`；Agent C 实看确认六角地图仍占主视觉，单一底缘 `AL / OBJ / AX` rail、道路、补给、单位、selected、HIT/RET、交战结论和 HUD 可读，无黑屏或明显视觉回归。结果包中的 AppIntents metadata warning 为非致命警告，不影响构建、截图或验收。
- 本地仍未运行 Swift、swiftc typecheck、RulesSmokeTest、XCTest、Xcode build、模拟器或截图；regular PNG 不能证明 compact、窄屏、`xxxLarge` Dynamic Type 或多焦点状态，相关契约由 Agent C 源码审查确认。

遗留事项：

- v2.41 代码、文档与云端 artifact 验收已完成。下一轮风险是现有 workflow 仍只生成 regular PNG，compact/窄屏、`xxxLarge` Dynamic Type、不同焦点状态和真实设备上的 rail cue/fade 可见性仍主要依赖源码审查；后续迭代需继续保持三段完整数组、地图优先和既有规则/输入边界。

### v2.40 / 道路环路密度微调

日期：2026-08-09

核心变更：

- `RoadConnectionNetwork` 继续从 `.road` 邻接构造 canonical 无向边，并先用稳定 Kruskal 保留主干、桥接边和端点；随后按每个连通组件的 `edgeCount - vertexCount + 1` 计算 `cycleRank`，将回边 quota 固定为无环 0、有环 1。
- 回边候选在主干上做确定性 BFS，按环路长度优先、内部高阶节点数量、端点度数和 q/r/direction 稳定排序，优先较长、低分叉的环路，避免短三角回边主导高密度地图；selected canonical edges 仍只向两端投影 paired half-path。
- `TerrainTexture` 的道路 shadow、主体和 dashed highlight、孤立道路短中心笔触、河流/补给线及 v2.39 AL/OBJ/AX rail 保持原链；不改 `GameState`、模型、路线成本、地图输入、tile frame、contentShape、zIndex 或 workflow。

关键文件：

- `WW2Tactics/WW2Tactics/BattlefieldMap.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v2（六角格战争界面）/v2.40（道路环路密度微调）.md`

验证依据与结果：

- 本轮基于已由 Agent C 验收的 v2.39 `origin/main` commit `daba43bee0a5f70e75674a34cad0c90ff58bf948`、workflow run `31299229972`、attempt `1`、artifact `ww2tactics-ci-v2.39-main-daba43b-run31299229972-attempt1`（digest `sha256:bea48ba4d543afc678573a7f06f677532512400226736a850c2732827209749c`）实现本轮目标；这些是 v2.40 实现前基线，不是本轮验收结果。
- 本地遵循人工要求，不运行 Swift、Xcode、typecheck、RulesSmokeTest、XCTest、模拟器或截图；提交前仅执行 `git diff --check`、工作树/范围核对。v2.40 需由 GitHub Actions 和 Agent C 云端 artifact 完成重验证。
- 功能实现 commit `7284c41c64d0e0637ddb0faca80dd14bd934e77d` 已由 workflow run `31300583825`、attempt `1` 通过 static checks、RulesSmokeTest、Xcode `build-for-testing` 和 `selected-combat-impact-steady` regular 截图；artifact 为 `ww2tactics-ci-v2.40-main-7284c41-run31300583825-attempt1`，digest `sha256:7b6d442cec080684b7a879da67757ce4bb2a2abd2fd3fa9ac0e5cb89287e4778`。
- 该结果包的 `junit.xml` 为 4 tests、0 failures/errors/skips；PNG 为 iPad Pro 13-inch (M5) `2064x2752`、`5961392` bytes、SHA-256 `1a3937d9dcb540351a183da433f26d438ef042b84a1e2ab3350c6703f6904dbb`，`WW2Tactics.xcresult/Info.plist` 可读且 `xcodebuild.log` 含 `** TEST BUILD SUCCEEDED **`。Agent C 已从 `/private/tmp/ww2tactics-c-review-31300583825/` 下载并实看：道路主干、分支、长环路、边界、孤立笔触和 AL/OBJ/AX、补给、单位、HIT/RET、交战结论、HUD 清晰，未见短三角回边主导或 lattice 回归。

遗留事项：

- v2.40 功能与云端视觉验收已完成；现有 workflow 只生成 regular 截图，compact/Dynamic Type 和不同地图状态仍以源码结构审查与后续观察为证。当前已核对 `cycleRank == 0` 无回边、含环组件最多一条回边、主干/paired half-path/规则与输入边界不变；后续仅观察更多地图状态下的长环连续性。

### v2.39 / 窄屏轨道与道路环路

日期：2026-08-09

核心变更：

- `ObjectiveJumpStrip` 读取 Dynamic Type，在 `xxxLarge` 及以上切换为兵种 code、`OBJ` 等短可视标签；section 标题与项目在同一底部轨道内使用 16/48pt 大字号或 14/50pt 普通布局，视觉 Dynamic Type 在短模式封顶到 `.large`，避免固定项目被辅助字号撑高或裁切。
- 友军、据点和敌军仍遍历完整事实数组并独立横向滚动，按钮宽度、焦点边框、阵营线和 `select`/`focus` action 不变；完整单位/据点名称、阵营、HP、行动、将领、补给和战术状态继续由 VoiceOver 读取。
- 道路从纯生成树调整为 canonical 无向边主干加受控回边：每个含环组件保留一条确定性低密度回边，再投影为两端 paired half-path，避免重复 lattice，同时保留桥接边、端点和孤立道路笔触。

关键文件：

- `WW2Tactics/WW2Tactics/BattlefieldChrome.swift`
- `WW2Tactics/WW2Tactics/BattlefieldMap.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v2（六角格战争界面）/v2.39（窄屏轨道与道路环路）.md`

验证依据与结果：

- 本轮基于已由 Agent C 验收的 v2.38 `origin/main` commit `467c9aaa727933a3e9e4483d813f0d670b587d8d`、workflow run `31297090421`、attempt `1`、artifact `ww2tactics-ci-v2.38-main-467c9aa-run31297090421-attempt1`（digest `sha256:a660d3976d265706472f21adf503a55b4ee18f2dd782b3c3efbd4765c859614e`）实现本轮目标；这些是 v2.39 实现前基线，不是本轮验收结果。
- 本地遵循人工要求，不运行 Swift、Xcode、typecheck、RulesSmokeTest、XCTest、模拟器或截图；提交前仅执行 `git diff --check`、工作树/范围核对。v2.39 需由 GitHub Actions 和 Agent C 云端 artifact 完成重验证。
- 功能实现 commit `97767158289b254863f53f6ad15c597202c486e1` 已由 workflow run `31298292205`、attempt `1` 通过 static checks、RulesSmokeTest、Xcode `build-for-testing` 和 `selected-combat-impact-steady` regular 截图；artifact 为 `ww2tactics-ci-v2.39-main-9776715-run31298292205-attempt1`，digest `sha256:de82e3d00734261fca8c3b9fa2cb6cdda28b2908b2f2ea828872782092749974`。
- 该结果包的 `junit.xml` 为 4 tests、0 failures/errors/skips；截图为 iPad Pro 13-inch (M5) `2064x2752`、`5962104` bytes、SHA-256 `65f87208896cbbe5fd6f39dec26ea00336d8f4e34150318d66dd9a72da343649`，`WW2Tactics.xcresult/Info.plist` 可读且 `xcodebuild.log` 含 `** TEST BUILD SUCCEEDED **`。Agent C 已从 `/private/tmp/ww2tactics-c-review-31298292205/` 下载并实看该包。

遗留事项：

- v2.39 功能与云端视觉验收已完成；现有 workflow 只生成 regular 截图，compact/Dynamic Type 仍以源码结构审查为证：短可视标签与 `.large` 上限、完整 VoiceOver/44pt 命中区、canonical 道路回边与规则/输入边界均已核对。后续仅观察不同地图状态下的窄屏轨道密度与道路环路可读性。

### v2.38 / 支援甲板信息轨道

日期：2026-08-09

核心变更：

- 地图底缘 `ObjectiveJumpDock` 继续保留 `AL / OBJ / AX` 三段完整事实数组、独立横向滚动和既有选择/定位 action，但收敛为单一深色半透明外层轨道；section 改用短码、数量和细分隔，单位/据点项目改为透明底、焦点边框与阵营色底线，降低嵌套卡片墙的视觉重量。
- 展开的 `ForceRibbon` 不再重复渲染完整盟军/轴心单位卡，改为只读双方数量与 READY 摘要；支援甲板默认收起，战术命令、增援、图例等独有入口保持可访问。
- 本轮仅修改 SwiftUI 表现层和同步文档，不改 `GameState`、地图输入、规则、排序、数据数组、zIndex 或 CI 配置；44pt 命中区、VoiceOver、Dynamic Type、Reduce Motion、地图工作区和 `select`/`focus` action 保持原契约。

关键文件：

- `WW2Tactics/WW2Tactics/BattlefieldChrome.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v2（六角格战争界面）/v2.38（支援甲板信息轨道）.md`

验证依据与结果：

- 本地按人工要求未运行 Swift、Xcode、typecheck、RulesSmokeTest、XCTest、模拟器、Playwright 或截图；仅执行 Git 状态、变更范围和 `git diff --check` 轻量检查。
- 本轮基于已由 Agent C 验收的 v2.37 `origin/main` commit `fc4af213b77d01b41bfed5f295e0727eb8d1fb95`、workflow run `31294998218`、attempt `1`、artifact `ww2tactics-ci-v2.37-main-fc4af21-run31294998218-attempt1`（digest `sha256:41ef756d0eba2d6a45121f80995affe8b15150203ce6ebfe216b6aa8c5a92884`）拆分本轮目标；这些仅是实现前基线，不是 v2.38 验收结果。
- 功能实现 commit `41dbb185cc19e3b2622101a9fa443398e02949ba` 已推送到 `main`，对应 GitHub Actions workflow run `31296511173`、attempt `1`；Agent C 已下载并核对 artifact `ww2tactics-ci-v2.38-main-41dbb18-run31296511173-attempt1`（7,187,380 bytes，digest `sha256:c8e9e95e9120e8bcdcb0adfc102f7b82b0301cb03a20804cd6c9dc2a6b16a229`）。manifest 的 `branch`、`commitSha`、`runId`、`runAttempt` 与 `origin/main` 完全一致，static checks、RulesSmokeTest、Xcode `build-for-testing` 和 battlefield screenshot 均为 success；JUnit 为 4 tests / 0 failures / 0 errors / 0 skipped，XCTest execution 按 CI 策略 skipped。
- artifact 中 PNG 为 `2064x2752`、`5,959,673` bytes（SHA-256 `84d0c92608edaed3f689e41812c539670e578fb301f0c584ceff38fac69f6a73`），Agent C 已实际查看：地图工作区、道路/补给线、单位模型、暖金选中焦点、HIT/RET、交战结论、HUD 与单位状态保持清晰；底缘呈单一深色半透明轨道，`AL / OBJ / AX` 三段短码、数量和横向列表可读，展开入口保持收起且未再重复渲染完整单位卡。

遗留事项：

- v2.38 功能与云端视觉验收已完成；后续迭代应继续以最新 artifact 为基线观察窄屏、Dynamic Type 和不同地图状态下的信息轨道密度。

### v2.37 / 道路方向去重

日期：2026-08-09

核心变更：

- 依据 v2.36 最终云端截图中相邻道路格重复叠出棕色三角/交叉 lattice 的事实，仅在 `HexMapView` 表现层为 `.road` 构造稳定 canonical 无向边网络：按方向 `0/1/2` 确定性枚举每条视觉边一次，并向两端投影 paired half-path。
- 道路 shadow、主体和 highlight 共用该 `connectionPath`，移除逐格固定水平 `roadHighlight`；无相邻道路的孤立格用确定性短中心笔触保持可读，河流、弱林带和其他地貌连接保持原邻接链。
- 不改变 `TerrainKind`、`TerrainTile`、移动力、路线成本、路线预览、`GameState`、tile frame、contentShape、输入、zIndex、VoiceOver 或 v2.36 补给线/ v2.35 selected / v2.34 战果表现。

关键文件：`BattlefieldMap.swift`、README、flow、flowchart、test、prompt README、v2.37 prompt 和本日志。

验证依据与结果：

- 本轮分配依据为 v2.36 最终 commit `d69e0ae2d78d9f84ad7daa73ecae11ebb8ae03c1`、run `31291811412`、attempt `1`、artifact `ww2tactics-ci-v2.36-main-d69e0ae-run31291811412-attempt1`，digest `sha256:6ec6d20afeb0d92c8b165e18139d600b2c56dbb4aba162e51ca1d926f22f75c3`；PNG `2064x2752`、约 `5,959,930` bytes 已由 Agent C 实际查看并确认补给线、M10 暖金选中焦点、HIT/RET、交战结论、HUD 和 AL/OBJ/AX 清晰，道路 lattice 为下一轮依据。
- 本地按人工要求未运行 Swift、Xcode、typecheck、RulesSmokeTest、XCTest、模拟器、Playwright 或截图；仅执行 Git 状态、范围和 `git diff --check` 轻量检查。
- v2.37 功能实现先由 commit `9f6a7935c9374d29c54c9b767306fb53a2a7aced` 推送；首轮 run `31293202537` 的 static/smoke 通过但 Xcode 因 `ForEach(game.tiles)` 的 Binding overload 推断失败，截图被跳过。修复 commit `a235809125a883a34fc12028ff1a472f56820f9d` 显式加入 id 后仍复现同一错误，最终 commit `290b1e379b73ac9eb13c11a8b05fec3966aec534` 以明确 `[TerrainTile]` value collection 和单一 `[Int]` 三元派生收敛 `ViewBuilder` 类型推断；未改道路网络、路径或规则。
- 最终 `origin/main` commit `290b1e379b73ac9eb13c11a8b05fec3966aec534` 对应 workflow run `31293767771`、attempt `1`，artifact `ww2tactics-ci-v2.37-main-290b1e3-run31293767771-attempt1`，digest `sha256:01fab665f36834b1d38b021ec72ca5adc1fc62c51c6ecbef5fa91298fcecc8ea`；manifest 的 branch/SHA/run/attempt 完全匹配，static、RulesSmokeTest、Xcode build-for-testing、截图均 success，JUnit `4 tests / 0 failures / 0 errors / 0 skipped`，PNG `2064x2752`、`5,938,459` bytes。Agent C 已下载并实看 PNG：道路读作细棕色斜向/蜿蜒走廊，孤立短笔触、端点、路口和地图边缘可读，未见首轮大面积三角 lattice；河流、地貌、单位模型、M10 暖金 selected、HIT/RET、交战结论、HUD、AL/OBJ/AX 均清晰。

遗留事项：v2.37 已完成云端验收；后续迭代仍应观察不同地图种子下视觉森林对环路和多路口的保留程度，不得把道路视觉网络改写为规则路径状态。

### v2.36 / 补给线覆盖降噪

日期：2026-08-09

核心变更：

- 补给路径仍由 `GameState.supplyLineTiles(for:)` 提供，地图仅从同一只读集合和 `HexCoordinate.neighbors` 派生相邻方向。
- `SupplyLineMarker` 从每格绿色粗胶囊改为细窄、低对比的中心到边界笔触，相邻六角格可连续读作后勤通道；单格使用短中心笔触，不再形成绿色圆牌。
- 补给线六角边框收为接近基础蚀刻网格的弱提示，selected、MOVE/ATK/POS、路线、火力、态势/复盘 marker 和单位模型保持更高层级；攻击焦点过滤、`SUP`/`CUT`、补给计数、输入、zIndex 与 VoiceOver 摘要不变。

关键文件：`BattlefieldMap.swift`、`BattlefieldTheme.swift`、README、flow、flowchart、test、prompt README、v2.36 prompt 和本日志。

验证结果：

- 本地按人工要求未运行 Swift、Xcode、typecheck、RulesSmokeTest、XCTest、模拟器、Playwright 或截图；仅执行 Git 状态、范围和 `git diff --check` 轻量检查。
- Agent C 已下载并核对未加密 artifact `ww2tactics-ci-v2.36-main-1d1c518-run31290789962-attempt1`，digest 为 `sha256:131d5a87ebb8fdac2c390561489246b37bd70d457ac8715ea9a726a511b6a115`；manifest 的 `branch=main`、`commitSha=1d1c5186b8504ddb2bdd022a2aa0566f270fc6fa`、`runId=31290789962`、`runAttempt=1` 与 `origin/main` 完全一致。
- static、RulesSmokeTest、Xcode `build-for-testing` 和 screenshot 四项 outcome 均为 success；JUnit 共 4 项、0 failures、0 errors、0 skips，`.xcresult` 有效，PNG 为 `2064x2752`、`5,959,930` bytes。
- PNG 已实际查看：补给线收敛为低对比连续细笔触，不再形成绿色粗胶囊或整格粗边；白昼地貌、道路/河流、M10 暖金选中底座与抬升、军械模型、`HIT -21 / 64 -> 43`、`RET -7 / 64 -> 57`、“交火”、HUD、AL/OBJ/AX 和高优先级 marker 均保持清晰。
- 随后文档修正 commit `ceb237d528757b9516312fd0e7039c239fd01ee3` 触发 run `31291315530`、attempt `1`，Agent C 已核对 artifact `ww2tactics-ci-v2.36-main-ceb237d-run31291315530-attempt1`，digest 为 `sha256:89bc298abb3d2cb8be22add78829816d7141dae1dc1a43d47b6ddb3c39cd34ac`；manifest 的 branch、commitSha、runId、runAttempt 全匹配，static、RulesSmokeTest、Xcode `build-for-testing`、screenshot 四项 outcome、JUnit 4/0 failures、规则 smoke、build、screenshot、PNG `2064x2752`/`5,959,947` bytes 与实看结论一致。
- 两次验收链已闭合：功能 commit `1d1c518` 的源码/视觉 artifact 先完成验证，随后文档修正 commit `ceb237d` 的云端 run 复核了同一事实链；本条目不再保留“等待”或“待核对”状态。

遗留事项：v2.36 已完成 Agent C 云端 artifact 验收；后续可基于该 PNG 再拆分下一轮表现目标。

### v2.35 / 选中兵棋实体焦点

日期：2026-07-28

核心变更：

- 选中态从黄色粗边、青色地环、蓝色四角框统一为暖金/象牙实体底座、1.5pt 辅助边和同色四角框。
- 选中 `UnitCounter` 仅做 3pt 静态渲染抬升并增加暖金接地阴影，不改变布局或命中。
- 新增共享 `BattlefieldTheme.selectedPiece` token；选中状态同时由底座、边框、四角、位移和阴影表达。

关键文件：`BattlefieldTheme.swift`、`BattlefieldMap.swift`、README、flow、flowchart、test、prompt README、v2.35 prompt 和本日志。

验证结果：

- v2.34 修复 commit `cec4ecc102ae3608d4810b3109e17d0b254366dd`、run `30322225981`、attempt `1`、artifact `ww2tactics-ci-v2.34-main-cec4ecc-run30322225981-attempt1` 已完成结构核对和 PNG 实看；digest 匹配，四项检查成功，JUnit 4/4，XCTest 执行 skipped、测试 bundle 已构建，2064x2752 PNG 中 HIT/RET 已完全分离且无关键回归。
- 本轮本地只做 Git 级检查，不运行 Swift、Xcode、smoke、XCTest、模拟器或截图。

- v2.35 最新 commit `c0f15815bcd1129e9216506e2bce2db2902a8741` 的 run `30324158129`、attempt `1` 和 artifact `ww2tactics-ci-v2.35-main-c0f1581-run30324158129-attempt1` 已完成云端结构、规则、构建和截图验收。
- PNG 已实际查看：M10 攻击方位于战果区且可直接定位，暖金实体底座、3pt 抬升、接地阴影和四角准框清晰；`HIT -21 / 64 -> 43`、`RET -7 / 64 -> 57`、“交火”、HUD 与 marker 均可读。
- 本轮本地只做 Git 级检查，不运行 Swift、Xcode、smoke、XCTest、模拟器或截图。

遗留事项：补给线在 steady-state PNG 中仍以每格绿色粗胶囊和整格粗边重复表达，已由 v2.36 收敛为低对比连续通道。

### v2.34 / 紧凑交战战果铭牌

日期：2026-07-28

核心变更：

- HIT/RET 战果从上下两行黑牌收为单行金属铭牌，以不同系统图标、文字类型、伤害和 HP 前后共同编码。
- 缩小铭牌的圆角、padding、描边、阴影和交战结论胶囊，减少对军械模型、状态条和交战轴线的遮挡。
- 保持真实 `CombatResultSummary`、表现 phase、任务取消、Reduce Motion、steady-state、输入和单一 VoiceOver 摘要不变；同时修复 `WavingFlagShape` 声明排版。

关键文件：

- `WW2Tactics/WW2Tactics/BattlefieldMap.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v2（六角格战争界面）/v2.34（紧凑交战战果铭牌）.md`
- `update_log.md`

验证结果：

- v2.33 云端 artifact `ww2tactics-ci-v2.33-main-2684833-run30209317453-attempt1` 已下载到 `/private/tmp/ww2tactics-c-review-30209317453/`；digest、manifest、failure summary、JUnit、日志和 `.xcresult` 已核对，static、RulesSmokeTest、build-for-testing 与 screenshot 均成功，JUnit 4 项 0 失败，XCTest 执行按当前 CI 策略 skipped。
- 已实际查看 v2.33 的 2064x2752、5,942,553-byte PNG：雪地针叶树、坦克舱口/炮口、细道路、山体、河流、单位底座、HIT/RET、动作坞和 AL/OBJ/AX 正常；双行战果牌遮挡交战关系是本轮依据。
- 人工要求全部重验证走云端；本轮本地不运行 Swift、Xcode、typecheck、RulesSmokeTest、XCTest、模拟器或截图，只做 Git 级检查。
- 首个 v2.34 commit `e66f96b8ef9221a78aaaf94340b1a1007352fe9b` 的 run `30321435140`、attempt `1` 和 artifact `ww2tactics-ci-v2.34-main-e66f96b-run30321435140-attempt1` 配置检查全部成功；实看 2064x2752 PNG 后发现横向相邻交战的两块单行铭牌互相覆盖，视觉验收不通过，已在本版本追加沿交战轴向外错位的修复，并用 `@ScaledMetric` 恢复紧凑字号的 Dynamic Type 响应，等待新 run 复验。

遗留事项：

- 待 v2.34 云端 artifact 实看确认铭牌收敛后的数值可读性和遮挡改善。

### v2.33 / 雪原针叶树与坦克细节

日期：2026-07-26

核心变更：

- 雪地格约半数（按 q/r seed）散布 3 棵积雪针叶树：双层三角冠 + 树干 + 白色雪顶高光，雪原不再是纯白平板。
- 坦克兵模细节层新增炮塔指挥塔舱口圆与炮口制退器刻线，立体感提升。
- 清理 v2.31 农田重构时遗留的孤立路径片段。

验证结果：

- 人工要求全部云端，本地不运行 build、typecheck、smoke、XCTest、模拟器或截图；提交前只做 Git 状态、diff 与提交范围检查。
- v2.32 云端截图（run 30208825970）已确认：道路细带生效，密集路口区读作蜿蜒小径。

遗留事项：

- v2.33 云端截图已确认针叶树散布密度、坦克舱口与炮口细节正常；后续聚焦交战反馈遮挡。

### v2.32 / 道路网细化

日期：2026-07-26

核心变更：

- 道路连接带宽度 6 -> 4.5、透明度 0.85 -> 0.68：互邻三格道路的中心互连不再形成粗重三角网，密集路口区读作蜿蜒小径。

验证结果：

- 人工要求全部云端，本地不运行 build、typecheck、smoke、XCTest、模拟器或截图；提交前只做 Git 状态、diff 与提交范围检查。
- v2.31 云端截图（run 30208366355）已确认：平原跨格斜线消失，地表干净；山脉、河道、旗帜、羊皮纸铭牌均保持预期。

遗留事项：

- 若道路仍偏密，可后续引入基于坐标的方向去重（只画 3 个方向的半边连接）。

### v2.31 / 农田纹理去线

日期：2026-07-26

核心变更：

- 平原格移除跨格犁沟斜线（在浅色地表上会串联成贯穿全图的长对角线），保留 4 片柔和农田色块；地块透明度微降。

验证结果：

- 人工要求全部云端，本地不运行 build、typecheck、smoke、XCTest、模拟器或截图；提交前只做 Git 状态、diff 与提交范围检查。
- v2.30 云端截图（run 30207872586）已确认：据点旗杆红旗与羊皮纸将领牌生效；山脉雪顶与道路网可辨；平原斜线串联问题在本轮修复。

遗留事项：

- 道路密集区互邻三格互连形成三角路口网，视觉偏密，考虑后续为道路连接引入方向去重。

### v2.30 / 旗帜旗杆化与羊皮纸据点铭牌

日期：2026-07-26

核心变更：

- 据点旗标从胶囊药丸改为 GoG3 风格旗杆 + 飘动旗面（贝塞尔波浪外形），阵营色渐变旗面叠加深色描边与短码。
- 据点铭牌从深色半透明底改为羊皮纸渐变底 + 深棕文字 + 阵营色边，贴近 GoG3 城市铭牌。

验证结果：

- 人工要求全部云端，本地不运行 build、typecheck、smoke、XCTest、模拟器或截图；提交前只做 Git 状态、diff 与提交范围检查。
- v2.29 云端截图（run 30205765406）已确认：山地格呈岩灰山体 + 白色雪顶，地图上缘读作连续山脉；道路网泥土棕带清晰可辨，河流蓝带与道路并存不混淆。

遗留事项：

- 待本轮云端截图确认旗面与羊皮纸铭牌的观感；平原农田线的长对角线纹理可在后续轮次弱化。

### v2.29 / 山体重塑与道路显影

日期：2026-07-26

核心变更：

- 山地格从三片低对比水洗改为完整山体：岩灰主体剪影 + 受光亮面 + 双峰白色雪顶，峰高由 q/r seed 派生，地图上缘呈连续山脉。
- 道路连接带颜色从浅褐 0.72 透明度加深为泥土棕 0.85，浅色地表上道路网络重新可辨。

验证结果：

- 人工要求全部云端，本地不运行 build、typecheck、smoke、XCTest、模拟器或截图；提交前只做 Git 状态、diff 与提交范围检查。
- v2.28 云端截图（run 30205281461）已确认：将领羊皮纸画像牌、金色军衔徽记生效，射程 scope 圆徽消失，接敌区域信息密度明显下降。

遗留事项：

- 待本轮云端截图确认山脉剪影与道路对比度；雪地针叶树等细节可在后续轮次补充。

### v2.28 / 射程徽记去重与将领画像牌

日期：2026-07-26

核心变更：

- 选中单位后的射程覆盖格不再逐格叠加橙色 scope 圆徽，只保留柔和橙色边框；与 v2.27 的威胁去重同一原则。
- 将领徽章从黑底圆圈改为 GoG3 风格羊皮纸画像牌：暖色底 + 金色描边 + 阵营色角标，尺寸 24 -> 20。
- 地图棋子右下军衔从黑色胶囊改为无底金色徽记 + 深色投影，进一步减少每单位的胶囊数量。

验证结果：

- 人工要求全部云端，本地不运行 build、typecheck、smoke、XCTest、模拟器或截图；提交前只做 Git 状态、diff 与提交范围检查。
- v2.27 云端截图（run 30204811037）已确认：受威胁/控制区红色水洗单独承载信号，`!` 与三角圆徽消失，战场明显整洁。

遗留事项：

- 待本轮云端截图确认将领画像牌与金色军衔在浅色地表的辨识度。

### v2.27 / 威胁标记去重

日期：2026-07-26

核心变更：

- 选中单位后的受威胁格与敌方控制区不再逐格叠加 `!` 胶囊和红色三角圆徽，只保留 v2.25 引入的半透明红色水洗与细边，同一信号不再三重表达。
- `ControlZoneMarker` / `ThreatenedMoveMarker` 视图保留定义，侧栏 THR 计数与规则语义不变。

验证结果：

- 人工要求全部云端，本地不运行 build、typecheck、smoke、XCTest、模拟器或截图；提交前只做 Git 状态、diff 与提交范围检查。
- v2.26 云端截图（run 30204318355）已确认：单层阵营地环、战备圆点与加宽阵营 HP 条生效，浅色地表下单位清晰；截图为模拟器亮度渐变帧，内容经提亮核对无异常。

遗留事项：

- 待本轮云端截图确认威胁水洗单独承载信号后的可读性。

### v2.26 / 兵棋子底座与状态徽记收敛

日期：2026-07-26

核心变更：

- 地图棋子的阵营底座从"黑影 + 粗描边/虚线椭圆"收敛为单层半透明阵营色地环 + 细实线圈，轴心不再使用红色虚线圈，贴近 GoG3 单位脚下的柔和光环。
- 移动/攻击双状态圈徽（箭头圈 + 准星圈）合并为单个战备圆点：绿=全可动、黄=剩一动、灰=完成；HP 条加宽至 40pt 保持阵营着色。
- 单位下方信息带从 64x13 收窄到 56x11，全图每单位减少两枚圆形徽章的噪音。

验证结果：

- 人工要求全部云端，本地不运行 build、typecheck、smoke、XCTest、模拟器或截图；提交前只做 Git 状态、diff 与提交范围检查。
- 待本轮 `origin/main` GitHub Actions run 与 artifact 截图验收。

遗留事项：

- 需要云端截图确认战备圆点在浅色地表的辨识度以及底座收敛后的选中反馈。

### v2.25 / 河道化水系与覆盖降噪

日期：2026-07-26

核心变更：

- 河流格底色改为原野同族浅色，水由中央水塘 + 加深的蜿蜒连接带表达，河流呈连续河道而非整格蓝色六角，站在河格上的单位不再浮在蓝块上。
- 河流连接带宽度 15 -> 11，颜色加深提亮，保持上下游连续。
- 受威胁 (THR) 与敌方控制区格从红色描边改为半透明红色水洗填充，MOVE 可达格叠加淡青水洗；边框降为细线，接近 GoG3 的范围着色语言。
- 射程覆盖边框同步减淡，选中/攻击/路线等高优先级反馈保持原强度。

验证结果：

- 人工要求全部云端，本地不运行 build、typecheck、smoke、XCTest、模拟器或截图；提交前只做 Git 状态、diff 与提交范围检查。
- 待本轮 `origin/main` GitHub Actions run 与 artifact 截图验收。

遗留事项：

- 需要云端截图确认河道连续性与范围水洗在选中态下的可读性。

### v2.24 / 白昼战场基调与轴心野战灰蓝

日期：2026-07-26

核心变更：

- 参照 EasyTech《将军的荣耀3》商店截图，将七类地貌与地图底板从暗夜色调整为白昼原野基调：邻接地貌共享相近浅色，地形识别主要交给纹理层。
- 六角格改为通体浅色蚀刻描边，贴近 GoG3 的整片手绘大地上叠浅色网格的观感。
- 城市纹理升级为浅墙 + 暖色瓦顶的建筑簇，山地亮暗面对比增强，森林树冠改用双层实色绿，农田用暖黄/深绿地块表达。
- 轴心军械色板从灰褐改为德军野战灰蓝，与盟军橄榄绿在浅色地表上直接可分；地图 HP 条按阵营着色（盟军蓝/轴心红，残血红）。
- 移除地图棋子上的 AL/AX 文字角标（阵营环 + 阵营 HP 条已承载语义），非焦点敌军的 `7>1` 射程说明胶囊只在聚焦时显示，全图噪音下降。

验证结果：

- 人工要求全部云端，本地不运行 build、typecheck、smoke、XCTest、模拟器或截图；提交前只做 Git 状态、diff 与提交范围检查。
- 待本轮 `origin/main` GitHub Actions run 与 artifact 截图验收。

遗留事项：

- 需要云端截图确认浅色地表上 marker、路线与文字的对比度未退化。

### v2.0 / 六角格战场视觉基座

日期：2026-07-13

核心变更：

- 将主题、chrome/HUD、地图/input 和单位视觉从 `ContentView.swift` 抽离为四个独立 Swift 文件。
- 七类地形使用确定性纹理与同类邻接连接，取消默认六角格厚阴影卡片感，保留所有 marker 与命中语义。
- 坦克、步兵、火炮和侦察车改用独立军械剪影，并加入盟军圆角/轴心切角虚线底座、稳定 HP 条、状态角标和通用将领徽章。
- 收薄顶栏/地图工具条，主要快捷操作保持 44pt 点击区，地图焦点滚动支持 Reduce Motion。
- 同轮云端失败修复将 `FireRiskLevel` 纯视觉扩展迁入共享主题文件，恢复拆分后地图模块对风险颜色和图标的访问，不改变规则或地图行为。
- 后续同轮修复将 `MissionObjectiveState` 图标与颜色扩展迁入共享主题文件，恢复 chrome/HUD 对任务状态视觉的访问。

关键文件：

- `WW2Tactics/WW2Tactics/BattlefieldTheme.swift`
- `WW2Tactics/WW2Tactics/BattlefieldChrome.swift`
- `WW2Tactics/WW2Tactics/BattlefieldMap.swift`
- `WW2Tactics/WW2Tactics/BattlefieldUnitViews.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`

验证结果：

- 人工明确禁止本地 build、typecheck、smoke、XCTest、模拟器和视觉测试；Agent B 仅执行静态 diff 范围检查。
- GitHub Actions 最终成功 run 为 `29220790248`，attempt `1`，commit `277e6e0ab33fa88bce123240594285fa7974ce43`，artifact 为 `ww2tactics-ci-v2.0-main-277e6e0-run29220790248-attempt1`；static、rules smoke 和 build-for-testing 均成功，Agent C 已下载核对。

遗留事项：

- v2.0 artifact 没有运行截图，尚不能证明像素级视觉质量；v2.1 补齐云端截图证据后，再选择地貌细化或战斗动效之一。

### v2.1 / 云端战场截图验收链

日期：2026-07-15

核心变更：

- GitHub Actions 在 build-for-testing 成功后动态选择可用 iOS Simulator，安装并启动 app，生成首屏战场 PNG 与启动日志。
- screenshot outcome 进入 manifest、failure summary、JUnit 和最终失败门禁；artifact 同时保存构建、规则与视觉证据。
- 本轮只改云端验证与文档，不改变 SwiftUI 画面或规则。

验证结果：

- 本地未运行 build、typecheck、smoke、XCTest、模拟器或截图，只做 Git diff 范围检查和 YAML 静态解析。
- GitHub Actions run `29426676489`、attempt `1`、commit `b2d97b685448a2aec8d8d0296feb041d8839d61c` 成功；artifact `ww2tactics-ci-v2.1-main-b2d97b6-run29426676489-attempt1` 的 static、rules smoke、build 和 screenshot 均成功，JUnit 4 项 0 failures。
- 云端 iPad Pro 13-inch (M5) / iOS 26.5 截图为 2064x2752，确认 app 正常启动并显示战场，而非黑屏或 SpringBoard。

遗留事项：

- 首张截图显示顶栏过高、地图内战役信息重复、支援区常驻、地形代码和默认边线噪音偏大、单位偏小；v2.2 按这些证据修正。

### v2.2 / 战场占比与信息降噪

日期：2026-07-17

核心变更：

- 顶栏固定为单行，战役切换改为图标菜单，状态条横向滚动；地图内移除重复战役 HUD。
- 编队、战术、增援和图例进入默认收起的支援甲板，地图获得更多首屏高度。
- 普通格地形代码仅在焦点空地显示，默认六角边线和地貌色阶降噪；交互与风险 marker 保持原优先级。
- 地图单位与 HP 条放大、传入真实补给状态，删除重复 READY/DONE/HP 条。

验证结果：

- 人工要求全部云端，本地未运行 build、typecheck、smoke、XCTest、模拟器或视觉测试。
- GitHub Actions run `29589038142`、attempt `1`、commit `b1184544b2ef4f3f9c6ab1f3464f847b537957c2` 成功；artifact `ww2tactics-ci-v2.2-main-b118454-run29589038142-attempt1` 的 static、rules smoke、build 和 screenshot 均成功，JUnit 4 项 0 failures，`.xcresult` 存在。
- Agent C 已下载到 `/private/tmp/ww2tactics-c-review-29589038142/` 并核对 manifest、failure summary、JUnit、日志、`.xcresult` 和 2064x2752 iPad 战场截图。

遗留事项：

- v2.2 截图确认单行顶栏、默认收起支援甲板、地形代码降噪和单位放大均生效；但常驻 Inspector 仍占据约三分之一首屏宽度，v2.3 改为地图优先情报抽屉。

### v2.3 / 地图优先情报抽屉

日期：2026-07-17

核心变更：

- 地图默认占满顶栏以下工作区，不再为 Inspector 预留固定宽度或高度。
- Inspector 改为 44pt 边缘按钮按需展开；regular 宽度从右缘覆盖，compact 宽度从底部覆盖，全部详情和命令入口保留。
- 抽屉展开尊重 Reduce Motion，提供 VoiceOver 标签、状态值和 hover help；覆盖背景提高不透明度。

验证结果：

- 人工要求全部云端，本地未运行 build、typecheck、smoke、XCTest、模拟器或视觉测试。
- GitHub Actions run `29596560289`、attempt `1`、commit `cb01d29f8e2c4df9943ea8cd8208c4fbe1f3688c` 成功；artifact `ww2tactics-ci-v2.3-main-cb01d29-run29596560289-attempt1` 的 static、rules smoke、build 和 screenshot 均成功，JUnit 4 项 0 failures，`.xcresult` 存在。
- Agent C 已下载到 `/private/tmp/ww2tactics-c-review-29596560289/`，核对 manifest、failure summary、JUnit、日志、`.xcresult` 与 2064x2752 iPad 截图；地图全宽和右缘抽屉按钮均符合 v2.3 验收标准。

遗留事项：

- 地图占比问题已解决；截图显示普通地貌仍重复同一中心辐射线和纹理位置，v2.4 优先自然化连续地貌。

### v2.4 / 连续地貌自然化

日期：2026-07-18

核心变更：

- 普通平原、城市、山地和雪地不再绘制同类邻接中心辐射，河流/道路保留并收细连接，森林使用更弱连接带。
- 由 q/r 坐标计算确定性 seed，改变田垄坡度、树簇位置与尺寸、城市块、山脊峰位和雪纹曲线，重绘稳定且不写回模型。
- 降低普通地貌纹理密度与对比，保留单位、据点和战术 marker 的视觉优先级。

验证结果：

- 人工要求全部云端，本地未运行 build、typecheck、smoke、XCTest、模拟器或视觉测试。
- 首次 run `29600905223` / commit `79cef65d48673a5fc1efc49bc3a6beef6ed1c01d` 因三个带局部参数的 `some View` 函数缺少显式返回而 build 失败，截图按门禁跳过；随后追加修复 commit。
- 最终 GitHub Actions run `29604249640`、attempt `1`、commit `e884fd417331808d5eb48e922fbf103aa4127659` 成功；artifact `ww2tactics-ci-v2.4-main-e884fd4-run29604249640-attempt1` 的 static、rules smoke、build 和 screenshot 均成功，JUnit 4 项 0 failures，`.xcresult` 存在。
- Agent C 已下载到 `/private/tmp/ww2tactics-c-review-29604249640/` 并核对 manifest、failure summary、JUnit、日志、`.xcresult` 与 2064x2752 iPad 截图；普通地貌拼花减少，河流/道路连续，单位与 marker 层级未受影响。

遗留事项：

- 地貌自然化已通过；截图中单位仍以单色合并剪影为主，v2.5 优先强化军械模型层次。

### v2.5 / 单位模型层次

日期：2026-07-18

核心变更：

- 盟军使用橄榄军械色板、轴心使用灰褐色板，并保留蓝色圆角/红色切角阵营底座。
- `UnitModelView` 为四类单位增加落地阴影、边缘高光和内部结构线：步兵队形/枪线、坦克履带/负重轮/炮塔、火炮轮组/炮架、侦察车轮毂/车窗/天线。
- `MiniHealthBar` 统一地图 HP 绘制，保留现有比例与红绿阈值并增加五段刻度。
- UnitShapeBadge 外接尺寸、Commander、rank、CUT、战术状态、spent、地图 marker 和规则状态保持不变。

验证结果：

- 人工要求全部云端，本地未运行 build、typecheck、smoke、XCTest、模拟器或视觉测试。
- GitHub Actions run `29884658051`、attempt `1`、commit `f1fc7fce80654e440a2b2cb95a5fcae172807246` 成功；artifact `ww2tactics-ci-v2.5-main-f1fc7fc-run29884658051-attempt1` 的 static、rules smoke、build 和 screenshot 均成功，JUnit 4 项 0 failures，`.xcresult` 存在。
- Agent C 已下载到 `/private/tmp/ww2tactics-c-review-29884658051/` 并核对 manifest、failure summary、JUnit、日志、`.xcresult` 与 2064x2752 iPad 截图；四类单位、阵营军械色板和内部结构清晰，既有角标与 marker 未被遮挡。

遗留事项：

- 单位模型层次已通过；截图显示固定 0.86 缩放使地图上下保留明显空带，v2.6 优先让战区满幅占据工作区。

### v2.6 / 战区满幅构图

日期：2026-07-22

核心变更：

- 默认战役档从固定绝对缩放改为按当前地图 viewport 高度计算 fill scale，避免地图内容较矮时在上下居中形成大块空带。
- 战术与细节档改为满幅基线上的 1.16 / 1.32 倍放大，保留双轴滚动；切换缩放后重新居中当前焦点。
- tile 尺寸、坐标、地图输入、marker、HUD、规则与 `GameState` 保持不变。

验证结果：

- 人工要求全部云端，本地未运行 build、typecheck、smoke、XCTest、模拟器或视觉测试。
- GitHub Actions run `29885508105`、attempt `1`、commit `bfdaf9780ec0beba8eb8186ecca6e8e906ad253a` 成功；artifact `ww2tactics-ci-v2.6-main-bfdaf97-run29885508105-attempt1` 的 static、rules smoke、build 和 screenshot 均成功，JUnit 4 项 0 failures，`.xcresult` 存在。
- Agent C 已下载到 `/private/tmp/ww2tactics-c-review-29885508105/` 并核对 manifest、failure summary、JUnit、日志、`.xcresult` 与 2064x2752 iPad 截图；地图已覆盖工作区高度，双方单位、据点和既有边缘入口仍可见。

遗留事项：

- 满幅构图已通过；空闲态大型动作卡仍遮挡地图，选中和攻击焦点主要依赖六角边框，v2.7 优先收敛 HUD 并强化战斗焦点。

### v2.7 / 战斗焦点与空闲 HUD 收敛

日期：2026-07-24

核心变更：

- 未选择单位时以小型边缘 `NEXT` 指挥坞替代大型空闲动作卡，选中单位后仍显示完整紧凑动作 HUD。
- 选中单位增加蓝色地面光环与四角框；当前聚焦的 ATK/POS 目标分别增加红色/橙色四角准星。
- 所有反馈只读现有 `selectedUnit`、`focusedCoordinate` 和 `MapActionHint`，不改变规则、tile frame、坐标、命中或 marker 数据。

验证结果：

- 人工要求全部云端，本地未运行 build、typecheck、smoke、XCTest、模拟器或视觉测试。
- GitHub Actions run `30065985230`、attempt `1`、commit `512c819d06da3721c5a3638e7f74010f00f35622` 成功；artifact `ww2tactics-ci-v2.7-main-512c819-run30065985230-attempt1` 的 static、rules smoke、build 和 screenshot 均成功，JUnit 4 项 0 failures，`.xcresult` 存在。
- Agent C 已下载到 `/private/tmp/ww2tactics-c-review-30065985230/` 并核对 manifest、failure summary、JUnit、日志、`.xcresult` 与 2064x2752 iPad 截图；空闲动作卡已收敛为小型 `NEXT` 指挥坞，地图继续满幅，双方单位、Inspector、目标跳转条和支援甲板入口仍可见。

遗留事项：

- 空闲 HUD 收敛已通过；截图中地图单位仍被大面积圆形阵营底板包裹，v2.8 优先让军械模型直接落在地表。

### v2.8 / 地图单位落地模型

日期：2026-07-24

核心变更：

- 地图 `UnitCounter` 改用透明 `MapUnitPiece`，放大既有四类军械模型并移除大面积实心阵营徽章底板。
- 阵营改由蓝/红椭圆地面环、盟军实线/轴心虚线和 AL/AX 短码共同表达。
- Commander、rank、CUT、战术状态、spent 和五段 HP 保持；HUD、侧栏和编队条继续使用原 `UnitShapeBadge`。

验证结果：

- 人工要求全部云端，本地未运行 build、typecheck、smoke、XCTest、模拟器或视觉测试。
- GitHub Actions run `30066551656`、attempt `1`、commit `99de0e88cdda06c6d613542ab11e2171d7240779` 成功；artifact `ww2tactics-ci-v2.8-main-99de0e8-run30066551656-attempt1` 的 static、rules smoke、build 和 screenshot 均成功，JUnit 4 项 0 failures，`.xcresult` 存在。
- Agent C 已下载到 `/private/tmp/ww2tactics-c-review-30066551656/` 并核对 manifest、failure summary、JUnit、日志、`.xcresult` 与 2064x2752 iPad 截图；四类地图军械已直接落在透明阵营地面环上，AL/AX、Commander、HP 与既有 marker 清晰，非地图徽章未受影响。

遗留事项：

- 地图单位落地模型已通过；截图中地貌仍主要是平铺色块和细线符号，v2.9 优先增强田块、树林、城市、山地、雪地与河路纵深。

### v2.9 / 地貌纵深与战区质感

日期：2026-07-24

核心变更：

- 平原增加稳定田块深浅与田垄，森林增加树冠前后层和落地影，城市增加道路底槽、建筑投影与屋顶高光。
- 山地增加闭合亮面/暗面与脊线，雪地增加冷色凹陷与双层雪脊。
- 河流和道路的暗边、主体与高光复用同一邻接 Path，保持连续；全部变体只由 q/r seed 派生。
- 不改变 tile frame、坐标、命中、marker、单位、规则或 `GameState`。

验证结果：

- 人工要求全部云端，本地未运行 build、typecheck、smoke、XCTest、模拟器或视觉测试。
- 首次 run `30067386520` 虽通过技术门禁，但 Agent C 从截图发现道路黑色三角、河流黑线和田块过重，退回 Agent B 收敛连接层。
- 修复 commit `1911ae4104f61433b909804f89c2ade1e2d347b7` 对应 GitHub Actions run `30067975922`、attempt `1` 成功；artifact `ww2tactics-ci-v2.9-main-1911ae4-run30067975922-attempt1` 的 static、rules smoke、build 和 screenshot 均成功，JUnit 4 项 0 failures，`.xcresult` 存在。
- Agent C 已下载到 `/private/tmp/ww2tactics-c-review-30067975922/` 并核对 manifest、failure summary、JUnit、日志、`.xcresult` 与 2064x2752 iPad 截图；异常黑色连接层已消失，七类地貌层次与单位、HP、marker、NEXT 坞和 Inspector 入口清晰。

遗留事项：

- v2.9 已通过；既有 CI 截图仍是空闲态，v2.10 优先补齐选中单位和 POS 目标的云端视觉证据。

### v2.10 / 选中与接敌态云端证据

日期：2026-07-24

核心变更：

- CI 截图启动使用 `--ci-selected-approach-preview`，稳定选择阿登 M10 并聚焦敌方装甲侦察营，形成不执行命令的 POS 接敌预览。
- 启动场景复用现有 `GameState.handleTap` 与 `focus`，不直接写规则字段；普通启动不带参数时保持默认状态。
- 截图场景名写入截图日志、failure summary、manifest 和 JUnit 描述，便于 Agent C 区分选中态证据与旧空闲截图。

验证结果：

- 人工要求全部云端，本地未运行 build、typecheck、smoke、XCTest、模拟器、YAML 解析或视觉测试。
- GitHub Actions run `30068638485`、attempt `1`、commit `e01348e1b227dad26593526c49502e00f0686151` 成功；artifact `ww2tactics-ci-v2.10-main-e01348e-run30068638485-attempt1` 的 static、rules smoke、build 和 selected-approach screenshot 均成功，JUnit 4 项 0 failures，`.xcresult` 存在。
- Agent C 已下载到 `/private/tmp/ww2tactics-c-review-30068638485/` 并核对 manifest、failure summary、JUnit、日志、`.xcresult` 与 2064x2752 iPad 截图；M10 蓝色选中反馈、敌方侦察单位橙色 POS 准星、动作 HUD 和接敌预览同屏成立。

遗留事项：

- v2.10 已通过；截图同时暴露 29 个 MOVE、9 个 THR 和多枚 POS 文字胶囊过密，v2.11 优先收敛非焦点战术标记。

### v2.11 / 战术覆盖层降噪

日期：2026-07-24

核心变更：

- 最终修复保持 v2.10 已验证的 `ActionMarker` 与 `ThreatenedMoveMarker` 单一 HStack 结构，不再传入 `isFocused` 或创建条件视图。
- MOVE、ATK、POS、THR 的重复前缀分别缩为成本数字、伤害数字、`P` 和 `!`，同时减小字号、padding 和描边。
- 不修改 `GameState`、可达/攻击/接敌/风险集合、tile 命中或 VoiceOver 主摘要；当前目标继续由准星和完整动作 HUD 表达。

验证结果：

- 人工要求全部云端，本地未运行 build、typecheck、smoke、XCTest、模拟器、YAML 解析或视觉测试。
- 初始 commit `32a4bfc553d892739d006cdafa011b30511d7982` 对应 run `30069332880` attempt 1/2 的 static、smoke、build 和脚本截图状态均成功，但两份 PNG SHA-256 完全相同且仅 117,630 bytes，实际画面除状态栏与 home indicator 外全黑；Agent C 两次均不通过。
- 第一份修复 commit `9f5732999b3bca572cb4b0d11c9ad6f02e869767` 对应 run `30070660664` 的 static/smoke/build 成功，但 PNG 仍仅 155,086 bytes；新门禁正确输出 `screenshotOutcome=failure`、JUnit 1 failure，Agent C 不通过。
- 第二份同轮修复完全恢复 v2.10 marker 结构，只使用固定短标签和紧凑样式；commit `0c3d1f8e9cf96de5b3dc0af0b3c33414888c17ae` 对应 GitHub Actions run `30071383570`、attempt `1` 成功，artifact `ww2tactics-ci-v2.11-main-0c3d1f8-run30071383570-attempt1` 的 static、rules smoke、build 和 screenshot 均成功，JUnit 4 项 0 failures，`.xcresult` 存在。
- Agent C 已下载到 `/private/tmp/ww2tactics-c-review-30071383570/`，核对 manifest SHA/run/attempt、failure summary、JUnit、日志、`.xcresult` 与 2064x2752、5,982,330-byte iPad 战场截图；短标签、橙色 POS 准星、M10 选中态和完整动作 HUD 均成立。

遗留事项：

- v2.11 已通过；下一轮进入真实 ATK 攻击判定与火力解算界面。

### v2.12 / 攻击判定与火力解算

日期：2026-07-24

核心变更：

- CI 新增 `--ci-selected-attack-preview` 场景，复用 `handleTap` 与 `handleSecondaryAction` 让 M10 真实接敌移动后停在攻击前状态；旧 POS 参数和普通启动保持不变。
- `InlineMapCommandPreview` 的 `.attack` 分支升级为紧凑火力解算带，显示双方当前/预计 HP、HIT 主伤害、RET 反击和 OUT 战果，并提供 44pt 手动“开火”入口。
- 所有预测读取 `.attack` 关联值、选中/聚焦单位和 `combatPreviewAgainstFocusedTarget()`；不修改规则公式或自动执行攻击。
- workflow 截图场景切换为 `selected-attack-preview`，继续保留 500 KB 黑屏门禁和完整 artifact 元数据。

验证结果：

- 人工要求全部云端，本地不运行 build、typecheck、smoke、XCTest、模拟器、截图或 YAML 解析；提交前只做 Git 状态、diff 与提交范围检查。
- GitHub Actions run `30072585832`、attempt `1`、commit `aa394f17fa9b180b939dfd115f5ed72aec9ade51` 成功；artifact `ww2tactics-ci-v2.12-main-aa394f1-run30072585832-attempt1` 的 static、rules smoke、build 和 selected-attack screenshot 均成功，JUnit 4 项 0 failures，`.xcresult` 存在。
- Agent C 已下载到 `/private/tmp/ww2tactics-c-review-30072585832/` 并核对 manifest SHA/run/attempt、failure summary、JUnit、日志、`.xcresult` 和 2064x2752、5,875,823-byte PNG；截图清楚显示 M10 与装甲侦察营双方 HP 预测、HIT -21、RET -11、OUT 存活、红色 ATK 准星和手动开火入口，顶部消息证明仍为攻击前状态。

遗留事项：

- v2.12 已通过；截图显示全图控制区、射程覆盖和次要 marker 仍抢占攻击焦点，v2.13 继续专项降噪。

### v2.13 / 交战轴线与攻击态降噪

日期：2026-07-24

核心变更：

- `HexMapView` 从现有 `.attack` 预览只读派生攻击聚焦模式，不新增规则状态。
- 攻击态下暂时隐藏非焦点控制区、射程覆盖、命令 marker 与次要态势 chips；当前焦点 ATK 标记、红色准星、双方单位/HP、地形和据点保持。
- `EngagementAxisOverlay` 使用 selected/focused 地图点位连接攻击方与目标，缩短端点以避开单位模型，并关闭 hit testing 与无障碍读取。
- 底层规则集合、tile accessibility、frame、坐标、滚动、缩放和输入链不变；离开 `.attack` 后覆盖层恢复。

验证结果：

- 人工要求全部云端，本地不运行 build、typecheck、smoke、XCTest、模拟器、截图或 YAML 解析；提交前只做 Git 状态、diff 与提交范围检查。
- 初始 commit `87a01ca4df62dea028988643ed5d5499183cb32f` 对应 run `30073533656`、attempt `1` 的 static 与 rules smoke 成功，但 Xcode build-for-testing 因在 `ViewBuilder` body 内分支赋值触发 `type '()' cannot conform to 'View'` 而失败，截图按门禁跳过；Agent C 已下载失败 artifact 并退回同版本修复。
- 修复 commit `3bb90532e075e559b3254671d13f86d7a7714d50` 对应 run `30073890297`、attempt `1` 成功；artifact `ww2tactics-ci-v2.13-main-3bb9053-run30073890297-attempt1` 的 static、rules smoke、build 和 selected-attack screenshot 均成功，JUnit 4 项 0 failures，`.xcresult` 存在。
- Agent C 已下载到 `/private/tmp/ww2tactics-c-review-30073890297/` 并核对 manifest SHA/run/attempt、failure summary、JUnit、日志、`.xcresult` 和 2064x2752、5,769,576-byte PNG；截图保留 v2.12 火力解算与焦点 ATK，同时隐藏全图控制区/覆盖/次要 chips，并显示 M10 到目标的短橙色交战轴线。

遗留事项：

- v2.13 已通过；下一轮补齐真实开火后的地图级战损与结果反馈。

### v2.14 / 短促战斗结果反馈

日期：2026-07-24

核心变更：

- `CombatResultSummary` 增加攻击方与防守方执行时坐标，`GameState.attack` 与真实伤害、反击、HP 快照一起写入，避免攻击后选择轮转或击毁目标导致地图定位丢失。
- `CombatResolutionOverlay` 从 `latestCombatResult` 只读显示防守端 HIT/HP、实际反击时的 RET/攻击方 HP，以及交火、压制或击毁结论；叠层不拦截输入并提供组合 VoiceOver 摘要。
- XCTest 与 RulesSmokeTest 增加双方结果坐标断言。
- CI 新增 `--ci-selected-combat-result` 场景，复用公开地图动作链完成接敌移动和真实攻击；workflow 元数据切换为 `selected-combat-result`，旧预览参数继续保留。
- README、flow、flowchart、test 和 prompt 索引同步当前实现与云端验收要求。

验证结果：

- 人工要求全部云端，本地不运行 build、typecheck、smoke、XCTest、模拟器、截图或 YAML 解析；提交前只做 Git 状态、diff 与提交范围检查。
- 初始 commit `812512b11a9cab273fa7398fa237a0d05e066502` 对应 run `30075113736`、attempt `1` 的 static、rules smoke 与 Xcode build-for-testing 成功，但模拟器 launch 后首次截图只有 117,630 bytes；Agent C 下载 artifact 到 `/private/tmp/ww2tactics-c-review-30075113736/`，核对 manifest 和日志并实际确认 PNG 为黑屏，因此验收不通过。
- workflow 保持 500 KB 门禁，改为 launch 后最多 4 次、每次间隔 6 秒的有界截图重试，并把每次状态与大小写入日志；不修改游戏实现或放宽黑屏判定。
- 修复 commit `a28e82586cfd65e9716ac09e10bc47fdb8df13ac` 对应 run `30075856174`、attempt `1` 成功；artifact `ww2tactics-ci-v2.14-main-a28e825-run30075856174-attempt1` 的 static、rules smoke、build 和 selected-combat-result screenshot 均成功，JUnit 4 项 0 failures，`.xcresult` 存在。
- Agent C 已下载到 `/private/tmp/ww2tactics-c-review-30075856174/` 并核对 manifest SHA/run/attempt、failure summary、JUnit、日志、`.xcresult` 和 2064x2752、5,930,084-byte PNG；首次截图即通过 500 KB 门禁。
- Agent C 实际查看 PNG：画面为真实攻击后状态，攻击方显示 `RET -7 / 64 -> 57`，防守方显示 `HIT -21 / 64 -> 43`，中央“交火”明确；三块地图反馈贴近原交战位置且没有遮挡双方单位主体。
- Agent C 验收记录 commit `51dad562c78dcffa26f9246fd721b7ec38acf71e` 对应最新 run `30076575519`、attempt `1` 再次成功；artifact `ww2tactics-ci-v2.14-main-51dad56-run30076575519-attempt1` 已下载到 `/private/tmp/ww2tactics-c-review-30076575519/`，manifest 与 `origin/main` 完全一致，四项 JUnit 0 failures，截图仍为 5,930,084 bytes 且目视内容一致。

遗留事项：

- v2.14 已通过。攻击前预判为 RET -11、真实结算为 RET -7，后续轮次应单独核对经验/晋升或状态变化导致的预判与实战差异；不得在 View 修正或伪造数值。

### v2.15 / 攻击预判与结算一致性

日期：2026-07-24

核心变更：

- 定位预判差异根因：`combatPreview` 原先用受击前防守方计算反击，真实攻击则在防守方扣血、士气下降和双方姿态清除之后计算。
- `previewCombatantsAfterPrimaryAttack` 使用 `BattleUnit` 值副本模拟主伤害后的必要状态：防守方 HP/士气/姿态，攻击方经验、晋升 HP、士气与姿态；不写入 scenario、日志或 latest result。
- `combatPreview` 继续复用既有 `counterDamageValue`，不复制伤害公式；击毁或超出反击射程时仍返回 0。
- XCTest 和 RulesSmokeTest 直接断言 preview/result 的主伤害、反击伤害和双方最终 HP 一致，并覆盖士气跨阈值、攻击方防御姿态清除和晋升 HP 增益。
- README、flow、flowchart、test 与 prompt 索引同步当前规则链。

验证结果：

- 人工要求全部云端，本地不运行 build、typecheck、smoke、XCTest、模拟器、截图或 YAML 解析；提交前只做 Git 状态、diff 与提交范围检查。
- 等待本轮 `origin/main` GitHub Actions run 与 Agent C artifact 验收。

遗留事项：

- 云端必须证明规则 smoke 与 build-for-testing 通过，并确认 selected-combat-result 截图仍显示真实 `RET -7` 与 `HIT -21`。

### 维护 / Unity 迁移可行性分析

日期：2026-07-26

核心结论：

- 基于当前 SwiftUI 状态机、22x14 六角地图、115 个 XCTest 方法、RulesSmokeTest 的 1,333 个断言调用和现有 Xcode CI 证据，暂不建议全量重写为 Unity。
- Unity 的合理触发条件是明确的 Android/PC 发布、多战役内容生产/编辑器，或对实时战斗演出与地图表现提出已确认的需求；当前地图规模不是迁移理由。
- 若立项，先在 Swift 主线完成稳定单位 ID、版本化战役 JSON、结构化命令/事件和跨引擎 golden fixtures，再以诺曼底基本回合链做独立 Unity 2D 纵切；不得直接翻译 UI 或在 Unity 中重算 View 反馈。

关键文件：

- `md/unity分析/Unity迁移可行性分析报告.md`

验证结果：

- 本轮为文档分析，不运行 Swift、Xcode、Unity 或 GitHub Actions 验证；文档完成后执行 `git diff --check`。

遗留事项：

- 是否启动 Unity 取决于人工确认的发布平台、内容生产、演出目标，以及 Unity 许可和 CI 凭据可用性。

### v0.1 / 初始 SwiftUI 战棋原型

日期：2026-06-27 前后

核心变更：

- 建立 `WW2Tactics` SwiftUI iOS 工程。
- 实现二战战役、六边形大地图、单位、地形、移动、攻击、AI、补给、士气、指令点、增援、战术命令、地图交互和侧栏。
- 建立 `WW2TacticsTests` 和 `Tools/RulesSmokeTest.swift`。

关键文件：

- `WW2Tactics/WW2Tactics/GameModels.swift`
- `WW2Tactics/WW2Tactics/GameState.swift`
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
- GitHub Actions `WW2Tactics CI Results` run `28734740377` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.18-main-e224775-run28734740377-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28734740377/`，目录大小 `2.4M`。
- Manifest `commitSha=e2247750110970afcc102ba8f40bd4fc076d3c72`、`branch=main`、`runId=28734740377`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 执行回放只记录玩家采纳建议后走既有入口产生的最近一次结果，不新增一键执行、动画、音效或自动战术代理。
- 本轮不改变 AI、战斗数值、移动规则、敌方意图/反制建议生成算法、整补成本、胜负条件、排序或执行桥接语义。

### v1.19 / 反制建议敌方回合复核

日期：2026-07-05

核心变更：

- 新增 `EnemyThreatCountermeasureFollowUpResultKind`、`EnemyThreatCountermeasureFollowUpComparison` 和 `EnemyThreatCountermeasureFollowUpSummary`，记录反制建议执行后经敌方 AI 回合验证的 HP、位置、据点归属、威胁来源和 AI 总览对照。
- `EnemyThreatCountermeasureExecutionResultSummary` 补充受威胁单位 ID、威胁来源 ID 和威胁目标坐标，让敌方回合复核能稳定绑定 v1.18 即时回放对应的单位和据点。
- `GameState` 新增 `latestEnemyThreatCountermeasureFollowUpResult` 和私有 pending baseline；`endTurn()` 在清理即时回放前保存执行后基线，在 `finishAIPhaseRecording()` 后、盟军新回合休整前发布复核，保留即时回放跨回合清理语义。
- 普通无基线回合切换不会生成虚假复核；新的反制执行、普通移动/攻击/整补/部署/战术命令/占点、重开和切战役会清理旧复核。
- `ContentView` 在反制回放和 AI 回合摘要之间展示“敌方回合复核”卡，显示反制类型、执行单位、目标、威胁来源、结论和前三项对照；UI 只展示 `GameState`/`GameModels` 字段。
- 补充 XCTest 和规则 smoke test，覆盖无基线不生成、抢先打击、撤退、据点防守、整补四类复核、即时回放清理、AI summary 绑定和重开清理。

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
- `md/prompt/v1（地图操作体验）/v1.19（反制建议敌方回合复核）.md`

验证结果：

- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- `git diff --check`：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28736246624` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.19-main-3945f81-run28736246624-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28736246624/`，目录大小 `2.5M`。
- Manifest `commitSha=3945f81b4397c249252fb27c1f099e56476bf118`、`branch=main`、`runId=28736246624`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 敌方回合复核是基于 HP、位置、据点归属、威胁源存活和 AI 总览的保守验证，不包含逐行动 attacker/target 事件归因。
- 本轮不改变 AI、战斗数值、移动规则、敌方意图/反制建议生成算法、整补成本、胜负条件、排序或执行桥接语义。

### v1.20 / AI 回合行动时间线

日期：2026-07-05

核心变更：

- 新增 `AIPhaseTimelineEventKind` 和 `AIPhaseTimelineEvent`，把敌方 AI 回合的整补、部署、战术命令、攻击、移动和占点记录成结构化时间线。
- `AIPhaseSummary` 新增 `timeline`，由 `GameState` 在 AI phase 成功路径内填充；时间线与摘要一起发布，避免独立状态失步。
- `GameState` 在 `reinforce`、`deploy`、`useTacticalCommand`、`attack`、`move` 和 `applyObjectiveCaptureReward` 的真实成功路径记录事件；玩家预览、失败命令和被动据点休整不生成时间线事件。
- 移动事件先于 `updateObjectiveControl()` 写入，因此移动占点会稳定显示为 `move -> objectiveCapture`；机动追击场景会显示 `attack -> move -> objectiveCapture`，占点作为结果事件不增加 `AIPhaseSummary.totalActions`。
- `ContentView` 在 AI 回合摘要卡内展示最多 5 条行动时间线，包含顺序、短码、摘要和 VoiceOver 可读标签。
- 补充 XCTest 和规则 smoke test，覆盖战术命令、移动+攻击、部署、整补、机动追击占点、重开/切战役清理和时间线顺序号。

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
- `md/prompt/v1（地图操作体验）/v1.20（AI回合行动时间线）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28737859604` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.20-main-5463496-run28737859604-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28737859604/`，目录大小 `2.6M`。
- Manifest `commitSha=5463496adc17ebd94f861dfcc81caee2069c3574`、`branch=main`、`runId=28737859604`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮只展示侧栏时间线，不新增地图 AI 动作标记、动画、音效、镜头播放、暂停/回放控制或真实美术资产。
- 本轮不改变 AI 决策、战斗数值、移动规则、整补成本、部署逻辑、战术命令、胜负条件或反制建议语义。

### v1.21 / AI 行动地图复盘标记

日期：2026-07-05

核心变更：

- 新增 `AIPhaseMapMarkerRole` 和 `AIPhaseMapMarker`，为最近一次敌方 AI 回合的时间线事件提供地图只读复盘标记。
- `GameState.latestAIPhaseMapMarkers` 从 `latestAIPhaseSummary.timeline` 纯派生，不新增独立持久状态；移动输出起点/终点，攻击和战术命令输出行动单位/目标，部署和整补输出目的坐标，占点输出据点坐标。
- `useTacticalCommand` 记录 AI 战术命令事件的施放者坐标，让火炮弹幕等命令能同时在地图上标记行动单位和目标。
- `ContentView` 将 AI 复盘标记按坐标聚合到地图格，新增独立 `AI` 徽标、低优先级边框、图例和 VoiceOver 文案；UI 只展示 `GameState` 派生字段，不从当前单位或战报反推行动。
- 补充 XCTest 和规则 smoke test，覆盖战术命令、移动+攻击、部署、整补、机动追击占点、被击毁目标坐标保留、事件顺序回连、重开/切战役清理和玩家预览/失败命令不生成复盘标记。

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
- `md/prompt/v1（地图操作体验）/v1.21（AI行动地图复盘标记）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28738927530` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.21-main-e9131e6-run28738927530-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28738927530/`，目录大小 `2.7M`。
- Manifest `commitSha=e9131e650a1fb441c95f992ee770f37fcb20cf9b`、`branch=main`、`runId=28738927530`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮只显示最近一次 AI 回合的紧凑地图复盘标记，不新增逐帧播放、动画、镜头移动、音效或真实美术资产。
- 本轮不改变 AI 决策、战斗数值、移动规则、整补成本、部署逻辑、战术命令、胜负条件或反制建议语义。

### v1.22 / AI 直取据点优先

日期：2026-07-05

核心变更：

- `runAxisAI()` 在后勤、可击毁攻击和战术命令之后、普通非击杀攻击之前，新增直取可达非己方据点的决策分支。
- 新增 `bestImmediateObjectiveCaptureDestination(for:)`，只从本回合可达、未被占据、非己方的据点中选择目的地，敌方据点优先于中立据点，并保持坐标稳定排序。
- 新增 `resolveAxisPostMoveAction(unitID:)` 复用移动后攻击或待命收尾，避免直取据点引入第二套行动完成语义。
- 直取据点仍走现有 `move`、`updateObjectiveControl()` 和 `applyObjectiveCaptureReward()` 路径，因此会产生占点奖励、AI summary、`move -> objectiveCapture` timeline 和 v1.21 地图复盘标记。
- 补充 XCTest 和规则 smoke test，覆盖“无击杀机会时先占点而非普通攻击”、目标 HP 不变、据点归属变化、timeline 顺序和地图复盘标记；既有机动追击测试继续覆盖可击毁目标优先。

关键文件：

- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1（地图操作体验）/v1.22（AI直取据点优先）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28740721340` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.22-main-ebfc7b2-run28740721340-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28740721340/`。
- Manifest `commitSha=ebfc7b2c89b8ae8bb40e48e388952bd22ec3ef81`、`branch=main`、`runId=28740721340`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮只增加本回合可达据点的直接优先级，不新增全局目标分配、概率 AI、撤退 AI、生产队列或复杂战略规划。
- 本轮不改变伤害、移动、补给、士气、战术命令、部署、整补、胜负和反制建议语义。

### v1.23 / AI 移动后火炮弹幕

日期：2026-07-05

核心变更：

- `resolveAxisPostMoveAction(unitID:)` 在移动后普通攻击不可用时，会继续检查 `bestTacticalCommandPlan(for:)`；若战术命令可用，则复用 `useTacticalCommand` 执行命令。
- 移动后普通攻击仍优先于移动后战术命令，既有移动后攻击和直取据点规则不改变。
- 新增轴心火炮移动后弹幕测试场景：火炮初始不在普通射程或弹幕射程内，移动后进入 `artilleryBarrage` 射程但仍不在普通射程内，AI 会形成 `move -> tacticalCommand`。
- 补充 XCTest 和规则 smoke test，覆盖移动后弹幕的战术命令结果、AI summary、timeline、地图复盘标记，以及普通移动后攻击优先级不退化。

关键文件：

- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1（地图操作体验）/v1.23（AI移动后火炮弹幕）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28742152086` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.23-main-d05916e-run28742152086-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28742152086/`。
- Manifest `commitSha=d05916e821f19abe4369000864aab0f964ecb7db`、`branch=main`、`runId=28742152086`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮只增加移动后普通攻击不可用时的战术命令收尾，不新增概率 AI、全局炮兵站位规划、撤退 AI、生产队列或复杂战略搜索。
- 本轮不改变战术命令数值、普通攻击、反击、移动、补给、士气、部署、整补、胜负和反制建议语义。

### v1.24 / AI 时间线点选定位复盘

日期：2026-07-05

核心变更：

- `GameState` 新增 `focusAIPhaseTimelineEvent(order:)`，从最新 `AIPhaseSummary.timeline` 查找事件，按 `event.to ?? event.from` 定位地图焦点并发布 `AI复盘 #<order>` 消息。
- 侧栏 AI 行动时间线行改为 `Button`，点选后复用 `focusedCoordinate` 的地图自动滚动链路；行内增加无障碍 hint，明确只定位地图复盘、不执行命令。
- 无 summary、无事件、无坐标或坐标不在当前地图时，点选入口只更新提示并保留旧焦点。
- 补充 XCTest 和规则 smoke test，覆盖 AI 时间线点选定位、消息、无效顺序号、无 summary，以及点选不改变单位、指令点、AI summary 或地图复盘标记。

关键文件：

- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1（地图操作体验）/v1.24（AI时间线点选定位复盘）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28744631070` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.24-main-39079a6-run28744631070-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28744631070/`，目录大小 `2.7M`。
- Manifest `commitSha=39079a66204581ea3ac20ec9ce4eeb17edacd2f9`、`branch=main`、`runId=28744631070`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮只让可见 AI 时间线条目定位地图复盘坐标，不新增逐帧播放、自动镜头动画、历史 AI 回合列表、音效或真实美术资产。
- 本轮不改变 AI 决策、战斗数值、移动、补给、士气、部署、整补、据点、胜负和反制建议语义。

### v1.25 / AI 复盘事件选中态和地图标记强调

日期：2026-07-05

核心变更：

- `GameState` 新增当前 AI 复盘事件顺序号 `focusedAIPhaseTimelineEventOrder`，成功点选时间线时记录 order；无 summary、无事件或无有效坐标时保留旧复盘选中态。
- 新增 `focusedAIPhaseMapMarkers` 只读派生属性，从 `latestAIPhaseMapMarkers` 过滤当前 order，不保存第二份地图复盘 marker。
- `ContentView` 在侧栏 AI 时间线行显示当前复盘事件选中态，并在地图 AI 复盘徽标、tile 边框和无障碍文案中强调当前事件对应标记。
- 重开、切战役、重新加载场景和下一次 AI 回合开始记录时清理旧复盘选中 order，避免跨战役或跨回合残留。
- 扩展 XCTest 和规则 smoke test，覆盖成功点选、无效 order 保留、派生 marker 一致性、重开/切战役/下一次 AI 回合清理，以及点选不改变单位、指令点、AI summary、timeline 或 `latestAIPhaseMapMarkers`。

关键文件：

- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1（地图操作体验）/v1.25（AI复盘事件选中态和地图标记强调）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28746017540` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.25-main-d3e84b9-run28746017540-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28746017540/`，目录大小 `2.8M`。
- Manifest `commitSha=d3e84b9cdbac53b4f015655848f618161fd956bf`、`branch=main`、`runId=28746017540`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮只增强最近一次 AI 时间线的当前事件反馈，不新增逐帧播放、自动镜头动画、历史 AI 回合列表、音效或真实美术资产。
- 本轮不改变 AI 决策、战斗数值、移动、补给、士气、部署、整补、据点、胜负和反制建议语义。

### v1.26 / AI 复盘连续查看控制

日期：2026-07-06

核心变更：

- `GameState` 新增 AI 时间线上一条/下一条复盘导航入口和边界 can 状态；无当前 order 时下一条从第一条开始、上一条从最后一条开始。
- 相邻导航复用 `focusAIPhaseTimelineEvent(order:)` 成功路径，只改变复盘焦点、当前 order、消息和派生 marker 强调；首尾边界只写提示并保留旧焦点和旧 order。
- `ContentView` 在 AI 行动时间线标题行增加上一条/下一条 icon 按钮，按钮禁用状态来自 `GameState`，并提供 VoiceOver label/hint。
- 扩展 XCTest 和规则 smoke test，覆盖连续查看起点、相邻切换、首尾边界、无 summary 提示和只读不变性。

关键文件：

- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1（地图操作体验）/v1.26（AI复盘连续查看控制）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28766614890` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.26-main-5ecea4b-run28766614890-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28766614890/`，目录大小 `2.8M`。
- Manifest `commitSha=5ecea4bdd9d45e19651c490bdcf1deedde248fda`、`branch=main`、`runId=28766614890`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮只增强最近一次 AI 时间线的手动连续查看，不新增自动播放、逐帧动画、时间轴滑块、历史 AI 回合列表、音效或真实美术资产。
- 本轮不改变 AI 决策、战斗数值、移动、补给、士气、部署、整补、据点、胜负和反制建议语义。

### v1.27 / AI 复盘自动播放控制

日期：2026-07-06

核心变更：

- `GameModels` 新增 `AIPhaseTimelinePlaybackPace`，提供慢速、标准、快速三档复盘速度和 tick 间隔。
- `GameState` 新增 AI 复盘播放状态、播放可用性、播放/暂停、速度切换和播放 tick 推进入口；无当前 order 时从第一条开始，有当前 order 时推进到下一条，到最后一条后自动暂停。
- 播放 tick 复用 AI 时间线定位语义，只改变复盘焦点、当前 order、消息和派生 marker 强调；无 summary、无事件、无坐标、坐标不在当前地图或已在最后一条时只写提示并保持只读边界。
- `ContentView` 在 AI 行动时间线标题行增加播放/暂停按钮和速度菜单；SwiftUI timer 只在播放中调用 `GameState.advanceAIPhaseTimelinePlayback()`，不自行计算下一个 order。
- 扩展 XCTest 和规则 smoke test，覆盖播放开始、tick 推进、末尾自动暂停、末尾边界、手动暂停、速度切换、无 summary 和只读不变性。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.27（AI复盘自动播放控制）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28768207176` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.27-main-9b11c5c-run28768394430-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28768394430/`，目录大小 `2.9M`。
- Manifest `commitSha=9b11c5c3c49f84f5a9eaf4fd2159ce7bffef372b`、`branch=main`、`runId=28768394430`、`runAttempt=1` 与 `origin/main` 最新提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮只增强最近一次 AI 时间线的自动播放、暂停和速度控制，不新增逐帧动画、镜头动画、时间轴滑块、历史 AI 回合列表、音效或真实美术资产。
- 本轮不改变 AI 决策、战斗数值、移动、补给、士气、部署、整补、据点、胜负和反制建议语义。

### v1.28 / AI 复盘战果结论面板

日期：2026-07-06

核心变更：

- `GameModels` 新增纯派生 `AIPhaseSummary.replayConclusion`、结论类型、指标和关键事件模型，将最近一次敌方 AI 回合归类为夺点突破、火力压制、后勤整备、机动推进或低强度回合。
- 复盘结论固定汇总伤害、占点、后勤和指令点变化，并从时间线中按占点、击毁/高伤害、战术命令和后勤优先级选择最多 3 条关键事件。
- `ContentView` 在 AI 摘要指标之后、行动时间线之前显示复盘结论；结论区只展示模型派生字段，不调用 `GameState` 写状态方法。
- 扩展 XCTest 和规则 smoke test，覆盖移动后火炮弹幕、后勤部署/整补、机动追击占点、直取据点和低强度空时间线的结论分类、指标和关键事件。

关键文件：

- `WW2Tactics/WW2Tactics/GameModels.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.28（AI复盘战果结论面板）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28769699201` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.28-main-8e5bd41-run28769699201-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28769699201/`，目录大小 `2.9M`。
- Manifest `commitSha=8e5bd41b513421d572b1ce6d7c5976c6d3172951`、`branch=main`、`runId=28769699201`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮只新增最近一次 AI 回合的结论和关键事件摘要，不新增历史 AI 回合列表、镜头动画、音效或真实美术资产。
- 本轮不改变 AI 决策、战斗数值、移动、补给、士气、部署、整补、据点、胜负和反制建议语义。

### v1.29 / AI 复盘结论关键事件定位

日期：2026-07-06

核心变更：

- `ContentView` 将 AI 复盘结论关键事件改为可点选行，按钮只把 key event 的 order 转发给既有 `GameState.focusAIPhaseTimelineEvent(order:)`。
- 结论关键事件和时间线行共享 `focusedAIPhaseTimelineEventOrder` 选中态；点选后地图焦点、消息和 `focusedAIPhaseMapMarkers` 与同 order 时间线事件一致。
- 不新增 `@Published` 状态，不改变 `AIPhaseSummary.replayConclusion` 分类、指标、关键事件排序或地图 marker 派生规则。
- 扩展 XCTest 和规则 smoke test，覆盖结论关键事件 order 定位、marker 强调、消息和单位/指令点/summary/timeline/marker/播放状态只读不变性。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.29（AI复盘结论关键事件定位）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28771041128` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.29-main-63c1515-run28771041128-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28771041128/`，目录大小 `2.9M`。
- Manifest `commitSha=63c1515e5baf4dfb466508b9e63d37991361bd8b`、`branch=main`、`runId=28771041128`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮只增强最近一次 AI 复盘结论关键事件的地图定位，不新增历史 AI 回合列表、镜头动画、音效或真实美术资产。
- 本轮不改变 AI 决策、战斗数值、移动、补给、士气、部署、整补、据点、胜负、播放控制和反制建议语义。

### v1.30 / 路径风险对比

日期：2026-07-06

核心变更：

- `GameModels` 新增 `SafeEngagementComparisonPreview`，将安全接敌候选与默认 POS 路线的风险等级、潜在承伤、最高单源伤害、敌火来源数量、路线受威胁步数、移动力消耗和控制区惩罚做成纯派生对比。
- `GameState` 新增 `focusedSafeEngagementComparisons` 和对比 helper，稳定以未切换安全候选前的默认 POS 首选路线为参考；点选安全候选后，对比参考不会漂移成候选自身。
- `ContentView` 的安全接敌面板和地图命令预览改为消费同一对比模型，显示少承伤、风险变化、移动代价、路线暴露和控制区差异；按钮仍只切换预览，不移动、不攻击。
- 扩展 XCTest 和规则 smoke test，覆盖候选对比字段、默认路线基线、聚焦候选后的只读边界和执行预览不变性。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.30（路径风险对比）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28773648692` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.30-main-e8f2f19-run28773648692-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28773648692/`，目录大小 `3.0M`。
- Manifest `commitSha=e8f2f1911134e9ac4a73ff417ed7e347a62f0584`、`branch=main`、`runId=28773648692`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮只增强 POS 安全接敌路线对比，不改变安全候选排序、默认 POS 执行路线、移动、攻击、战斗数值、AI、据点、补给、士气、后勤、胜负和反制建议语义。
- 路线受威胁步数是解释性对比字段；现有安全接敌场景的最优候选明确降低终点承伤，但中途路线暴露可能相同，UI 会照实显示。

### v1.31 / 据点推进优先级解释

日期：2026-07-06

核心变更：

- `ObjectiveAdvancePreview` 新增纯派生优先级说明字段，解释据点归属、本回合可占/可夺或推进距离、当前距离到剩余距离、路线消耗、步数、控制区惩罚和终点火力风险。
- `ContentView` 的目标计划行和无障碍文案展示同一优先级说明，让 OBJ 候选更容易理解为什么首项优先。
- 不改变 `objectiveAdvancePlanSort`、OBJ 快捷按钮顺序、移动、占点奖励、胜负或 AI 语义。
- 扩展 XCTest 和规则 smoke test，覆盖直达据点、远距推进、火力风险和多目标排序场景的解释字段。

关键文件：

- `WW2Tactics/WW2Tactics/GameModels.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.31（据点推进优先级解释）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28775792182` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.31-main-78d1a47-run28775792182-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28775792182/`，目录大小 `3.0M`。
- Manifest `commitSha=78d1a47ead9ae02383037aa95d6ad67a51cdeb3a`、`branch=main`、`runId=28775792182`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮只解释现有 OBJ 排序输入，不新增据点评分公式，不改变目标计划排序。
- 终点火力风险作为提示展示，不参与现有 OBJ 排序。

### v1.32 / 反制复核结论定位

日期：2026-07-06

核心变更：

- `EnemyThreatCountermeasureFollowUpSummary` 新增纯派生复核结论等级，按既有复核结论和 comparisons 区分奏效、部分奏效或失败。
- 复核 summary 新增执行单位、威胁来源和受威胁目标/据点定位目标；`GameState.focusEnemyThreatCountermeasureFollowUpTarget(_:)` 负责校验当前复核并定位地图。
- `ContentView` 的敌方回合复核卡显示等级徽标和定位按钮；按钮只转发到 `GameState`，不会执行命令。
- 扩展 XCTest 和规则 smoke test，覆盖复核等级、定位目标、过期目标提示和定位只读不变性。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.32（反制复核结论定位）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28778275990` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.32-main-f6af271-run28778275990-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28778275990/`，目录大小 `3.0M`。
- Manifest `commitSha=f6af2718c924577481a31d74f09c23e1f1794e13`、`branch=main`、`runId=28778275990`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮只增强敌方回合复核的等级展示和地图定位，不改变敌方意图、反制建议排序、AI、移动、攻击、整补、部署、据点、胜负或战斗数值。
- 复核等级是解释性派生字段，不重新模拟 AI，也不精确归因逐个 AI 行动。

### v1.33 / 战线态势汇总

日期：2026-07-06

核心变更：

- `GameModels` 新增 `BattlefieldSituationSummary`、态势等级、重点类型和紧凑指标模型，汇总当前阵营指令点、待命部队、据点进度、敌方意图、可执行反制、受威胁据点和首要建议。
- `GameState` 新增只读 computed property `battlefieldSituationSummary`，复用敌方意图、反制建议、据点和待命部队派生，不新增 `@Published` 状态，不调用真实执行方法。
- `ContentView` 在侧栏靠前显示“战线态势”卡，展示等级徽标、指标、受威胁据点和建议说明；UI 只消费 `GameState` 字段，不计算规则。
- 扩展 XCTest 和规则 smoke test，覆盖默认战役态势字段、威胁/反制统计、受威胁据点、推进兜底建议和只读不变性。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.33（战线态势汇总）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- 云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只增加态势总览，不新增态势卡的自动执行按钮，不改变敌方意图、反制建议、OBJ 计划、AI、移动、攻击、整补、部署、据点、胜负或战斗数值。
- 下一轮可在态势汇总基础上增加更细的敌方行动解释或可定位行动入口，但仍需保持执行动作走既有 `GameState` 命令链。

### v1.34 / 战线态势定位入口

日期：2026-07-06

核心变更：

- `BattlefieldSituationSummary` 新增首要定位目标，按可执行反制、受威胁据点、OBJ 推进计划和待命单位的顺序从当前态势纯派生。
- `GameState.focusBattlefieldSituationPrimaryTarget()` 新增态势卡定位入口，每次点击都基于最新 summary 重新取目标，并复用既有反制聚焦、OBJ 聚焦或单位选择逻辑。
- `ContentView` 的“战线态势”卡新增紧凑定位按钮，展示目标类型、标题和说明；按钮只转发到 `GameState`，不会自动执行命令。
- 扩展 XCTest 和规则 smoke test，覆盖反制定位、OBJ 兜底定位、目标派生和定位只读不变性。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.34（战线态势定位入口）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28783232525` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.34-main-daec553-run28783232525-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28783232525/`，目录大小 `3.2M`。
- Manifest `commitSha=daec55392f5a469977ff24cff691e41dd5746710`、`branch=main`、`runId=28783232525`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮只增加态势卡首要目标定位，不新增自动执行、不改变反制建议、OBJ 计划、AI、移动、攻击、整补、部署、据点、胜负或战斗数值。
- 下一轮可继续强化定位后的执行前后解释或敌方行动解释，但仍需保持真实动作走既有 `GameState` 命令链。

### v1.35 / 战线态势下一步提示

日期：2026-07-06

核心变更：

- `BattlefieldSituationFocusTarget` 新增 `BattlefieldSituationActionHint`，把首要定位目标和下一步入口提示绑定在同一纯派生模型上。
- `GameState` 在派生态势目标时同步给出 ATK、MOVE、整补、选择或防守查看提示；提示只说明下一步应走的既有入口，不执行命令。
- `ContentView` 的“战线态势”定位按钮新增下一步入口行和入口短码，并把说明纳入无障碍文案。
- 扩展 XCTest 和规则 smoke test，覆盖反制/OBJ action hint、定位后的反制执行桥接一致性和只读不变性。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.35（战线态势下一步提示）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- 云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只增加态势定位后的入口提示，不新增自动执行、不改变反制建议、OBJ 计划、AI、移动、攻击、整补、部署、据点、胜负或战斗数值。
- 下一轮可继续强化执行后的闭环解释，或补充更细的敌方行动解释。

### v1.36 / 战线态势执行闭环

日期：2026-07-06

核心变更：

- `GameModels` 新增 `BattlefieldSituationResponseSummary` 和响应类型，用于描述最近一次态势相关真实执行反馈。
- `GameState.battlefieldSituationResponseSummary` 新增只读 computed property，优先从 `latestEnemyThreatCountermeasureExecutionResult` 派生反制执行反馈，其次从 `latestObjectiveCaptureResult` 派生据点占领反馈，不新增 `@Published` 状态。
- `ContentView` 的“战线态势”卡新增紧凑执行反馈行，展示反制预计/实际对照或占点奖励与进度；UI 只消费 `GameState` 字段，不计算规则。
- 扩展 XCTest 和规则 smoke test，覆盖反制执行响应、OBJ 占点响应、读取无副作用和普通无关攻击不伪造响应。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.36（战线态势执行闭环）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- GitHub Actions `WW2Tactics CI Results` run `28788564127` / attempt `1`：completed / success。
- Artifact `ww2tactics-ci-v1.36-main-4c143fb-run28788564127-attempt1`：Agent C 已下载到 `/private/tmp/ww2tactics-c-review-28788564127/`，目录大小 `3.4M`。
- Manifest `commitSha=4c143fb48056195e2e5c37acdfb1aa02536e9b6a`、`branch=main`、`runId=28788564127`、`runAttempt=1` 与 `origin/main` 功能提交一致。
- `ci-failure-summary.md`、`junit.xml`、`static-checks.log`、`rules-smoke.log`、`xcodebuild.log` 和 `WW2Tactics.xcresult` 均已核对；静态检查、规则 smoke 和 Xcode build-for-testing 均为 success，XCTest 执行按当前 CI 策略为 skipped。

遗留事项：

- 本轮只增加战线态势卡的执行反馈展示，不新增自动执行、不改变反制建议、OBJ 计划、AI、移动、攻击、整补、部署、据点、胜负或战斗数值。
- 下一轮可继续把态势响应和敌方回合后的复核/AI 影响解释串联起来。

### v1.37 / 战线态势敌方回合影响

日期：2026-07-06

核心变更：

- `BattlefieldSituationResponseKind` 新增敌方回合影响类型，让战线态势响应能区分即时反制、占点和敌方回合复核。
- `GameState.battlefieldSituationResponseSummary` 调整为优先从 `latestEnemyThreatCountermeasureFollowUpResult` 派生敌方回合影响，其次才展示即时反制执行回放或据点占领反馈。
- 战线态势卡在反制进入敌方回合后会显示复核等级、反制类型、执行单位/目标、关键敌方回合前后对比和复核坐标；UI 只消费 `GameState` 字段，不计算复核规则。
- 扩展 XCTest 和规则 smoke test，覆盖 follow-up 响应优先级、读取无副作用、无反制 baseline 不伪造 follow-up 响应，以及既有即时反制/占点响应不被破坏。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.37（战线态势敌方回合影响）.md`

验证结果：

- `git diff --check`：通过，退出码 0。
- 规则 smoke 编译：通过，退出码 0。
- `/private/tmp/WW2TacticsRulesSmokeTest`：通过，输出 `Rules smoke test passed`。
- iOS app 源码级 typecheck：通过，退出码 0。
- 测试模块 emit：通过，退出码 0。
- `GameStateTests.swift` 源码级 typecheck：通过，退出码 0。
- 云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只把既有反制复核结果接入战线态势卡，不新增 AI 模拟、不改变复核生成、反制建议、OBJ 计划、AI、移动、攻击、整补、部署、据点、胜负或战斗数值。
- 下一轮可继续处理普通战斗/后勤结果与态势影响的联动，或强化 AI 复盘定位和地图反馈。

### v1.38 / 战线态势 AI 复盘联动定位

日期：2026-07-06

核心变更：

- `GameModels` 新增 `BattlefieldSituationReplayTarget`，并让 `BattlefieldSituationSummary` 携带可选的 AI 关键复盘定位目标。
- `GameState.battlefieldSituationSummary` 从最新 `AIPhaseSummary.replayConclusion.keyEvents.first` 纯派生战线态势复盘目标，并用同一 timeline 回查可定位坐标；无 summary、无关键事件、无坐标或坐标越界时不伪造目标。
- 新增 `focusBattlefieldSituationReplayTarget()`，点击战线态势复盘入口时只复用既有 `focusAIPhaseTimelineEvent(order:)`，不直接设置坐标、不执行命令、不改变 AI 生成或 marker 派生。
- `ContentView` 的“战线态势”卡新增“复盘影响”紧凑按钮，展示敌方关键 AI 事件并定位地图；UI 只消费 summary 字段，不查 timeline 或 marker。
- 扩展 XCTest 和规则 smoke test，覆盖 replay target 派生、定位复用、只读无副作用以及无 summary/无坐标/越界坐标退化。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.38（战线态势AI复盘联动定位）.md`

验证结果：

- 本地轻量检查通过：`git diff --check`、macOS smoke test 编译/运行、iOS Simulator 源码 typecheck、`WW2Tactics.swiftmodule` emit、`GameStateTests.swift` 源码 typecheck。
- 云端 GitHub Actions 通过：commit `631e788e99965be2f03ac098c99b41cdc7038719`，run `28791381710`，attempt `1`，artifact `ww2tactics-ci-v1.38-main-631e788-run28791381710-attempt1`，下载目录 `/private/tmp/ww2tactics-c-review-28791381710/`，artifact 约 `3.4M`。
- Agent C 已核对 `origin/main`、manifest、JUnit、规则 smoke 日志、主构建日志和 `.xcresult`，commit/run/artifact 一致且通过。

遗留事项：

- 本轮只把战线态势卡和既有 AI 复盘关键事件定位连接起来，不新增 AI 行为、不改变关键事件排序、不改变战线态势首要定位、不新增自动执行。
- 下一轮可继续处理普通战斗/后勤结果与态势影响解释的联动，或进一步增强地图反馈的可读性。

### v1.39 / 普通行动态势响应

日期：2026-07-06

核心变更：

- `BattlefieldSituationResponseKind` 新增普通战斗、战术命令、部署和整补响应类型，并提供对应短标签和 SF Symbols 图标。
- `GameState.battlefieldSituationResponseSummary` 在敌方回合影响、反制执行和占点反馈之后，继续从最新普通攻击、战术命令、部署和整补结果纯派生态势响应。
- 普通战斗响应展示攻击/目标、伤害、反击、HP 前后、防御姿态、夹击和机动追击；战术命令响应展示命令、施放者、目标、伤害、指令点、士气/状态和无反击；部署/整补响应展示来源、坐标、恢复、消耗和剩余指令点。
- `ContentView` 为普通攻击、战术命令、部署和整补响应补齐颜色映射；UI 仍只消费 `GameState` 派生摘要，不在 View 中计算规则。
- 扩展 XCTest 和规则 smoke test，覆盖普通攻击、战术命令、部署、整补响应的字段、优先级和读取无副作用，并确认普通移动、预览聚焦和失败命令不会伪造态势响应。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.39（普通行动态势响应）.md`

验证结果：

- 本地轻量检查通过：`git diff --check`、macOS smoke test 编译/运行、iOS Simulator 源码 typecheck、`WW2Tactics.swiftmodule` emit、`GameStateTests.swift` 源码 typecheck。
- 云端 GitHub Actions 通过：commit `36cb166133ff2f3b83428b194d838386252c772b`，run `28793320521`，attempt `1`，artifact `ww2tactics-ci-v1.39-main-36cb166-run28793320521-attempt1`，下载目录 `/private/tmp/ww2tactics-c-review-28793320521/`，artifact 约 `3.4M`。
- Agent C 已核对 `origin/main`、manifest、JUnit、规则 smoke 日志、主构建日志和 `.xcresult`，commit/run/artifact 一致且通过。

遗留事项：

- 本轮只把已有成功行动结果接入战线态势响应，不新增行动类型、AI 行为、动画、自动执行、历史响应列表或复杂美术资源。
- 下一轮可继续强化态势响应在地图上的定位/高亮，或进一步解释据点防守取舍。

### v1.40 / 态势响应地图标记

日期：2026-07-06

核心变更：

- `GameModels` 新增 `BattlefieldSituationResponseMapMarker`，复用战线态势响应类型的短标签和 SF Symbols 图标，为地图格提供只读响应投影。
- `GameState.battlefieldSituationResponseMapMarker` 从当前最高优先级 `battlefieldSituationResponseSummary` 纯派生；只有响应坐标存在且仍在当前地图内时才输出 marker，不新增 `@Published` 状态。
- `ContentView.HexMapView` 将响应 marker 传入对应 `HexTileView`，地图格显示紧凑态势响应胶囊标记，并把响应摘要加入 tile 无障碍文案。
- 地图边框和图例补充态势响应语义；响应 marker 避让 INT、OBJ/CAP、火力风险和反制聚焦标记，UI 只展示 `GameState` 派生数据，不回查单位或计算规则。
- 扩展 XCTest 和规则 smoke test，覆盖反制、敌方回合影响、占点、普通攻击、战术命令、部署、整补响应 marker，以及普通移动、预览和失败命令不生成 marker。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.40（态势响应地图标记）.md`

验证结果：

- 本地轻量检查和云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只显示当前最高优先级态势响应的单点地图标记，不新增历史响应列表、动画、镜头移动、自动滚动或自动执行。
- 下一轮可继续处理态势响应定位入口/连续查看，或进一步解释据点防守取舍。

### v1.41 / 态势响应定位入口

日期：2026-07-06

核心变更：

- `GameState` 新增 `focusBattlefieldSituationResponseTarget()`，从当前 `battlefieldSituationResponseMapMarker` 重新读取合法响应坐标，只更新地图焦点和消息。
- `ContentView` 的战线态势响应卡在存在合法响应 marker 时显示紧凑定位按钮，可直接把地图焦点切到最近响应发生格。
- 响应定位会清理临时 OBJ/SAFE/反制引导，但不执行移动、攻击、战术命令、部署、整补、回合推进或 AI，也不改变响应摘要、marker、latest result、单位、据点、指令点或战报。
- 扩展 XCTest 和规则 smoke test，覆盖普通攻击、部署和无响应场景的定位入口，确认只读边界和无 marker 退化。

关键文件：

- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.41（态势响应定位入口）.md`

验证结果：

- 本地轻量检查和云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只做当前最高优先级态势响应的单点定位入口，不新增历史响应列表、上一条/下一条响应浏览、动画、自动播放或自动执行。
- 下一轮可优先处理据点防守取舍的执行前后解释，或先设计态势响应历史模型后再做连续查看。

### v1.42 / 据点防守取舍解释

日期：2026-07-06

核心变更：

- `GameModels` 新增 `EnemyThreatObjectiveDefenseTradeoff`，并让 `EnemyThreatCountermeasurePreview.objectiveDefenseTradeoff` 从现有守点建议字段纯派生进驻/封堵取舍说明。
- 取舍解释只读取 `destination`、`threatTargetCoordinate`、`targetName`、`routeCost`、`score` 和 objective impact；非 `.objectiveDefense` 建议返回空，不新增 `@Published` 状态。
- `ContentView` 的反制建议行在据点防守建议上显示进驻/封堵、路线代价和优先值说明；UI 不重算路线、score 或守点规则。
- 扩展 XCTest 和规则 smoke test，覆盖“后方油库”守点建议的取舍字段、非守点建议退化、排序/limit 不变、聚焦和执行桥接语义不变。

关键文件：

- `WW2Tactics/WW2Tactics/GameModels.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.42（据点防守取舍解释）.md`

验证结果：

- 本地轻量检查和云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只解释当前守点建议为什么进驻或封堵，不改变守点候选选择、score、排序、聚焦、执行桥接、真实 MOVE 或 AI 行为。
- 下一轮可处理态势响应连续查看，或细化据点防守执行后的敌方回合复核归因。

### v1.43 / 态势响应连续查看

日期：2026-07-06

核心变更：

- `GameModels` 新增 `BattlefieldSituationResponseHistoryEntry`，用稳定 order 保存态势响应摘要快照。
- `GameState` 新增最近 5 条态势响应历史、当前查看响应 order、历史追加/裁剪/清空和上一条/下一条导航；真实攻击、战术命令、占点、部署、整补、反制执行和反制敌方回合复核成功发布点会追加响应历史。
- `battlefieldSituationResponseSummary` 和 `battlefieldSituationResponseMapMarker` 改为从当前查看的历史响应派生；普通移动、预览、聚焦和失败命令不追加历史；重开/切战役会清空历史。
- `ContentView` 的战线态势响应卡显示历史位置，并提供上一条/下一条按钮；响应定位和地图 RSP 标记跟随当前查看的历史响应。
- 追加修正响应历史浏览和响应定位的只读边界：只切换当前响应、焦点坐标和消息，不再清理 OBJ/SAFE/反制临时引导。
- 扩展 XCTest 和规则 smoke test，覆盖最近 5 条容量裁剪、上一条/下一条只读导航、marker 跟随当前响应、普通移动/失败部署不追加历史和 restart 清理历史。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.43（态势响应连续查看）.md`

验证结果：

- 本地轻量检查和云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只做最近 5 条响应历史和手动连续查看，不新增自动播放、筛选器、搜索、大型日志或新战斗/AI 规则。
- 下一轮可细化据点防守执行后的敌方回合复核归因，或继续强化 AI 复盘与战线态势地图反馈。

### v1.44 / 据点防守复核细分

日期：2026-07-07

核心变更：

- `GameModels` 新增 `EnemyThreatObjectiveDefenseFollowUpDetail`，为据点防守复核结构化记录进驻/封堵动作、据点归属、防守单位、威胁源、守点位置结果和威胁压迫结果。
- `EnemyThreatCountermeasureFollowUpSummary` 为 `.objectiveDefense` 保留可选细分字段，并优先从结构化结果派生奏效/部分奏效/失败等级；其他反制仍沿用既有 comparisons 派生逻辑。
- `GameState` 的据点防守复核新增“守点位置”和“威胁来源”对照，结论会说明进驻或封堵已复核、目标据点是否仍由盟军控制、威胁源是否仍压迫据点；该复核只读取真实 AI 后状态，不改变反制建议、AI 或执行规则。
- `ContentView` 的敌方回合复核卡展示据点防守细分摘要，UI 只读展示 `GameState`/`GameModels` 字段，不重算守点规则。
- 扩展 XCTest 和规则 smoke test，覆盖据点防守复核新增 comparison、结构化 detail、态势响应 leading result 和守点成功但允许防守单位受损的基线。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.44（据点防守复核细分）.md`

验证结果：

- 本地轻量检查和云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只细分执行后的守点复核，不新增 AI 行动归因、不模拟未防守分支、不改变 objectiveDefense 建议排序、score、移动攻击规则或敌方 AI 行为。
- 下一轮可继续补充据点攻防的敌方行动归因，或强化 AI 复盘与战线态势地图反馈。

### v1.45 / 复核关联 AI 行动

日期：2026-07-07

核心变更：

- `GameModels` 新增 `EnemyThreatCountermeasureFollowUpAIEventRelation` 和 `EnemyThreatCountermeasureFollowUpAIEvent`，让敌方回合复核能保存来自真实 AI 时间线的轻量关联行动。
- `EnemyThreatCountermeasureFollowUpSummary` 新增 `relatedAIEvents`，据点防守复核会按目标据点坐标、防守单位、原威胁源和受威胁目标从同一 `AIPhaseSummary.timeline` 中保守筛选最多 3 条事件。
- `GameState` 只读取真实 AI 后 summary 和 timeline，不调用移动、攻击、战术命令、AI 或模拟分支；关联行动只表达“相关真实事件”，不声明精确因果。
- `ContentView` 的敌方回合复核卡显示“关联AI行动”，每条用现有 `focusAIPhaseTimelineEvent(order:)` 做只读定位，不新增执行入口。
- 扩展 XCTest 和规则 smoke test，覆盖关联事件 order 来自最新 timeline、kind 合法、威胁源关联存在、成功守点不出现敌方夺取目标据点事件，以及点击关联事件不改变单位、据点、AI summary 或 follow-up。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.45（复核关联AI行动）.md`

验证结果：

- 本地轻量检查和云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只做真实 AI 时间线的保守关联，不做精确逐行动因果归因，不模拟未防守分支，不改变 AI 行为、时间线记录、守点评分或执行规则。
- 下一轮可继续强化 AI 复盘与战线态势地图反馈，或补充更多据点攻防的非模拟解释。

### v1.46 / 据点防守压力列表

日期：2026-07-06

核心变更：

- `GameModels` 新增 `BattlefieldSituationObjectivePressure`，把受威胁据点、当前归属、威胁来源数量、占点风险和推荐入口整理为结构化只读条目。
- `GameState.battlefieldSituationSummary` 基于同一批敌方 `.objectiveCapture` 意图和同 threatID 反制建议派生据点防守压力列表，不新增 `@Published` 状态，不改变敌方意图排序、反制 score、AI 或战斗规则。
- `ContentView` 的“战线态势”卡新增紧凑“据点压力”列表，展示据点名、归属、威胁来源、占点风险和 DEF/MOVE 等入口短码；UI 只消费 summary 字段，不计算威胁或反制。
- 扩展 XCTest 和规则 smoke test，覆盖“后方油库”据点压力字段、推荐守点入口、无威胁退化和读取 summary 的只读边界。

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
- `md/prompt/v1（地图操作体验）/v1.46（据点防守压力列表）.md`

验证结果：

- 本地轻量检查和云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只解释玩家回合据点防守压力，不新增自动守点、AI 行动归因、未防守分支模拟、动画、音效或新美术资源。
- 不改变 AI、移动、攻击、补给、士气、据点奖励、胜负、敌方意图或反制建议排序。

### v1.47 / 据点压力定位入口

日期：2026-07-07

核心变更：

- 将战线态势卡的据点防守压力行升级为只读定位入口。
- 新增 `focusBattlefieldSituationObjectivePressure(id:)`，每次点击重新校验最新压力 id，有匹配反制时复用反制聚焦，无匹配时定位受威胁据点。
- 压力定位只改变选择、焦点、目标引导、反制聚焦和消息，不执行移动、攻击、整补、部署、战术命令或 AI。
- 扩展 XCTest 和规则 smoke test，覆盖压力定位只读边界。

关键文件：

- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.47（据点压力定位入口）.md`

验证结果：

- 本地轻量检查和云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 后续仍可继续强化 AI 复盘与战线态势地图反馈，或增加更多据点攻防解释。

### v1.48 / 据点压力地图标记

日期：2026-07-07

核心变更：

- 新增 `BattlefieldSituationObjectivePressureMapMarker`，把当前点选压力投射为 PRS 受压据点和 DEF 守点目的格地图标记。
- `GameState` 保存私有当前压力 id，并从最新 `battlefieldSituationSummary.objectivePressures` 纯派生 marker，不新增 `@Published` marker 数组。
- `ContentView` 按坐标渲染压力 marker、地图边框和无障碍摘要，UI 不计算威胁、反制或坐标。
- 扩展 XCTest 和规则 smoke test，覆盖 marker 坐标、无效压力 id 清理和只读边界。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.48（据点压力地图标记）.md`

验证结果：

- 本地轻量检查和云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只做当前压力的只读地图反馈，不新增自动守点、未防守分支模拟、动画、音效或新美术资源。

### v1.49 / 据点压力行选中态

日期：2026-07-07

核心变更：

- 新增 `isBattlefieldSituationObjectivePressureFocused(id:)`，从当前压力 id 和最新 `battlefieldSituationSummary.objectivePressures` 派生据点压力行当前态。
- `ContentView` 的据点压力行显示“当前”标识、背景和边框强调，并更新无障碍文案；UI 只消费 `GameState` 查询，不保存独立 `@State`。
- 扩展 XCTest 和规则 smoke test，覆盖点选压力后的当前态、过期 id 清理、普通地图聚焦清理，以及只读边界不变。

关键文件：

- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.49（据点压力行选中态）.md`

验证结果：

- 本地轻量检查和云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只把侧栏压力行与现有 PRS/DEF 地图标记对齐，不新增自动守点、未防守分支模拟、动画、音效或新美术资源。

### v1.50 / 据点压力威胁来源标记

日期：2026-07-07

核心变更：

- `BattlefieldSituationObjectivePressure` 新增 `threatSourceCoordinates`，从同一压力分组内敌方威胁来源单位的当前坐标纯派生。
- `BattlefieldSituationObjectivePressureMapMarkerRole` 新增 SRC 威胁来源标记，当前压力地图反馈从 PRS/DEF 扩展为 PRS/SRC/DEF。
- `GameState` 继续从当前压力 id 和最新 pressure 纯派生 marker，不新增 `@Published` marker 数组；`ContentView` 复用现有压力 marker 展示和 tile 无障碍摘要。
- 扩展 XCTest 和规则 smoke test，覆盖威胁来源坐标、SRC marker、过期 id 清理、普通地图聚焦清理，以及只读边界不变。

关键文件：

- `WW2Tactics/WW2Tactics/GameModels.swift`
- `WW2Tactics/WW2Tactics/GameState.swift`
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
- `WW2Tactics/Tools/RulesSmokeTest.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.50（据点压力威胁来源标记）.md`

验证结果：

- 本地轻量检查和云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只补齐当前压力的威胁来源地图标记，不新增自动守点、AI 复盘来源入口、未防守分支模拟、动画、音效或新美术资源。

### v1.51 / 据点压力复盘线索

日期：2026-07-07

核心变更：

- `BattlefieldSituationObjectivePressure` 新增可选 `replayTarget`，从最新 `AIPhaseSummary.timeline` 保守匹配当前压力的威胁来源单位或受压据点坐标。
- `GameState` 新增当前压力复盘线索派生属性和 `focusBattlefieldSituationObjectivePressureReplayTarget()`，点击后复用既有 AI 时间线定位入口，只切换 AI 复盘焦点和地图复盘标记强调。
- `ContentView` 在据点压力列表下方新增独立“复盘线索”按钮，避免嵌套在压力行按钮中；文案只表达关联线索，不宣称因果。
- 扩展 XCTest 和规则 smoke test，覆盖无 AI summary 不生成线索、无匹配不回退全局复盘、匹配线索定位、AI summary 不变和只读边界。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.51（据点压力复盘线索）.md`

验证结果：

- 规则 smoke 编译通过。
- `/private/tmp/WW2TacticsRulesSmokeTest` 通过，输出 `Rules smoke test passed`。
- iOS SwiftUI typecheck、XCTest 源码级 typecheck、`git diff --check` 和云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只做当前压力与 AI 时间线的保守关联复盘线索，不新增自动守点、AI 因果归因、未防守分支模拟、动画、音效或新美术资源。

### v1.52 / 据点压力态势对照

日期：2026-07-07

核心变更：

- `BattlefieldSituationObjectivePressure` 新增 `comparison`，从据点归属、威胁来源数量、路线状态、action hint、匹配反制和复盘线索纯派生当前/应对态势。
- `GameState` 在构造据点压力时生成 `BattlefieldSituationObjectivePressureComparison`，表达当前守势、敌控、中立争夺或争夺态，以及应对入口是否可执行、是否有复盘线索。
- `ContentView` 在据点压力行内显示紧凑的“当前 / 应对”两行和态势短码，继续保持压力行只有外层按钮，不新增嵌套按钮。
- 扩展 XCTest 和规则 smoke test，覆盖 comparison 字段、复盘线索注入后的文案和 pressure id 稳定性。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.52（据点压力态势对照）.md`

验证结果：

- 规则 smoke 编译通过。
- `/private/tmp/WW2TacticsRulesSmokeTest` 通过，输出 `Rules smoke test passed`。
- `git diff --check`、iOS SwiftUI typecheck、XCTest 源码级 typecheck 和云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只做据点压力行的只读态势对照，不新增未来分支模拟、自动防守、自动移动、自动攻击、AI 因果归因、动画、音效或新美术资源。

### v1.53 / 战线态势复盘筛选

日期：2026-07-07

核心变更：

- `BattlefieldSituationReplayTarget` 新增 `source`，区分当前压力关联、响应位置关联和全局关键事件。
- `GameState.battlefieldSituationReplayTarget` 改为优先使用当前点选据点压力线索，其次按当前态势响应坐标匹配 AI 时间线，最后回退全局关键事件。
- `ContentView` 的战线态势“复盘影响”按钮显示来源标题和 PRS/RSP/KEY 来源短码，UI 仍只消费 `GameState` 派生字段。
- 扩展 XCTest 和规则 smoke test，覆盖压力线索优先、响应坐标匹配、全局 key event 回退和复盘定位只读边界。

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
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.53（战线态势复盘筛选）.md`

验证结果：

- 本地轻量检查和云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只筛选和解释既有 AI 时间线事件，不新增 AI 因果归因、未来分支模拟、自动防守、自动移动、自动攻击、动画、音效或新美术资源。

### v1.54 / 据点压力敌方回合影响

日期：2026-07-07

核心变更：

- `BattlefieldSituationObjectivePressure` 新增 `enemyPhaseImpact`，从最新守点反制 follow-up 和最新 AI summary 纯派生据点压力的敌方回合后影响。
- `GameState` 只在 follow-up 为据点防守、受威胁据点坐标匹配且 AI 回合号匹配时生成压力影响；无真实 follow-up 时不从普通 AI 复盘线索或全局关键事件伪造影响。
- `ContentView` 在据点压力行显示敌方回合前后对比和结果，UI 仍只消费 `GameState` 派生字段。
- 扩展 XCTest 和规则 smoke test，覆盖初始压力无影响、复盘线索不伪造影响、守点 follow-up 后压力行显示影响、pressure id 稳定和只读边界。

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
- `md/prompt/v1（地图操作体验）/v1.54（据点压力敌方回合影响）.md`

验证结果：

- 本地轻量检查和云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只把真实守点 follow-up 映射回据点压力行，不新增 AI 因果归因、未来分支模拟、自动防守、自动移动、自动攻击、动画、音效或新美术资源。

### v1.55 / 据点压力来源标识

日期：2026-07-07

核心变更：

- `BattlefieldSituationObjectivePressureSource` 区分 NOW 当前威胁和 CHK 回合复核。
- `GameState` 构造当前 `.objectiveCapture` 压力时标记 `.currentThreat`，构造守点 follow-up 压力时标记 `.enemyPhaseFollowUp`，并优先按 source.sortRank 排序，让当前威胁稳定排在回合复核前。
- `ContentView` 在据点压力行和压力区域无障碍文案中展示来源，UI 仍只消费 `GameState` 派生字段。
- 扩展 XCTest 和规则 smoke test，覆盖来源标题、短码、sortRank、id 包含来源、当前威胁和回合复核来源断言。

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
- `md/prompt/v1（地图操作体验）/v1.55（据点压力来源标识）.md`

验证结果：

- 本地轻量检查和云端 GitHub Actions 结果以本轮最终交付记录为准。

遗留事项：

- 本轮只做压力来源标识和排序解释，不新增 AI 因果归因、未来分支模拟、自动防守、自动移动、自动攻击、动画、音效或新美术资源。

### v1.56 / 战场界面视觉重构基线

日期：2026-07-11

核心变更：

- `ContentView` 新增 `BattlefieldTheme` 和 tactical surface 通用表现样式，统一首屏战场视觉语言。
- 重构顶层背景、`TopCommandBar`、战役标题、状态芯片和结束回合按钮色彩层级。
- 重构 `BattlefieldView`、`MapCommandCenter`、`MapToolbar`、`MapHudBackground` 和 `InspectorPanel` 容器质感，让地图、HUD 和侧栏更接近战区指挥台。
- 保持所有 `GameState` 操作入口和核心规则不变，本轮只调整表现层。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.56（战场界面视觉重构基线）.md`

验证结果：

- 本轮人工要求不跑本地测试，全部交给 GitHub Actions 云端重验证；最终结果以本轮交付记录中的 run 和 artifact 为准。

遗留事项：

- 本轮只建立首屏外壳视觉基线；地图格美术、单位棋子、结果卡、AI 复盘和更多细分面板仍需后续小轮次继续重构。

### v1.57 / 地图格与单位棋子视觉升级

日期：2026-07-11

核心变更：

- `HexTileView` 从单色地形块升级为地形渐变、高光/低光、细描边和据点归属覆盖。
- `TerrainSymbol`、`TerrainCodeBadge` 和 `ObjectiveNamePlate` 统一到战区指挥台主题，提升地形符号、地形代码和据点名牌可读性。
- `UnitShapeBadge` 保留原兵种形状和信息字段，同时增加阵营渐变、底影、高光、战场金属描边和状态层级。
- 本轮只改 `ContentView` 表现层，不改变地图输入、标记、规则、AI 或 `GameState` 调用链。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.57（地图格与单位棋子视觉升级）.md`

验证结果：

- 本轮人工要求不跑本地测试，全部交给 GitHub Actions 云端重验证；最终结果以本轮交付记录中的 run 和 artifact 为准。

遗留事项：

- 本轮未重构战斗结果卡、战线态势面板、AI 复盘时间线或地图标记拥挤度；这些应继续拆成后续 UI 小轮次。

### v1.58 / 攻击预览与战斗结果反馈卡视觉统一

日期：2026-07-11

核心变更：

- `AttackTargetsView` 和 `AttackTargetButton` 升级为战报式目标牌，强化聚焦态、目标 HP、预计伤害、反击和 KILL 提示。
- `CombatForecastView` 统一为战斗预测牌，突出攻击方、目标方、伤害、目标剩余、反击、击毁/反击风险和影响来源。
- `CombatResultSummaryView` 和 `CombatantResultLine` 升级为普通攻击结果战报卡，强化结论、战斗叙述、攻防双方 HP 变化和后续效果。
- 本轮只改 `ContentView` 表现层，不改变 `GameState` 攻击、反击、伤害、经验、士气、追击或结果生成规则。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.58（攻击预览与战斗结果反馈卡视觉统一）.md`

验证结果：

- 本轮人工要求不跑本地测试，全部交给 GitHub Actions 云端重验证；最终结果以本轮交付记录中的 run 和 artifact 为准。

遗留事项：

- 本轮未重构战线态势面板、AI 复盘时间线、地图标记拥挤度或 `InlineMapCommandPreview` / `FocusedCommandPreviewPanel` 文案去重；这些应继续拆成后续 UI 小轮次。

### v1.59 / 战线态势指挥简报重构

日期：2026-07-11

核心变更：

- 将超长 `BattlefieldSituationSummaryView` 拆成标题、最近响应、复盘入口、首要目标、据点压力和页脚等专属私有子 View，保持原显示顺序。
- 战线态势主卡升级为指挥简报式层级，突出优先级、摘要、真实响应、行动入口、压力和指标。
- 重构据点压力行，保留 NOW/CHK、威胁源、当前/应对对照、敌方回合影响、推荐入口和当前焦点，同时改善窄侧栏可读性。
- 将态势响应上一条/下一条和定位入口扩为至少 44x44 点击区，保留原 action、disabled 和 VoiceOver 文案。
- 本轮只改 `ContentView` 表现层，不改变 `GameState` 态势派生、压力排序、响应历史、定位、AI 复盘或地图 marker 行为。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.59（战线态势指挥简报重构）.md`

验证结果：

- 本轮人工要求不跑本地测试，全部交给 GitHub Actions 云端重验证；最终结果以本轮交付记录中的 run 和 artifact 为准。

遗留事项：

- 本轮未重构 AI 复盘时间线、地图标记拥挤度或命令预览重复实现；这些应继续拆成后续 UI 小轮次。

### v1.60 / AI 战况回放界面重构

日期：2026-07-11

核心变更：

- `AIPhaseSummaryView` 重构为回合头部、AI 专属九宫指标、复盘结论、播放控制、当前事件、前五条时间线和战果尾注分区。
- 新增 AI 专属指标组件，不修改高复用 `CombatResultMetric`。
- 新增当前回放事件条，自动播放或手动导航进入第 6 条以后，侧栏仍显示当前 order、类型和行动摘要。
- 重构复盘结论和关键事件，保留模型派生顺序与共享 focused order，并将关键事件点击区扩到至少 44pt。
- 重构时间线行和播放控件视觉，时间线按钮至少 44pt，保留原 action、disabled、速度 value/hint 和 VoiceOver 语义。
- Timer publisher、播放 active 判断、pace interval 和 `advanceAIPhaseTimelinePlayback()` 调用链保持不变。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.60（AI战况回放界面重构）.md`

验证结果：

- 本轮人工要求不跑本地测试，全部交给 GitHub Actions 云端重验证；最终结果以本轮交付记录中的 run 和 artifact 为准。

遗留事项：

- 本轮未处理地图复盘标记拥挤度或 `InlineMapCommandPreview` / `FocusedCommandPreviewPanel` 重复实现；这些应继续拆成后续 UI 小轮次。

### v1.61 / 地图标记拥挤度治理

日期：2026-07-12

核心变更：

- `HexTileView` 将反制、据点压力、态势响应、敌方意图、火力风险、OBJ/CAP 与 AI 复盘/攻击位收入统一顶/底 marker 栈。
- 顶/底栈各最多显示 2 个徽标，溢出显示 `+N`；MOVE/ATK/POS 与不可用目标仍固定角落，避免被折叠掉。
- 删除分散的 `*MarkerTopPadding` / `aiPhaseMarkerBottomPadding` 硬编码错位。
- 本轮只改 `ContentView` 表现层，不改变 `GameState` marker 生成、聚焦或命令链；无障碍文案仍列出全部标记语义。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.61（地图标记拥挤度治理）.md`

验证结果：

- 本地仅 `git diff --check`；完整验证交给 GitHub Actions 云端重验证。

遗留事项：

- 下一轮优先处理 `InlineMapCommandPreview` / `FocusedCommandPreviewPanel` 命令预览去重。

### v1.62 / 命令预览去重

日期：2026-07-12

核心变更：

- 新增 `MapCommandPreviewChrome`，集中命令预览的图标、色阶、路线风险、火力暴露、移动后攻击与安全接敌摘要。
- `InlineMapCommandPreview` 与 `FocusedCommandPreviewPanel` 改为调用共享 helper，保留各自短/长文案密度。
- 本轮只改 `ContentView` 表现层，不改变 `GameState` 命令预览生成与执行链。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.62（命令预览去重）.md`

验证结果：

- 本地仅 `git diff --check`；完整验证交给 GitHub Actions。

遗留事项：

- 可继续推进其他 UI 可读性/可玩性小轮次，不强制重复命令预览重构。

### v1.63 / 后勤与战术结果卡视觉统一

日期：2026-07-12

核心变更：

- `TacticalCommandResultSummaryView`、`ObjectiveCaptureResultSummaryView`、`DeploymentResultSummaryView`、`ReinforcementResultSummaryView` 对齐战斗结果战报卡层级。
- 细节行复用 `BattleResultDetailLine`，统一渐变底、结论胶囊和指标条。
- 本轮只改 `ContentView` 表现层，不改变结果生成规则。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.63（后勤结果卡视觉统一）.md`

验证结果：

- 本地仅 `git diff --check`；完整验证交给 GitHub Actions。

遗留事项：

- 反制执行回放卡等仍可继续视觉对齐。

### v1.64 / 反制回放卡视觉统一

日期：2026-07-12

核心变更：

- `EnemyThreatCountermeasureExecutionResultSummaryView` 与 `EnemyThreatCountermeasureFollowUpSummaryView` 对齐战斗结果战报卡层级。
- 统一渐变底、结论胶囊、主体信息块、指标条与 `BattleResultDetailLine` 细节行。
- 保留复核定位按钮、关联 AI 行动入口与无障碍语义；不改变 `GameState` 反制/复核规则。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.64（反制回放卡视觉统一）.md`

验证结果：

- 本地仅 `git diff --check`；完整验证交给 GitHub Actions。

遗留事项：

- 后续可继续推进 HUD 信息密度与触控手感优化。

### v1.65 / HUD 信息密度整理

日期：2026-07-12

核心变更：

- 收紧顶栏 `StatusChip`/`StatusStrip` 间距与字号，保留全部战况字段。
- 压缩 `MapCampaignHUD`/`MapActionHUD` 固定宽度与内边距，降低地图遮挡。
- `MapToolbar` 副标题改为缩放与焦点摘要，避免与消息条重复。
- 快捷命令按钮最小高度提升到 36pt；指标条更紧凑。
- 本轮只改 `ContentView` 表现层，不改变 `GameState` 命令与数值来源。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.65（HUD信息密度整理）.md`

验证结果：

- 本地仅 `git diff --check`；完整验证交给 GitHub Actions。

遗留事项：

- 后续可继续推进触控手感与侧栏信息层级优化。

### v1.66 / 触控手感与侧栏层级

日期：2026-07-12

核心变更：

- `InspectorPanel` 增加分区标题：主操作、战线态势、执行结果、敌情与反制、战报。
- 放大常用触控目标：单位详情整补/待命/取消、战术条图标按钮、编队条、定位条、部署按钮、结束回合与重开按钮。
- 本轮只改 `ContentView` 表现层，不改变侧栏数据来源与 `GameState` 命令。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.66（触控手感与侧栏层级）.md`

验证结果：

- 本地仅 `git diff --check`；完整验证交给 GitHub Actions。

遗留事项：

- 可继续推进图例/编队条视觉统一与更完整的窄屏适配。

### v1.67 / 图例与编队条视觉统一

日期：2026-07-12

核心变更：

- `MapLegendView` 增加标题条与指挥台背板，图例项统一到 `BattlefieldTheme` 质感。
- `ForceRibbon` 增加编队标题与盟军/轴心分区标签，编队按钮选中态使用阵营色强调。
- 本轮只改 `ContentView` 表现层，不改变图例条目集合与编队选择/定位逻辑。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.67（图例与编队条视觉统一）.md`

验证结果：

- 本地仅 `git diff --check`；完整验证交给 GitHub Actions。

遗留事项：

- 可继续窄屏适配与动态字体优化。

### v1.68 / 窄屏布局适配

日期：2026-07-12

核心变更：

- `ContentView` 引入中宽/宽断点：`>=760` 并排 inspector，`<760` 上下堆叠并给 inspector 动态高度。
- 地图 chrome 在宽度较窄时将 `MapCampaignHUD`/`MapActionHUD` 改为右侧紧凑叠放。
- 本轮只改 `ContentView` 布局表现，不改变 `GameState` 与命令入口。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.68（窄屏布局适配）.md`

验证结果：

- 本地仅 `git diff --check`；完整验证交给 GitHub Actions。

遗留事项：

- 可继续动态字体与更多面板微调。

### v1.69 / 动态字体与面板微调

日期：2026-07-12

核心变更：

- `VictoryPanel`、`ScenarioPanel`、`TileDetail`、`BattleLogView` 对齐战区指挥台卡片视觉。
- 战役规则说明改为统一规则行样式；据点徽章显示归属短码。
- 关键正文增加 `lineLimit`/`minimumScaleFactor`，胜利重开按钮保持 44pt 高度。
- 本轮只改 `ContentView` 表现层，不改变 `GameState` 文案数据源。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.69（动态字体与面板微调）.md`

验证结果：

- 本地仅 `git diff --check`；完整验证交给 GitHub Actions。

遗留事项：

- 可继续可玩性反馈与剩余面板微调。

### v1.70 / 单位详情层级与战术条视觉

日期：2026-07-12

核心变更：

- `UnitDetail` 增加单位头卡与状态/作战方案/指挥分区标题，保留全部原有子面板与主操作按钮。
- `TacticalOrderStrip`、`ReinforcementDock` 对齐 `BattlefieldTheme` 指挥台背板与标题色。
- 本轮只改 `ContentView` 表现层，不改变单位详情数据源与命令入口。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.70（单位详情层级与战术条视觉）.md`

验证结果：

- 本地仅 `git diff --check`；完整验证交给 GitHub Actions。

遗留事项：

- 可继续可玩性反馈与更多细面板视觉统一。

### v1.71 / 状态面板视觉统一

日期：2026-07-12

核心变更：

- `SupplyPanel`、`MoralePanel`、`ExperiencePanel`、`ThreatSummary` 统一为指挥台渐变卡片。
- `StatRows`/`StatBox`/`ActionBadge` 对齐 `BattlefieldTheme` 质感，并改善动态字体缩放。
- 本轮只改 `ContentView` 表现层，不改变补给/士气/经验/威胁规则。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.71（状态面板视觉统一）.md`

验证结果：

- 本地仅 `git diff --check`；完整验证交给 GitHub Actions。

遗留事项：

- 可继续可玩性反馈与剩余细面板微调。

### v1.72 / 作战规划面板可玩性视觉

日期：2026-07-12

核心变更：

- `ObjectiveAdvancePlanPanel`、`SafeEngagementOptionsPanel`、`TacticalCommandGroup`、`CommanderView` 对齐指挥台渐变卡片。
- 目标计划与安全接敌行提高最小高度，强化当前预览态可读性。
- 本轮只改 `ContentView` 表现层，不改变规划/战术命令规则与入口。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.72（作战规划面板可玩性视觉）.md`

验证结果：

- 本地仅 `git diff --check`；完整验证交给 GitHub Actions。

遗留事项：

- 可继续敌情/反制细面板微调。

### v1.73 / 敌情与反制面板视觉

日期：2026-07-12

核心变更：

- `EnemyThreatIntentPanel`、`EnemyThreatCountermeasurePanel` 对齐指挥台渐变卡片。
- 意图行与反制行提高最小高度，强化当前预览描边与数量胶囊。
- 本轮只改 `ContentView` 表现层，不改变威胁意图/反制建议生成与聚焦规则。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.73（敌情与反制面板视觉）.md`

验证结果：

- 本地仅 `git diff --check`；完整验证交给 GitHub Actions。

遗留事项：

- 可继续可玩性反馈增强与剩余细面板微调。

### v1.74 / 反制下一步与关联 AI 行动反馈

日期：2026-07-12

核心变更：

- `EnemyThreatCountermeasureExecutionHint` 升级为指挥台卡片，显示可执行/不可执行状态与入口说明。
- `EnemyThreatCountermeasureFollowUpAIEventRow` 提高触控高度与信息层级，便于定位关联 AI 复盘事件。
- 本轮只改 `ContentView` 表现层，不自动执行命令，不改变反制/复核规则。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.74（反制下一步与关联AI行动反馈）.md`

验证结果：

- 本地仅 `git diff --check`；完整验证交给 GitHub Actions。

遗留事项：

- 可继续剩余细面板与可玩性反馈增强。

### v1.75 / 态势响应与 AI 回放反馈强化

日期：2026-07-12

核心变更：

- `BattlefieldSituationResponseCard` 升级为指挥台渐变卡片，结果标题改为胶囊强调。
- `AIPhaseReplayControls` 增加播放态背板；`AIPhaseCurrentTimelineEventView` 强化当前事件编号与类型反馈。
- 本轮只改 `ContentView` 表现层，不改变响应历史导航与 AI 播放状态机。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.75（态势响应与AI回放反馈强化）.md`

验证结果：

- 本地仅 `git diff --check`；完整验证交给 GitHub Actions。

遗留事项：

- 可继续剩余细面板与可玩性反馈增强。

### v1.76 / 据点压力与复盘入口反馈

日期：2026-07-12

核心变更：

- `BattlefieldSituationObjectivePressureRow` 提高卡片层级与当前焦点态。
- `BattlefieldSituationReplayTargetButton` 对齐指挥台渐变卡片并增强入口描边。
- 本轮只改 `ContentView` 表现层，不改变压力排序与复盘定位规则。

关键文件：

- `WW2Tactics/WW2Tactics/ContentView.swift`
- `WW2Tactics/README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（地图操作体验）/v1.76（据点压力与复盘入口反馈）.md`

验证结果：

- 本地仅 `git diff --check`；完整验证交给 GitHub Actions。

遗留事项：

- 可继续剩余细面板与可玩性反馈增强。
