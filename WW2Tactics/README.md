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
- 据点奖励：占领中立或敌方据点会立刻获得指令点，并提升占领单位的士气与经验，侧栏会显示占领结果摘要，地图在最新占领据点显示 CAP
- 据点推进：选中可移动单位时，侧栏会显示最多 3 条目标计划；OBJ 首项与快捷按钮一致，计划行会说明本回合可占/可夺或推进几格、剩余距离、路线代价和终点风险；可点选任一计划把路线、目的格、最终目标和火力风险投射到地图预览，但不会直接消耗行动
- 据点休整：补给畅通且驻守己方据点的受损单位，会在本方回合开始自动恢复耐久
- 关卡评价：每个战役有回合期限、快速胜利和保留部队三星目标，超时会判定任务失败
- 指令点：据点在新回合提供指令点，可用于部署援军和整补受损单位，成功部署或整补会在侧栏显示消耗和结果摘要
- 战术命令：火炮单位可消耗指令点发动火炮弹幕，坦克和侦察可发动突破突击；命令会造成伤害、降低士气，且不触发反击，执行后会在结果面板和战报中显示 HP 前后、士气/状态、指令点消耗和防御姿态消耗
- 增援：己方据点及相邻空格可部署步兵、坦克、火炮和侦察车，部署结果会记录来源据点、新单位、地点和剩余指令点
- AI：轴心国会使用指令点优先整补据点守军、在据点周边部署增援，评估高价值目标使用火炮弹幕或突破突击；没有可击毁目标时会优先直取本回合可达的中立或盟军据点，再用完整移动范围压向据点或进入攻击位，移动后若普通攻击不可用但进入弹幕射程，火炮会继续用火炮弹幕压制目标；回到盟军回合后侧栏会显示敌方回合摘要、复盘战果结论和行动时间线，复盘结论会按夺点突破、火力压制、后勤整备、机动推进或低强度回合归类，汇总伤害、占点、后勤和指令点变化，并列出最多 3 条关键事件；地图用 AI 复盘标记显示移动起终点、攻击/战术目标、部署/整补和占点坐标，结论关键事件和时间线条目都可点选定位到对应复盘坐标并保留当前事件选中态，也可用上一条/下一条连续查看敌方行动，或用慢/中/快三档自动播放并可随时暂停；地图同步强调当前事件的 AI 标记，但不会执行命令
- 敌方意图预判：玩家回合侧栏会列出最多 3 条轴心国威胁，区分直接攻击、机动接敌攻击和据点占领风险，地图用 INT 标记目标格；其下方会给出抢先打击、撤出危险区、据点防守和整补支撑等反制建议，建议行可点选聚焦执行单位、敌军或目的格，并显示战果、生存、守点、恢复、路线、优先值、排序依据、首选对比解释和执行前后预计对照；据点防守建议会额外解释本轮选择进驻据点还是相邻封堵、路线代价和优先值，在地图显示 ACT/SRC/CTR/TGT 反制聚焦标记和“下一步”入口提示，指向现有 ATK、MOVE 或单位详情整补按钮；玩家通过这些既有入口成功执行后，侧栏会显示最近一次反制回放，把预计值、实际结果和偏差说明并列展示；结束回合后会基于敌方 AI 后的 HP、位置、据点归属和威胁源存活发布“敌方回合复核”，显示奏效/部分奏效/失败等级，并可点选定位执行单位、威胁来源和受威胁目标；据点防守复核会进一步标出进驻/封堵、守点位置、威胁来源是否仍压迫据点、防守单位状态和最多 3 条真实 AI 时间线关联行动，关联行动可直接定位到 AI 复盘事件，但不声明精确因果；建议行本身不会自动移动、攻击或整补
- 战线态势汇总：侧栏靠前显示当前阵营的指令点、待命部队、据点进度、敌方意图、可执行反制、受威胁据点、据点防守压力列表和首要建议；防守压力会列出 NOW 当前威胁或 CHK 回合复核来源、据点归属、威胁来源数量、占点风险、当前/应对态势对照、匹配守点复核后的敌方回合前后影响和推荐入口，且当前威胁稳定排在回合复核前；压力行可点选定位匹配守点反制或受威胁据点，被点选行会显示当前态，并在地图显示 PRS 受压据点、SRC 威胁来源和 DEF 守点目的格标记；若当前压力能和最新 AI 时间线保守匹配，压力列表下方会显示“复盘线索”按钮，可直接定位关联 AI 行动；首要定位按钮也可一键定位首要反制、守点、OBJ 推进或待命单位；定位入口会同步提示下一步应走 ATK、MOVE、整补、选择或防守查看，玩家通过既有入口真实执行反制、占点、普通攻击、战术命令、部署或整补后，卡片会把最近 5 条真实态势响应保存为历史，概括反制预计/实际对照、据点占领奖励与进度、战斗伤害、战术压制、部署消耗或整补恢复，并可用上一条/下一条连续查看；地图响应短码标记和定位按钮会跟随当前查看的历史响应；若反制后进入敌方回合，卡片会显示敌方回合影响，说明复核等级、关键对比、守点进驻/封堵结果和目标是否撑住，并提供“复盘影响”按钮直接定位敌方 AI 事件；该复盘入口会优先使用当前压力线索，其次匹配当前态势响应坐标，最后回退全局关键事件，并显示 PRS/RSP/KEY 来源短码；该卡片、压力行定位、压力行当前态、压力来源标识、压力态势对照、压力敌方回合影响、压力复盘线索、压力地图标记、响应历史导航、战线态势复盘筛选和地图响应标记都由 `GameState` 管理或派生，不会自动移动、攻击、整补、部署、模拟 AI 或改变反制建议排序
- UI：顶部回合栏、剩余回合、战局进度、三星目标、双方战力、编队条、战术指令条、地图缩放、战区坐标、按当前焦点排序的全友军/据点/全敌军快速定位、地图命令预览、单位详情、地形详情、将领加成、图例、战报、重新开始；v1.56 起首屏外壳使用统一战区指挥台视觉基线，顶栏、状态芯片、地图容器、HUD 背板和侧栏容器共享战场主题、半透明面板、细描边和更明确的信息层级；v1.57 起地图格使用地形渐变、高光、归属覆盖和更清晰的据点/地形标签，单位棋子带阵营渐变、底影、高光和状态徽标，地图仍是第一工作区；v1.58 起攻击目标、战斗预测和普通攻击结果卡统一为战报式反馈牌，强化聚焦态、HP 变化、伤害、反击、击毁、追击和影响来源读数
- 地图交互：鼠标左键选择己方单位、聚焦地格或预览敌军，右键对 MOVE 标记格移动、对 ATK 标记敌军攻击、对 POS/射程外可接敌目标执行接敌移动；触屏点按和右键共用同一执行链，MOVE/POS 路线会显示步序、每步消耗、敌火风险等级、潜在承伤和预计剩余耐久，安全接敌候选会显示相对默认 POS 路线的承伤、风险、移动力、控制区和路线暴露步数对比；战线态势、态势响应卡、目标计划、AI 复盘结论关键事件、AI 时间线、反制建议和反制复核目标都可点选切换路线/目标/响应位置/复盘预览，战线态势压力行会显示当前选中态、来源短码、当前/应对态势对照和真实守点复核后的敌方回合影响，并把当前受压据点、威胁来源与守点目的格投射为地图短码；当前压力存在关联 AI 行动时，可用独立复盘线索按钮切到对应 AI 时间线事件，定位按钮会标明定位后的下一步入口，并在真实执行后显示最近 5 条态势响应历史、地图响应标记和上一条/下一条响应查看，在敌方回合后显示反制影响和可定位的 AI 关键复盘事件，AI 结论关键事件和时间线点选会保留当前复盘行选中态并强调对应地图标记，上一条/下一条按钮可连续切换 AI 复盘事件，播放按钮会按当前速度自动推进到下一条并在末尾暂停，当前反制建议会把执行点、威胁来源、建议目标、排序依据、据点防守进驻/封堵取舍、执行前后预计变化和下一步入口投射到地图/侧栏；若随后用现有 ATK/MOVE/整补入口真实执行，会追加最近一次反制回放，并在下一次敌方回合后追加复核卡，移动后若出现 NEXT 目标会自动聚焦，继续点按或再次右键可攻击；据点条、战线态势、态势响应卡、目标计划、AI 复盘结论、AI 时间线和敌军编队条可快速定位目标并自动滚动到地图焦点，但不会消耗行动或误触发攻击
- 战斗辅助：选中单位后在地图和侧栏显示战线态势汇总、据点防守压力列表、据点压力定位入口、据点压力行当前态、据点压力来源标识、据点压力态势对照、据点压力敌方回合影响、据点压力地图 PRS/SRC/DEF 标记、据点压力复盘线索、战线态势复盘影响来源筛选、首要目标定位、态势响应定位、态势响应最近 5 条历史和上一条/下一条连续查看、下一步入口提示、普通攻击/战术命令/部署/整补/占点/反制执行后的态势响应反馈、敌方回合后的态势影响解释、战线态势关联的敌方关键复盘事件、可移动格、可攻击目标、可用战术命令、兵种克制、地形适性、补给通道、目标推进计划、目标计划优先级解释、路线总消耗、控制区额外消耗、路线威胁来源、移动后敌火来源、潜在伤害、HP 后果、风险等级、可点选安全接敌候选、安全接敌路径风险对比、敌方意图预判、反制建议、反制建议收益解释、据点防守进驻/封堵取舍解释、排序依据、首选对比解释、执行前后预计对照、反制聚焦 ACT/SRC/CTR/TGT 标记、反制建议下一步入口提示、反制执行回放、敌方回合复核等级、据点防守复核细分、关联 AI 行动和复核目标定位、预计伤害、反击伤害、移动后最佳攻击目标、击毁提示、攻击前战斗预测牌、攻击后战斗结果回放、战术命令结果摘要、据点占领结果摘要、部署/整补结果摘要、AI 回合行动摘要、可点选定位的复盘战果结论关键事件、可上一条/下一条连续查看、可播放/暂停并切换速度且保留选中态的行动时间线和地图复盘标记、双方 HP 前后对比、反击/无反击/击毁/追击/防御姿态消耗、经验进度、晋升、士气状态和敌方威胁提示
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

