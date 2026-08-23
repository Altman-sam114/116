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

当前推进到 `v2.54（据点静态整格轮廓局部化）.md` 的实现阶段：Agent B 已按 prompt 完成 `BattlefieldMap.swift` 唯一五处 Swift 改动并同步本轮文档，冻结文件无 diff；本地只执行 Git/text 白名单检查。v2.54 的最新 commit、workflow run、attempt 和 artifact 由 push 后 Agent C 精确核对，本索引不预填未知 CI 事实。

v2.53 已完成最终云端闭环：文档闭环提交 `b6bd2a4349c5ea4c427d5fc181035c5366d89385` 对应 workflow run `32639356579`、attempt `1`、`completed/success`；artifact 为 `ww2tactics-ci-v2.53-main-b6bd2a4-run32639356579-attempt1`，artifact id `9493294466`，digest `sha256:bdbd51fe7b19190eb7b06ef10b3f67b2faed6f19dd711e90576a46aa4d71c478`。Agent C 已下载到 `/private/tmp/ww2tactics-c-review-32639356579/` 并精确核对，旧的“文档闭环提交待最新 run 复验”状态已关闭。

v2.52 已完成完整云端闭环：功能提交 `69dfd3f1e2530927ef9ec1c5fa59a066137bade2` 对应 workflow run `32633020222`、attempt `1` 和 artifact `ww2tactics-ci-v2.52-main-69dfd3f-run32633020222-attempt1`；最终文档闭环 SHA `27e21351187fffaf04aaa2e7362f840168a4f45b` 对应 workflow run `32633841924`、attempt `1`、artifact `ww2tactics-ci-v2.52-main-27e2135-run32633841924-attempt1`、artifact id `9491881137`、digest `sha256:ac9a381743dda8eff0d299806e3467b81f82a70e907ef205160fbefdf23a4c47`。最终结果包已由 Agent C 下载到 `/private/tmp/ww2tactics-c-review-32633841924/` 并精确核对，旧的“等待文档提交、push 和验收”状态已关闭。

v2.53 已在 `BattlefieldMap.swift` 的 `HexTileView.borderColor` 与 `borderWidth` 删除普通态 `isThreatenedMoveTile`、`isEnemyControlZone`、`isSupplyLine` 三组重复整格边框分支，共六行；threat/ZOC 红 wash、连续 `SupplyLineMarker`、`isAttackCoverage` 橙色 `0.40`/`1pt` 唯一射程边框、通用 stroke 和所有高优先级状态保持不变。功能 artifact 的 manifest、static、Rules smoke、Xcode 26.6 build-for-testing、JUnit、`.xcresult` 和 regular PNG 已由 Agent C 核对；PNG 为 `2064×2752`、`5,589,062 bytes`、8-bit RGBA、non-interlaced，SHA-256 为 `3bfd75abb47a01931709e589d625ec5da00e863a9b8c8b48150d89121556c344`，红 ZOC/绿 supply 整格边减少且 red wash/连续补给线保留。XCTest 执行仍 skipped；两条 AppIntents warning 与 Node/punycode/`url.parse` 提醒为非致命维护信息。

历史阶段 v2.0-v2.53 已完成地图优先构图、白昼底材、地貌连续性、军械、据点、轨道、材质、河道、蚀刻边界、道路路基、战果反馈、平原雪地连续晕染与控制区/威胁/补给边框去重等表现层迭代；各轮 prompt 和云端证据仍保留在本目录与 `update_log.md`，当前轮次见上方 v2.54 条目。
