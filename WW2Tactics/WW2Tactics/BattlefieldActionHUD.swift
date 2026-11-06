import SwiftUI

/// The selected-unit strip only projects rules and invokes GameState commands.
struct MapActionHUD: View {
    @EnvironmentObject private var game: GameState
    let compact: Bool
    var condensed = false
    var inlineOrders = false

    var body: some View {
        if let unit = game.selectedUnit {
            VStack(alignment: .leading, spacing: 0) {
                let layout = inlineOrders
                    ? AnyLayout(HStackLayout(alignment: .center, spacing: 16))
                    : AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                layout {
                    UnitCommandIdentity(unit: unit, condensed: condensed)
                        .frame(width: inlineOrders ? (condensed ? 240 : 300) : nil, alignment: .leading)
                    if unit.hasMoved && unit.hasAttacked {
                        HStack(spacing: 7) {
                            Image(systemName: "checkmark.circle")
                            Text("行动完毕").font(BattlefieldTheme.hudLabel)
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(BattlefieldTheme.mutedInk)
                    } else {
                        UnitCommandActions(unit: unit)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, condensed ? 7 : 10)
                if let preview = game.focusedCommandPreview, preview.isExecutable {
                    Rectangle().fill(BattlefieldTheme.brass.opacity(0.2)).frame(height: 1)
                    CommandOrderLine(preview: preview)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                }
            }
            .foregroundStyle(BattlefieldTheme.fieldPaper)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FieldPlate(emphasized: true))
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
        HStack(spacing: 12) {
            if let commander = unit.commander {
                CommanderPortrait(commander: commander, faction: unit.faction)
                    .frame(width: condensed ? 42 : 48, height: condensed ? 49 : 56)
            } else {
                UnitModelView(kind: unit.kind, faction: unit.faction, isSpent: unit.hasMoved && unit.hasAttacked,
                              variant: BattlefieldVehicleVariant.matching(unit))
                    .frame(width: condensed ? 64 : 80, height: condensed ? 44 : 52)
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    Text(unit.kind.title).foregroundStyle(BattlefieldTheme.brass)
                    Text(unit.rank.title).foregroundStyle(BattlefieldTheme.mutedInk)
                    if let commander = unit.commander { Text(commander.name).foregroundStyle(BattlefieldTheme.brass) }
                }
                .font(.system(size: 9, weight: .medium)).lineLimit(1)
                Text(unit.name).font(.system(size: condensed ? 13 : 15, weight: .bold)).lineLimit(1)
                HStack(spacing: 6) {
                    MiniHealthBar(ratio: unit.hpRatio, factionTint: BattlefieldTheme.alliesRing)
                        .frame(width: condensed ? 34 : 44, height: 4)
                    Text("\(unit.hp)/\(unit.maxHP)").font(BattlefieldTheme.militaryFont(14)).monospacedDigit()
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
    }

    private var readiness: UnitReadinessPresentation {
        UnitReadinessPresentation(hasMoved: unit.hasMoved, hasAttacked: unit.hasAttacked)
    }
}

private struct UnitCommandActions: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit

    var body: some View {
        HStack(spacing: 5) {
            command("攻击", icon: "scope", enabled: !game.attackableUnits(for: unit).isEmpty, action: game.focusNearestAttackTarget)
            command("接敌", icon: "arrow.up.right", enabled: game.nearestApproachTarget(for: unit) != nil, action: game.focusNearestApproachTarget)
            command("据点", icon: "flag", enabled: game.nearestObjectiveTarget(for: unit) != nil, action: game.focusNearestObjectiveTarget)
            command("待命防御", caption: "防御", icon: "shield.lefthalf.filled", enabled: true, action: game.waitSelectedUnit)
            if game.focusedCommandPreview?.isExecutable == true {
                Button(action: game.executeFocusedCommand) {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark").font(.system(size: 15, weight: .bold))
                        Text("执行").font(BattlefieldTheme.hudCaption)
                    }
                    .foregroundStyle(BattlefieldTheme.commandDeckDeep)
                    .frame(minWidth: 44, maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                    .background(BattlefieldTheme.actionBrass, in: BeveledFieldShape())
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
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 16, weight: .regular))
                Text(caption ?? title).font(BattlefieldTheme.hudCaption)
            }
            .frame(minWidth: 44, maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
            .background(.white.opacity(0.055), in: BeveledFieldShape())
            .overlay { BeveledFieldShape().stroke(.white.opacity(0.12), lineWidth: 0.7) }
        }
        .buttonStyle(.plain).accessibilityLabel(title)
        .opacity(enabled ? 1 : 0.35).disabled(!enabled)
    }
}

private struct CommandOrderLine: View {
    let preview: MapCommandPreview

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.turn.down.right").font(.system(size: 11))
            Text(MapCommandPreviewChrome.compactTitle(for: preview) + " · " + detail)
                .font(BattlefieldTheme.hudLabel).lineLimit(2)
            Spacer(minLength: 0)
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
