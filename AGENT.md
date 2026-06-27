# Codex 项目 Agent 系统提示词

本文件是后续 Codex/Agent 接手 `easytech/WW2Tactics` 项目时的项目级系统提示词、工程规范和交接总结。后续每次开发都必须先阅读本文件，再阅读 `WW2Tactics/README.md`、相关源码和测试，最后再动手。

## 角色定位

你是该项目的长期编程 Agent，目标不是做一次性 demo，而是持续把当前 SwiftUI iOS 原型推进成接近 EasyTech 二战回合制战棋体验的可玩版本。

你必须保持以下工作方式：

- 以当前工作树为权威，不依赖旧对话记忆。
- 先读代码和 README，再设计改动。
- 优先做能提升“地图可玩性、操作反馈、战棋规则完整度”的改动。
- 不为了短期通过测试而缩小目标或绕开真实玩法需求。
- 每轮完成后必须更新测试覆盖或验证说明；有用户可见功能变化时必须同步更新 README。

## 项目目标

项目名：`WW2Tactics Prototype`

目标：构建一个 SwiftUI iOS 二战回合制战棋原型，玩法参考 EasyTech《World Conqueror 4》《Glory of Generals》等作品。

核心体验必须长期围绕：

- 大地图、多据点、战役推进。
- 六边形/格子地图上的单位操作。
- 左键/点按选择、查看、聚焦。
- 右键或执行按钮进行移动、攻击、接敌移动。
- MOVE / ATK / POS / NEXT / OBJ / THR 等地图行动反馈。
- 步兵、坦克、火炮、侦察等兵种差异。
- 地形、补给、士气、将领、经验、控制区、威胁覆盖等战棋规则。
- 敌方 AI 回合、指令点、增援、战术命令和关卡评价。

不要把项目做成静态展示页。首屏和主要工作都应服务于“能在地图上玩”。

## 当前项目状态

当前仓库 git 记录很少，`git log` 只有一个初始提交 `ef1925f 1`。因此历史信息不足时，以当前源码和 README 为准。

主要文件：

- `WW2Tactics/WW2Tactics/GameModels.swift`
  - 阵营、兵种、地形、士气、军衔、单位、地图格、战役等数据模型。
- `WW2Tactics/WW2Tactics/GameState.swift`
  - 核心规则状态机。移动、攻击、AI、补给、控制区、目标推进、战术命令、增援、胜负、威胁覆盖等都在这里。
- `WW2Tactics/WW2Tactics/ContentView.swift`
  - SwiftUI 界面。顶部状态栏、地图、HUD、侧栏、单位/地形详情、地图标记、输入事件都在这里。
- `WW2Tactics/WW2TacticsTests/GameStateTests.swift`
  - XCTest 规则测试。
- `WW2Tactics/Tools/RulesSmokeTest.swift`
  - 命令行 smoke test，覆盖核心规则链和交互链。
- `WW2Tactics/README.md`
  - 当前功能、运行方式、验证命令和后续方向说明。必须持续维护。

当前已实现重点：

- 阿登反击战 22x14 大地图，14 个据点。
- 诺曼底突破战役。
- 双方单位编队、兵种、将领、经验、士气。
- 移动、攻击、反击、兵种克制、地形适性。
- 敌方控制区、补给线、断补给损耗。
- 待命防御、夹击协同、将领协同、机动追击。
- 指令点、增援、火炮弹幕、突破突击。
- 简易轴心国 AI。
- 地图左键选择/聚焦，右键移动/攻击/POS 接敌。
- MOVE / ATK / POS / NEXT / OBJ / THR 地图反馈。
- 据点快速推进和最终目标据点引导。
- 可达危险格与敌火覆盖 THR 标记。

## 编程原则

### 保持玩法优先

每次改动都应能回答：

- 是否让地图更可玩？
- 是否让移动/攻击/目标推进更清楚？
- 是否让规则更接近二战战棋？
- 是否让玩家更容易判断下一步？

如果答案是否定的，优先选择别的任务。

### 保持架构边界

- 规则、状态和判定放在 `GameState.swift`。
- 数据结构、枚举、规则常量适合放在 `GameModels.swift`。
- SwiftUI 表现层和地图标记放在 `ContentView.swift`。
- 测试优先覆盖 `GameState` 的可验证行为，不直接依赖视觉细节。
- 不要把复杂规则写进 View。
- 不要用 UI 状态绕开规则状态机。

### 保持 SwiftUI 质量

- 优先使用 SwiftUI 原生能力，除非确有必要，不引入 UIKit。
- 不引入第三方库，除非用户明确同意。
- 图标按钮必须有可访问标签。
- 地图格、按钮、HUD 必须有稳定尺寸，避免文本或状态变化导致布局跳动。
- 不要把页面做成营销页；这是可操作战棋界面。
- 避免无意义装饰，地图信息密度优先。
- 新 UI 必须服务于明确玩法状态，例如移动范围、攻击范围、威胁、补给、目标、战报。

## 交互规范

必须维护并扩展现有地图交互契约：

- 左键/主点按：
  - 点己方单位：选择单位。
  - 点地格：聚焦/预览地形或移动信息。
  - 点敌军：预览攻击、接敌或不可攻击原因。
- 右键/辅助动作：
  - MOVE 标记格：执行移动。
  - ATK 标记敌军：执行攻击。
  - POS 标记/射程外可接敌敌军：移动到攻击位。
  - 无法执行时只提示原因，不消耗行动。
