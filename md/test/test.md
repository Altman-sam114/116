## 当前验收状态：v3.3 全幅战场与贴边指挥，待最新云端包

首轮最新提交 `5f51cac6bc2040829100633aa574b4a73550bbf3` / run `40618452705` / attempt `1` failure。exact artifact `ww2tactics-ci-v3.3-main-5f51cac-run40618452705-attempt1`（id `12786923387`，177,812,112 bytes，API digest `sha256:4a1e68a1383e5cb7a753ebd35e2914f785ac54846b3a94e709c5050ae853e743`）。完整包下载过慢而中止；从同一已认证 artifact 使用显式 HTTP 范围下载 manifest/summary/JUnit/全部主日志/真实 unit 和 UI summary，逐 ZIP entry 校验 CRC；目录 `/private/tmp/ww2tactics-c-review-40618452705/`，没有宣称完整 archive SHA 校验或全套 xcresult 本地读取通过。

已确认 static/smoke/build/152 actual unit（0 failed / 0 skipped）成功，四张竖屏门禁成功；两设备各 1 项 UI 在 VisualTests 第 29 行“情报关闭按钮出现”断言失败，横屏六图阶段失败。首启恢复确实工作：iPad 第一次 240 秒超时、第二次成功，累计 335.6 秒；iPhone 90.9 秒成功。失败与前轮纯启动超时不同，不以 unit 通过掩盖 UI 问题。

纠正为 plain 图标和命令明确 label contentShape、HUD/情报显式覆盖层级、情报开关/关闭稳定 ID；保留并增加 hittable 断言，不删情报/移动/回合链。defer 始终保留最终原图和界面层级，云端 UI 失败也导出诊断、按原断言结论失败；诊断不冒充六张合格图，workflow 仅增加 txt 原附件上传。仍不运行本地测试/语法检查/构建/模拟器。详情见 `v3.3-cloud-review.md`，等待追加修正 SHA 的全套云端结果。

2026-10-28（Asia/Taipei），按人工要求普通任务直接迭代，不走 A/B/C、不启子智能体、不做任何本地项目测试或构建。已 fetch 并核对 main/origin/main `752b35972be46dd6846cc8f7d6ae92e6819868cd`，最新 run `40079663176` / attempt `1` failure；Altman-sam114 认证下载 exact 包 `ww2tactics-ci-v3.2-main-752b359-run40079663176-attempt1`（id `12554434327`，45,336 bytes，digest `sha256:e1f63178690da5a600af62a8a095be624d9ba9f0ef8451dbf56a659216bcaf58`）至 `/private/tmp/ww2tactics-c-review-40079663176/`。manifest/JUnit/summary/主日志一致：static/smoke/build 成功，iPad 首启 CoreLocation 数据迁移超时；0 actual tests，UI/六图未执行，属于模拟器环境失败，不是规则断言失败，更不是验收通过。

本轮接续已有同方向 UI 草稿，不回滚；原 147 项不删，增加 5 项，目标 152 actual：道路成对连接完整性/无重复/端点/顺序确定性、单边及非法方向拒绝、静态地形 Equatable 身份、MOVE 文字牌焦点/终点过滤、攻击聚焦仅当前对象。沿用六 PNG/20 sprite/24 MB 资源门禁。

两设备各 1 项真实 UI 测试保留旋转/frame/结束回合命中/M10/情报开合与双帧原图，增加“下一支第4装甲师 → 据点预览 → 执行 → 移动资源可用变已用 → 第二回合”的真实按钮链及执行后原始附件。此设计不等于已实测通过；最新 run 执行结果才是证据，不证明逐格直接触摸、拖动、鼠标、VoiceOver 或全字号。

云端启动由并行改为串行，减少首启迁移争抢；单次 bootstatus 仍 240 秒，失败只 shutdown/reboot 同一既有设备一次并记录尝试/耗时。每设备独立捕获错误，后续设备仍执行诊断；如果 unit 尚未启动，下一个成功设备执行一次，不因断言失败换设备重试。总 workflow 35 分钟上限不提高。所有原静态/smoke/build/unit/UI/六图门禁保留，原附件不修图、不转像素。

本地只 Git/text 审查、下载并查看云端包/既有图像，未运行 diff --check、YAML/Python/plist/Swift/smoke/XCTest/Xcode/模拟器或 app 截图。原始云端启动失败包没有图，为视觉基线另下载其紧邻前轮 `40077251421` 必要包查看四张有效竖屏；旧包明确不作 v3.3 通过证据。等待本轮 main 新 SHA 的 exact 包。

## v3.2 历史实施与纠正过程

2026-10-24（Asia/Taipei），本轮不走 A/B/C、不启子智能体、不做本地测试。先同步核对最新 `origin/main=479ed12ac4ec88df4e7bce26b86cb84b1eb5c50f` / run `40056322104` / attempt `1`，exact artifact `ww2tactics-ci-v3.1-main-479ed12-run40056322104-attempt1`（id `12545409200`，digest `sha256:268f50f3688122580de2c12ad459893a0855fb2351a1a88c11ca9e69abcab5e1`）已下载缓存且本次逐项复核。140 actual / 0 failed / 0 skipped，static/smoke/build/test 成功；四张 PNG 身份匹配并逐图打开，但 iPhone 战果图有 Apple Intelligence 系统通知遮住顶栏，视觉问题不因 CI success 被掩盖；详见 `v3.1-cloud-review.md`。

v3.2 保留全部 140 项，新增 7 项：命名军械与兵种边界、错误阵营/兵种回退、城镇河道相对邻接、真实两岸桥梁、城镇街道成对连接和 canonical 保留、地貌确定性/多样性、短横屏视口分档。目标实际 XCTest 147 项（116 规则 + 31 表现/资源/导航），不以源计数代替实际运行。原资源测试扩展为六 PNG/20 sprite，预算仍 24,000,000 bytes。

首轮 `16d499de0a3dc06fa4b632f3054154aaa85f9414` / run `40077251421` / attempt `1` failure。已下载 exact artifact `ww2tactics-ci-v3.2-main-16d499d-run40077251421-attempt1`（id `12553689900`，49,447,636 bytes，digest `sha256:306d453ffcfcc77ded0df516bed7a036f73289af20489b972a1dea785c1e249c`）到 `/private/tmp/ww2tactics-c-review-40077251421/`。static/smoke/build 成功，147 actual / 0 failed / 0 skipped，四张竖屏成功且无已知系统通知；横屏像素仍竖向，故六图阶段失败。iPhone 图实看为横界面侧躺在竖向设备画布，iPad 请求未生效；不能旋转 PNG 修饰通过。规则测试实际约 3 秒，整 run 17m2s 主要为首启迁移、截图等待/方向失败重拍，不归咎规则性能。

纠正：新增 `WW2TacticsVisualUITests`，主 unit 命令明确 `-only-testing:WW2TacticsTests` 保留 147 actual；两设备分别 `-only-testing:WW2TacticsVisualUITests` 各跑 1 项真实 UI 测试，用 XCUIDevice 旋转、验证横向 frame、结束回合可点、M10 可见与情报开合，并保留相隔一秒的两个命名原始 app screenshot 附件。云端 `xcresulttool export attachments` 只按 manifest 明确名字取图，原字节复制，不旋转/裁剪/消除通知；两帧都经 ≥500 KB/亮度/Vision/实际方向门禁。新增独立 `landscape-ui-tests` 阶段、UI summary/result bundle 与 JUnit suite，CI 阶段/147 unit/2 UI 分开计数。原四图与 8 次有界重拍不减。云端只并行 boot 两个现有设备减首启等待，不并发测试、不创建设备。app 的 DEBUG 强制方向钩子移除。

剩余：新 UI 用例不证明地图触屏命令、鼠标/拖拽、VoiceOver、全字号或全部缩放；以纠正 SHA 的云端真实结果为准。

本地只 Git/text 范围审查与原创源图元数据/alpha 读取及复制，没有运行项目测试、diff --check、plist/YAML/Python 语法测试、Swift/Xcode/模拟器/app 截图；所有门禁由 push 后最新 SHA 的云端结果决定，不预填通过。

