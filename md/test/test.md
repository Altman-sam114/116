# 测试规范

本文指导 Agent B、Agent C 和未来 Agent X 循环选择测试层级、记录命令和判断当前基线。

## 1. 默认策略

- 默认云端重验证，本机只跑轻量检查。
- 只有人工明确说“本机测试”“本地 build”“本地跑探针”“本地 xcodebuild”等，Agent 才把本机完整构建或模拟器验证作为默认路径。
- 文档-only 修改至少运行 `git diff --check`。
- workflow 修改还必须本地解析 YAML。
- Xcode project 修改还必须运行 `plutil -lint WW2Tactics/WW2Tactics.xcodeproj/project.pbxproj`。
- Swift / Xcode / 规则 / UI 相关改动完成后，默认由 Agent B commit 并 `git push origin main`，让 GitHub Actions 运行重验证。
- 若人工明确要求“不做本地测试，全部云端”，本地轻量检查可在该轮跳过；交付必须明确列出未跑本地命令及原因，并由 GitHub Actions artifact 覆盖 `git diff --check`、project plist、规则 smoke 和 Xcode build-for-testing。
- 地图格、单位棋子、地图标记槽位折叠、命令预览 helper 去重、后勤与战术结果卡视觉、反制回放/复核卡视觉、HUD 信息密度、触控手感与侧栏层级、图例与编队条视觉、窄屏布局适配、动态字体与面板微调、单位详情层级与战术条视觉、HUD、侧栏、战斗预览/结果卡、战线态势指挥简报、AI 战况回放和主题样式等纯 UI 表现层改动仍必须通过云端 Xcode build-for-testing；若该轮跳过本地测试，不能把本地未跑命令写成已验证。
- 战线态势、据点压力、压力来源标识、压力态势对照、压力敌方回合影响、压力复盘线索、战线态势复盘影响来源筛选、反制建议或地图入口变化必须覆盖只读定位边界：点选入口可改变选择、焦点、引导、AI 复盘 order 和消息，但不得消耗行动或改变单位、据点、指令点、战报、latest result、AI summary 或 follow-up。
- Agent C 必须下载未加密 CI 结果包，不能只看 Agent B 的文字汇报。
- Agent X 循环下，每轮仍以 Agent B 本地轻量检查、GitHub Actions artifact、Agent C 下载复判为准。
- 不能运行、不能 push 或不能下载 artifact 时，必须说明缺少远端、权限、登录、Xcode、runner 或模拟器环境中的哪一项。

## 2. Agent X 循环验证规则

- Agent X 可以拆分总目标并调度多轮，但每轮验证链路仍是 `Agent B 本地轻量检查 -> git push origin main -> GitHub Actions artifact -> Agent C 下载复判`。
- Agent X 不得跳过 Agent C artifact 验收，也不得只凭 Agent B 文字汇报进入下一轮。
- Agent C 验收不通过时，Agent X 必须退回 Agent B 追加修复 commit，不能继续下一轮或伪装成功。
- 每轮只认最新 `origin/main` commit 对应的 workflow run、`runAttempt` 和 artifact；旧 run、旧 artifact、本地 output 或 checkout 自带报告都不能作为通过依据。
- 若 CI 连续失败且原因相同、连续 3 轮遇到同一阻塞、连续 2 轮没有有效 diff，Agent X 必须暂停并交还人工决策。
- 若需要账号、权限、密钥、付费服务、下载大体积数据或人工产品决策，Agent X 必须停止等待人工确认。

## 3. 测试数据与下载容量限制

本项目默认采用小数据量验证策略，避免下载过大 artifact、模型、数据集、缓存或结果包，把本机、CI runner 或临时目录容量撑爆。

规则：

