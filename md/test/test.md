# 测试规范

本文指导 Agent B 和 Agent C 选择测试层级、记录命令和判断当前基线。

## 固定前缀 / 环境要求

- 项目目录：`/Users/a114514/Desktop/codex/easytech/WW2Tactics`
- 需要本机安装 Xcode 和 iPhone Simulator SDK。
- 若机器未接受 Xcode license，需要人工先执行 `sudo xcodebuild -license`。
- 完整 XCTest 依赖可用 iOS Simulator runtime 和 CoreSimulatorService。
- 推荐使用 `/private/tmp/WW2TacticsModuleCache` 和 `/private/tmp/WW2TacticsDerivedData`，避免污染项目目录。

## 测试分层

### 1. Probe / Fast

最快发现主链路断点。

触发条件：

- 只改 `GameModels.swift`、`GameState.swift` 或规则测试。
- 修改地图命令判定、移动、攻击、补给、AI、目标推进、威胁覆盖。

命令：

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -swift-version 5 \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
  -target arm64-apple-macos14.0 \
  -module-cache-path /private/tmp/WW2TacticsModuleCache \
  -parse-as-library \
  WW2Tactics/GameModels.swift WW2Tactics/GameState.swift Tools/RulesSmokeTest.swift \
  -o /private/tmp/WW2TacticsRulesSmokeTest

/private/tmp/WW2TacticsRulesSmokeTest
```

当前基线：

- 预期输出 `Rules smoke test passed`。
- 覆盖战役配置、地图、单位、移动、攻击、AI、补给、士气、目标推进、THR 威胁覆盖等主规则链。

### 2. Smoke

验证主要集成路径。

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
  -typecheck WW2Tactics/*.swift
```

当前基线：

- SwiftUI 和项目源码应完成 typecheck。

### 3. Stage Regression

覆盖当前阶段核心模块。

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
  WW2Tactics/*.swift

/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -swift-version 5 \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk \
  -target arm64-apple-ios17.0-simulator \
  -module-cache-path /private/tmp/WW2TacticsModuleCache \
  -I /private/tmp \
  -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib \
  -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks \
  -parse-as-library \
  -typecheck WW2TacticsTests/GameStateTests.swift
```

当前基线：

- `GameStateTests.swift` 应通过源码级 typecheck。

### 4. Full

全量测试构建。

触发条件：

- 准备交付较大功能。
- 修改 Xcode project、scheme、测试 target、构建配置。
- Agent C 验收正式版本。

命令：

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project WW2Tactics.xcodeproj \
  -scheme WW2Tactics \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/WW2TacticsDerivedData \
  build-for-testing CODE_SIGNING_ALLOWED=NO
```

当前基线：

- 预期能构建 app 和 test bundle。
- 实际运行 XCTest 需要 CoreSimulatorService 和可用模拟器 runtime；不可用时必须明确说明。

## 静态检查

文档-only 修改至少运行：

```sh
git diff --check
```

可选检查：

```sh
find . -name '*.md' -maxdepth 4 -type f
```

当前没有配置 markdown lint。

## 规则

- 每次实现前先读本文件。
- 默认从最小测试开始，根据改动范围扩大测试。
- 文档-only 修改可只跑 `git diff --check`，但必须说明未跑业务测试原因。
- 不得伪造测试结果。
- 不得用“已验证”代替具体命令和结果。
- 环境失败和代码失败必须区分说明。
