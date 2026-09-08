# Prompt 目录

本目录保存每轮 Agent A 写给 Agent B 的详细实现提示词。

## 角色召唤

- 用户消息以 `agenta`、`a:` 或 `A:` 开头，表示召唤 Agent A。
- 用户消息以 `agentb`、`b:` 或 `B:` 开头，表示召唤 Agent B。
- 用户消息以 `agentc`、`c:` 或 `C:` 开头，表示召唤 Agent C。
- 用户消息以 `agentx`、`x:` 或 `X:` 开头，表示召唤 Agent X。
- 没有这些前缀时，按普通 Codex 任务处理；若任务需要 A/B/C/X 边界，先提醒用户指定角色或说明本轮按普通任务执行。
- Agent A 最终回复第一行必须写：`我是 Agent A。`
- Agent B 最终回复第一行必须写：`我是 Agent B。`
- Agent C 最终回复第一行必须写：`我是 Agent C。`
- Agent X 最终回复第一行必须写：`我是 Agent X。`

## 命名规则

推荐格式：

- `md/prompt/v0（项目初始化）/v0.1（建立迭代文档）.md`
- `md/prompt/v0（项目初始化）/v0.2（优化测试规范）.md`
- `md/prompt/v1（核心功能）/v1.0（实现主流程）.md`
- `md/prompt/v1（核心功能）/v1.1（修复主流程问题）.md`

## 版本规则

- Agent A 每次写提示词都必须写入版本号。
- 人工指定版本时，以人工指定为准。
- 人工未指定版本时，Agent A 自动判断版本，从当前最大版本递增。
- 同一阶段的小任务、修复、优化递增小版本，例如 `v0.1` -> `v0.2` -> `v0.3`。
- 大任务、架构阶段、核心功能阶段或重要里程碑新开大版本，例如 `v0.x` -> `v1.0`。
- 同一大版本下的提示词放在同一个目录：`md/prompt/v0（简要标题）/`、`md/prompt/v1（简要标题）/`。
- 文件名使用 `v0.1（简要说明）.md`，说明要短，能表达本轮目标。

## 每份提示词必须包含

- 版本号。
- 版本分配依据。
- 背景。
- 目标。
- 非目标。
- 当前架构依据。
- 实现步骤。
- 关键文件。
- 测试要求。
- 文档更新要求。
- 验收标准。
- 风险和禁止项。

## Agent X 提示词管理规则

- Agent X 可以围绕人工总目标 X 拆分多轮任务，并要求 Agent A 为每轮生成版本化提示词。
- Agent X 不直接替代 Agent A 写正式实现提示词；每轮仍应产出 `md/prompt/vN（阶段）/vN.x（任务）.md`。
- 每轮提示词必须包含本轮目标、非目标、验证要求、CI 触发方式、artifact 内容、Agent C 下载和验收要求。
- 每轮提示词必须说明本轮是否允许 Agent B 提交和 `git push origin main`；默认遵循 `main` 直推和云端 artifact 验收流程。
- Agent X 进入下一轮前，必须确认上一轮 Agent C 已核对最新 `origin/main` commit、workflow run、run attempt 和 artifact。
- Agent C 验收不通过时，Agent X 只能要求 Agent B 追加修复 commit，不能生成下一轮新功能提示词伪装通过。

## 云端阶段要求

Agent A 写给 Agent B 的提示词必须包含：

- 当前固定使用 `main` 作为唯一上传、提交、推送和云端验证分支。
- 本轮不使用 `smalldata_test`、`develop`、`codeb/...` 或 PR 流程。
- Agent B 开始前同步最新 `origin/main`，确认当前分支是 `main`，工作区没有无关改动。
- Agent B 完成后先跑本地轻量检查，再用 `vN.x: 简要说明` 提交并 `git push origin main`。
- GitHub Actions 必须生成未加密 CI 结果包，至少包含 `ci-artifact-manifest.json`、`ci-failure-summary.md`、`junit.xml`、主构建日志和项目专属结果文件。
- Swift / Xcode / 规则 / UI 改动的云端重验证必须包含规则 smoke test 和 Xcode build 或等价 typecheck。
- Agent C 必须用 `gh auth login` 后下载 artifact 到 `/private/tmp/ww2tactics-c-review-<run_id>/`。
- Agent C 必须核对 manifest 的 `branch=main`、`commitSha`、`runId`、`runAttempt` 与 `origin/main` 最新状态一致。
- 云端失败时，Agent C 写退回清单；Agent B 在 `main` 上追加修复 commit 并重新 push。
- 若仓库没有 `origin/main` 或没有 artifact 下载权限，Agent 必须停止并说明阻塞，不能伪装云端验证完成。

## 当前建议

