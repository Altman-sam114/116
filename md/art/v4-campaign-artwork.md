# v4 战场美术与界面重构

日期：2026-11-06（Asia/Taipei）。单模型执行；所有项目编译、测试、运行和截图仅在云端。

## 参考与实现

实际在百度移动站搜索“将军的荣耀3”，打开图片结果并查看夏季、雪地六角战场。参考其连续地貌、具象军械、将领头像、紧凑贴边操作与低对比网格。来源：[百度图片结果](https://m.baidu.com/sf/vsearch?pd=image_content&word=%E5%B0%86%E5%86%9B%E7%9A%84%E8%8D%A3%E8%80%803)、[官方 App Store](https://apps.apple.com/us/app/glory-of-generals-3-ww2/id1535759278)。商业截图仅用于视觉观察，没有下载到工程或作为随包资产。

重构使用原生 SwiftUI / Canvas 和内置 image_gen 生成的原创 PNG，不引入库或运行时网络。地图地表、连续雪带、河岸、道路与单位状态只表达实际地格和规则事实；没有新建战斗状态机。

## 原创资产

四张新图使用内置 image_gen 默认模式生成。原字节复制到 `WW2Tactics/WW2Tactics/BattlefieldArt/`；保留真实 alpha，不进行抠图、涂改或重新编码。

- `ground-campaign.png`：平滑低对比草土，取代颗粒较重旧底材。
- `scenery-campaign.png`：2×2；针叶林、山脊、村镇、冬季树林。村镇中心留空，单位可以落在镇中。
- `woodland-campaign.png`：2×2；疏林、混交林、稀疏雪林、农庄。
- `commanders.png`：2×2；巴顿、蒙哥马利、古德里安、曼施坦因的原创绘画头像，按实际名字匹配。不是档案照片，不修改将领规则。

旧的 ground-frontline、scenery-frontline、woodland-detail 与已不被使用的 scenery 使用 trash 可恢复移出随包目录；历史版本留在 Git 中。现有车辆与步兵资源复用。预算仍为 24 MB；所有 sprite 解码、格位、透明度与缓存复用由云端直接测试，不以生成成功代替运行验收。

## 完整生成提示词

### ground

```text
Use case: illustration-concept.
Asset type: seamless square ground material for an original WWII hex strategy game on iOS, rendered under small tank and infantry models.
Primary request: a refined hand-painted aerial ground texture of the western European countryside in late autumn. A single continuous quiet landscape material, completely flat orthographic overhead view. Muted pale sage-green meadow and softly blended ochre earth, soft small grass tufts, tiny sparse exposed limestone, subtle compressed earth and gently varied low-frequency broad areas. Sophisticated classic 3D strategy game terrain, painted matte miniature diorama finish, beautiful natural colors, luminous overcast daylight. Fairly light midtones, very low contrast so tiny models and hex lines remain clear. Surface detail should be smooth and controlled, never granular or stippled. All four edges have the same neutral meadow mixture so it tiles invisibly. The material fills the entire square to every edge.
Color palette: restrained sage and moss greens, pale khaki, warm limestone grey, faint brown earth. No dark vignette, no hard shadows.
Constraints: ONLY the bare ground material. No roads, no rivers, no hills, no mountains, no trees, no buildings, no troops, no tanks, no grid, no borders, no UI, no text, no symbols, no checkerboard, no logos. No photographic noise, no broad stripes, no dramatic lighting. The image is opaque and square.
```

### scenery

```text
Use case: illustration-concept.
Asset type: original terrain sprite atlas for a polished WWII hex strategy game.
Primary request: exactly FOUR separate scenery sprites arranged in a precise 2 by 2 grid, on a wide 1536 by 1024 canvas with a genuinely transparent background. Every 768 by 512 quadrant contains one centered scenery cluster; no overlap between cells. Leave at least 8 percent transparent margin inside every cell. All objects share a 45-degree elevated isometric camera, identical scale and soft neutral overcast daylight from upper left, hand-painted 3D diorama realism, attractive clean classic PC strategy-game finish. Soft edges and atmospheric midtones, restrained sage greens, limestone greys, warm grey roofs. Fine details remain legible when each cluster is rendered only 100 pixels wide.
TOP LEFT: a natural broad copse of about 10 European spruce and fir trees, irregular heights and distances, a few bare deciduous trunks, rich sage-green needles, sparse low grasses, feathery irregular perimeter. No block of solid terrain.
TOP RIGHT: a broad rugged limestone mountain outcrop, three layered grey stone ridges, a scattering of moss and firs at the foot, small pale snow traces on the highest crest. Beautiful sculpted rock faces, not a steep isolated cone.
BOTTOM LEFT: a small Belgian Ardennes village, seven stone houses with muted terracotta and slate gabled roofs and a modest church, tiny lanes and garden walls, houses arranged around an OPEN central square that leaves room for a military model to be drawn on top. Irregular sparse perimeter.
BOTTOM RIGHT: a wintry copse of about 9 tall firs with believable soft snow on their branches, some bare tree trunks, small irregular snow at roots, enough clear space between trunks. No broad white ground disc.
Constraints: the four sprites are fully isolated cutouts, real transparent alpha everywhere outside the objects, including corners and gutters. No opaque background, no rectangular ground slabs, no labels, no text, no grid lines, no frames, no hexagons, no borders, no UI, no people, no vehicles, no logos, no watermark. Consistent light, style, proportions. Avoid dark black shadows and photoreal noise. The overall output must be landscape 3:2.
```

### woodland

```text
Use case: illustration-concept.
Asset type: transparent original scenery variations for a polished WWII hex strategy battlefield.
Primary request: exactly FOUR isolated scenery clusters in an exact 2 by 2 layout on a 1536 by 1024 landscape canvas. Each 768 by 512 quadrant holds one centered scene object with at least 7 percent transparent margins and no overlap. Same refined hand-painted isometric 3D diorama style throughout, 45-degree elevated camera, warm neutral daylight from upper left, pale sage-green and moss, weathered stone, fine clean edge detail. Clear silhouettes at tiny on-map size. Matte, sophisticated classic strategy game finish.
Top left quadrant: sparse open conifer woodland, eight varied medium-height firs and two bare deciduous trees, irregular spacing and little grassy roots.
Top right quadrant: mixed European woodland, five muted golden brown autumn deciduous trees and six sage green firs, layered irregular broad cluster, visible gaps.
Bottom left quadrant: sparse winter woodland, eight snow-dusted firs plus bare grey tree trunks, thin natural snow patches at roots, lots of transparent gaps.
Bottom right quadrant: an Ardennes farmstead, three small weathered grey-stone farm buildings with pale terracotta or slate roofs around a little open yard, low stone walls, a few little orchard trees, rustic yet bright and welcoming.
Constraints: genuine transparent alpha outside the artwork and between sparse objects, NO opaque background. No rectangular or oval terrain slab or backdrop, no frames, no borders, no labels, no text, no dividers, no grid, no hexagons, no people, no vehicles, no UI, no logos. Do not use black silhouettes or harsh dark shadows. Consistent scale and light.
```

### commanders

```text
Use case: illustration-concept.
Asset type: original painted WWII general portraits, transparent sprite atlas for a historical hex strategy game.
Primary request: a precisely aligned TWO BY TWO atlas on a landscape 1536 by 1024 canvas. Each equal 768 by 512 cell contains one separate centered head-and-shoulders portrait; generous fully transparent margins, no overlap. A refined realistic hand-painted oil illustration with clean readable faces and subdued military colors. Consistent soft upper-left light and three-quarter-view frontal head angle. These are dignified historically inspired character illustrations, not photographs.
Top left: George S. Patton, older American general with his characteristic firm jaw and serious weathered face, olive steel helmet, olive field jacket with wool collar, scarf.
Top right: Bernard Montgomery, lean older British general, lined clean-shaven face, dark black beret and khaki battledress, alert measured expression.
Bottom left: Heinz Guderian, middle-aged German general, broad face, thin small moustache, grey military peaked cap and grey field officer coat.
Bottom right: Erich von Manstein, slim older German general, long angular clean-shaven face, grey peaked cap and grey wool officer uniform.
Composition: face and head occupy the upper central half of each cell, shoulders fill its lower middle, each portrait roughly 60 percent of its cell width and 85 percent height. Balanced face sizes. Warm skin, field olive, muted slate, tiny cream highlights, no pure black silhouettes.
Constraints: real transparent background outside each individual portrait. No backgrounds, no circles, no frames, no labels, no text, no lettering, no badges, no eagles, no political insignia, no swastikas, no armbands, no logos, no watermark, no dividers. Exactly four distinct portraits in the stated order.
```
