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

读图说明：这张图展示后续项目不再由单个 Agent 直接乱改，而是按 A 设计、B 在 `main` 实现并直推、GitHub Actions 云端重验证、C 下载结果包验收、人工复核循环推进；如果 C 不通过，则退回 B 在 `main` 上追加修复 commit。

```mermaid
flowchart TD
  H["人工提出目标、限制、验收标准"] --> A["Agent A：分析目标并写实现提示词"]
  A --> P["md/prompt/vN（阶段）/vN.x（任务）.md"]
  P --> S["Agent B：同步 origin/main 并确认位于 main"]
  S --> B["Agent B：实现、补测试、轻量检查、更新文档"]
  B --> M["main commit：vN.x: 简要说明"]
  M --> U["git push origin main"]
  U --> G["GitHub Actions：静态检查、smoke、Xcode build"]
  G --> Q["未加密 CI 结果包：manifest、failure summary、JUnit、log、xcresult"]
  Q --> C["Agent C：下载结果包并核对 origin/main 最新 commit"]
  C --> D{"验收是否通过？"}
  D -->|不通过| B2["退回 Agent B：问题清单、缺失测试、风险"]
  B2 --> R["main 追加修复 commit"]
  R --> U
  D -->|通过| F["Agent C：确认最新 run、artifact 和文档同步"]
  F --> K["人工复核 main 最新提交和验收结论"]
  K --> H
```

## 5. 云端结果包验收流

读图说明：这张图展示 Agent C 的验收对象不是 Agent B 的文字汇报，而是 `origin/main` 最新 run 上传的未加密 artifact。manifest 中的 commit 和 run 信息必须与远端最新状态一致。

```mermaid
flowchart TD
  O["origin/main 最新 commit"] --> R["GitHub Actions run"]
  R --> A["artifact：ww2tactics-ci-vX.Y-main-<sha>-run<id>-attempt<n>"]
  A --> M["ci-artifact-manifest.json"]
  A --> F["ci-failure-summary.md"]
  A --> J["junit.xml"]
  A --> L["xcodebuild.log / rules-smoke.log"]
  A --> X["WW2Tactics.xcresult"]
  C["Agent C：gh auth login"] --> D["下载到 /private/tmp/ww2tactics-c-review-<run_id>/"]
  D --> M
  D --> F
  D --> J
  D --> L
  D --> X
  M --> V{"branch、commitSha、runId、runAttempt 是否匹配？"}
  V -->|否| N["不通过：不能验收旧 run 或旧 artifact"]
  V -->|是| T{"日志、JUnit、summary 是否通过？"}
  T -->|否| B["退回 Agent B：main 追加修复 commit"]
  B --> O
  T -->|是| Y["通过：确认 main 最新 run"]
```