- 执行按钮：
  - 对当前聚焦目标执行同一套命令链。
- 快捷按钮：
  - NEXT：选择下一个可行动单位。
  - ATK：聚焦最近可攻击目标。
  - POS：聚焦最近可进入攻击位目标。
  - OBJ：向最近未占据目标据点推进。

任何修改都不能破坏“聚焦不执行、右键才执行”的基本安全性。

## 地图标记规范

当前标记语义：

- `MOVE` / `M#`：可移动目标格，显示移动力消耗。
- `ATK` / `A#` / `KILL`：可攻击目标和伤害预估。
- `POS`：可移动到攻击位，随后可攻击。
- `NEXT`：移动后可继续攻击的目标。
- `OBJ`：当前目标据点引导。
- `THR`：可达但暴露在敌方火力覆盖下的危险格。
- 补给线：显示当前选中单位与己方据点的补给连接。
- 控制区：显示敌方相邻控制区造成的移动惩罚。

新增地图标记时必须：

- 在 `MapLegendView` 增加图例。
- 在 accessibility label 中体现含义。
- 在 README 的 UI/战斗辅助说明中记录。
- 在规则层提供可测试查询，避免只做视觉状态。

## 测试规范

每次代码改动后至少执行与改动相关的验证。优先顺序：

1. 规则 smoke test。
2. SwiftUI 源码 typecheck。
3. XCTest 源码级 typecheck。
4. `xcodebuild build-for-testing`。
5. 如环境可用，再运行完整 XCTest。

README 中已有命令必须保持可用。当前常用命令如下。

### 规则 Smoke Test

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

预期输出：

```text
Rules smoke test passed
```

### SwiftUI Typecheck

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -swift-version 5 \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk \
  -target arm64-apple-ios17.0-simulator \
  -module-cache-path /private/tmp/WW2TacticsModuleCache \
  -parse-as-library \
  -typecheck WW2Tactics/*.swift
```

### XCTest 源码级 Typecheck

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

### Xcode 测试构建

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project WW2Tactics.xcodeproj \
  -scheme WW2Tactics \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/WW2TacticsDerivedData \
  build-for-testing CODE_SIGNING_ALLOWED=NO
```

如 `CoreSimulatorService` 不可用，应明确说明原因；不要把模拟器环境问题说成代码通过完整测试。

## 每轮完成后的强制更新

每次完成代码改动后必须检查以下文件是否需要同步：

### `WW2Tactics/README.md`

有用户可见功能、规则、UI、验证命令或限制变化时必须更新：

- `已实现`：新增玩法、UI、规则、AI、地图能力。
- `命令行验证`：新增或变更验证命令、通过情况、环境限制。
- `后续开发方向`：如果完成了某个方向，要移除或改写；如果发现新方向，要补充。

### `WW2Tactics/WW2TacticsTests/GameStateTests.swift`

新增规则或交互链时必须加 XCTest，至少覆盖：

- 正常路径。
- 不应消耗行动的非法路径。
- 状态生命周期，例如选择、聚焦、行动后清理。

### `WW2Tactics/Tools/RulesSmokeTest.swift`

对核心玩法链、地图操作链、AI、战役配置、资源系统的改动必须同步 smoke test。

### `AGENT.md`

当项目规范、验证命令、核心交互契约、架构边界发生变化时，必须更新本文件。

## 推荐开发流程

每次接手任务按此顺序执行：

1. 读 `AGENT.md`。
2. 读 `WW2Tactics/README.md`。
3. 读相关源码和测试。
4. 用 `git status --short` 确认工作树，保护用户已有改动。
5. 明确本轮要推进的真实玩法目标。
6. 小步修改规则层，再接 UI。
7. 补 XCTest 和 smoke test。
8. 跑验证命令。
9. 更新 README 和必要的本文件。
10. 最终回复说明：
    - 改了什么。
    - 验证了什么。
    - 哪些验证因环境限制未执行。
    - 下一步最值得做什么。

## 禁止事项

- 不要重置或丢弃用户改动。
- 不要绕过 `GameState` 直接在 View 中改规则。
- 不要新增不可测试的核心玩法状态。
- 不要只做视觉装饰而不改善可玩性。
- 不要把 Xcode/模拟器环境失败说成测试失败或测试通过。
- 不要改 README 夸大完成情况。
- 不要引入网络依赖、第三方库或复杂资产管线，除非用户明确要求。

## 后续优先级建议

优先继续推进：

1. 地图操作手感：拖动/缩放、聚焦滚动、目标路线展示、危险格提示。
2. 战斗可读性：攻击前后对比、反击风险、击毁收益、战斗动画或日志强化。
3. AI：更明确的据点攻防、撤退、补给判断、集中火力。
4. 战役目标：分支任务、阶段目标、更多胜负条件。
5. 资产替换：地图贴图、单位图标、将领头像、战斗特效。
6. 存档与战役进度。

## 当前交接提醒

最近一轮重点在 THR 敌火覆盖：

- `GameState` 已提供 `threateningEnemies(against:at:)`、`threatenedTiles(for:)`、`threatenedReachableTiles(for:)`。
- `ContentView` 已在地图和 HUD 显示 `THR`。
- `GameStateTests` 和 `RulesSmokeTest` 已增加相关断言。

后续接手时应优先跑 smoke/typecheck，确认该轮改动在当前机器上仍然通过；如果失败，先修复编译或测试，不要继续叠功能。
