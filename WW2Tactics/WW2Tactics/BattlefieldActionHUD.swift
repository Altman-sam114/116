import SwiftUI

struct MapActionHUD: View {
    @EnvironmentObject private var game: GameState
    let compact: Bool
    var condensed = false

    var body: some View {
        if let unit = game.selectedUnit {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    UnitModelView(kind: unit.kind, faction: unit.faction, isSpent: unit.hasMoved && unit.hasAttacked,
                                  variant: BattlefieldVehicleVariant.matching(unit))
                        .frame(width: 58, height: 38)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(unit.name).font(.system(size: 13, weight: .bold)).lineLimit(1)
                        HStack(spacing: 8) {
                            Text("HP \(unit.hp)/\(unit.maxHP)").monospacedDigit()
                            Text(unit.hasMoved ? "移动已用" : "可移动").foregroundStyle(unit.hasMoved ? BattlefieldTheme.mutedInk : .cyan)
                            Text(unit.hasAttacked ? "攻击已用" : "可攻击").foregroundStyle(unit.hasAttacked ? BattlefieldTheme.mutedInk : BattlefieldTheme.brass)
                        }
                        .font(.system(size: 10, weight: .semibold))
                    }
                    Spacer(minLength: 0)
                    Button(action: game.waitSelectedUnit) {
                        Image(systemName: "pause.fill").frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("待命防御")
                    .disabled(unit.hasMoved && unit.hasAttacked)
                }
                if unit.hasMoved && unit.hasAttacked {
                    if !condensed {
                        Label("本回合行动完毕 · 可切换下一支部队", systemImage: "checkmark.circle")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(BattlefieldTheme.mutedInk)
                    }
                } else {
                    HStack(spacing: 6) {
                        quick("攻击", icon: "scope", enabled: !game.attackableUnits(for: unit).isEmpty, action: game.focusNearestAttackTarget)
                        quick("接敌", icon: "arrow.up.right", enabled: game.nearestApproachTarget(for: unit) != nil, action: game.focusNearestApproachTarget)
                        quick("据点", icon: "flag.fill", enabled: game.nearestObjectiveTarget(for: unit) != nil, action: game.focusNearestObjectiveTarget)
                        if game.focusedCommandPreview?.isExecutable == true {
                            Button(action: game.executeFocusedCommand) {
                                Label("执行", systemImage: "play.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(BattlefieldTheme.commandDeckDeep)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(BattlefieldTheme.actionBrass, in: RoundedRectangle(cornerRadius: 3))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                if let preview = game.focusedCommandPreview, preview.isExecutable {
                    Text(MapCommandPreviewChrome.compactTitle(for: preview) + " · " + commandDetail(preview))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(BattlefieldTheme.brass)
                        .lineLimit(2)
                }
            }
            .padding(condensed ? 6 : 10)
            .foregroundStyle(.white)
            .frame(maxWidth: condensed ? 420 : compact ? .infinity : 520)
            .background(BattlefieldTheme.commandMetal, in: RoundedRectangle(cornerRadius: 4))
            .overlay { RoundedRectangle(cornerRadius: 4).stroke(BattlefieldTheme.brass.opacity(0.34), lineWidth: 0.8) }
            .overlay(alignment: .top) { Rectangle().fill(unit.faction.accentColor).frame(height: 2) }
        }
    }

    private func quick(_ title: String, icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 3))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func commandDetail(_ preview: MapCommandPreview) -> String {
        switch preview {
        case let .attack(_, defender, damage, counter, hp, _):
            return "\(defender) −\(damage)，剩余 \(hp) HP，反击 −\(counter)"
        case let .move(_, _, route):
            return "移动消耗 \(route.totalCost)"
        default:
            return "预览不消耗行动，确认后执行"
        }
    }
}
