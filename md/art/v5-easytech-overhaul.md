# v5.0 / v5.1 EasyTech 风格贴图架构、材质与特效记录

日期：2026-11-24。全部资产均为原创离线资源，统一按语义子目录安置在 `WW2Tactics/WW2Tactics/BattlefieldArt/` 下，严守 24 MB 随包预算（当前 20 份 PNG 共 23,060,426 bytes，余量 939,574 bytes）；不引入任何商业游戏素材或第三方依赖。

## 统一目录规划

- `BattlefieldArt/Terrain/`
  - `ground-field-v2.png`（768×768 RGB）：原有手绘欧洲乡野草土地表。
  - `ground-snow.png`（512×512 RGB，v5.1 优化）：严格整周期无缝冬雪风蚀雪脊与冻土质感，用于裁剪填充真实雪带。
  - `water-river.png`（512×512 RGB，v5.0 新增）：无缝周期河流水面纹理（深蓝板岩河水与流动波纹），用于裁剪填充真实河道。
  - `scenery-campaign.png`（1536×1024，2×2 RGBA）：针叶林、山地、欧洲村镇、冬林。
  - `woodland-campaign.png`（1536×1024，2×2 RGBA）：疏林、混交林、稀疏雪林、农庄。
  - `industrial-city.png`（1024×682 RGBA）：工业城市与铁路编组站。
  - `supply-depot.png`（1024×682 RGBA）：补给站与沙袋营地。
  - `city-landmarks.png`（1024×682，2×2 RGBA，v5.1 新增 AI 手绘透明图集）：盟军统帅部城堡（圣维特/滩头阵地）、混凝土永备碉堡与龙牙工事（南部桥头堡/西墙工事/默兹渡口）、前线军用机场与机库塔台（铁路枢纽/机场）、欧洲教堂大都会广场（马尔梅迪/卡昂/列日/装甲集结地）。
- `BattlefieldArt/Units/`
  - `vehicles-field-v2.png`（1536×1024，2×2 RGBA）：盟/轴标准坦克与侦察车。
  - `troops.png`（1536×1024，2×2 RGBA）：盟/轴三人步兵班与野战榴弹炮。
  - `armor-detail.png`（1536×1024，2×2 RGBA）：M10、虎式、M7 牧师、豹式专属外观。
  - `elite-units.png`（1024×682，2×2 RGBA，v5.1 新增 AI 手绘透明图集）：盟军 M26 潘兴重坦（重装突击坦克团/王牌装甲）、轴心虎王重坦（党卫装甲预备队）、盟军 T34 管风琴火箭坦克（远程炮兵群/火箭炮）、轴心 42 型装甲火箭车（火箭炮连）。
- `BattlefieldArt/Commanders/`
  - `commanders.png`（1536×1024，2×2 RGBA）：巴顿、蒙哥马利、古德里安、曼施坦因油画肖像。
  - `commanders-hq.png`（1024×682，2×2 RGBA，v5.1 新增 AI 手绘透明图集）：艾森豪威尔、布莱德雷、隆美尔、朱可夫油画肖像，实现 8 名将领全员手绘油画立绘覆盖。
- `BattlefieldArt/VFX/`
  - `combat-vfx.png`（1024×1024，2×2 RGBA，v5.0 新增）：体积火焰爆炸、炮口焰冲击波、战地浓烟云团、金色统帅光环。
- `BattlefieldArt/UI/`
  - `ui-metal-plate.png`（512×512 RGB，v5.0 新增）：拉丝枪铁暗橄榄军用钢板底纹。
  - `ui-brass-panel.png`（512×512 RGB，v5.0 新增）：锤纹古铜皮革战区指挥桌底纹。
  - `ui-icons-resources.png`（1024×1024，2×2 RGBA，v5.0 新增）：3D 法线浮雕金币、工业齿轮、荣誉勋章、补给弹药箱。
  - `ui-items-shop.png`（1024×1024，2×2 RGBA，v5.1 升级为 AI 精绘透明图集）：鎏金英雄十字勋章、橡叶虎式装甲徽章、军绿皮带野战急救箱、满溢金币勋章的最高统帅战备宝箱。
  - `ui-emblems.png`（1024×1024，2×2 RGBA，v5.0 新增）：复古黄铜沙漏、盟军蓝星军徽、轴心红铁十字徽章、统帅部金月桂双剑徽章。

说明：原有两份未使用的旧文件 `vehicles.png` 与 `ground-campaign.png` 已通过 `trash` 安全移出；对全部透明 RGBA 图集执行了无损透明像素归零优化以压缩体积而不改变任何可见像素。v5.1 的四套新透明图集通过画图模型直接生成并逐格目视核对了透明通道、占比与构图清晰度。
