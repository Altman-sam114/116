# v5.0 EasyTech 风格贴图架构、材质与特效记录

日期：2026-11-24。全部资产均为原创离线资源，统一按语义子目录安置在 `WW2Tactics/WW2Tactics/BattlefieldArt/` 下，严守 24 MB 随包预算（当前 17 份 PNG 共 23,191,455 bytes）；不引入任何商业游戏素材或第三方依赖。

## 统一目录规划

- `BattlefieldArt/Terrain/`
  - `ground-field-v2.png`（1024×1024）：原有手绘欧洲乡野草土地表。
  - `ground-snow.png`（512×512，新增）：无缝周期 fBm 法线光照冬雪地貌纹理，用于裁剪填充真实雪带，替代旧版平面白色模糊。
  - `water-river.png`（512×512，新增）：无缝周期河流水面纹理（深蓝板岩河水与流动波纹），用于裁剪填充真实河道。
  - `scenery-campaign.png`（1536×1024，2×2 RGBA）：针叶林、山地、欧洲村镇、冬林。
  - `woodland-campaign.png`（1536×1024，2×2 RGBA）：疏林、混交林、稀疏雪林、农庄。
  - `industrial-city.png`（1024×682 RGBA）：工业城市与铁路编组站（高质量重采样以留出预算）。
  - `supply-depot.png`（1024×682 RGBA）：补给站与沙袋营地。
- `BattlefieldArt/Units/`
  - `vehicles-field-v2.png`（1536×1024，2×2 RGBA）：盟/轴标准坦克与侦察车。
  - `troops.png`（1536×1024，2×2 RGBA）：盟/轴三人步兵班与野战榴弹炮。
  - `armor-detail.png`（1536×1024，2×2 RGBA）：M10、虎式、M7 牧师、豹式专属外观。
- `BattlefieldArt/Commanders/`
  - `commanders.png`（1536×1024，2×2 RGBA）：巴顿、蒙哥马利、古德里安、曼施坦因肖像。
- `BattlefieldArt/VFX/`
  - `combat-vfx.png`（1024×1024，2×2 RGBA，新增）：体积火焰爆炸、炮口焰冲击波、战地浓烟云团、金色统帅光环。
- `BattlefieldArt/UI/`
  - `ui-metal-plate.png`（512×512，新增）：拉丝枪铁暗橄榄军用钢板底纹。
  - `ui-brass-panel.png`（512×512，新增）：锤纹古铜皮革战区指挥桌底纹。
  - `ui-icons-resources.png`（1024×1024，2×2 RGBA，新增）：3D 法线浮雕金币、工业齿轮、荣誉勋章、补给弹药箱。
  - `ui-items-shop.png`（1024×1024，2×2 RGBA，新增）：英雄十字勋章、装甲钢盾徽章、野战急救箱、最高统帅战备宝箱。
  - `ui-emblems.png`（1024×1024，2×2 RGBA，新增）：复古黄铜沙漏、盟军蓝星军徽、轴心红铁十字徽章、统帅部金月桂双剑徽章。

说明：原有两份未使用的旧文件 `vehicles.png` 与 `ground-campaign.png` 已通过 `trash` 安全移出。本次生图期间 `image-generator`（`gemini-3.1-flash-image`）触发 429 配额上限（冷却中），因此上述 8 份新增 PBR 材质、3D 金属浮雕图标与体积战斗特效均由本轮原创物理光照脚本生成并逐张目视审查确认透明通道、构图与清晰度；待后续配额恢复后可继续追加其余名将油画肖像与新建筑地标。