## v3.1 历史实施与纠正过程

2026-10-24（Asia/Taipei），Agent X 按人工最新指令直接实施，不走 A/B/C 串行、不启子智能体。已重新 fetch 并核对最新基线 `60ee9a7825c70cf7260bb06580d59a9a4e7dff0f` / run `39823597384` / attempt `1`；认证账号 Altman-sam114，exact artifact `ww2tactics-ci-v3.0-main-60ee9a7-run39823597384-attempt1`（id `12446114032`，36,443,119 bytes，digest `sha256:0b11b516c5b6e04862aa0c0bbe636d5bc4440ee3dd9b81305d98dcdfef87e634`）已下载到 `/private/tmp/ww2tactics-c-review-39823597384/`。manifest、failure summary、JUnit、static/smoke/build/test 日志、summary 和四图已核对；五阶段通过，131 actual / 0 failed / 0 skipped，四图逐张打开并核对 SHA-256。

v3.1 不改 GameState/GameModels。已有 131 项用例全部保留，新加 9 项：最近存活双方前线的确定性、阵营缺失/非法 scale 回退、重开镜头身份、全部地图缩略投影 round-trip、空集/无效尺寸/边界拒绝、空白角与稀疏地图间隙拒绝、河岸共享点/宽/切线、河岸分叉/端点/孤立/有限性、总览导航不执行指令。目标真实 XCTest 为 140 项（116 规则 + 24 表现/资源/导航），以新 SHA 实际报告为准；不得用源函数计数代替执行。

80 个旧 Inspector 顶层声明按领域拆分，文本审查确认无遗漏且除共享访问级别外无内容变更；这不是 Swift 编译或运行通过。新增源文件已加入 Xcode Sources，由云端 plist、build-for-testing 和真实 XCTest 验证。四张新图还须看到双方前线、低对比连续雪原、变宽河岸、宽屏总览、右上情报入口与完整 HIT/RET；小地图不伪造视口矩形。触屏、VoiceOver、横屏与全部 Dynamic Type 仍无运行证据。

本地仅 Git/text 编辑、范围审查、下载云端包与查看参考/云端图片，不运行项目编译、smoke、XCTest、plutil/YAML/Python 语法测试、模拟器或 app 截图。所有门禁由 main push 后云端完成，历史本机命令不覆盖本轮人工限制。

首轮 `3361cae` / run `40054994609` / attempt `1` 的 exact artifact 已下载核对：static/smoke success，build 因小地图三元 Path 类型推断超时失败，实际 XCTest/四图未运行。已拆分显式绘制函数并追加修复，门禁和 140 项目标不变，等待新 SHA；详见 update_log。

第二轮 `d6eb879` / run `40055783651` / attempt `1` 已下载核对：原类型推断超时消除，build 暴露默认无障碍 action 调用签名错误，static/smoke success、XCTest/四图未运行。改成尾随闭包，不更改测试、timeout 或规则；继续等待修复 SHA 全套证据。

### v3.0 历史技术与美术纠正过程

C 已下载核对 `origin/main=c3a2f6c7ea869cb4d4daeb55e4ab2ddc284bc525`，run `39813336318` / attempt `1`，artifact `ww2tactics-ci-v3.0-main-c3a2f6c-run39813336318-attempt1`（id `12442631249`，18,566,892 bytes，digest `sha256:63a306c05c048f8bc7dbafed6b904e70bf585fe0ef2fa39c281702ec0b6cd572`），目录 `/private/tmp/ww2tactics-c-review-39813336318/`，约 19M。五阶段 success，127 XCTest 全通过/0 skipped，四图逐张查看，交战中点与 HIT/RET 裁切修复通过。实际 XCTest 用时 132.994 秒；不能把 CI 等候/模拟器启动耗时都归给规则测试。

几何美术仍未达到人工目标，故继续原 v3.0 的 C 退回 B，不虚称总目标完成。本轮增加四份原创 PNG 与原生缓存/裁格读取、连续地貌/曲线河路、精细兵模和 HUD，新增三项资源解码/透明度/格位/24 MB 预算测试。movementRoutes 只读快照优化增加独立旧 FIFO 搜索 oracle，逐真实战役、全部单位、双方行动阵营比较完整路线，不削减旧用例。目标真实 XCTest：131 项（116 规则 + 15 表现/资源），仍须由本次最新 SHA 的全套云端结果验收。

本地只 Git/text/资源复制与原图元数据、alpha 像素读取，不运行任何项目编译、smoke、XCTest、模拟器或 app 截图。生成工具原图检查不是游戏集成测试，实际资源门禁也只在云端执行。历史失败和原停止证据保留在 `v3.0-cloud-review.md`。

# v3.0 当前云端验证基线

人工明确不做本地项目测试；本地只 Git/text diff/status/范围审查与美术资源复制/原图检查。YAML/Python/plist/Swift/smoke/XCTest/Xcode/模拟器/截图全部在 GitHub Actions，本轮不执行旧文档中的本机命令。

## 当前必需门禁

- 云端 static：`git diff --check HEAD^ HEAD`（有父提交时）、`plutil -lint`、Ruby YAML 解析、Python `py_compile`、`run_with_timeout.py --self-test`。
- 云端 Rules smoke：编译 GameModels/GameState/RulesSmokeTest 并真实执行；包含批量地图提示与单格入口一致性。
- 云端 build：`xcodebuild ... -destination 'generic/platform=iOS Simulator' build-for-testing CODE_SIGNING_ALLOWED=NO ARCHS="$(uname -m)" ONLY_ACTIVE_ARCH=YES`，只编译 runner 的原生模拟器架构，覆盖该 runner 上两种设备。截图检查器失败不阻止独立实际 XCTest 执行。
- 云端真实测试：已有 iPad 上 `xcodebuild ... -destination 'platform=iOS Simulator,id=<云端UDID>' -parallel-testing-enabled NO test-without-building CODE_SIGNING_ALLOWED=NO`；900 秒上限，保存独立 `xctest.log` 与 `WW2Tactics-tests.xcresult`。
- `xcresulttool get test-results summary/tests` 输出真实总数、失败、跳过及用例树。总数不得少于测试源中所有零参数公开 `func test...()`（排除 private 带参数 helper），失败/跳过必须为零才通过；CI 阶段数不冒充 XCTest 数。
- 同 commit/run/attempt 四图：`battlefield-ipad-default.png`、`battlefield-ipad-selected-combat-impact-steady.png`、`battlefield-iphone-default.png`、`battlefield-iphone-selected-combat-impact-steady.png`。
- 每场景明确 terminate/relaunch；默认无启动参数，战果只用公开 action。每图 ≥500 KB，中央战场采样 mean ≥45/255、≥45% 点亮度 ≥55，连续两帧可读，最多 8 次×6 秒等待；保存尺寸、bytes、SHA-256、device/runtime/UDID、portrait、场景与 outcome。亮度门禁不替代 Agent C 逐图检查。
- always 上传 manifest（含美术资源摘要）、artwork-resources.json、failure summary、阶段与实际 XCTest JUnit、static/smoke/build/test/screenshot 日志、两个 xcresult、四图及元数据；不上传 DerivedData、缓存、运行时或编译出的辅助二进制。

## 旧测试夹具审计

首次真实执行暴露的 7 项旧用例已逐项审查：不删用例/断言、不 skip、不更改生产规则。修正提前胜利与堵路的夹具，拆分弹幕/断补给伤害，明确 ZOC 成本、响应坐标优先和完整意图查询，并补全局回放与射程外断言。实际集合为既有 115 + 新增 10 = 125 个零参数测试；另 2 个 private test... helper 不计数。后续修复增加 2 个几何测试，美术纠正增加 3 个资源测试和 1 个独立旧寻路 oracle，当前目标为 131；以最新 SHA 的实际集合为准。

## 新增表现层测试

