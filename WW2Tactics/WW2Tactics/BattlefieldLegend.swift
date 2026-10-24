import SwiftUI

struct MapLegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(BattlefieldTheme.brass)
                Text("图例")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(BattlefieldTheme.ink)
                Text("操作 · 风险 · 态势 · 兵种")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                Spacer(minLength: 0)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    LegendItem(color: .white.opacity(0.85), label: "左键选择")
                    LegendItem(color: .orange.opacity(0.94), label: "右键执行")
                    LegendItem(color: .yellow, label: "选中")
                    LegendItem(color: .cyan, label: "步序/消耗", symbol: "1")
                    LegendItem(color: .red.opacity(0.82), label: "路线风险", symbol: "!")
                    LegendItem(color: FireRiskLevel.high.accentColor, label: "火力风险", symbol: "HIGH")
                    LegendItem(color: .red, label: "攻击预估", symbol: "A")
                    LegendItem(color: .orange.opacity(0.86), label: "移动后目标", symbol: "NX")
                    LegendItem(color: .orange.opacity(0.76), label: "攻击位", symbol: "POS")
                    LegendItem(color: .red.opacity(0.78), label: "敌火覆盖", symbol: "TH")
                    LegendItem(color: .pink.opacity(0.86), label: "敌方意图", symbol: "INT")
                    LegendItem(color: .mint.opacity(0.9), label: "反制聚焦", symbol: "ACT")
                    LegendItem(color: .pink.opacity(0.9), label: "据点压力", symbol: "PRS")
                    LegendItem(color: .orange.opacity(0.9), label: "态势响应", symbol: "RSP")
                    LegendItem(color: .indigo.opacity(0.88), label: "AI复盘", symbol: "AI")
                    LegendItem(color: .black.opacity(0.62), label: "同格折叠", symbol: "+N")
                    LegendItem(color: .green.opacity(0.9), label: "补给线")
                    LegendItem(color: .red.opacity(0.92), label: "断补给", symbol: "CUT")
                    LegendItem(color: .white.opacity(0.85), label: "焦点")
                    LegendItem(color: Faction.allies.accentColor, label: "盟军")
                    LegendItem(color: Faction.axis.accentColor, label: "轴心国")
                    LegendItem(color: .purple.opacity(0.92), label: "压制", symbol: "PIN")
                    UnitLegendItem(kind: .infantry, faction: .allies)
                    UnitLegendItem(kind: .tank, faction: .allies)
                    UnitLegendItem(kind: .artillery, faction: .axis)
                    UnitLegendItem(kind: .recon, faction: .axis)
                }
                .padding(.vertical, 1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(BattlefieldTheme.commandDeckDeep.opacity(0.58))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(BattlefieldTheme.brass.opacity(0.16), lineWidth: 1)
                )
        )
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    var symbol: String?

    var body: some View {
        HStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                if let symbol {
                    Text(symbol)
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                }
            }
            .frame(width: 14, height: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.ink.opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(BattlefieldTheme.fieldGlass.opacity(0.48), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(BattlefieldTheme.hairline, lineWidth: 1)
        )
    }
}

private struct UnitLegendItem: View {
    let kind: UnitKind
    let faction: Faction

    var body: some View {
        HStack(spacing: 5) {
            UnitShapeBadge(kind: kind, faction: faction, rank: .green, width: 34, height: 18)
            Text(kind.title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.ink.opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(BattlefieldTheme.fieldGlass.opacity(0.48), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(BattlefieldTheme.hairline, lineWidth: 1)
        )
    }
}
