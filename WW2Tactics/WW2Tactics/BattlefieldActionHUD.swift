import SwiftUI

/// Sleek left-docked EasyTech selected-unit tactical card (never spans full-screen dead space).
struct MapActionHUD: View {
    @EnvironmentObject private var game: GameState
    let compact: Bool
    var condensed = false
    var inlineOrders = false
    var onOpenGenerals: () -> Void = {}

    var body: some View {
        if let unit = game.selectedUnit {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: condensed ? 10 : 14) {
                    UnitCommandIdentity(unit: unit, condensed: condensed, onOpenGenerals: onOpenGenerals)

                    FieldToolDivider(axis: .horizontal)

                    if unit.hasMoved && unit.hasAttacked {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(BattlefieldTheme.brass)
                                Text("行动完毕")
                                    .font(BattlefieldTheme.hudLabel)
                                    .foregroundStyle(BattlefieldTheme.fieldPaper)
                            }
                            QuickFieldItemRow(unit: unit)
                        }
                    } else {
                        UnitCommandActions(unit: unit, condensed: condensed)
                    }
                }
                .padding(.horizontal, condensed ? 10 : 12)
                .padding(.vertical, condensed ? 6 : 8)

                if let preview = game.focusedCommandPreview, preview.isExecutable {
                    Rectangle().fill(BattlefieldTheme.brass.opacity(0.32)).frame(height: 1)
                    CommandOrderLine(preview: preview)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                }
            }
            .foregroundStyle(BattlefieldTheme.fieldPaper)
            .background { FieldPlate(emphasized: true, material: .gunmetal) }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("battlefield-selected-unit")
            .accessibilityValue("q\(unit.position.q),r\(unit.position.r)，\(unit.hasMoved ? "移动已用" : "移动可用")，\(unit.hasAttacked ? "攻击已用" : "攻击可用")")
        }
    }
}

private struct UnitCommandIdentity: View {
    let unit: BattleUnit
    let condensed: Bool
    let onOpenGenerals: () -> Void