`BattlefieldPresentationTests.swift` 覆盖两战役全部 tile/最右下的 union bounds、六邻格完整共享边、统一投影中心、缩放边界、空集/负坐标/非法 scale、四种 M/A 状态、带非零 origin 的绘制与命中、真实攻击证据不变；批量提示对全部战役/兵种和空闲/耗尽/胜利状态与单格提示逐格等价且只读。全部既有 GameStateTests 保留。

## 证据与停止边界

v2.64 最新基线 `4b49cd3677236b9bbc67c7ee1054412dada84b04` 的 run `38343683400` / attempt `1` 已下载核对：static/smoke/build/timeout 契约成功，XCTest skipped，regular PNG 实看偏黑，因此不是 v3.0 验收通过证据。v3.0 当前等待新提交的云端结果，不能预填 run 或宣称通过。

无 UI test target，触屏、鼠标、拖动、VoiceOver、横屏、Dynamic Type 和 Reduce Motion 没有运行证据时只能源码审查。相同原因 CI 连续失败按 AGENTS 停止条件处理，不靠无限提高 timeout 或削弱断言通过。

---

# 历史验证规范（v2.64 及之前）

以下保留历史契约和旧命令供追溯，涉及 regular-only、XCTest skipped 或本地命令的段落不覆盖当前 v3.0 门禁。

## v2.64 云端超时执行恢复（待验收）

人工要求全部云端，本地仅 Git/text 范围审查，不执行 YAML、Python、plutil、Swift、Xcode、smoke、XCTest、模拟器或截图。macOS runner 不保证 GNU `timeout` 存在，所有有界构建/模拟器命令统一使用 `python3 .github/scripts/run_with_timeout.py <seconds> <command>...`；返回原始退出状态，超时为 `124`，缺少命令为 `127`，启动异常为 `126`。

云端 static 阶段执行 `python3 .github/scripts/run_with_timeout.py --self-test`，在 `timeout-contracts.log` 记录成功、普通失败、超时、缺命令、信号退出和忽略 TERM 的子孙进程回收契约；任一失败进入 static 总门禁。同时在云端执行 YAML 解析、`git diff --check` 和项目 `plutil -lint`。Rules smoke、Xcode build-for-testing、regular `selected-combat-impact-steady` 500 KB PNG 门禁保持；XCTest 仍 skipped，不能称为实际执行通过。Agent C 必须下载最新 commit/run/attempt 的包，核对契约日志并打开 PNG 后才能确认恢复；旧 run `38342329685` 因 `timeout: command not found` 未产图，不是游戏规则失败。

## v2.57 云端验证边界

