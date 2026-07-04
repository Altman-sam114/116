# WW2 Tactics Prototype

一个 SwiftUI iOS 原型，目标是做成类似 EasyTech 二战回合制战棋的基础版本。当前美术全部用几何色块、地图符号、兵种轮廓和系统图标占位，后续可以替换为真实地图、兵模和将领头像。

当前玩法参考 EasyTech《World Conqueror 4》《Glory of Generals》一类二战战棋的核心体验：离线战役、大地图多据点推进、格子地图、步兵/坦克/火炮等兵种、将领加成、地形影响、左键选择/查看并用右键移动或攻击，回合结束后由敌方 AI 行动。触屏点按也复用同一套 MOVE/ATK/POS 命令链，可点选单位后直接点地图标记格执行移动、接敌和攻击。

## 协作与维护文档

后续 Codex/Agent 迭代必须先阅读项目根目录的 `AGENTS.md`。项目维护文档结构如下：

- `AGENTS.md`：项目入口记忆、基本规则和 Agent A/B/C 工作流。
- `update_log.md`：版本更新记录、历史决策、完成事项和遗留问题。
- `md/prompt/`：Agent A 写给 Agent B 的版本化实现提示词。
- `md/test/test.md`：测试规范、测试分层、命令、触发条件和当前基线。
- `md/flow/flow.md`：当前真实核心逻辑文档。
- `md/flow/flowchart.md`：核心数据流、执行流和 Agent 迭代流的 Mermaid 图。

### 协作与云端验证

后续默认使用 `main` 直推和 GitHub Actions 云端重验证：Agent B 在本地完成轻量检查后提交并推送到 `origin/main`，Actions 生成未加密 CI 结果包；Agent C 下载结果包，核对 manifest、JUnit、构建日志、规则 smoke 日志和 `.xcresult` 后验收。只有人工明确要求时，才默认在本机运行完整 Xcode build 或模拟器验证。

未来可用 `agentx:`、`x:` 或 `X:` 启动主控循环：Agent X 接收总目标并拆分多轮任务，但不直接替代 A/B/C；每轮仍由 Agent A 写提示词、Agent B 实现并 push、Agent C 下载 artifact 验收后，再由 Agent X 判断继续、退回、暂停或完成。

## 已实现