- 测试数据必须尽量小，只覆盖必要边界。
- CI artifact 只上传必要文件：manifest、JUnit 或测试摘要、关键日志、失败摘要、必要结果包。
- 不上传大体积 DerivedData、完整 build cache、无关截图、视频、模型文件、历史 artifact 或重复压缩包。
- Agent C 下载 artifact 前优先确认只下载最新 run 对应的必要结果包。
- 下载缓存默认放在 `/private/tmp/ww2tactics-c-review-<run_id>/`。
- 下载后应检查目录大小：

```sh
du -sh /private/tmp/ww2tactics-c-review-<run_id>/
```

- 禁止使用非 `Altman-sam114` 的 GitHub 账号伪装完成 push、CI 或 artifact 验收。
- 禁止默认下载大体积测试数据、模型、历史 artifact 或无关产物。

## 4. 本地轻量检查

### 4.1 文档和空白检查

触发条件：

- 任何文档-only 修改。
- 提交前最终检查。

命令：

```sh
git diff --check
```

预期结果：

- 无输出，退出码为 0。

### 4.2 GitHub Actions YAML 检查

触发条件：

- 新增或修改 `.github/workflows/ci-results.yml`。

命令：

```sh
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
```

预期结果：

```text
yaml ok
```

### 4.3 Xcode project plist 检查

触发条件：

- 修改 `WW2Tactics/WW2Tactics.xcodeproj/project.pbxproj`。
- Agent C 需要快速确认 project 文件未损坏。

命令：

```sh
plutil -lint WW2Tactics/WW2Tactics.xcodeproj/project.pbxproj
```

预期结果：

```text
WW2Tactics/WW2Tactics.xcodeproj/project.pbxproj: OK
```

## 5. 云端重验证

### 5.1 触发方式

默认 workflow：`.github/workflows/ci-results.yml`

触发条件：

```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:
```

Agent B 默认流程：

```sh
git fetch origin
git switch main
git pull --ff-only origin main
git status --short --branch
git add 相关文件
git commit -m "vN.x: 简要说明本轮做了什么"
git push origin main
```

若 `origin/main` 不存在或无权限 push，停止并说明原因，不得伪装云端验证已完成。

### 5.2 云端检查内容

GitHub Actions 至少运行：

- `git diff --check`
- `plutil -lint WW2Tactics/WW2Tactics.xcodeproj/project.pbxproj`
- 规则 smoke test 编译和执行
- `xcodebuild build-for-testing CODE_SIGNING_ALLOWED=NO`
- 结果包 manifest 生成
- JUnit 摘要生成
- failure summary 生成
- artifact 上传

项目专属重验证产物：

- `ci-results/rules-smoke.log`
- `ci-results/xcodebuild.log`
- `ci-results/junit.xml`
- `ci-results/ci-failure-summary.md`
- `ci-results/ci-artifact-manifest.json`
- `ci-results/WW2Tactics.xcresult`

### 5.3 CI artifact 命名

建议格式：

```text
ww2tactics-ci-vX.Y-main-<short_sha>-run<run_id>-attempt<run_attempt>
```

### 5.4 manifest 必须包含

`ci-artifact-manifest.json` 至少包含：

```json
{
  "version": "vX.Y",
  "branch": "main",
  "commitSha": "...",
  "shortSha": "...",
  "runId": "...",
  "runAttempt": "...",
  "workflowName": "WW2Tactics CI Results",
  "createdAt": "...",
  "projectName": "WW2Tactics",
  "scheme": "WW2Tactics",
  "destination": "generic/platform=iOS Simulator",
  "resultBundlePath": "ci-results/WW2Tactics.xcresult",
  "junitPath": "ci-results/junit.xml",
  "buildLogPath": "ci-results/xcodebuild.log",
  "failureSummaryPath": "ci-results/ci-failure-summary.md",
  "staticChecksOutcome": "success/failure",
  "smokeTestOutcome": "success/failure/skipped",
  "buildOutcome": "success/failure",
  "testOutcome": "skipped",
  "projectSpecificReports": ["ci-results/rules-smoke.log"]
}
```