本轮是 SwiftUI 表现层改动；本机只运行 `git diff --check`、`git diff --name-only`、`git status --short --branch` 和范围 `rg`，不运行 Swift、RulesSmokeTest、XCTest、Xcode、模拟器或截图。push 后 GitHub Actions 必须运行 static checks、Rules smoke、Xcode build-for-testing 和 `selected-combat-impact-steady` regular screenshot；Agent C 需下载 exact artifact、核对 manifest 的 commit/run/attempt 并打开 PNG。XCTest 若仍为 skipped 必须照实记录，regular PNG 不覆盖 compact、窄宽、Dynamic Type、VoiceOver、Reduce Motion 等证据边界。

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
- v2.0 人工明确禁止本地 build、typecheck、RulesSmokeTest、XCTest、模拟器和本地视觉测试；Agent B 仅允许执行 Git diff/status/范围检查，重验证必须由最新 `origin/main` GitHub Actions run 承担。静态范围检查不是测试，不能表述为代码或视觉已通过。
- v2.1 把云端视觉证据纳入 CI：build-for-testing 成功后必须启动可用 iOS Simulator、安装并启动 app、生成 `battlefield-screenshot.png` 和截图日志；manifest、failure summary、JUnit 和最终门禁都必须记录 screenshot outcome。验收必须实际查看 PNG，文件存在本身不能证明 app 画面正确。
- v2.2 的云端截图验收必须和 v2.1 基线对比：顶栏从多行降为单行，地图区域增大，支援甲板默认收起，普通地格代码减少，单位主体放大；同时确认高优先级 marker、地图输入和 Inspector 没有被遮挡或移除。
- v2.3 的云端截图验收必须确认 Inspector 默认收起、地图占满顶栏以下宽度、右缘抽屉按钮可见、六角地图与单位占比高于 v2.2；代码审查同时确认 Inspector 内容和既有 `GameState` action 未删除，抽屉状态不进入规则层。
- v2.4 的云端截图验收必须和 v2.3 对比普通地貌拼花：平原/山地/雪地不再显示同形中心辐射，森林/城市/山雪纹理存在稳定变化，河流与道路仍连续且不过粗；同时确认 tile frame、命中输入、单位和 marker 层级不变。
- v2.5 的云端截图验收必须确认四类单位在不依赖文字时仍可区分、盟军/轴心军械色板不同、内部结构线与落地阴影可见、五段 HP 不改变比例；同时确认 Commander、rank、CUT、战术状态、spent 和地图 marker 没有被遮挡。
- v2.6 的云端截图验收必须和 v2.5 对比地图上下空带：默认战役档应让六角地貌覆盖地图工作区高度，首屏仍能看到双方单位、河流和据点；代码审查确认缩放只改变渲染/滚动 frame，tile frame、坐标、命中、marker、HUD 与 `GameState` 不变。
- v2.7 的云端截图验收必须确认空闲态右上大型信息卡已替换为小型边缘 `NEXT` 指挥坞，地图继续满幅显示且双方单位、Inspector、目标跳转坞和支援甲板入口仍可见；代码审查确认选中单位使用蓝色光环与四角框、聚焦 ATK/POS 目标使用红色/橙色四角准星，并且这些只读叠加不改变 tile frame、命中、marker 或 `GameState`。
- v2.8 的云端截图验收必须和 v2.7 对比地图单位：四类军械不再被大面积圆形阵营底板包裹，透明模型与地面环的落地关系更清楚，蓝/红、实/虚线和 AL/AX 仍能区分阵营；同时确认 Commander、rank、CUT、战术状态、spent、HP 和 marker 没有丢失或明显遮挡，非地图 `UnitShapeBadge` 与规则边界不变。
- v2.9 的云端截图验收必须和 v2.8 对比地貌纵深：平原存在柔和田块深浅，森林有树冠前后层与落影，城市有道路底槽、屋顶和投影，山地有闭合明暗面，雪地有冷色凹陷；河流/道路暗边、主体和高光仍沿同一邻接 Path 连续且不过粗。代码审查同时确认所有变体仅由 q/r seed 派生，tile frame、坐标、命中、marker、单位和 `GameState` 不变。
- v2.10 的云端截图必须使用 `--ci-selected-approach-preview`，并在截图日志、failure summary 与 manifest 记录 `selected-approach-preview`。PNG 必须同时显示 M10 的蓝色选中地面环/四角框、敌方装甲侦察营的橙色 POS 准星、接敌位置提示和已选单位动作 HUD；代码审查必须确认场景只复用 `handleTap`/`focus`，不执行行动、不直接写规则字段，且无参数启动保持默认状态。
- v2.11 的云端截图必须与 v2.10 选中态对比：MOVE 的 `M5` 缩为 `5`、攻击伤害去掉 `A`、`POS3` 缩为 `P3`、`THR` 缩为 `!`，胶囊 padding 更小；当前焦点仍由橙色准星和完整动作 HUD 表达，HUD 的 MOVE/ATK/THR/SUP 数量保持一致。代码审查确认 marker 保持 v2.10 已验证的单一 HStack 结构，不修改 `GameState`、actionHint、命中或 accessibility 主摘要。v2.11 attempt 1/2 曾生成完全相同的 117,630-byte 黑屏 PNG，修复 commit `9f57329` 仍生成 155,086-byte 黑屏并被新门禁正确判失败；截图必须至少 500 KB，且 Agent C 仍须实际查看画面。
- v2.12 的云端截图必须使用 `--ci-selected-attack-preview`，场景元数据为 `selected-attack-preview`。启动链必须通过 `handleTap(q7,r6)` 和 `handleSecondaryAction(q9,r6)` 让 M10 真实进入攻击位但不自动攻击；PNG 必须显示红色 ATK 目标准星、双方当前/预计 HP、HIT、RET、OUT 和至少 44pt 的“开火”按钮。Agent C 必须确认截图仍是攻击前状态、PNG 至少 500 KB，且代码只读取 `.attack` 关联值与 `combatPreviewAgainstFocusedTarget()`，没有在 View 重算伤害。
- v2.13 的云端截图必须与 v2.12 的 5,875,823-byte ATK 截图对比：火力解算、红色目标准星、焦点 ATK 伤害标记和双方模型/HP 保持，攻击方到目标间新增清晰交战轴线；全图控制区圆点/边线、射程覆盖点、非焦点命令和次要态势 chips 显著减少。代码审查必须确认仅由 `.attack` 派生视觉过滤，底层集合、tile accessibility、frame、命中和 `GameState` 不变，轴线禁止 hit testing。
- v2.14 的云端截图必须使用 `--ci-selected-combat-result`，场景元数据为 `selected-combat-result`。启动链复用 `handleTap(q7,r6)`、`handleSecondaryAction(q9,r6)` 和 `executeFocusedCommand()` 真实结算攻击；PNG 必须是 HP 已改变的攻击后状态，并在原交战位置显示 HIT、RET、双方 HP 前后和交火/击毁结论。XCTest 与 smoke 必须断言 `latestCombatResult` 保存执行时双方坐标；代码审查确认地图不重算伤害、不从攻击后的 selected/focused 状态猜测位置，叠层禁止 hit testing 且 PNG 至少 500 KB。模拟器 launch 成功后允许最多 4 次、每次间隔 6 秒的有界截图重试；每次大小必须进入日志，不能降低 500 KB 门禁或把黑屏当成功。
- v2.15 的云端规则验收必须对同一攻击先读取 `CombatPreview` 再执行，断言 `damage`、`counterDamage`、`defenderHPAfterAttack`、`attackerHPAfterCounter` 分别等于 `CombatResultSummary` 的真实值；至少覆盖主伤害降低反击方 HP、士气从稳定跨入低落、攻击方防御姿态清除和攻击方晋升 HP 增益。代码审查确认预判仅修改 `BattleUnit` 值副本并复用 `counterDamageValue`，不写 scenario/log/latest result。selected-combat-result PNG 应继续显示 M10 `RET -7 / 64 -> 57` 和目标 `HIT -21 / 64 -> 43`。
- v2.16 的云端截图必须使用 `--ci-selected-combat-impact-steady`，场景元数据为 `selected-combat-impact-steady`；启动链仍通过公开操作生成真实 `latestCombatResult`，steady-state 只跳过表现计时并复用正常 resolved 视图。PNG 必须同时显示目标格静态冲击残迹、`HIT -21 / 64 -> 43`、`RET -7 / 64 -> 57` 和“交火”，且至少 500 KB、非黑屏、没有大面积遮挡单位、HP、HUD 或输入层。代码审查必须确认每个 `summary.id` 只触发一次可取消序列，新战果和 View 消失会取消旧任务；phase 只在 SwiftUI、所有坐标与数值只读 summary、叠层禁止 hit testing、装饰对 VoiceOver 隐藏且整层只暴露一次摘要。Reduce Motion 必须直接显示完整结果，不得缩放、位移、旋转或震动。
- v2.17 的代码审查必须确认正常战果在 resolved 停留约 2.4 秒后以约 220ms opacity 退场，hidden 后不暴露 VoiceOver 且始终不拦截输入；`.task(id: summary.id)` 的所有阶段写入前检查取消，新结果不会继承旧 hidden。退场只能修改 `CombatResolutionOverlay` 本地 phase，`latestCombatResult`、Inspector、态势响应与复盘继续保留。Reduce Motion 只允许 opacity 退场；`--ci-selected-combat-impact-steady` 必须永久停在 resolved，PNG 继续满足 v2.16 的真实战果和 500 KB 门禁。
- v2.18 的代码审查必须确认地图 `UnitCounter` 使用固定宽度的“移动图标 + 五段 HP + 开火图标”轨道，图标只读 `hasMoved/hasAttacked`，消耗后在原位切换完成符号且隐藏于无障碍树；军械模型与地面环仅在 `hasMoved && hasAttacked` 时降权，底部状态条不能继承 completed opacity，单独移动或攻击不能伪装成完全 spent。`HexMapView` 必须在 tile sibling 层只读派生普通地格、含单位、聚焦单位和选中单位的逐级 `zIndex`，交战轴线和战果叠层必须更高；不得改变 tile frame、坐标、`Hexagon` 命中、`HexInputReader` action 或规则数据。`--ci-selected-combat-impact-steady` 的真实完成态 M10 在 4x 裁切中必须同时看到左右圆槽、完成勾和五段 HP，不得被相邻地形覆盖；同时 PNG 继续满足 v2.16 战果内容与 500 KB 门禁。
- v2.19 的代码审查必须确认 `MapActionHUD` 在无可执行 inline preview 时只有两行主内容：上行同时容纳单位徽章、单行名称/HP、MOVE/ATK/THR/SUP 图标数值和 44pt 待命，下行保留四个总高至少 44pt 的 NEXT/ATK/POS/OBJ。compact `MapHudMetric` 必须隐去可视长标签但用组合 `accessibilityLabel` 完整读出标签和数值，默认 `MapCampaignHUD` 指标结构不变。所有 enabled 条件、action 和 `InlineMapCommandPreview` 条件原样保留，不新增规则状态。`--ci-selected-combat-impact-steady` PNG 必须比 v2.18 `a135f11` 显示更矮的右上动作坞与更多战场，且 HIT/RET、“交火”、交战轴线和单位状态轨道不回归。
- v2.20 的代码审查必须确认底部 `ObjectiveJumpDock` 在 regular/compact 都同时显示 AL、OBJ、AX 三段，每段使用独立横向 `ScrollView`/`LazyHStack` 并遍历完整既有数组，不使用 `prefix`、分页或 `@State` 缓存。单位和据点项目必须固定 72/84pt 宽、50pt 高，点击区至少 44pt；长名称、HP、行动状态和焦点 overlay 不得改变尺寸。单位必须显示模型、HP、M/A 图标与已用勾号，据点必须显示旗标、AL/AX/NEU 和坐标，颜色不能是唯一编码；VoiceOver 必须读出完整动作、名称、阵营/归属、HP、行动和关键状态。代码 diff 不得涉及 `GameState`，友军 `select(unitID:)`、敌军 `focus(unitID:)`、据点 `focus(coordinate:)` 及排序保持不变。`--ci-selected-combat-impact-steady` PNG 必须无需滚动同时看到三段和至少一个完整项目，轨道高度接近 v2.19，且真实 HIT/RET、“交火”、单位状态轨道和紧凑动作坞不回归。
- v2.21 的代码审查必须确认 `BattlefieldView` 已移除地图外消息/重开 HStack，`BattlefieldMessageDock` 只读完整 `game.message`、固定 regular/compact 宽度、至少 44pt 高、单行截断且 `allowsHitTesting(false)`；它必须与右上动作坞同处顶缘而不重叠，并以组合 VoiceOver 读出完整消息。`MapRestartButton` 必须位于 `MapToolbar`、点击区至少 44x44pt 且只调用 `game.restart()`。`GameState`、地图输入、缩放、动作坞和 AL/OBJ/AX 不得变化。`--ci-selected-combat-impact-steady` PNG 必须比 v2.20 多露出纵向地图，同时保留 HIT/RET、“交火”、单位状态和三段定位轨道。
- v2.22 的代码审查必须确认 `CommandTitle` 只用一行显示 WW2、战役名和年份；`StatusStrip` 保留回合、剩余、阵营、据点、指令点和待命单位全部六项，并在既有横向滚动中只显示图标与短值，不得使用 `prefix`、分页或缓存。每个 `StatusChip` 必须组合提供完整 accessibility label/value。`EndTurnButton` 必须是稳定 44x44pt 的 plain 圆角方形按钮，只调用 `game.endTurn()` 并保留 winner 禁用条件。`GameState`、战役菜单、地图输入、通讯坞、动作坞和 AL/OBJ/AX 不得变化。`--ci-selected-combat-impact-steady` PNG 必须比 v2.21 的顶栏更薄、更低噪音，同时保留真实 HIT/RET、“交火”、单位状态和三段定位轨道。
- v2.23 的代码审查必须确认 `UnitModelView` 只从 `UnitKind/Faction/isSpent` 派生暗色厚度、主材质、装备面、结构线和高光；坦克、火炮、步兵与侦察车的 plate/highlight 路径必须具有各自装备特征。地图模型放大不得修改 `HexTileView` frame、contentShape、输入、marker 或 zIndex；阵营环、AL/AX、军衔、将领、CUT、战术状态、五段 HP 和移动/攻击轨道必须保留。所有新装饰层隐藏于无障碍树，`UnitCounter` 仍只暴露完整组合摘要；completed 降权继续严格等于 `hasMoved && hasAttacked`。`--ci-selected-combat-impact-steady` PNG 必须比 v2.22 更清楚显示模型厚度和军种结构，同时保留真实 HIT/RET、“交火”、动作坞与 AL/OBJ/AX，且不得发生 sibling 遮挡回归。
- v2.34 的代码审查必须确认 `CombatDamagePlate` 只展示 `CombatResultSummary` 提供的 HIT/RET、伤害和 HP 前后值，主攻击/反击使用不同图标与文字双重编码；两块牌必须是稳定单行布局，装饰隐藏于无障碍树，整层仍只暴露既有完整摘要。不得修改 `CombatResolutionPhase`、任务时序、Reduce Motion、steady-state、地图坐标、输入或 `GameState`。`--ci-selected-combat-impact-steady` PNG 必须完整显示 `HIT -21 / 64 -> 43`、`RET -7 / 64 -> 57` 和“交火”，铭牌明显矮于 v2.33 双行黑牌，且军械模型、HP 状态、交战轴线、动作坞和 AL/OBJ/AX 不得被大面积遮挡。
- v2.35 的代码审查必须确认选中 border、reticle、`SelectedUnitGroundHalo` 和 `UnitCounter` offset 只读既有 `isSelected` 并共享暖金 token；选中状态必须以实体底座、细边、四角框、3pt 抬升和阴影共同编码，不能只依赖颜色。offset/shadow 不得改变 tile frame、contentShape、输入、zIndex、单位摘要或 `GameState`。`--ci-selected-combat-impact-steady` 真实结算后必须通过公开 `handleTap(latestCombatResult.attackerCoordinate)` 重新选择可见攻击方，且只限 steady-state 参数；PNG 必须能直接定位攻击方，且不与盟军蓝环、轴心红环或红色目标混淆。Commander、HP、战备点、v2.34 HIT/RET、“交火”、动作坞和 AL/OBJ/AX 不得回归。
- v2.36 的云端 `--ci-selected-combat-impact-steady` PNG 必须至少 500 KB 且非黑屏；补给线应由相邻六角格中心到边界的细窄、低对比笔触读作连续战术通道，不再形成整格绿色粗边或重复粗胶囊，单格也不能变成醒目的绿色圆牌。地貌、道路/河流、单位军械、暖金选中焦点、路线、高优先级 marker、v2.34 HIT/RET、交战结论、HUD、AL/OBJ/AX 和单位状态轨道不得被补给层覆盖或降级；`.attack` 过滤、`SUP`/`CUT`、补给计数、VoiceOver 摘要、tile frame、contentShape、输入和 zIndex 保持。代码审查确认路径只来自 `GameState.supplyLineTiles(for:)`，View 不复制 BFS、不修改 `SupplyState`，`SupplyLineMarker` 装饰继续关闭 hit testing 并隐藏于无障碍树。
- v2.37 的云端 `--ci-selected-combat-impact-steady` PNG 必须至少 500 KB 且非黑屏；道路应由 `HexMapView` 的稳定 canonical 无向边网络生成细、低对比的蜿蜒走廊：方向 `0/1/2` 每条视觉边只枚举一次，并向相邻两端投影 paired half-path，不再形成 v2.36 所见的大面积棕色三角、菱形或交叉 lattice。单格道路、端点、三路/多路路口和地图边缘必须可读；孤立格允许确定性短中心笔触；同一道路边不能因两侧 tile 重复叠笔而明显变粗，shadow/主体/highlight 必须共用同一路径且不再有固定水平虚线。河流、弱林带、地貌、v2.36 补给通道、v2.35 暖金 selected、v2.34 HIT/RET、交战结论、单位/HP/行动轨道、MOVE/ATK/POS/路线 marker、HUD、AL/OBJ/AX、输入与 VoiceOver 不回归；代码审查确认 road-only 视觉网络是只读生成森林，不改变 `TerrainKind`、移动力、路线成本、`GameState`、tile frame、contentShape、zIndex 或 `HexInputReader`。
- v2.38 的云端 `--ci-selected-combat-impact-steady` PNG 必须至少 500 KB 且非黑屏；地图底缘应一眼读出单一深色半透明轨道中的 `AL | OBJ | AX` 三段，各自显示数量、完整数组的独立横向滚动和至少一个完整 item；section/item 不得再形成多重厚重卡片墙，item 仍保持固定 72/84pt 宽、50pt 高和至少 44pt 命中区。友军 item 继续 `select(unitID:)`，敌军 item 继续 `focus(unitID:)`，据点 item 继续 `focus(coordinate:)`；完整 VoiceOver、Dynamic Type、Reduce Motion、地图工作区、道路/v2.36 supply/v2.35 selected/v2.34 HIT/RET/交战结论/HUD/单位状态不回归。支援甲板默认收起且标题至少 44pt；展开态不得再次渲染完整 AL/AX 单位卡，`ForceRibbon` 只读数量/READY 摘要，TacticalOrderStrip、ReinforcementDock、MapLegendView 入口仍可访问。代码审查确认不修改 `GameState`、事实数组、排序、缓存、分页、地图 frame、输入、zIndex 或 workflow。
- v2.39 的云端 regular `--ci-selected-combat-impact-steady` PNG 仍必须至少 500 KB 且非黑屏，保留 v2.38 单一 AL/OBJ/AX 背板、ForceRibbon 摘要、道路/补给/单位/战果/HUD；代码审查必须覆盖最窄 compact、`dynamicTypeSize >= .xxxLarge`、长名称不溢出、section 标题与 count 不挤出、每段完整数组继续独立横滚、项目 44pt 以上 Button 命中区和完整 VoiceOver。大字号只改变短可视标签与 16/48pt 内部排版，不增高永久地图面板、不改断点或 action。道路审查必须确认 canonical 无向边只画一次、生成树桥接边/端点保留、含 cycle 的组件至少有一条确定性回边、密集路口不回到 lattice、孤立道路短笔触稳定；`GameState.swift`/`GameModels.swift`/输入/zIndex/路线成本无 diff。workflow 没有 compact/Dynamic Type 专用截图，Agent C 不得用 regular PNG 冒充该部分证据。
- v2.40 的云端 regular `--ci-selected-combat-impact-steady` PNG 必须至少 500 KB 且非黑屏；道路主干、端点、分支、长环路、边界和孤立格应连续可追踪，高密度区域不得由短三角回边主导。源码/纯图审查必须确认 canonical 每条无向边最多一次、主干连通、`cycleRank == 0` 时回边数为 0、`cycleRank > 0` 时每组件最多 1 条，选边总数不超过 `vertexCount - 1 + 1`，重复构造结果一致；AL/OBJ/AX、补给、单位、HIT/RET、输入、tile frame/contentShape/zIndex 和 v2.39 ForEach 修复无回归。workflow 仍只生成 regular 截图，Agent C 不得用旧 v2.39 artifact 代替本轮证据。
- v2.41 的云端 regular `--ci-selected-combat-impact-steady` PNG 仍必须至少 500 KB 且非黑屏，并保留单一底缘 `AL / OBJ / AX` rail、道路、补给、单位、暖金 selected、HIT/RET、交战结论与 HUD。源码审查必须确认三段完整数组和既有排序、72/84pt 宽、48/50pt 高、至少 44pt Button、既有 select/focus action 与完整 VoiceOver 不变；每段只在内容真实溢出时按 section-local viewport/content/minX 显示正确 leading/trailing fade/chevron，cue 层 `allowsHitTesting(false)`，到端不显示错误方向。`focusedUnit`/`focusedCoordinate` 只用对应 section 的 UUID/coordinate 稳定 id 经 `ScrollViewReader.scrollTo` 定位，空/失效 id 不滚动，Reduce Motion 不播放自动滚动动画。workflow 没有 compact、xxxLarge 或多焦点截图，Agent C 只能作源码审查，不能用 regular PNG 冒充这些响应式证据；同时确认 `GameState`、模型、地图/输入、project 和 workflow 无 diff。
- v2.42 的云端 regular `--ci-selected-combat-impact-steady` PNG 必须至少 500 KB 且非黑屏：六角地图仍为主要工作区，顶栏应读为一条克制连续的 War Ledger，完整回合/剩余/阵营/据点/指令点/待命字段、地图 HUD 与单一 `AL / OBJ / AX` rail 清晰，且不被新增厚卡遮挡；道路、补给、单位、暖金 selected、HIT/RET 和交战结论不回归。源码审查必须确认 `WarLedgerSurface`/token 只统一 `TopCommandBar`、`MapHudBackground` 和 rail 底材，`CampaignPicker`、`endTurn`、winner 禁用、所有真实数值、44pt、完整 VoiceOver、v2.41 完整数组/edge fade/chevron/focus scroll/stable id、72/84pt、48/50pt 和 Reduce Motion 不变，并确认 `GameState`、模型、地图/输入、`ContentView`、project、workflow 与测试实现无 diff。workflow 仍只生成 regular PNG；compact、窄宽度、xxxLarge、不同焦点和 Reduce Motion 只可源码审查，不能冒充实拍证据。
- v2.43 的云端 regular `--ci-selected-combat-impact-steady` PNG 必须至少 500 KB 且非黑屏：地图仍为主工作区，静态底图不得出现规则方格、斜刻线、常驻 q/r 坐标牌或系统双轴滚动条，普通六角接缝不得形成白色蜂巢框；低频泥土/纸张底、道路/河流走廊、森林/山体连续块须可读，而单位、据点、补给、暖金 selected、MOVE/ATK/POS、路线/态势 marker、HIT/RET、交战结论、HUD 与 AL/OBJ/AX 不回归。源码审查必须确认 tile frame/position/id、`contentShape(Hexagon())`、zIndex、`HexInputReader`、地图 `ScrollViewReader`/缩放/Reduce Motion、完整 tile VoiceOver 坐标摘要和既有状态 border 优先级不变；`BattlefieldChrome` 仅地图双轴 `showsIndicators: false`，`GameState`、模型、地图数据/road network、输入、`ContentView`、单位、project、workflow 与测试实现无 diff。workflow 仍仅有 regular PNG；compact、窄屏、xxxLarge、多焦点和 Reduce Motion 只能源码审查。
- v2.44 的云端 regular `--ci-selected-combat-impact-steady` PNG 必须至少 500 KB 且非黑屏：六角地图仍为主工作区，tank/artillery/infantry/recon 四类地图棋子在没有新增兵种文字的情况下可由履带/炮塔、炮轮/炮架、三人/步枪与轮组/天线辨识；每枚棋子应读为克制的接地阴影、单一阵营底座/细 rim、暗色厚度、阵营主体漆面、装备结构线和有限顶缘高光，不得出现双重 selected 环、巨大阴影、厚黑卡、强 blur、荧光或遮蔽地貌。源码审查必须确认 `UnitCounter` 的完整 VoiceOver 摘要、HP/ready、rank、commander、CUT/status、spent 条件与 `UnitShapeBadge` 调用语义不变；selected halo/3pt 抬升、marker、HIT/RET、战果 overlay、tile frame/position/id/`contentShape`/zIndex、`HexInputReader`、scroll/zoom/focus、规则和 action 均无 diff。源码仅限 UnitViews/Theme（若无必要 Map 组合无 diff）；compact、窄屏、xxxLarge、多焦点、VoiceOver 与 Reduce Motion 仅源码审查，不能由 regular PNG 冒充实测。
- v2.45 的云端 regular `--ci-selected-combat-impact-steady` PNG 必须至少 500 KB 且非黑屏，并继续以六角地图和军械棋子为主工作区；画面阅读顺序应是结论、HIT 主牌/防守方 HP 前后、真实 RET 次牌/攻击方 HP 前后。源码审查必须确认 `CombatResolutionConclusion` 从 `CombatResultSummary` 的击毁/反击 flags 派生，并为防守方击毁、攻击方反击击毁、交火、压制和无反击提供文字与 SF Symbol 双重编码；`CombatDamagePlate` 保留单行 `HIT -伤害 / HP起止`、真实 `RET -伤害 / HP起止`，不从 message、selected/focused 或当前单位存在性猜测。HIT/RET 要沿既有执行时 attacker/defender 点位和局部 axis 两端布局，短距、斜向和相邻单位不互相覆盖，也不盖住军械模型、HP/行动轨道、HUD、通讯坞或 `AL / OBJ / AX` rail；结论矩形独立于两块铭牌，装饰不命中且隐藏于 VoiceOver，父 overlay 只有一条完整摘要。代码审查还需确认 `CombatResolutionPhase` 成员、`.task(id:)` 取消、约 2.4 秒 resolved 停留/淡出、steady-state、Reduce Motion、地图坐标/frame/contentShape/zIndex/滚动和输入均不变；`GameState.swift`、`GameModels.swift`、`ContentView.swift`、`BattlefieldChrome.swift`、`BattlefieldUnitViews.swift`、`BattlefieldTheme.swift`、测试实现、project 与 workflow 无 diff。workflow 没有 compact/窄宽度/xxxLarge Dynamic Type/多焦点/VoiceOver/Reduce Motion/独立 4x 输出，Agent C 只能作源码审查，不能用 regular PNG 冒充这些证据。
- v2.47 的云端 regular `--ci-selected-combat-impact-steady` PNG 必须至少 500 KB 且非黑屏；地图底材应呈暖纸张白昼明度而非整体偏暗、纯白画布或营销式全屏渐变，普通平原/森林/城市/山地/雪地/河流/道路仍需保留色相与结构差异，道路/河流连续性不能被洗掉。源码审查必须确认明度调整只落在 `BattlefieldTheme.swift` 与 `BattlefieldMap.swift` 的 `MapGridBackdrop`、`HexTileView` 底材和 `TerrainTexture` 局部明暗区域；底材 < 普通地貌 < 道路/河流/据点 < 军械/状态 < marker/战果/HUD/rail 的阅读阶梯保持，v2.46 建筑/旗标/名称牌、v2.44 tank/artillery/infantry/recon、HP/行动轨道、selected/spent、v2.45 HIT/RET/结论和 `AL / OBJ / AX` rail 不得降级或被覆盖。必须确认没有全屏 `Color.white` wash、强曝光、黑色暗角、厚 blur、动画、timer、动态主题、缓存、网络/图片/第三方依赖，也没有修改 `GameState`、GameModels、ContentView、BattlefieldChrome、BattlefieldUnitViews、ObjectiveJumpDock、CombatResolutionOverlay、输入、地图坐标/frame/contentShape/zIndex/scroll/zoom、测试实现、project 或 workflow；纯装饰继续关闭命中并隐藏于 VoiceOver，`HexTileView` 仍只暴露完整摘要。workflow 没有 compact、窄宽度、`xxxLarge` Dynamic Type、多焦点、VoiceOver、Reduce Motion 或独立 4x 输出，Agent C 只能作源码审查，不能把 regular PNG 冒充这些证据。
- v2.48 的云端 regular `--ci-selected-combat-impact-steady` PNG 必须至少 500 KB 且非黑屏；地图仍为主工作区，普通平原、森林、城市、山地、雪地应以不同且低频的局部材质语汇呈现，不再形成逐格同数量/同位置/同强度的纹理墙，白昼明度与 v2.47 一致。源码审查必须确认 Swift diff 仅为 `BattlefieldTheme.swift` 的 v2.48 token、`BattlefieldMap.swift` 的 `TerrainTexture` 五个非道路/非河流方法及同步文档；`connectionLayer`、`connectionPath`、道路/河流颜色宽度/方向、`MapGridBackdrop`、地图坐标/frame/contentShape/zIndex/scroll/zoom、`GameState`、模型、单位、据点、marker、HIT/RET、HUD、rail、输入、测试实现、project 和 workflow 无回归。必须确认所有纹理只从既有 `terrainSeed`/q/r 确定性派生，仍在既有 tile bounds/Hexagon 内、关闭命中并隐藏于 VoiceOver，不新增状态/缓存/动画/图片/网络/依赖；compact、窄宽度、`xxxLarge` Dynamic Type、多焦点、VoiceOver、Reduce Motion 和没有独立输出的 4x 只能源码审查，不能由 regular PNG 冒充。
- v2.49 的云端 regular `--ci-selected-combat-impact-steady` PNG 必须至少 500 KB 且非黑屏；河流应读为连续、窄而低饱和的走廊，不再被逐格大蓝圆节或管线感主导，孤立 river 仍可辨识。源码审查必须确认 Swift diff 仅为 `BattlefieldTheme.swift` 的 river-only token、`BattlefieldMap.swift` 的 `TerrainTexture` river connection 分支/颜色宽度 helper/`waterHighlight(in:)` 及同步文档；`connectionPath`、endpoint、`connectionDirections`、道路 connection/network/颜色/宽度、高亮、v2.47 白昼、v2.48 五类非河流方法、地图坐标/frame/contentShape/zIndex/scroll/zoom、`GameState`、模型、单位、据点、marker、HIT/RET、HUD、rail、输入、测试实现、project 和 workflow 无回归。必须确认 river 装饰只从既有 tile、q/r seed 和方向确定性派生，仍在既有 tile bounds/Hexagon 内、关闭命中并隐藏于 VoiceOver，不新增状态/缓存/动画/图片/网络/依赖；compact、窄宽度、`xxxLarge` Dynamic Type、多焦点、VoiceOver、Reduce Motion 和没有独立输出的 4x 只能源码审查，不能由 regular PNG 冒充。
- v2.50 本地只允许运行 `git diff --check`、`git diff --name-only`、`git status` 和范围 `rg`；禁止本地 Swift、`swiftc`、RulesSmokeTest、XCTest、Xcode build、模拟器、Playwright 和截图。云端 `--ci-selected-combat-impact-steady` regular PNG 必须至少 500 KB 且非黑屏，六角结构应可辨但普通格不形成同权重硬网格，同类地貌共享面更连续，地形切换和地图外缘保留克制层次；v2.49 河道、道路网络/环路、五类地貌、据点、单位、HP/行动轨道、selected、marker、HIT/RET、HUD 和 `AL / OBJ / AX` rail 不回归。源码审查必须确认 Swift diff 仅为 `BattlefieldTheme.swift` 六角边界 token、`BattlefieldMap.swift` 的 `HexMapView`/`HexTileView` 只读邻接边界派生和 tile-local 边段 Shape；`TerrainTexture`、road/river connection、地图 geometry/contentShape/zIndex/scroll/zoom、输入、规则、模型、`ContentView`、测试、project 与 workflow 无 diff。边界层必须关闭命中、隐藏于无障碍树、使用既有 tile/邻接确定性派生且无状态/缓存/动画/资源；compact、窄宽度、`xxxLarge` Dynamic Type、多焦点、VoiceOver、Reduce Motion 和无独立输出的 4x 只能源码审查，不能由 regular PNG 冒充。
- v2.51 本地只允许运行 `git diff --check`、`git diff --name-only`、`git status` 和范围 `rg`；禁止本地 Swift、`swiftc`、RulesSmokeTest、XCTest、Xcode build、模拟器、Playwright 和截图。云端必须为最新 v2.51 SHA 运行 static checks、RulesSmokeTest、Xcode build-for-testing 或等价 typecheck 和 `--ci-selected-combat-impact-steady` regular screenshot；PNG 必须至少 500 KB、非黑屏，并由 Agent C 实际查看。道路应呈低对比路基、明显窄于旧 4.5pt 的主路面和只在两侧露出的克制 rim，不得形成亮中心线、粗黑边、发光管线、棕色三角或 lattice；主干、端点、分支、路口、长环路、边缘连接和孤立短笔触仍须可追踪。源码审查必须确认 Swift diff 仅为 `BattlefieldMap.swift` 的 `TerrainTexture` road-only connection/material 分支；`RoadConnectionNetwork`、`RoadDisjointSet`、canonical/selected edges、loop quota、`roadConnectionDirectionsByCoordinate`、`terrainConnectionDirections`、`connectionPath`、`endpoint`、`TerrainKind`、river corridor、v2.50 边界、非道路材质、地图 geometry/contentShape/zIndex/scroll/zoom、输入、规则、模型、测试、project 和 workflow 无 diff。装饰继续继承既有 Hexagon clip、关闭命中并隐藏于 VoiceOver，不新增状态、缓存、动画或资源；compact、窄宽度、`xxxLarge` Dynamic Type、多焦点、VoiceOver、Reduce Motion 和没有独立输出的 4x 只能源码审查，不能由 regular PNG 冒充。
- v2.52 本地只允许运行 `git diff --check`、`git diff --name-only`、`git status --short --branch` 和范围 `rg -n "terrainConnectionDirections|terrainContinuityLayer|map(Plains|Snow|Forest|Mountain)Continuity|fieldLines|snowDrifts|HexEtchedBoundaryLayer|connectionPath|roadConnectionLayer|riverConnectionLayer" WW2Tactics/WW2Tactics/BattlefieldMap.swift WW2Tactics/WW2Tactics/BattlefieldTheme.swift`；禁止本地 Swift、`swiftc`、RulesSmokeTest、XCTest、Xcode build、模拟器、Playwright、预览和截图。云端必须为最新 v2.52 SHA 运行 static checks、RulesSmokeTest、Xcode build-for-testing/等价 typecheck 和 `--ci-selected-combat-impact-steady` regular screenshot；PNG 至少 500 KB、非黑屏，并由 Agent C 实际查看。平原/雪地必须只在 `terrainContinuityLayer(_:)` 各复用同一个既有 path 绘制一次极弱宽幅 round stroke，降低同类区域逐格切片感且不形成中心线、放射星芒、管线、假道路/河流/补给线、中心池或格边 halo；可选 theme diff 最多两个 map-only token。`fieldLines`、`snowDrifts`/针叶树、森林/山地 continuity、边界、道路/河流、地图 geometry/input、规则、模型、`ContentView`、测试、project 和 workflow 无 diff。现有 workflow 只生成 regular PNG；compact、窄宽度、`.xxxLarge` Dynamic Type、多焦点、VoiceOver、Reduce Motion 和无独立输出的 4x 只能源码审查，不能由 regular PNG 冒充。
- v2.53 本地只允许运行 `git diff --check`、`git diff --name-only`、`git status --short --branch` 和范围 `rg -n "private var border(Color|Width)|isAttackFocusMode|isAttackCoverage|isThreatenedMoveTile|isEnemyControlZone|isSupplyLine|SupplyLineMarker|supplyLineConnectionDirections|HexEtchedBoundaryLayer|contentShape|accessibilityLabel" WW2Tactics/WW2Tactics/BattlefieldMap.swift`；禁止本地 Swift、`swiftc`、RulesSmokeTest、XCTest、Xcode build、模拟器、Playwright、预览和截图。云端必须为最新 v2.53 SHA 运行 static checks、RulesSmokeTest、Xcode build-for-testing/等价 typecheck 和 `--ci-selected-combat-impact-steady` regular screenshot；PNG 至少 500 KB、非黑屏，并由 Agent C 实际查看。Swift diff 必须仅在 `HexTileView.borderColor`/`borderWidth` 删除 threatened、enemy ZOC、supply 三组共六行低优先级整格边框分支；red wash、连续 `SupplyLineMarker`、`isAttackCoverage` 橙色 `0.40`/`1pt` 边、通用 stroke、所有高优先级状态、geometry/input/VoiceOver、GameState、规则、测试、project 和 workflow 无 diff。regular 场景可直接证明 enemy ZOC/supply 整格边减少，但不激活 threatened；threatened、route、实时 ATK/POS、CUT、compact、窄宽度、`.xxxLarge` Dynamic Type、多焦点、VoiceOver、Reduce Motion 和无独立输出的 4x 只能源码审查，不能由 regular PNG 冒充。
- v2.54 本地只允许运行 `git diff --check`、`git diff --name-only`、`git status --short --branch`、`git diff -- WW2Tactics/WW2Tactics/BattlefieldMap.swift` 和 prompt 指定的 `rg` 范围检查；禁止本地 Swift、`swiftc`、RulesSmokeTest、XCTest、Xcode build、`xcodebuild`、模拟器、Playwright、SwiftUI preview、预览和截图。Swift diff 必须只包含 owner stroke opacity 统一为 `0.10` 和两套 `borderColor`/`borderWidth` 中四个 `tile.isObjective` fallback 删除；owner fill、owner lineWidth、通用 stroke、surviving 高优先级边框、ObjectiveLandmark/旗牌/名称牌、HexEtchedBoundaryLayer、geometry/input/VoiceOver、GameState、模型、规则、测试、project 和 workflow 无 diff。云端必须为最新 v2.54 SHA 运行 static checks、RulesSmokeTest、Xcode build-for-testing/等价 typecheck 和 `--ci-selected-combat-impact-steady` regular screenshot；PNG 至少 500 KB、非黑屏，并由 Agent C 实际查看。regular 只能证明静态据点粗整格边减少和 selected/combat response 等真实激活状态保留，attack-focus fallback、latest capture、guided、AI、实时 ATK/MOVE/POS、route、fire exposure、countermeasure/pressure/intent、compact、窄宽度、`.xxxLarge` Dynamic Type、多焦点、VoiceOver、Reduce Motion 和 4x 只能源码审查，不能冒充独立实测。
- v2.55 本地只允许运行 `git diff --check`、`git diff --name-only`、`git status --short --branch`、`git diff -- WW2Tactics/WW2Tactics/BattlefieldMap.swift` 和必要的 `rg`/文本边界检查；禁止本地 Swift、`swiftc`、RulesSmokeTest、XCTest、Xcode build、`xcodebuild`、模拟器、Playwright、SwiftUI preview、预览、截图和完整构建。Swift diff 必须只触及 `BattlefieldMap.swift` 的 `HexTileView` 最底层 `tile.terrain.mapGradient` fill 或同文件纯视觉 helper，并确认 `0.78` opacity 没有包裹后续 overlay；`TerrainKind` token、TerrainTexture、HexEtchedBoundaryLayer、owner/status/marker、据点、单位、geometry、contentShape、zIndex、input、VoiceOver、GameState、模型、规则、测试、project 和 workflow 无 diff。云端必须为最新 v2.55 SHA 运行 static checks、RulesSmokeTest、Xcode build-for-testing/等价 typecheck 和 `--ci-selected-combat-impact-steady` regular screenshot；PNG 至少 500 KB、非黑屏，并由 Agent C 实际查看。regular 只证明该运行的 regular 战场状态，compact、窄宽度、`.xxxLarge` Dynamic Type、多焦点、VoiceOver、Reduce Motion 和无独立输出的 4x 仍只能源码审查，不能冒充独立实测。
- 地图格、单位棋子、地图标记槽位折叠、命令预览 helper 去重、后勤与战术结果卡视觉、反制回放/复核卡视觉、HUD 信息密度、触控手感与侧栏层级、图例与编队条视觉、窄屏布局适配、动态字体与面板微调、单位详情层级与战术条视觉、状态面板视觉统一、作战规划面板可玩性视觉、敌情与反制面板视觉、反制下一步与关联AI行动反馈、态势响应与AI回放反馈强化、据点压力与复盘入口反馈、HUD、侧栏、战斗预览/结果卡、战线态势指挥简报、AI 战况回放和主题样式等纯 UI 表现层改动仍必须通过云端 Xcode build-for-testing；若该轮跳过本地测试，不能把本地未跑命令写成已验证。
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
- `battlefield-screenshot.png` 和 `battlefield-screenshot.log` 是否来自本次 run；截图是否为已启动的 WW2Tactics 战场，而不是 SpringBoard、黑屏、崩溃或空白画面。
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


