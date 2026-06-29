# 项目流程图

本文用 Mermaid 图把当前真实逻辑画出来。每张图前都有读图说明，方便人工快速理解。

## 1. 核心逻辑图

读图说明：这张图从玩家输入开始，看状态如何进入 `GameState`，再如何通过规则更新并回到 SwiftUI 界面。左侧是用户入口，中间是规则状态机，右侧是渲染和测试。

```mermaid
flowchart TD
  U["用户操作：左键 / 点按 / 右键 / 快捷按钮"] --> V["ContentView：地图格、HUD、侧栏"]
  V --> I["输入转发：handleTap / handlePrimaryAction / handleSecondaryAction / executeFocusedCommand"]
  I --> S["GameState：核心状态机"]
  M["GameModels：Scenario、BattleUnit、TerrainTile、HexCoordinate、CommandPreview"] --> S
  S --> R["规则判定：移动、攻击、补给、控制区、士气、AI、OBJ、THR"]
  R --> W["状态写回：单位位置、HP、行动状态、据点归属、消息、战报、胜负"]
  W --> P["@Published 状态变化"]
  P --> V
  S --> T["测试层：GameStateTests / RulesSmokeTest"]
```

## 2. 地图命令执行流

读图说明：这张图展示地图交互的安全边界。聚焦只看信息，不消耗行动；右键或执行按钮才会进入实际命令执行。

```mermaid
flowchart TD
  A["玩家点地图格"] --> B{"是否己方单位？"}
  B -->|是| C["选择单位 selectedUnitID"]
  B -->|否| D["更新 focusedCoordinate"]
  D --> E["生成地图预览 MapCommandPreview"]
  E --> F{"输入类型"}
  F -->|左键/主点按聚焦| G["只显示预览消息，不消耗行动"]
  F -->|右键/执行按钮| H{"预览是否可执行？"}
  H -->|MOVE| I["move：移动、消耗移动、更新据点"]
  H -->|ATK| J["attack：伤害、反击、经验、士气、战报"]
  H -->|POS| K["移动到攻击位并聚焦目标"]
  H -->|不可执行| L["提示原因，不消耗行动"]
  I --> M{"移动后是否有 NEXT 目标？"}
  M -->|是| N["自动聚焦可攻击目标"]
  M -->|否| O["保持移动后状态"]
```

## 3. 规则状态图

读图说明：这张图展示 `GameState` 内部主要规则之间的关系。移动、攻击、补给和 AI 都会影响战役状态，最后统一进入胜负检查。

```mermaid
flowchart LR
  S["Scenario 当前战役"] --> U["units 单位列表"]
  S --> T["tiles 地图格和据点"]
  U --> MV["movementRoutes 可达路线"]
  T --> MV
  U --> AT["attackableTiles / combatPreview 攻击预测"]
  T --> AT
  U --> SUP["supplyLine / supplyState 补给"]
  T --> SUP
  U --> ZOC["enemyControlZoneTiles 控制区"]
  U --> THR["threatenedReachableTiles 敌火覆盖"]
  MV --> CMD["MapCommandPreview"]
  AT --> CMD
  CMD --> EX["executeMapCommand"]
  EX --> RES["更新单位、据点、消息、战报"]
  RES --> WIN["checkVictory / checkTurnLimit"]
  RES --> AI["runAxisAI 轴心国回合"]
  AI --> RES
```

## 4. Agent 迭代流程图

读图说明：这张图展示后续项目不再由单个 Agent 直接乱改，而是按 A 设计、B 实现、C 验收、通过后自动按版本提交、人工复核循环推进；如果 C 不通过，则退回 B 修复。

```mermaid
flowchart TD
  H["人工提出目标、限制、验收标准"] --> A["Agent A：分析目标并写实现提示词"]
  A --> P["md/prompt/vN（阶段）/vN.x（任务）.md"]
  P --> B["Agent B：实现、补测试、跑验证、更新文档"]
  B --> C["Agent C：查看 diff、核对测试、验收实现"]
  C --> D{"验收是否通过？"}
  D -->|不通过| B2["退回 Agent B：指出问题、缺失测试和需修复点"]
  B2 --> B
  D -->|通过| F["更新 md/flow、flowchart、update_log"]
  F --> G["按版本号 git commit：vN.x: 简要说明"]
  G --> R["人工复核提交和汇报"]
  R --> H
```