## 6. Agent C 下载和验收

Agent C 必须先登录 GitHub CLI：

```sh
gh auth login
```

下载缓存默认放在：

```text
/private/tmp/ww2tactics-c-review-<run_id>/
```

推荐下载流程：

```sh
mkdir -p /private/tmp/ww2tactics-c-review-<run_id>
gh run download <run_id> \
  --name <artifact_name> \
  --dir /private/tmp/ww2tactics-c-review-<run_id>
```

Agent C 必须核对：

- `git ls-remote origin main` 的 commit 是否等于 manifest 的 `commitSha`。
- manifest 的 `branch` 是否为 `main`。
- manifest 的 `runId` 和 `runAttempt` 是否等于本次 Actions run。
- `ci-failure-summary.md` 是否记录成功或失败原因。
- `junit.xml` 是否存在并能说明静态检查、smoke 和 build 结果。
- `xcodebuild.log` 和 `rules-smoke.log` 是否来自本次 run。
- `.xcresult` 是否存在；若缺失，manifest 和 failure summary 必须说明原因。
- 下载目录大小是否合理，必要时运行 `du -sh /private/tmp/ww2tactics-c-review-<run_id>/`。

CI 失败时，Agent C 写退回清单；Agent B 在 `main` 上追加修复 commit 并重新 push。

## 7. 人工明确要求时的本机构建命令

以下命令不是默认路径，只有人工明确要求或排查云端失败时才运行。

### 7.1 Probe / Fast

触发条件：

- 修改 `GameModels.swift`、`GameState.swift` 或规则测试。
- 修改地图命令判定、移动、攻击、补给、AI、目标推进、威胁覆盖。

命令：

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -swift-version 5 \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
  -target arm64-apple-macos14.0 \
  -module-cache-path /private/tmp/WW2TacticsModuleCache \
  -parse-as-library \
  WW2Tactics/WW2Tactics/GameModels.swift WW2Tactics/WW2Tactics/GameState.swift WW2Tactics/Tools/RulesSmokeTest.swift \
  -o /private/tmp/WW2TacticsRulesSmokeTest

/private/tmp/WW2TacticsRulesSmokeTest
```

当前基线：

- 预期输出 `Rules smoke test passed`。
- 覆盖战役配置、地图、单位、移动、攻击、AI、补给、士气、目标推进、目标推进计划摘要、目标计划优先级解释、目标计划候选预览、安全接敌候选点选预览、安全接敌路径风险对比、敌方威胁意图预判、敌方意图反制建议、反制建议收益解释、据点防守取舍解释、排序对比解释、执行前后预计对照、反制建议点选聚焦、地图标记、执行入口桥接预览、执行回放、敌方回合复核、据点防守复核细分、关联 AI 行动、复核等级、复核目标定位、战线态势汇总、据点防守压力列表、据点压力定位入口、据点压力行当前态、据点压力来源标识、据点压力态势对照、据点压力敌方回合影响、据点压力威胁来源和地图标记、据点压力复盘线索、战线态势复盘影响来源筛选、首要目标定位、下一步提示、执行反馈、普通攻击/战术命令/部署/整补态势响应、态势响应最近 5 条历史、上一条/下一条响应查看、态势响应地图标记、态势响应定位入口、敌方回合影响、AI 关键复盘联动定位、普通移动/预览/失败命令不生成态势响应和地图标记、普通行动不生成或清理旧回放、重开/切战役清理回放和响应历史、部署/整补结果摘要、AI 直取据点优先、AI 移动后火炮弹幕、AI 回合行动摘要、复盘战果结论、结论关键事件点选定位、行动时间线、AI 时间线点选定位、复盘事件选中态、上一条/下一条连续查看、自动播放控制、地图复盘标记强调、THR 威胁覆盖等主规则链。

### 7.2 Smoke

触发条件：

- 修改 SwiftUI 界面、地图标记、HUD、输入事件。
- 修改 `GameState` 与 `ContentView` 的交互契约。

命令：

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -swift-version 5 \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk \
  -target arm64-apple-ios17.0-simulator \
  -module-cache-path /private/tmp/WW2TacticsModuleCache \
  -parse-as-library \
  -typecheck WW2Tactics/WW2Tactics/*.swift
```

