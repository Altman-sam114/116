import SwiftUI

struct MapActionHUD: View {
    @EnvironmentObject private var game: GameState
    let compact: Bool
    var condensed = false
    var inlineOrders = false

    var body: some View {
        if let unit = game.selectedUnit {
            VStack(alignment: .leading, spacing: 7) {
                let layout = inlineOrders ? AnyLayout(HStackLayout(spacing: 14)) : AnyLayout(VStackLayout(alignment: .leading, spacing: 7))
                layout {
                    UnitCommandIdentity(unit: unit, condensed: condensed)
                    if unit.hasMoved && unit.hasAttacked {
                        Label("行动完毕", systemImage: "checkmark.circle.fill")
                            .font(BattlefieldTheme.hudLabel)
                            .foregroundStyle(BattlefieldTheme.mutedInk)
                    } else {
                        UnitCommandActions(unit: unit)
                    }
                }
                if let preview = game.focusedCommandPreview, preview.isExecutable {
                    CommandOrderLine(preview: preview)
                }
            }
            .padding(.horizontal, 11).padding(.vertical, condensed ? 7 : 10)
            .foregroundStyle(BattlefieldTheme.fieldPaper)
            .frame(maxWidth: inlineOrders ? 620 : compact ? .infinity : 460, alignment: .leading)
            .background(FieldPlate(emphasized: true))
            .overlay(alignment: .leading) {
                Rectangle().fill(unit.faction.accentColor).frame(width: 3).padding(.vertical, 4)
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
        HStack(spacing: 9) {
            UnitModelView(kind: unit.kind, faction: unit.faction, isSpent: unit.hasMoved && unit.hasAttacked,
                          variant: BattlefieldVehicleVariant.matching(unit))
                .frame(width: condensed ? 62 : 84, height: condensed ? 44 : 55)
                .background {
                    Ellipse().fill(.black.opacity(0.28)).frame(height: 13).offset(y: 16)
                }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text(unit.kind.title).foregroundStyle(BattlefieldTheme.brass)
                    Text(unit.rank.title).foregroundStyle(BattlefieldTheme.mutedInk)
                    if let commander = unit.commander { Text(commander.name).foregroundStyle(BattlefieldTheme.brass) }
                }
                .font(BattlefieldTheme.hudCaption).lineLimit(1)
                Text(unit.name).font(.system(size: condensed ? 13 : 15, weight: .heavy)).lineLimit(1)
                HStack(spacing: 6) {
                    MiniHealthBar(ratio: unit.hpRatio, factionTint: unit.faction.accentColor)
                        .frame(width: condensed ? 38 : 48, height: 6)
                    Text("\(unit.hp)/\(unit.maxHP)").font(BattlefieldTheme.militaryFont(15)).monospacedDigit()
                    UnitReadinessTag(symbol: readiness.moveSymbol, title: readiness.moveTitle,
                                     available: readiness.canMove, tint: BattlefieldTheme.movement,
                                     showsTitle: !condensed)
                    UnitReadinessTag(symbol: readiness.attackSymbol, title: readiness.attackTitle,
                                     available: readiness.canAttack, tint: BattlefieldTheme.brass,
                                     showsTitle: !condensed)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: condensed ? 190 : 220, alignment: .leading)
    }

    private var readiness: UnitReadinessPresentation {
        UnitReadinessPresentation(hasMoved: unit.hasMoved, hasAttacked: unit.hasAttacked)
    }
}

private struct UnitCommandActions: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit

    var body: some View {
        HStack(spacing: 4) {
            command("攻击", icon: "scope", enabled: !game.attackableUnits(for: unit).isEmpty, action: game.focusNearestAttackTarget)
            command("接敌", icon: "arrow.up.right", enabled: game.nearestApproachTarget(for: unit) != nil, action: game.focusNearestApproachTarget)
            command("据点", icon: "flag.fill", enabled: game.nearestObjectiveTarget(for: unit) != nil, action: game.focusNearestObjectiveTarget)
            command("待命防御", caption: "防御", icon: "shield.lefthalf.filled", enabled: true, action: game.waitSelectedUnit)
            if game.focusedCommandPreview?.isExecutable == true {
                Button(action: game.executeFocusedCommand) {
                    VStack(spacing: 3) {
                        Image(systemName: "checkmark").font(.system(size: 14, weight: .heavy))
                        Text("执行").font(BattlefieldTheme.hudCaption)
                    }
                    .foregroundStyle(BattlefieldTheme.commandDeckDeep)
                    .frame(minWidth: 44, maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle()).background(BattlefieldTheme.actionBrass, in: RoundedRectangle(cornerRadius: 2))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("执行")
                .accessibilityIdentifier("battlefield-execute-order")
            }
        }
    }

    private func command(_ title: String, caption: String? = nil, icon: String, enabled: Bool,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                Text(caption ?? title).font(BattlefieldTheme.hudCaption)
            }
            .frame(minWidth: 44, maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle()).background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 2))
            .overlay { RoundedRectangle(cornerRadius: 2).stroke(BattlefieldTheme.brass.opacity(0.22), lineWidth: 0.7) }
        }
        .buttonStyle(.plain).accessibilityLabel(title)
        .opacity(enabled ? 1 : 0.35).disabled(!enabled)
    }
}

private struct CommandOrderLine: View {
    let preview: MapCommandPreview

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.turn.down.right").font(.system(size: 10, weight: .bold))
            Text(MapCommandPreviewChrome.compactTitle(for: preview) + " · " + detail)
                .font(BattlefieldTheme.hudLabel).lineLimit(2)
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
