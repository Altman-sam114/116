# 前线战场美术与界面

## 参考与边界

视觉参考《将军的荣耀3》的连续自然地貌、饱满兵模、阵营环/兵种徽章与贴边战争控件，不使用其商业图片、模型、肖像、标志或 UI 贴图。搜索与查看只用于比较视觉语言，下载的公共参考图不进入工程。

- 百度查询：[将军的荣耀3](https://m.baidu.com/s?word=%E5%B0%86%E5%86%9B%E7%9A%84%E8%8D%A3%E8%80%803)。移动搜索返回百度图片结果；桌面图片入口遇安全验证，未绕过。
- 官方公开来源：[Glory of Generals 3: WW2](https://apps.apple.com/us/app/glory-of-generals-3-ww2/id1535759278)。通过 Apple 公共 lookup 接口读取 iPad 截图，查看夏季/雪地两幅实机图；仅参考，不打包。
- 新素材由内置 ImageGen 生成，非 CLI/API fallback，不需要新增工程网络依赖。

## 新资源

`WW2Tactics/WW2Tactics/BattlefieldArt/scenery-frontline.png`，1536x1024，2x2 固定格位，各格 768x512。左上混交林、右上山脊、左下欧洲村镇、右下雪林。透明区域和主体占比由云端资源 XCTest 验证，不通过本机脚本伪称测试。

原始生成文件：`/Users/a114514/.codex/generated_images/01a18282-4b4e-7401-a99f-58189cd60650/call_848132805a2a4eabafb643c3c79762e3.png`。原字节复制入工程，不覆盖或删除旧素材，不做手工抠图。`BattlefieldArtwork` 用新 atlas 替换四款在用地貌，其余四款地貌、十二款军械保持复用；旧 `scenery.png` 保留。资源总量仍受现有 24 MB 随包预算约束。

### 完整生成提示词

```text
Use case: stylized-concept. Asset type: original offline terrain sprite atlas for a playable WWII hex strategy game on iOS. Generate one landscape 1536 x 1024 PNG with a genuine transparent background, in a precise 2 columns x 2 rows atlas. Each 768 x 512 cell contains exactly one isolated, complete diorama, comfortably within its cell with 8 percent transparent margins; nothing crosses the center dividing lines. Top left: a natural dense cluster of small European pine and broadleaf trees with irregular silhouette, moss and a tiny ground-contact shadow but NO solid oval base. Top right: a connected rugged Ardennes rocky mountain ridge, pale stone faces, darker crevices, a little snow on crests, multiple peaks with strong readable three dimensional relief, NO circular base. Bottom left: a compact Belgian village of 12 to 16 stone houses, warm brick and slate roofs, a small church tower, a few trees, streets that fade into transparency at the perimeter, NO solid tile base. Bottom right: a cluster of snow-dusted conifer trees with a few exposed rocks, irregular natural silhouette, NO solid tile base. Style: premium hand-painted pre-rendered isometric strategy-game terrain, crisp forms readable when reduced to 100 pixels wide, orthographic three-quarter top-down camera at 55 degrees, consistent sunlight from upper left, olive green / warm gray / restrained red roof palette. Terrain should feel grounded, detailed and realistic rather than toy-like. All empty areas must be fully transparent alpha. No sky, no background, no checkered texture, no grid lines, no text, no labels, no logos, no emblems, no existing game artwork. Original assets only.
```

工具参数：`transparent_background=true`；全新生成，未传商业参考图或编辑目标。

## 表现系统

- 地图：共享 86x100 尖顶六角坐标不变。默认战术镜头按可用视口短边控制密度；连续草土、确定性耕地/碎石草丛、林地接壤、村镇地基、收敛雪带和有路肩的道路位于 Equatable 静态 Canvas，不在每个单位内重画地形。
- 兵模：增加占格比例、模型接地阴影，轴心军械朝向与盟军对置；兵种章使用原生简单几何，蓝色实线/红色虚线与 AL/AX 字码保留非纯色辨识。血条五段，移动/攻击分别表示，双资源都用尽才算行动完毕。没有新增兵种规则或伪造装备属性。
- 战争 HUD：铆钉/拉丝金属小牌、军用窄体数字、圆形回合表；短横屏指令横排，窄竖屏纵排。情报面板尺寸限制在可用视口内，有独立关闭与遮罩。只有选中/焦点展开环境战术文字，显式 AI 回放仍按真实事件显示，详情没有从规则投影中移除。
- 代码：根战场/地格/无障碍摘要/输入/四类标记/地图兵模/边缘控件/金属牌/情报外壳分离。局部状态只负责展开、缩放和镜头，GameState 继续是唯一规则事实源。

## 证据要求

云端执行现有固定全套 static、smoke、build-for-testing、规则/表现 XCTest、两设备真实 UI 与六图；新增直接覆盖镜头密度、视口约束、确定性地表和标记降噪。原资源尺寸/透明度/主体占比/静态复用/预算测试保留，不放宽门槛。

横屏 UI 在 app 启动后旋转，以 `XCUIScreen.main.screenshot()` 保存真实屏幕原字节，同时断言 app frame 与按 UIImage 原生方向解读的显示尺寸均宽大于高；云端 ImageIO 独立读取 EXIF 方向，分别报告显示尺寸、原始像素尺寸和方向值，按方向取样亮度并传给 Vision。八种 EXIF 方向的角点、尺寸、坐标边界与一一映射先在云端 self-test。保留一秒间隔两帧、不旋转/裁剪/修图；面板开合、移动、回合必须实测。具体实现 SHA/run/attempt、结果和遗留风险写入更新日志，本文件不预填通过。

检查器从 `CGImageSourceCreateImageAtIndex` 的原始像素建立 bitmap，避免 `NSBitmapImageRep(data:)` 已自动转正后再应用 EXIF。八向 self-test 同时覆盖带方向 PNG 的编码/解码、原始宽高和逐点颜色，不能只验证脱离解码链的坐标公式。

颜色夹具和实际亮度采样均使用固定 sRGB，不依赖 runner 的设备 RGB 配置；报告记录采样色彩空间，契约失败输出方向、坐标、期望与实际颜色，保持原断言精度。
