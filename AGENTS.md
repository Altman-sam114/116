# AGENTS.md

本文是 `WW2Tactics` 项目的入口记忆、总览、基本规则和多 Agent 迭代工作流。

## 1. 项目总览

`WW2Tactics` 是一个 SwiftUI iOS 二战回合制战棋原型，目标是持续逼近 EasyTech《World Conqueror 4》《Glory of Generals》一类“大地图、多据点、单位移动、攻击判定、将领与地形规则”的可玩体验。

## 2. 必读文件

每个 Agent 动手前按顺序阅读：

1. `AGENTS.md`：入口规则和 Agent 协作方式。
2. `update_log.md`：历史决策、完成事项、遗留问题。
3. `md/flow/flow.md`：当前真实核心逻辑。
4. `md/flow/flowchart.md`：核心数据流、执行流和 Agent 迭代流。
5. `md/test/test.md`：测试分层、命令、触发条件。
6. `WW2Tactics/README.md`：面向使用者的项目现状和运行方式。
7. 与任务相关的源码、测试和 prompt 文件。

## 3. 角色召唤和身份标识

- 用户消息以 `agenta`、`a:` 或 `A:` 开头，表示召唤 Agent A。
- 用户消息以 `agentb`、`b:` 或 `B:` 开头，表示召唤 Agent B。
- 用户消息以 `agentc`、`c:` 或 `C:` 开头，表示召唤 Agent C。
- 没有这些前缀时，按普通 Codex 任务处理；若任务需要 A/B/C 边界，先提醒用户指定角色或说明本轮按普通任务执行。
- Agent A 最终回复第一行必须写：`我是 Agent A。`
- Agent B 最终回复第一行必须写：`我是 Agent B。`
- Agent C 最终回复第一行必须写：`我是 Agent C。`

## 4. 项目基本规则

- 以当前工作树为权威，不凭旧对话记忆判断项目状态。
- 优先推进地图可玩性、操作反馈、战棋规则和测试覆盖。
- 不把项目做成静态展示页或营销页；首屏和主要工作必须服务于地图操作。
- 有用户可见行为变化时，同步更新 `WW2Tactics/README.md`。
- 有核心逻辑变化时，同步更新 `md/flow/flow.md` 和 `md/flow/flowchart.md`。
- 有测试策略、命令或基线变化时，同步更新 `md/test/test.md`。
- 每个正式版本、重要任务或历史决策写入 `update_log.md`。

## 5. 核心架构边界

