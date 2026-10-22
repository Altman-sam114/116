# WW2Tactics 当前流程图（v3.0）

## 战争沙盘渲染与操作

```mermaid
flowchart TD
    State[GameState 唯一规则事实源] --> Models[战役 / 地形 / 单位 / 轴向坐标]
    Models --> Layout[共享六角投影 / union bounds / 已缩放子视图 Layout 锚框]
    Layout --> Terrain[原创底材与地貌 atlas / 柔化雪地 / 曲线河路]
    Layout --> Tiles[透明交互地格 / 稳定 ID / HexInputReader]
    State --> Routes[单次只读地格与 ZOC 快照 / 原 FIFO 与成本]
    Routes --> Hints[批量 mapActionHints 共享一次移动路线搜索]
    Hints --> Tiles
    State --> Rules[可达 / 攻击 / 控制区 / 补给 / 预判]
    Rules --> Tiles
    Artwork[四份离线原创 PNG / ImageIO 单次解码与复用] --> Terrain
    Artwork --> Units[八款精细兵模 / AL 实线 AX 虚线 / HP / M 与 A]
    Tiles --> Units
    State --> Result[执行时坐标与真实 CombatResultSummary]
    Layout --> Feedback[轴线 / 定宽夹紧 HIT 与 RET / HP 前后 / 交战中点焦点]
    Result --> Feedback
    Terrain --> Screen[全幅战场与边缘指挥带]
    Units --> Screen
    Feedback --> Screen
    State --> Deck[战役资源 / 单一动作坞 / 通讯 / 按需轨道与支援]
    Deck --> Screen
    Screen --> Input[点击 / 鼠标主次键 / 选择与聚焦 / 执行 / 结束回合]
    Input --> State
    State --> Inspector[按需情报 / 原有规划态势反制后勤与回放]
```

所有装饰不命中，所有规则只在 GameState。地图布局、单位、战果和输入共用坐标；绘制层不重算伤害。Inspector/支援/轨道开关与缩放是 SwiftUI 局部状态，不复制规则。

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
    A[A 版本化目标与边界] --> B[B main 实现 / 测试源码 / 文档]
    B --> Push[核对 main + origin/main + Altman-sam114 / push]
    Push --> Static[云端 diff / plist / YAML / Python / 超时契约]
    Static --> Smoke[RulesSmokeTest]
    Smoke --> Build[Xcode build-for-testing]
    Build --> XCTest[云端 iPad 全部 XCTest / 资源 alpha 与预算 / 独立路线 oracle]
    XCTest --> Four[同 SHA 四图 iPad + iPhone 各默认与真实战果]
    Four --> Gates[尺寸 / 500 KB / 战场亮度 / 可读比例 / 有界重试]
    Gates --> Package[always manifest + JUnit + logs + xcresult + PNG]
    Package --> C[C 下载 exact 最新 commit / run / attempt artifact]
    C --> Review[核对身份 / 实际测试数 / 逐图检查 / 源码边界]
    Review --> Decision{X 判断}
    Decision -->|通过且仍需迭代| A
    Decision -->|不通过| B
    Decision -->|目标完成| Done[交付本轮与剩余风险]
    Decision -->|停止条件| Stop[暂停并请求必要人工决策]
```

JUnit 的阶段数不冒充 XCTest 数。四图不证明触屏、VoiceOver 或全部设备实测。失败也产包；不回滚远端，只追加修复。当前无子智能体，按阶段顺序在当前会话实施。