    var body: some View {
        HStack(spacing: condensed ? 8 : 10) {
            ZStack(alignment: .bottomTrailing) {
                if let commander = unit.commander {
                    CommanderPortrait(commander: commander, faction: unit.faction)
                        .frame(width: condensed ? 44 : 52, height: condensed ? 50 : 58)
                } else {
                    ZStack {
                        BeveledFieldShape(cornerCut: 4)
                            .fill(Color.black.opacity(0.38))
                        UnitModelView(kind: unit.kind, faction: unit.faction, isSpent: unit.hasMoved && unit.hasAttacked,
                                      variant: BattlefieldVehicleVariant.matching(unit))
                            .padding(3)
                    }
                    .frame(width: condensed ? 58 : 70, height: condensed ? 42 : 48)
                    .overlay(BeveledFieldShape(cornerCut: 4).stroke(BattlefieldTheme.brass.opacity(0.55), lineWidth: 0.8))
                }

                if unit.equippedMedal != nil, let medalIcon = BattlefieldArtwork.shopIcon(.heroCross) {
                    BattlefieldArtwork.image(medalIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .offset(x: 4, y: 4)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(unit.kind.title)
                        .foregroundStyle(BattlefieldTheme.selectedPiece)
                    Text("· \(unit.rank.title)")
                        .foregroundStyle(BattlefieldTheme.mutedInk)
                    if unit.isElite {
                        Text("王牌")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(BattlefieldTheme.commandDeckDeep)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(BattlefieldTheme.selectedPiece, in: Capsule())
                    }
                    if let commander = unit.commander {
                        Text(commander.name)
                            .foregroundStyle(BattlefieldTheme.selectedPiece)
                    } else {
                        Button(action: onOpenGenerals) {
                            Text("+委任将领")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(BattlefieldTheme.brass)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(BattlefieldTheme.brass.opacity(0.14), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .font(.system(size: 9, weight: .semibold))
                .lineLimit(1)

                Text(unit.name)
                    .font(.system(size: condensed ? 13 : 15, weight: .bold, design: .serif))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    MiniHealthBar(ratio: unit.hpRatio, factionTint: BattlefieldTheme.alliesRing)
                        .frame(width: condensed ? 38 : 48, height: 5)
                    Text("\(unit.hp)/\(unit.maxHP)")
                        .font(BattlefieldTheme.militaryFont(condensed ? 13 : 15))
                        .monospacedDigit()
                    Text("攻\(unit.attack) 移\(unit.movement)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(BattlefieldTheme.mutedInk)
                    UnitReadinessTag(symbol: readiness.moveSymbol, title: readiness.moveTitle,
                                     available: readiness.canMove, tint: BattlefieldTheme.movement,
                                     showsTitle: false)
                    UnitReadinessTag(symbol: readiness.attackSymbol, title: readiness.attackTitle,
                                     available: readiness.canAttack, tint: BattlefieldTheme.selectedPiece,
                                     showsTitle: false)
                }
            }
        }
    }

    private var readiness: UnitReadinessPresentation {
        UnitReadinessPresentation(hasMoved: unit.hasMoved, hasAttacked: unit.hasAttacked)
    }
}

private struct QuickFieldItemRow: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit

    var body: some View {
        let medkits = game.ownedFieldItems[.fieldMedkit, default: 0]
        if unit.hp < unit.maxHP && medkits > 0 {
            Button {
                game.useFieldItem(.fieldMedkit)
            } label: {
                HStack(spacing: 4) {
                    if let icon = BattlefieldArtwork.shopIcon(.fieldMedkit) {
                        BattlefieldArtwork.image(icon).resizable().scaledToFit().frame(width: 14, height: 14)
                    }
                    Text("急救 +30 (\(medkits))")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(BattlefieldTheme.fieldPaper)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.28), in: BeveledFieldShape(cornerCut: 4))
                .overlay(BeveledFieldShape(cornerCut: 4).stroke(Color.green.opacity(0.75), lineWidth: 0.8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("使用野战急救箱")
        }
    }
}

private struct UnitCommandActions: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit
    let condensed: Bool

    var body: some View {
        HStack(spacing: 4) {
            command("攻击", icon: "scope", accent: BattlefieldTheme.alert, enabled: !game.attackableUnits(for: unit).isEmpty, action: game.focusNearestAttackTarget)
            command("接敌", icon: "arrow.up.right", accent: BattlefieldTheme.movement, enabled: game.nearestApproachTarget(for: unit) != nil, action: game.focusNearestApproachTarget)
            command("据点", icon: "flag.fill", accent: BattlefieldTheme.selectedPiece, enabled: game.nearestObjectiveTarget(for: unit) != nil, action: game.focusNearestObjectiveTarget)
            command("待命防御", caption: "防御", icon: "shield.lefthalf.filled", accent: BattlefieldTheme.signal, enabled: true, action: game.waitSelectedUnit)

            if unit.hp < unit.maxHP && game.ownedFieldItems[.fieldMedkit, default: 0] > 0 {
                Button { game.useFieldItem(.fieldMedkit) } label: {
                    VStack(spacing: 2) {
                        if let icon = BattlefieldArtwork.shopIcon(.fieldMedkit) {
                            BattlefieldArtwork.image(icon).resizable().scaledToFit().frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "cross.case.fill").font(.system(size: 14))
                        }
                        Text("急救").font(BattlefieldTheme.hudCaption)
                    }
                    .frame(width: 44, height: 44)
                    .background(Color.green.opacity(0.22), in: BeveledFieldShape(cornerCut: 4))
                    .overlay(BeveledFieldShape(cornerCut: 4).stroke(Color.green.opacity(0.55), lineWidth: 0.8))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("使用野战急救箱")
            }

            if game.focusedCommandPreview?.isExecutable == true {
                Button(action: game.executeFocusedCommand) {
                    VStack(spacing: 2) {
                        Image(systemName: "checkmark").font(.system(size: 15, weight: .black))
                        Text("执行").font(.system(size: 10, weight: .black))
                    }
                    .foregroundStyle(BattlefieldTheme.commandDeckDeep)
                    .frame(width: condensed ? 48 : 54, height: 44)
                    .contentShape(Rectangle())
                    .background(BattlefieldTheme.actionBrass, in: BeveledFieldShape(cornerCut: 5))
                    .overlay { BeveledFieldShape(cornerCut: 5).stroke(Color.white.opacity(0.55), lineWidth: 1) }
                    .shadow(color: BattlefieldTheme.selectedPiece.opacity(0.42), radius: 5, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("执行")
                .accessibilityIdentifier("battlefield-execute-order")
            }
        }
    }

    private func command(_ title: String, caption: String? = nil, icon: String, accent: Color, enabled: Bool,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(enabled ? accent : BattlefieldTheme.mutedInk)
                Text(caption ?? title)
                    .font(BattlefieldTheme.hudCaption)
                    .foregroundStyle(BattlefieldTheme.fieldPaper)
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .background(Color.white.opacity(enabled ? 0.08 : 0.03), in: BeveledFieldShape(cornerCut: 4))
            .overlay {
                BeveledFieldShape(cornerCut: 4)
                    .stroke((enabled ? accent : Color.white).opacity(enabled ? 0.42 : 0.12), lineWidth: 0.8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .opacity(enabled ? 1 : 0.34)
        .disabled(!enabled)
    }
}

private struct CommandOrderLine: View {
    let preview: MapCommandPreview

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.turn.down.right").font(.system(size: 10, weight: .bold))
            Text(MapCommandPreviewChrome.compactTitle(for: preview) + " · " + detail)
                .font(BattlefieldTheme.hudLabel)
                .lineLimit(1)
        }
        .foregroundStyle(BattlefieldTheme.selectedPiece)
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
