# 项目核心流程

## 当前架构（v3.0 战争沙盘）

规则唯一事实源是 `GameState`。地图优先界面使用共享尖顶六角投影、地图级静态 Canvas、透明交互地格、原创精细预渲染兵模和按需边缘指挥面板；没有另建简化战斗状态机。

## 模块职责

- `GameModels.swift`：阵营、兵种、地形、轴向坐标、战役、单位、规则预览与结果值。
- `GameState.swift`：选择、焦点、移动、攻击、反击、AI、补给、士气、据点、命令点、增援、胜负、规划、态势与回放。`mapActionHints()` 在一次只读快照中共享移动路线搜索；单格与批量调用同一判定函数，不建立跨回合缓存。`movementRoutes` 在单次查询内建立地格/存活单位/敌 ZOC 快照；索引推进保留原 FIFO 顺序，成本与 tie-break 不变，独立旧搜索 oracle 逐路线对比。
- `ContentView.swift`：60pt 顶部战役带、全幅战场和本地情报展开状态。情报在宽屏右缘覆盖、窄屏底部覆盖，不挤压地图。
- `BattlefieldCommandDeck.swift`：战役菜单、资源、结束回合、地图缩放/重开、单一选中单位动作坞、战况通讯条、编队/据点与支援开关。支援和定位轨道默认收起。
- `BattlefieldChrome.swift`：AL/OBJ/AX 全量横向定位轨道、焦点滚动、紧凑行动标记和共用 HUD 小组件。
- `BattlefieldCommandPanels.swift`：既有详细攻击预览、编队摘要、战术命令和增援面板。详细预览仍可由情报入口访问。
- `BattlefieldInspector.swift`：保留单位详情、任务、地格、战线态势、压力、反制、战果、后勤、AI 时间线与战报；不在本轮重写业务语义。
- `BattlefieldMapLayout.swift`：统一六角顶点、中心、tile frame、全部实际地格的 union bounds、24pt 留白及缩放尺寸；另有纯值 `UnitReadinessPresentation`。
- `BattlefieldTerrainRenderer.swift`：一个静态 Canvas 组合原创草土底材、少量低频田块与透明树丛/岩脊/村镇/雪林。雪地按真实 snow 格中心覆盖柔化漂雪，不再硬填白色六角。道路/河道沿真实邻接的共享边中点连接，双邻接用中心为控制点的二次曲线；无随机状态、计时器或网络。
- `BattlefieldRoadNetwork.swift`：从真实道路邻接派生 canonical 主干及有界长回边，仅用于画路，不改变路线和移动成本。
- `BattlefieldMap.swift`：透明战术地格、标记、单位层次、稳定 coordinate ID、UIKit 输入桥和 SwiftUI 无障碍摘要。静态地形不再嵌入每个交互 View。
- `BattlefieldCombatFeedback.swift`：真实执行坐标上的交战轴线、HIT/RET/HP 前后、可取消反馈序列和 Reduce Motion。
- `BattlefieldUnitRenderer.swift`：呈现八款原创透明坦克、火炮、三人步兵与轮式侦察车，统一左上光源与接地阴影；不再逐实例重画几何图标。
- `BattlefieldArtwork.swift` / `BattlefieldArt/`：四份原创 PNG 随包离线使用，ImageIO 一次解码，三个 2×2 atlas 按固定象限裁成 12 个 CGImage 静态复用；资源读取失败由云端资源测试拒收，不关联任何 GameState。
- `BattlefieldUnitViews.swift`：将领/军衔/CUT/战术状态、实线 AL / 虚线 AX 阵营环与字码、五段 HP、独立移动与攻击槽。模型放大但不扩大输入六角；小实/虚线阵营环不再叠不透明棋子底座。spent 严格为 `hasMoved && hasAttacked`。
- `BattlefieldTheme.swift`：橄榄炭灰 chrome、浅色正文与克制黄铜强调。

## 地图坐标与渲染

规则仍使用 `HexCoordinate(q,r)` 和原有六邻接、距离。v3 将旧版不密铺的扁顶图形/近似步长组合整体替换为尖顶投影：

```text
width = 86; height = 100
rawCenter.x = (q + r/2) * 86 + 43
rawCenter.y = r * 75 + 50
bounds = union(全部实际 tile frame) + 24pt 四周留白
center = rawCenter + 统一 offset
```