当前 `v2.55（六角地貌底色连续化）.md` 功能已通过：功能提交 `0344bd67f4ff7f2e3f526b413ca697a67df33cfc` 的 `WW2Tactics CI Results` workflow_dispatch run `34172993990`、attempt `1` 为 `completed/success`，活动账号为 `Altman-sam114`。Agent C 已下载并核对唯一 exact artifact `ww2tactics-ci-v2.55-main-0344bd6-run34172993990-attempt1`（id `10036475656`，digest `sha256:41c43c57267fcc3b607e96a117b6ecf5b25cc28decd2bfcc2d4c964b4f56372e`，API size `7,034,095 bytes`，解包 `9.5M`，目录 `/private/tmp/ww2tactics-c-review-34172993990/`）。manifest 的 `version=v2.55`、`branch=main`、commitSha、runId、runAttempt、workflow 精确匹配；static project check、Rules smoke、build-for-testing、JUnit（4 stages、0 failures、0 errors、0 skipped）和可读 `.xcresult` 均通过，XCTest 实际 skipped。exact regular PNG 为 `selected-combat-impact-steady`（iPad Pro 13-inch (M5)、iOS 26.5 simulator），`2064x2752`、8-bit RGBA、non-interlaced、`5,808,590 bytes`，SHA-256 `1e3d32570a83f6497219b2fd1179dc784d58e8d085d44244a1f3f004e1c3fd6c`；底色连续化可见且地图、战术状态与 HUD 无明显回归。Swift 仅 `BattlefieldMap.swift` 一行 `mapGradient.opacity(0.78)`，冻结链无 diff；v2.54 objective fallback 未恢复，v2.50-v2.53 链保持。两条 AppIntents warning 与 Actions Node.js 20、`punycode`、`url.parse()` 弃用提示为非致命。regular 不证明 compact、窄宽、Dynamic Type、VoiceOver、Reduce Motion、多焦点、4x 或未激活状态。本次仅补录功能证据：文档闭环提交的新 SHA/run/attempt/artifact 尚未生成，不能预填、自引用或宣称已验收。

当前 `v2.54（据点静态整格轮廓局部化）.md` 功能已通过，文档闭环提交待最新 run 复验：功能提交为 `6cc5c378d9a0906b4ffce319e6c4a1637e4073f6`，对应 workflow run `32647289526`、attempt `1`、状态 `completed/success`；Agent C 已核对 artifact `ww2tactics-ci-v2.54-main-6cc5c37-run32647289526-attempt1`（id `9495311729`，digest `sha256:3d12474ebcba78629ecb457db9266d38f985b2e58ff627d72994d45653c7c071`，API size `6,797,996 bytes`，目录 `/private/tmp/ww2tactics-c-review-32647289526/`）。manifest 的 `version=v2.54`、`branch=main`、commit/run/attempt 完全匹配；static checks、Rules smoke、Xcode build-for-testing、JUnit 和 `xcresult` 均符合功能验收，实际 XCTest 为 skipped。regular PNG 为 `2064x2752`、8-bit RGBA、non-interlaced、`5,573,657 bytes`，SHA-256 为 `626362a33d1b44e8ecd5db9fbdbbc71f843f45d4929719ec8f8ae42a2a5ee7d7`；静态据点粗边减少、局部据点身份和 selected/combat-response 反馈保留且无明显回归。XCTest skipped、2 个非致命 AppIntents metadata warnings 以及 regular-only 限制仍如实保留；attack-focus/latest capture/guided/AI/实时命令/route/compact/窄宽/`xxxLarge`/多焦点/VoiceOver/Reduce Motion/4x 仅源码审查。即将生成的文档闭环 commit、run、attempt、artifact 和 digest 不预填。

v2.53 已完成最终云端闭环：文档闭环提交 `b6bd2a4349c5ea4c427d5fc181035c5366d89385` 对应 workflow run `32639356579`、attempt `1`、`completed/success`；artifact 为 `ww2tactics-ci-v2.53-main-b6bd2a4-run32639356579-attempt1`，artifact id `9493294466`，digest `sha256:bdbd51fe7b19190eb7b06ef10b3f67b2faed6f19dd711e90576a46aa4d71c478`。Agent C 已下载到 `/private/tmp/ww2tactics-c-review-32639356579/` 并精确核对，旧的“文档闭环提交待最新 run 复验”状态已关闭。

v2.52 已完成完整云端闭环：功能提交 `69dfd3f1e2530927ef9ec1c5fa59a066137bade2` 对应 workflow run `32633020222`、attempt `1` 和 artifact `ww2tactics-ci-v2.52-main-69dfd3f-run32633020222-attempt1`；最终文档闭环 SHA `27e21351187fffaf04aaa2e7362f840168a4f45b` 对应 workflow run `32633841924`、attempt `1`、artifact `ww2tactics-ci-v2.52-main-27e2135-run32633841924-attempt1`、artifact id `9491881137`、digest `sha256:ac9a381743dda8eff0d299806e3467b81f82a70e907ef205160fbefdf23a4c47`。最终结果包已由 Agent C 下载到 `/private/tmp/ww2tactics-c-review-32633841924/` 并精确核对，旧的“等待文档提交、push 和验收”状态已关闭。

v2.53 已在 `BattlefieldMap.swift` 的 `HexTileView.borderColor` 与 `borderWidth` 删除普通态 `isThreatenedMoveTile`、`isEnemyControlZone`、`isSupplyLine` 三组重复整格边框分支，共六行；threat/ZOC 红 wash、连续 `SupplyLineMarker`、`isAttackCoverage` 橙色 `0.40`/`1pt` 唯一射程边框、通用 stroke 和所有高优先级状态保持不变。功能 artifact 的 manifest、static、Rules smoke、Xcode 26.6 build-for-testing、JUnit、`.xcresult` 和 regular PNG 已由 Agent C 核对；PNG 为 `2064×2752`、`5,589,062 bytes`、8-bit RGBA、non-interlaced，SHA-256 为 `3bfd75abb47a01931709e589d625ec5da00e863a9b8c8b48150d89121556c344`，红 ZOC/绿 supply 整格边减少且 red wash/连续补给线保留。XCTest 执行仍 skipped；两条 AppIntents warning 与 Node/punycode/`url.parse` 提醒为非致命维护信息。

历史阶段 v2.0-v2.53 已完成地图优先构图、白昼底材、地貌连续性、军械、据点、轨道、材质、河道、蚀刻边界、道路路基、战果反馈、平原雪地连续晕染与控制区/威胁/补给边框去重等表现层迭代；各轮 prompt 和云端证据仍保留在本目录与 `update_log.md`，当前轮次见上方 v2.54 条目。