规则 smoke test 会验证战役切换、22x14 阿登大地图、14 个据点、扩展双方编队、全友军/全敌军快速定位、据点/敌军聚焦不误执行命令、据点即时奖励、据点推进计划摘要、优先级解释和候选预览、安全接敌候选点选预览、安全接敌路径风险对比、敌方威胁意图预判、敌方意图反制建议、反制建议收益解释、据点防守取舍解释、排序对比解释、执行前后预计对照、反制建议点选聚焦、地图标记、执行入口桥接、执行回放、敌方回合复核等级、据点防守复核细分、关联 AI 行动和目标定位、战线态势汇总、据点防守压力列表、据点压力定位入口、据点压力行当前态、据点压力来源标识、据点压力态势对照、据点压力敌方回合影响、据点压力威胁来源和地图标记、据点压力复盘线索、战线态势复盘影响来源筛选、首要目标定位、下一步提示、执行后的态势响应反馈、普通攻击/战术命令/部署/整补态势响应、态势响应最近 5 条历史、上一条/下一条响应查看、态势响应地图标记和响应定位入口、敌方回合后的态势影响解释、据点休整回血、兵种、兵种克制、兵种地形适性、控制区移动惩罚、待命防御减伤、夹击协同增伤、将领自身加成与相邻协同、机动追击、火炮弹幕与突破突击、部队经验晋升、补给线和断补给损耗、士气状态与恢复、关卡期限与三星评价、战局统计、指令点、增援部署、整补和后勤结果摘要、AI 直取据点优先、AI 移动后火炮弹幕、AI 回合行动摘要、复盘战果结论、结论关键事件点选定位、行动时间线、AI 时间线点选定位、复盘事件选中态、上一条/下一条连续查看、自动播放控制和地图复盘标记强调、战斗预测、目标查询、选择、移动、AI 全移动力推进、AI 回合和回合推进：

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
