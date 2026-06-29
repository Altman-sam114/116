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

## 3. 项目基本规则

- 以当前工作树为权威，不凭旧对话记忆判断项目状态。
- 优先推进地图可玩性、操作反馈、战棋规则和测试覆盖。
- 不把项目做成静态展示页或营销页；首屏和主要工作必须服务于地图操作。
- 有用户可见行为变化时，同步更新 `WW2Tactics/README.md`。
- 有核心逻辑变化时，同步更新 `md/flow/flow.md` 和 `md/flow/flowchart.md`。
- 有测试策略、命令或基线变化时，同步更新 `md/test/test.md`。
- 每个正式版本、重要任务或历史决策写入 `update_log.md`。

## 4. 核心架构边界

- `WW2Tactics/WW2Tactics/GameModels.swift`：数据模型、枚举、战役定义、地图格、单位、命令预览类型。
- `WW2Tactics/WW2Tactics/GameState.swift`：核心规则状态机。移动、攻击、AI、补给、控制区、目标推进、战术命令、增援、胜负和威胁覆盖放这里。
- `WW2Tactics/WW2Tactics/ContentView.swift`：SwiftUI 表现层。地图、HUD、侧栏、图例、输入事件、视觉标记放这里。
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`：XCTest 规则和交互行为测试。
- `WW2Tactics/Tools/RulesSmokeTest.swift`：命令行 smoke test，覆盖主规则链。

禁止把复杂规则写进 View，禁止用 UI 状态绕过 `GameState`。

## 5. 标准迭代工作流

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
2. 小步实现，不做无关重构。
3. 新增或修改测试。
4. 按 `md/test/test.md` 选择测试层级并运行。
5. 更新 README、flow、test、update_log 中需要同步的内容。
6. 输出改动、关键文件、测试命令和结果、未跑测试原因、风险和后续建议。

### Agent C：验收与核心逻辑更新

Agent C 负责验收 Agent B 的结果。

必须执行：

1. 阅读 Agent B 输出、实际 diff、测试结果和必读文件。
2. 核对实现是否满足 Agent A prompt 和人工目标。
3. 检查架构边界、测试覆盖、文档同步和未说明风险。
4. 更新 `md/flow/flow.md` 和 `md/flow/flowchart.md`。
5. 必要时更新 `update_log.md`。
6. 若不通过：明确问题清单、缺失测试、风险和需要 Agent B 回退/修复的具体点，不得提交。
7. 若通过：按本轮版本号自动创建 git 提交，提交说明必须简要概括该版本做了什么。
8. 输出通过/不通过、问题清单、已更新文档、git 提交信息和下一步建议。

### 版本提交规则

- Agent C 只有在最终验收通过后才能提交。
- 不通过时，必须退回 Agent B 修复；不得提交半成品。
- 提交前必须确认测试结果、文档同步和工作树 diff。
- 提交应包含本轮版本涉及的源码、测试和文档。
- 提交信息按版本号管理，推荐格式：

```text
vN.x: 简要说明本版本做了什么
```

示例：

```text
v0.4: 规范 Agent C 验收提交流程
v1.0: 增强地图拖拽和路径预览
```

- 如需提交正文，正文只写高信号概括：核心变更、测试结果、遗留风险。

## 6. 测试规则

- 每次实现前先读 `md/test/test.md`。
- 默认从最小测试开始，根据改动范围扩大。
- 核心规则改动至少跑 smoke test。
- SwiftUI 或源码结构改动至少跑 SwiftUI typecheck。
- 测试结果必须写具体命令和结果，不得写“已验证”代替。
- 不能伪造测试通过；未跑必须说明环境或范围原因。

## 7. 文档规则

- `AGENTS.md` 只写入口规则和协作方式，不堆历史细节。
- `update_log.md` 记录版本、重要维护事项、关键决策、遗留问题。
- `md/flow/flow.md` 只写当前真实核心逻辑，不写历史流水账。
- `md/flow/flowchart.md` 用中文说明和 Mermaid 图表达当前逻辑。
- `md/test/test.md` 写测试分层、命令、触发条件和当前基线。
- `md/prompt/` 保存每轮 Agent A 的详细实现提示词。

## 8. 交付格式

最终回复必须包含：

- 创建或修改了哪些文件。
- 每个文件的作用。
- 运行了哪些验证命令和结果。
- 哪些测试没跑及原因。
- Agent C 通过时的 git 提交哈希和提交说明；未提交时说明原因。
- 下一步建议。

## 9. 禁止项

- 不得重置、回滚或删除用户/其他 Agent 改动，除非用户明确要求。
- 不得绕过 `GameState` 直接在 View 中实现核心规则。
- 不得新增不可测试的核心玩法状态。
- 不得只做视觉装饰而不改善可玩性。
- 不得把 Xcode/模拟器环境失败说成测试失败或测试通过。
- 不得让 README、flow、test、update_log 与真实代码状态不一致。
- 不得引入第三方库、网络依赖或复杂资产管线，除非人工明确同意。
- 不得在 Agent C 验收不通过时提交版本。
- 不得使用模糊提交信息，例如 `update`、`fix`、`1`。