- 二战战役目录：1944 阿登反击战、1944 诺曼底突破
- 战役切换：顶部菜单可切换战役，重新开局会保留当前战役
- 六边形战棋地图：默认阿登战役已扩展为 22x14 大地图，包含 14 个据点、多道河线、森林防线、城市节点、山地、公路走廊、默兹渡口、西墙工事和鲁尔工业区等东部纵深目标，并用简易符号标出地形
- 回合制流程：盟军玩家回合，轴心国简易 AI 回合
- 兵种：步兵、坦克、火炮、侦察车，用不同几何形状块区分
- 将领：巴顿、蒙哥马利、古德里安、曼施坦因
- 兵种克制：坦克压制步兵与侦察，侦察克制炮兵，步兵突击炮兵，炮兵反装甲；战斗预测会显示战术优势或劣势
- 部队成长：攻击、反击和击毁敌军会获得经验，新兵、正规、老兵、精锐、王牌军衔会提升攻击与耐久上限
- 补给线：单位需要连接己方据点，断补给会降低攻击、减少移动并在回合开始损失耐久
- 士气：单位有低落、稳定、高昂三档士气，影响攻击与移动；攻击奏效、击毁、受击、反击、断补给和据点休整都会改变士气
- 规则：移动范围、射程、兵种地形适性、地形防御、攻击和反击；坦克适合平原/公路突击，步兵更适合森林/城市/山地，炮兵占山地有火力优势，河流会牵制重装备
- 控制区：敌军会影响相邻格，进入敌方控制区需要额外移动力，突破战线会更吃紧
- 待命防御：单位原地待命会构筑防御姿态，下一次受击或火炮弹幕伤害降至 75%，随后防御姿态被消耗
- 夹击协同：普通攻击时，目标相邻的其他友军会提供围攻支援，每支伤害 +10%，最高 +30%
- 将领协同：带将领单位会指挥相邻友军，提升普通攻击和突破突击伤害
- 机动追击：坦克和侦察在未移动时普通攻击击毁目标，可保留移动继续推进或抢占据点
- 据点：占领全部据点或消灭敌军触发胜负
- 据点奖励：占领中立或敌方据点会立刻获得指令点，并提升占领单位的士气与经验
- 据点休整：补给畅通且驻守己方据点的受损单位，会在本方回合开始自动恢复耐久
- 关卡评价：每个战役有回合期限、快速胜利和保留部队三星目标，超时会判定任务失败
- 指令点：据点在新回合提供指令点，可用于部署援军和整补受损单位
- 战术命令：火炮单位可消耗指令点发动火炮弹幕，坦克和侦察可发动突破突击；命令会造成伤害、降低士气，且不触发反击，执行后会在结果面板和战报中显示 HP 前后、士气/状态、指令点消耗和防御姿态消耗
- 增援：己方据点及相邻空格可部署步兵、坦克、火炮和侦察车
- AI：轴心国会使用指令点优先整补据点守军、在据点周边部署增援，评估高价值目标使用火炮弹幕或突破突击，并用完整移动范围压向据点或进入攻击位
- UI：顶部回合栏、剩余回合、战局进度、三星目标、双方战力、编队条、战术指令条、地图缩放、战区坐标、按当前焦点排序的全友军/据点/全敌军快速定位、地图命令预览、单位详情、地形详情、将领加成、图例、战报、重新开始
- 地图交互：鼠标左键选择己方单位、聚焦地格或预览敌军，右键对 MOVE 标记格移动、对 ATK 标记敌军攻击、对 POS/射程外可接敌目标执行接敌移动；触屏点按和右键共用同一执行链，MOVE/POS 路线会显示步序、每步消耗、敌火风险等级、潜在承伤和预计剩余耐久，移动后若出现 NEXT 目标会自动聚焦，继续点按或再次右键可攻击；据点条和敌军编队条可快速定位目标并自动滚动到地图焦点，但不会消耗行动或误触发攻击
- 战斗辅助：选中单位后在地图和侧栏显示可移动格、可攻击目标、可用战术命令、兵种克制、地形适性、补给通道、路线总消耗、控制区额外消耗、路线威胁来源、移动后敌火来源、潜在伤害、HP 后果、风险等级、安全接敌建议、预计伤害、反击伤害、移动后最佳攻击目标、击毁提示、攻击后战斗结果回放、战术命令结果摘要、双方 HP 前后对比、反击/无反击/击毁/追击/防御姿态消耗、经验进度、晋升、士气状态和敌方威胁提示
- 响应式布局：横屏/iPad 使用地图 + 侧栏，竖屏/iPhone 使用上下布局
- 共享 Xcode scheme：`WW2Tactics`
- 原生测试目标：`WW2TacticsTests`

## 打开方式

用 Xcode 打开：

```sh
open WW2Tactics.xcodeproj
```

选择任意 iPhone 或 iPad 模拟器后运行 `WW2Tactics` scheme。

## 命令行验证

如果机器还没有接受 Xcode license，需要先在终端执行：

```sh
sudo xcodebuild -license
```

已通过的 iOS Simulator 构建：

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project WW2Tactics.xcodeproj \
  -scheme WW2Tactics \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/WW2TacticsDerivedData \
  build CODE_SIGNING_ALLOWED=NO
```

已通过的测试构建：

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project WW2Tactics.xcodeproj \
  -scheme WW2Tactics \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/WW2TacticsDerivedData \
  build-for-testing CODE_SIGNING_ALLOWED=NO
```

实际运行 XCTest 需要可用的 iOS Simulator runtime 和 CoreSimulatorService。当前工程的测试 bundle 已能构建进 `WW2Tactics.app/PlugIns/WW2TacticsTests.xctest`。

已通过的 iOS SwiftUI typecheck：

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -swift-version 5 \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk \
  -target arm64-apple-ios17.0-simulator \
  -module-cache-path /private/tmp/WW2TacticsModuleCache \
  -parse-as-library \
  -typecheck WW2Tactics/*.swift
```

已通过的 XCTest 源码级 typecheck：

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

规则 smoke test 会验证战役切换、22x14 阿登大地图、14 个据点、扩展双方编队、全友军/全敌军快速定位、据点/敌军聚焦不误执行命令、据点即时奖励、据点休整回血、兵种、兵种克制、兵种地形适性、控制区移动惩罚、待命防御减伤、夹击协同增伤、将领自身加成与相邻协同、机动追击、火炮弹幕与突破突击、部队经验晋升、补给线和断补给损耗、士气状态与恢复、关卡期限与三星评价、战局统计、指令点、增援部署、战斗预测、目标查询、选择、移动、AI 全移动力推进、AI 回合和回合推进：

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

## 后续开发方向

- 替换真实地图贴图、单位立绘、将领头像和战斗特效
- 增加更多战役、国家和科技
- 增加更完整的 AI、生产队列、分支关卡目标和士气连锁事件
- 增加保存进度和战役进度界面