当前基线：

- SwiftUI 和项目源码应完成 typecheck。

### 7.3 Stage Regression

触发条件：

- 新增或修改 XCTest。
- 修改公共模型、命令预览类型、`@Published` 状态、战役数据。

命令：

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -swift-version 5 \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk \
  -target arm64-apple-ios17.0-simulator \
  -module-cache-path /private/tmp/WW2TacticsModuleCache \
  -parse-as-library \
  -enable-testing \
  -emit-module \
  -emit-module-path /private/tmp/WW2Tactics.swiftmodule \
  -module-name WW2Tactics \
  WW2Tactics/WW2Tactics/*.swift

/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -swift-version 5 \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk \
  -target arm64-apple-ios17.0-simulator \
  -module-cache-path /private/tmp/WW2TacticsModuleCache \
  -I /private/tmp \
  -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib \
  -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks \
  -parse-as-library \
  -typecheck WW2Tactics/WW2TacticsTests/GameStateTests.swift
```

当前基线：

- `GameStateTests.swift` 应通过源码级 typecheck，覆盖 AI 战术命令、移动后攻击、移动后火炮弹幕、直取据点优先、敌方威胁意图预判、敌方意图反制建议、反制建议收益解释、据点防守取舍解释、排序对比解释、执行前后预计对照、反制建议点选聚焦、地图标记、执行入口桥接预览、执行回放、敌方回合复核、据点防守复核细分、关联 AI 行动、复核等级和复核目标定位、战线态势汇总、据点防守压力列表、据点压力定位入口、据点压力行当前态、据点压力来源标识、据点压力态势对照、据点压力敌方回合影响、据点压力威胁来源和地图标记、据点压力复盘线索、首要目标定位、下一步提示、执行反馈、普通攻击/战术命令/部署/整补态势响应、态势响应历史追加、最多 5 条裁剪、上一条/下一条只读查看、态势响应地图标记、态势响应定位入口、普通移动/预览/失败命令不生成态势响应和地图标记、敌方回合影响和 AI 关键复盘联动定位、部署、整补、占点、歼灭、AI 回合行动时间线、复盘战果结论、结论关键事件点选定位、AI 时间线点选定位、复盘事件选中态、上一条/下一条连续查看、自动播放控制和地图复盘标记强调，以及重开/切战役清理 AI 回合行动摘要、行动时间线、复盘选中态、播放状态、地图复盘标记、态势响应历史、反制执行回放和复核。

### 7.4 Full

触发条件：

- 人工明确要求本机完整构建。
- 修改 Xcode project、scheme、测试 target、构建配置。
- 排查云端 Xcode build 失败。

命令：

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project WW2Tactics/WW2Tactics.xcodeproj \
  -scheme WW2Tactics \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/WW2TacticsDerivedData \
  -resultBundlePath /private/tmp/WW2Tactics.xcresult \
  build-for-testing CODE_SIGNING_ALLOWED=NO
```

当前基线：

- 预期能构建 app 和 test bundle。
- 实际运行 XCTest 需要 CoreSimulatorService 和可用模拟器 runtime；不可用时必须明确说明。

## 8. 规则

- 每次实现前先读本文件。
- 默认从本地轻量检查开始，根据改动范围扩大到云端重验证。
- 不得伪造测试结果。
- 不得用“已验证”代替具体命令和结果。
- 环境失败和代码失败必须区分说明。
- 未跑的本机完整测试必须写清原因，例如“本轮是文档和 workflow 修改，默认交由云端重验证”。