六角顶点与投影相符：每个邻格恰好共享两个顶点；不再漏算最右下行偏移，不因选中/战果重算另一套位置。Canvas、交互格、单位、轴线、战果、滚动尺寸共用布局。`HexInputReader` 在 tile 固定 frame 内组合；tile 自身缩放后由 SwiftUI Layout 放置，滚动锚点使用实际已缩放子视图 frame，不再包整图 `.position` 或依赖整图 transform。地形/轴线/战果独立使用相同比例。交战相关焦点定位双方中点，HIT/RET 固定 140pt、结论 174pt 并夹紧地图边缘。

绘制顺序：连续底材与静态地貌 → 透明交互格的 owner/控制区/可达/路线/补给 → 单位与 HP/行动槽 → 焦点、目标与局部 marker → 交战轴线与真实战果 → 边缘 chrome。装饰不命中并隐藏于无障碍树。普通格低对比边界，选中/目标/可达才强调。

## 操作与规则状态流

1. 战役菜单调用 `selectScenario(id:)`；重开调用 `restart()`。
2. 直接点击、鼠标主键、次键分别转发 `handleTap`、`handlePrimaryAction`、`handleSecondaryAction`，没有 Canvas 私有点击规则。
3. 友军轨道 `select(unitID:)`，敌军 `focus(unitID:)`，据点 `focus(coordinate:)`；完整数组、既有排序不截断。焦点变化使地图与轨道按稳定 ID 滚动，不执行命令。
4. AI 复盘的关键事件先按是否占点分组，再按原有战果分数降序及事件 order 升序；保持真实 timeline 和 AI 行为不变。
5. 单位选择后从 `mapActionHints()`、可达/攻击/控制区/补给、路线步骤、接敌位和预判驱动叠层。
6. 动作坞显示真实 HP 与 M/A 状态，攻击/接敌/据点按钮只调用现有 focus 入口。执行仅调用 `executeFocusedCommand()`；详细 `focusedCommandPreview` 与 `combatPreviewAgainstFocusedTarget()` 在情报中保留。
7. 移动仍经 GameState 路线搜索、地形适性、控制区成本、占据与剩余行动校验；攻击仍经距离、兵种/地形/将领/士气/夹击/防御姿态和经验规则，移动后再攻击不绕过校验。
8. `CombatResultSummary` 保存执行时双方坐标、伤害、HP 起止、反击和击毁事实；反馈不从当前焦点或消息猜测。正常序列可取消、2.4 秒 resolved 后透明度退场；Reduce Motion 不做缩放/移动，steady CI 参数固定真实 resolved。
9. `endTurn()` 推进轴心 AI，再恢复盟军行动，继续执行后勤、目标、任务和胜负规则。AI 时间线/复盘、反制执行回放/敌方回合复核、据点压力、态势响应历史均保留原 GameState 链路。

## 云端验证与验收

人工要求不做本地测试；本地只 Git/text 审查。`main` push → static（diff/plist/YAML/Python/timeout 契约）→ Rules smoke → Xcode build-for-testing → 已有云端 iPad 真正运行全部 XCTest → iPad/iPhone 各默认/真实选中战果两图 → always 生成结果包 → Agent C 下载最新 exact artifact。

四图均记录 device/UDID/runtime、场景、portrait、尺寸、bytes、SHA-256、亮度与可读比例。保留至少 500 KB 初筛，新增战场中央平均亮度 ≥45/255、≥45% 采样点亮度 ≥55，并至少等待两次截图机会；最多 8 次重试，拒绝早期 launch fade。大小与采样仍不能替代人工视觉检查。

资源门禁校验四图随包解码、固定格位、12 sprite 透明边缘/可见主体、静态复用和 24 MB 预算；结果包另存各资源字节与 SHA-256。manifest 分开记录 build、真实 test outcome/count/failure/skipped/result bundle 与四图。JUnit 的 CI 阶段和实际 XCTest suite 分离。没有 UI test target：拖动、触屏命令、VoiceOver、Dynamic Type、横屏与 Reduce Motion 的行为没有运行证据时只作源码审查，不宣称实测通过。

## A → B → C → X

本轮不启动子智能体：当前会话依次完成 A 版本化方案、B main 实现/push、C exact 最新包验收，X 依据证据推进/退回/暂停。旧 run、旧 screenshot、本地半成品均不得冒充最新通过。相同原因 CI 连续失败、同阻塞三轮、无有效 diff 两轮或需要账号/人工决策时停止无条件循环。