- `WW2Tactics/WW2Tactics/GameModels.swift`：数据模型、枚举、战役定义、地图格、单位、命令预览类型。
- `WW2Tactics/WW2Tactics/GameState.swift`：核心规则状态机。移动、攻击、AI、补给、控制区、目标推进、战术命令、增援、胜负和威胁覆盖放这里。
- `WW2Tactics/WW2Tactics/ContentView.swift`：SwiftUI 表现层。地图、HUD、侧栏、图例、输入事件、视觉标记放这里。
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`：XCTest 规则和交互行为测试。
- `WW2Tactics/Tools/RulesSmokeTest.swift`：命令行 smoke test，覆盖主规则链。

禁止把复杂规则写进 View，禁止用 UI 状态绕过 `GameState`。

## 6. main 直推和云端验证规则

- 当前固定使用 `main` 作为唯一上传、提交、推送和云端验证分支。
- 暂不设计 `smalldata_test`、`develop`、`codeb/...` 或其他长期/候选分支；不创建 PR 或 PR merge 流程。
- Agent B 每轮开始前必须执行或核对：

```sh
git fetch origin
git switch main
git pull --ff-only origin main
git status --short --branch
```

- 若仓库未配置 `origin/main` 或没有推送权限，必须停止在 push 前并说明阻塞；不得伪装已经云端验证。
- Agent B 完成本轮改动后，本地只跑 `md/test/test.md` 要求的轻量检查，随后在 `main` 提交并直接 `git push origin main` 触发 GitHub Actions。
- Agent C 只验收 `origin/main` 最新 commit 对应的 workflow run、`commitSha`、`runId`、`runAttempt` 和 artifact。
- Agent C 必须用 `gh auth login` 后下载未加密 CI 结果包；下载缓存默认放在 `/private/tmp/ww2tactics-c-review-<run_id>/`。
- Agent C 发现问题时，不回滚远端 `main`；默认退回 Agent B 在 `main` 上追加修复 commit 并重新 push。
- 任何 Agent 在 `git push origin main` 或改变远端 `main` 前，必须确认当前分支是 `main`，目标远端是 `origin/main`，提交范围只包含本轮相关文件。

## 7. 标准迭代工作流

### 人工

人工提出目标、限制、验收标准和测试要求。人工复核 Agent C 的验收结论后进入下一轮。

### Agent A：目标分析与提示词

Agent A 默认不直接写代码，负责把人工目标变成给 Agent B 的详细实现提示词。

必须执行：

1. 阅读本文件、`update_log.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/test/test.md`。
2. 阅读相关源码、测试和 README。
3. 明确本轮目标、非目标、边界、风险和验收标准。
4. 设计实现方案：模块、数据流、状态流、测试、文档更新。
5. 确定版本号。人工指定则使用人工版本；否则从当前 prompt 目录自动递增。
6. 写入 `md/prompt/vN（阶段名）/vN.x（任务名）.md`。

Agent A 的 prompt 必须包含：版本号、版本分配依据、背景、目标、非目标、架构依据、实现步骤、关键文件、测试要求、文档更新要求、验收标准、风险和禁止项。

### Agent B：实现与测试

Agent B 按 Agent A prompt 实现。

必须执行：

1. 阅读 Agent A prompt 和所有必读文件。
2. 同步最新 `origin/main`，确认位于 `main` 且工作区没有无关改动。
3. 小步实现，不做无关重构。
4. 新增或修改测试。
5. 按 `md/test/test.md` 选择本地轻量检查；除非人工明确要求，不默认本机完整 build。
6. 更新 README、flow、test、update_log 中需要同步的内容。
7. 提交本轮相关文件并 `git push origin main`，等待 GitHub Actions 生成结果包。
8. 输出改动、关键文件、本地轻量检查、commit、push、workflow run、artifact、未跑测试原因、风险和后续建议。

### Agent C：验收与核心逻辑更新

Agent C 负责验收 Agent B 推到 `origin/main` 的结果。

必须执行：

1. 阅读 Agent B 输出、实际 diff、Actions 结果包和必读文件。
2. 核对实现是否满足 Agent A prompt 和人工目标。
3. 确认 `origin/main` 最新 commit 与结果包 manifest 的 `commitSha` 完全一致。
4. 检查 `ci-artifact-manifest.json`、`ci-failure-summary.md`、`junit.xml`、主构建日志和项目专属结果文件。
5. 检查架构边界、测试覆盖、文档同步和未说明风险。
6. 必要时更新 `md/flow/flow.md`、`md/flow/flowchart.md` 和 `update_log.md`；若 Agent C 自己产生提交，也必须推送并重新核对最新 run。
7. 若不通过：明确问题清单、缺失测试、风险和需要 Agent B 追加修复 commit 的具体点，不得宣称验收通过。
8. 若通过：确认 `origin/main` 最新 run 通过，并输出 commit、run、artifact 和核对结论。

### 默认验证策略

- 默认云端重验证，本机只跑轻量检查。
- 只有人工明确说“本机测试”“本地 build”“本地跑探针”“本地 xcodebuild”等，Agent 才把本机完整构建或模拟器验证作为默认路径。
- 文档-only 修改至少跑 `git diff --check`；workflow 修改还要做 YAML 解析，Xcode project 修改还要跑 `plutil -lint`。
- Swift / Xcode / 规则 / UI 相关改动完成后，默认 commit 并 push 到 `origin/main`，由 GitHub Actions 运行重验证并上传未加密结果包。
- 云端失败时，Agent B 根据结果包中的失败摘要、日志路径和 manifest，在 `main` 上追加修复 commit 并继续 push。

### 版本提交规则

- Agent B 实现版本时，提交信息按版本号管理，推荐格式：

```text
vN.x: 简要说明本版本做了什么
```

- Agent C 不验收本地半成品，只验收 `origin/main` 最新 commit 的云端结果包。
- 不通过时，必须退回 Agent B 在 `main` 追加修复；不得提交或确认半成品。
- 提交前必须确认测试结果、文档同步和工作树 diff。
- 提交应包含本轮版本涉及的源码、测试和文档。
- 如需提交正文，正文只写高信号概括：核心变更、测试结果、遗留风险。

示例：

```text
v0.5: 升级 main 直推云端验证流程
v1.0: 增强地图拖拽和路径预览
```

## 8. 测试规则

- 每次实现前先读 `md/test/test.md`。
- 默认本地只跑轻量检查，云端 GitHub Actions 负责重验证。
- 核心规则改动的云端重验证必须包含 smoke test。
- SwiftUI 或源码结构改动的云端重验证必须包含 Xcode build 或等价 typecheck。
- 测试结果必须写具体命令和结果，不得写“已验证”代替。
- 不能伪造测试通过；未跑必须说明环境或范围原因。
- 不能下载 artifact 时必须说明权限、登录或远端配置阻塞。

## 9. 文档规则

- `AGENTS.md` 只写入口规则和协作方式，不堆历史细节。
- `update_log.md` 记录版本、重要维护事项、关键决策、遗留问题。
- `md/flow/flow.md` 只写当前真实核心逻辑，不写历史流水账。
- `md/flow/flowchart.md` 用中文说明和 Mermaid 图表达当前逻辑。
- `md/test/test.md` 写测试分层、命令、触发条件和当前基线。
- `md/prompt/` 保存每轮 Agent A 的详细实现提示词。

## 10. 交付格式

最终回复必须包含：

- 创建或修改了哪些文件。
- 每个文件的作用。
- 运行了哪些验证命令和结果。
- 哪些测试没跑及原因。
- 当前分支、commit SHA、workflow run id、run attempt、artifact 名称。
- 是否已 push 到 `origin/main`。
- Agent C 是否下载并核对结果包；未下载时说明原因。
- 下一步建议。

## 11. 禁止项

- 不得重置、回滚或删除用户/其他 Agent 改动，除非用户明确要求。
- 不得绕过 `GameState` 直接在 View 中实现核心规则。
- 不得新增不可测试的核心玩法状态。
- 不得只做视觉装饰而不改善可玩性。
- 不得把 Xcode/模拟器环境失败说成测试失败或测试通过。
- 不得让 README、flow、test、update_log 与真实代码状态不一致。
- 不得引入第三方库、网络依赖或复杂资产管线，除非人工明确同意。
- 不得把旧 artifact、旧 output 或 checkout 自带报告冒充本轮云端结果。
- 不得在 Agent C 验收不通过时宣称版本通过。
- 不得使用模糊提交信息，例如 `update`、`fix`、`1`。
