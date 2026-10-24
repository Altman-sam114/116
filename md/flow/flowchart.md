# WW2Tactics 当前流程图（v3.2）

## 战争沙盘渲染与操作

```mermaid
flowchart TD
    State[GameState 唯一规则事实源] --> Models[战役 / 地形 / 单位 / 轴向坐标]
    Models --> Layout[共享六角投影 / union bounds / 已缩放子视图 Layout 锚框]
    Layout --> Terrain[降噪原创底材 / 扩大错落地貌 / 连续漂雪]
    River[真实 river 邻接 / 共享岸点河宽切线 / 城镇连续河道 / 自然端潭] --> Terrain
    Infrastructure[canonical 道路保留 / 城镇成对接路 / 真实相对两岸桥梁] --> Terrain
    Layout --> Tiles[透明交互地格 / 稳定 ID / HexInputReader]
    State --> Routes[单次只读地格与 ZOC 快照 / 原 FIFO 与成本]
    Routes --> Hints[批量 mapActionHints 共享一次移动路线搜索]
    Hints --> Tiles
    State --> Rules[可达 / 攻击 / 控制区 / 补给 / 预判]
    Rules --> Tiles
    Artwork[六份离线原创 PNG / 20 sprite 单次解码与复用] --> Terrain
    Artwork --> Units[八款通用及四款命名军械 / AL 实线 AX 虚线 / HP / M 与 A]
    Tiles --> Units
    State --> Result[执行时坐标与真实 CombatResultSummary]
    Layout --> Feedback[轴线 / 定宽夹紧 HIT 与 RET / HP 前后 / 交战中点焦点]
    Result --> Feedback
    Terrain --> Screen[全幅战场与边缘指挥带]
    Units --> Screen
    Feedback --> Screen
    State --> Deck[独立战役栏 / 短横屏分档 / 单一动作坞 / 右上工具组 / 按需支援]
    Deck --> Screen
    State --> Overview[真实地貌单位据点缩略图 / 六角内点按只聚焦]
    Overview --> Screen
    Layout --> Camera[最近存活双方中点 / 独立前线锚框 / 重开镜头]
    Camera --> Screen
    Screen --> Input[点击 / 鼠标主次键 / 选择与聚焦 / 执行 / 结束回合]
    Input --> State
    State --> Inspector[可关闭情报 / 按单位规划态势战果敌情回放拆分]
```

所有装饰不命中，所有规则只在 GameState。地图布局、单位、战果和输入共用坐标；绘制层不重算伤害。Inspector/支援/轨道/总览开关与缩放是 SwiftUI 局部状态，不复制规则。前线入口仅滚动；小地图白框表示真实规则焦点，不是视口框，空白和格外点击无操作。

## 命令与回合

```mermaid
stateDiagram-v2
    [*] --> 空闲
    空闲 --> 已选单位: select / handleTap
    已选单位 --> 预览: focus / 地图主键
    预览 --> 已选单位: 仅改变焦点，不消耗行动
    预览 --> 移动结算: execute / 直接触摸 / 次键
    预览 --> 攻击结算: execute / 直接触摸 / 次键
    移动结算 --> 已选单位: 路线成本 / 占点 / M 资源
    攻击结算 --> 战果: 伤害 / 反击 / 士气 / 经验 / A 资源
    战果 --> 已选单位: 真实结果保留，地图反馈可退场
    已选单位 --> 轴心AI: endTurn
    空闲 --> 轴心AI: endTurn
    轴心AI --> 后勤: AI行动与时间线
    后勤 --> 空闲: 补给 / 据点 / 行动恢复
    后勤 --> 战役结束: 目标 / 回合期限 / 胜负
    战役结束 --> 空闲: restart / selectScenario
```

## 云端证据链

```mermaid
flowchart TD
    X[单智能体 X / 核对云端基线与公开参考] --> Implement[直接 main 实现 / 测试源码 / 文档]
    Implement --> Push[核对 main + origin/main + Altman-sam114 / push]
    Push --> Static[云端 diff / plist / YAML / Python / 超时契约]
    Static --> Smoke[RulesSmokeTest]
    Smoke --> Build[Xcode build-for-testing]
    Build --> XCTest[云端 iPad 全部 XCTest / 原 140 项加 7 项 / 不跳过]
    Build --> Boot[两个既有云端设备并行首启 / 不创建设备]
    Boot --> XCTest
    XCTest --> UI[两设备各 1 项 XCUITest / 真实旋转 / 结束回合命中 / 情报开合]
    UI --> Six[同 SHA 原四竖屏加两设备两帧命名原始附件 / 六张最终图]
    Six --> Gates[尺寸 / 500 KB / 亮度 / 方向一致 / Vision 拒绝已知系统通知 / 有界重试]
    Gates --> Package[always manifest + JUnit + logs + xcresult + PNG]
    Package --> Download[同一 X 下载 exact 最新 commit / run / attempt artifact]
    Download --> Review[核对身份 / 实际测试数 / 逐图检查 / 源码边界]
    Review --> Decision{X 判断}
    Decision -->|通过且仍需迭代| X
    Decision -->|不通过| Implement
    Decision -->|目标完成| Done[交付本轮与剩余风险]
    Decision -->|停止条件| Stop[暂停并请求必要人工决策]
```

JUnit 分开六阶段、147 unit 与两设备各 1 UI。UI 证据只覆盖明确的旋转/控件/抽屉路径，不证明地图触屏命令、鼠标拖动、VoiceOver 或全字号。桥梁/命名军械/地貌不改变规则；横屏由 XCUITest 旋转设备，原附件不转像素/修通知。失败也产包，不回滚远端，只追加修复；本轮无 A/B/C 调度、无子智能体，所有重验证云端。
