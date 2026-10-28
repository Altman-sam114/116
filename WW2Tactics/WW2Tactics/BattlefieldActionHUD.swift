import SwiftUI

struct MapActionHUD: View {
    @EnvironmentObject private var game: GameState
    let compact: Bool
    var condensed = false

    var body: some View {
        if let unit = game.selectedUnit {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 10) {
                    UnitModelView(kind: unit.kind, faction: unit.faction, isSpent: unit.hasMoved && unit.hasAttacked,
                                  variant: BattlefieldVehicleVariant.matching(unit))
                        .frame(width: condensed ? 60 : 76, height: condensed ? 36 : 49)
                        .background {
                            Ellipse().fill(unit.faction.accentColor.opacity(0.14)).frame(height: 16).offset(y: 12)
                        }
                    UnitCommandIdentity(unit: unit, condensed: condensed)
                    Spacer(minLength: 0)
                    Button(action: game.waitSelectedUnit) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 17))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.05), in: BeveledFieldShape())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("待命防御")
                    .disabled(unit.hasMoved && unit.hasAttacked)
                }
                if unit.hasMoved && unit.hasAttacked {
                    Label("行动完毕 · 选择下一支部队", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(BattlefieldTheme.mutedInk)
                } else {
                    UnitCommandActions(unit: unit, condensed: condensed)
                }
                if !condensed, let preview = game.focusedCommandPreview, preview.isExecutable {
                    CommandOrderLine(preview: preview)
                }
            }
            .padding(condensed ? 8 : 11)
            .foregroundStyle(BattlefieldTheme.fieldPaper)
            .frame(maxWidth: condensed ? 360 : compact ? .infinity : 440)
            .background(FieldPlate(emphasized: true))
            .overlay(alignment: .leading) {
                Rectangle().fill(unit.faction.accentColor).frame(width: 3).padding(.vertical, 8)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("battlefield-selected-unit")
            .accessibilityValue("q\(unit.position.q),r\(unit.position.r)，\(unit.hasMoved ? "移动已用" : "移动可用")，\(unit.hasAttacked ? "攻击已用" : "攻击可用")")
        }
    }
}

private struct UnitCommandIdentity: View {
    let unit: BattleUnit
    let condensed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Text(unit.kind.title).foregroundStyle(BattlefieldTheme.brass)
                Text(unit.rank.title).foregroundStyle(BattlefieldTheme.mutedInk)
                if let commander = unit.commander { Text(commander.name).foregroundStyle(BattlefieldTheme.brass) }
            }
            .font(.system(size: 8, weight: .bold))
            .lineLimit(1)
            Text(unit.name).font(.system(size: condensed ? 12 : 14, weight: .heavy)).lineLimit(1)
            HStack(spacing: 7) {
                Text("HP \(unit.hp)/\(unit.maxHP)").monospacedDigit().foregroundStyle(.white)
                Label(unit.hasMoved ? "已用" : "移动", systemImage: unit.hasMoved ? "checkmark" : "arrow.up.right")
                    .foregroundStyle(unit.hasMoved ? BattlefieldTheme.mutedInk : BattlefieldTheme.movement)
                Label(unit.hasAttacked ? "已用" : "攻击", systemImage: unit.hasAttacked ? "checkmark" : "scope")
                    .foregroundStyle(unit.hasAttacked ? BattlefieldTheme.mutedInk : BattlefieldTheme.brass)
            }
            .font(.system(size: 9, weight: .semibold))
            .lineLimit(1)
        }
    }
}

private struct UnitCommandActions: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit
    let condensed: Bool

    var body: some View {
        HStack(spacing: 5) {
            command("攻击", icon: "scope", enabled: !game.attackableUnits(for: unit).isEmpty, action: game.focusNearestAttackTarget)
            command("接敌", icon: "arrow.up.right", enabled: game.nearestApproachTarget(for: unit) != nil, action: game.focusNearestApproachTarget)
            command("据点", icon: "flag.fill", enabled: game.nearestObjectiveTarget(for: unit) != nil, action: game.focusNearestObjectiveTarget)
            if game.focusedCommandPreview?.isExecutable == true {
                Button(action: game.executeFocusedCommand) {
                    Label("执行", systemImage: "play.fill")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(BattlefieldTheme.commandDeckDeep)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(BattlefieldTheme.actionBrass, in: BeveledFieldShape())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("battlefield-execute-order")
            }
        }
    }

    private func command(_ title: String, icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.white.opacity(0.06), in: BeveledFieldShape())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .disabled(!enabled)
    }
}

private struct CommandOrderLine: View {
    let preview: MapCommandPreview

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "arrow.turn.down.right").font(.system(size: 10, weight: .bold))
            Text(MapCommandPreviewChrome.compactTitle(for: preview) + " · " + detail)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(2)
        }
        .foregroundStyle(BattlefieldTheme.brass)
    }

    private var detail: String {
        switch preview {
        case let .attack(_, defender, damage, counter, hp, _):
            return "\(defender) −\(damage)，剩余 \(hp) HP，反击 −\(counter)"
        case let .move(_, _, route):
            return "移动消耗 \(route.totalCost)"
        default:
            return "确认后执行"
        }
    }
}
