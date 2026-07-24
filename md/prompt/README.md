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

当前已进入 `v2（六角格战争界面）`。v2.0-v2.6 完成表现层拆分、云端截图链、地图优先布局、地貌自然化、单位结构和满幅战区；v2.7 收敛空闲 HUD 并加入战斗准星；v2.8 让地图军械模型脱离大面积徽章底板；v2.9 强化地貌纵深；v2.10 建立选中/POS 云端截图场景；v2.11 根据该截图收敛非焦点 MOVE、ATK、POS 和 THR 标记。下一轮应根据 v2.11 artifact 决定继续压低覆盖层边界强度，或进入攻击判定卡和短促战斗反馈动效。