### v2.58 云端基线

表现层改动只在本地运行 `git diff --check`；push 后由 GitHub Actions 执行 static checks、Rules smoke、Xcode build-for-testing 和 regular battlefield screenshot。XCTest 是否执行以 workflow manifest 为准。


### v2.59 云端基线

本轮本地只运行 `git diff --check`；UI 与 SwiftUI build、规则 smoke、截图由 GitHub Actions 验证。

### v2.60

本轮为 SwiftUI 表现层改动；按用户约束不运行本地 Swift、Xcode、模拟器或截图，推送后由 GitHub Actions 执行 static checks、Rules smoke、build-for-testing 和 regular screenshot。

## 原图方向契约

XCTest 原始 PNG 可保留竖向物理像素并以 EXIF 表示横屏。UI 需同时验证 app frame 与 UIImage 原生方向解读的显示尺寸；云端截图检查器通过 ImageIO 独立读取方向，分别报告 `pixelWidth/pixelHeight`、`width/height` 与 `exifOrientation`，按显示坐标取样亮度，并把同一方向传给 Vision。八种 EXIF 方向的角点、尺寸、边界和一一映射先执行云端 `inspect-screenshot --self-test`；不改原字节，不用改图冒充真实旋转。

尺寸/500 KB/亮度/可读比例/系统通知、两帧原附件与真实操作断言不放宽。失败诊断由 XCTest `addTeardownBlock` 保存最终屏幕、方向元数据及无障碍层级，避免 `continueAfterFailure=false` 的异常路径跳过 Swift defer；诊断不替代通过的场景图。

解码必须从 ImageIO 原始 CGImage 进入明确 big-endian sRGB RGBA8 的 CoreGraphics 缓冲区，再在采样坐标应用一次 EXIF；不经 AppKit/NSColor 隐式色域转换，不能把 `NSBitmapImageRep(data:)` 已自动转正的宽高当作原始像素。云端八向 self-test 要通过同一解码入口，验证带方向 PNG 的原始宽高、EXIF、逐点颜色及显示坐标映射，防止纯几何测试通过而真实图片被二次旋转。

PNG 夹具和亮度采样使用固定 sRGB，不能以设备相关 DeviceRGB 作为可复现颜色字节的基准；报告保留 `samplingColorSpace`，采样断言失败要记录 EXIF、原始坐标、期望与实际值，不通过扩大容差绕过失败。

固定 workflow 在游戏构建和模拟器 boot 前先编译检查器并执行八向 PNG 契约；日志为 `screenshot-inspector.log`，独立报告为 `screenshot-inspector-report.json`。失败时仍打包，manifest/JUnit 区分失败与未执行 skipped，零测试不算通过；成功继续原全套 smoke/build/unit/UI/六图并复用检查器，不新增 profile、设备或无关工作流。该前置门禁不改变六图、交互和资源预算要求。
