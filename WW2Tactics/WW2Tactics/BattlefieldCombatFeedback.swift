import SwiftUI

struct SelectedUnitGroundHalo: View {
    var body: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.34),
                        BattlefieldTheme.selectedPiece.opacity(0.26),
                        BattlefieldTheme.selectedPiece.opacity(0.08)
                    ],
                    center: .center,
                    startRadius: 2,
                    endRadius: 26
                )
            )
            .overlay {
                Ellipse()
                    .stroke(Color.black.opacity(0.52), lineWidth: 3)
            }
            .overlay {
                Ellipse()
                    .stroke(BattlefieldTheme.selectedPiece.opacity(0.94), lineWidth: 1.5)
            }
            .shadow(color: BattlefieldTheme.selectedPiece.opacity(0.58), radius: 5, y: 2)
            .accessibilityHidden(true)
    }
}

struct EngagementAxisOverlay: View {
    let start: CGPoint
    let end: CGPoint

    var body: some View {
        let angle = Angle(radians: Double(atan2(end.y - start.y, end.x - start.x)))
        let points = trimmedPoints

        ZStack {
            Path { path in
                path.move(to: points.start)
                path.addLine(to: points.end)
            }
            .stroke(Color.black.opacity(0.78), style: StrokeStyle(lineWidth: 5, lineCap: .round))

            Path { path in
                path.move(to: points.start)
                path.addLine(to: points.end)
            }
            .stroke(
                Color.orange.opacity(0.94),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [7, 4])
            )

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white)
                .padding(3)
                .background(Color.red.opacity(0.92), in: Circle())
                .rotationEffect(angle)
                .position(points.end)
        }
    }

    private var trimmedPoints: (start: CGPoint, end: CGPoint) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let distance = max(1, hypot(dx, dy))
        let inset = min(22, distance * 0.28)
        let unitX = dx / distance
        let unitY = dy / distance
        return (
            CGPoint(x: start.x + unitX * inset, y: start.y + unitY * inset),
            CGPoint(x: end.x - unitX * inset, y: end.y - unitY * inset)
        )
    }
}

struct CombatResolutionOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.combatResolutionSteadyState) private var isSteadyState
    @ScaledMetric(relativeTo: .caption) private var outcomeFontSize: CGFloat = 9

    let summary: CombatResultSummary
    let attackerPoint: CGPoint
    let defenderPoint: CGPoint

    @State private var phase: CombatResolutionPhase = .impact

    var body: some View {
        GeometryReader { proxy in
            let layout = CombatResolutionLayout(
                attackerPoint: attackerPoint,
                defenderPoint: defenderPoint,
                bounds: proxy.size
            )
            let conclusion = combatConclusion

            ZStack {
                Path { path in
                    path.move(to: layout.trimmedStart)
                    path.addLine(to: layout.trimmedEnd)
                }
                .stroke(Color.black.opacity(0.74), style: StrokeStyle(lineWidth: 5, lineCap: .round))

                Path { path in
                    path.move(to: layout.trimmedStart)
                    path.addLine(to: layout.trimmedEnd)
                }
                .stroke(
                    conclusion.color.opacity(activePhase == .impact ? 0.84 : 0.66),
                    style: StrokeStyle(
                        lineWidth: activePhase == .impact ? 2.8 : 2.1,
                        lineCap: .round,
                        dash: [5, 4]
                    )
                )

                CombatImpactMarker(
                    color: conclusion.color,
                    isImpactPhase: activePhase == .impact,
                    reduceMotion: reduceMotion || isSteadyState
                )
                .frame(width: 58, height: 58)
                .position(defenderPoint)

                CombatDamagePlate(
                    systemImage: "burst.fill",
                    title: "HIT -\(summary.damage)",
                    hpText: "\(summary.defender.startingHP) -> \(summary.defender.endingHP)",
                    color: summary.didDestroyDefender ? BattlefieldTheme.alert : BattlefieldTheme.brass
                )
                .position(layout.hitPlatePoint)
                .opacity(showsPrimaryDamage ? 1 : 0)
                .scaleEffect(plateScale(isVisible: showsPrimaryDamage))
                .offset(y: plateOffset(isVisible: showsPrimaryDamage))

                if summary.hasCounterAttack {
                    CombatDamagePlate(
                        systemImage: "arrow.uturn.backward.circle.fill",
                        title: "RET -\(summary.counterDamage)",
                        hpText: "\(summary.attacker.startingHP) -> \(summary.attacker.endingHP)",
                        color: summary.didDestroyAttacker ? BattlefieldTheme.alert : .orange
                    )
                    .position(layout.retPlatePoint)
                    .opacity(showsCounterDamage ? 1 : 0)
                    .scaleEffect(plateScale(isVisible: showsCounterDamage))
                    .offset(y: plateOffset(isVisible: showsCounterDamage))
                }

                CombatResolutionConclusionView(
                    title: conclusion.title,
                    systemImage: conclusion.systemImage,
                    qualifier: conclusion.qualifier,
                    qualifierSystemImage: conclusion.qualifierSystemImage,
                    color: conclusion.color,
                    fontSize: outcomeFontSize
                )
                .position(layout.conclusionPoint)
                .opacity(showsResolution ? 1 : 0)
                .scaleEffect(plateScale(isVisible: showsResolution))
                .offset(y: plateOffset(isVisible: showsResolution))
            }
        }
        .opacity(overlayOpacity)
        .animation(presentationAnimation, value: phase)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHidden(activePhase == .hidden)
        .task(id: summary.id) {
            await playPresentationSequence()
        }
    }

    private var activePhase: CombatResolutionPhase {
        isSteadyState ? .resolved : phase
    }

    private var showsPrimaryDamage: Bool {
        activePhase.rawValue >= CombatResolutionPhase.damage.rawValue
    }

    private var showsCounterDamage: Bool {
        activePhase.rawValue >= CombatResolutionPhase.counterDamage.rawValue
    }

    private var showsResolution: Bool {
        activePhase.rawValue >= CombatResolutionPhase.resolved.rawValue
    }

    private var overlayOpacity: Double {
        switch activePhase {
        case .dismissing, .hidden:
            return 0
        default:
            return 1
        }
    }

    private var presentationAnimation: Animation? {
        guard !isSteadyState else { return nil }
        if phase == .dismissing {
            return .easeOut(duration: 0.22)
        }
        return reduceMotion ? nil : .easeOut(duration: 0.11)
    }

    private func plateScale(isVisible: Bool) -> CGFloat {
        guard !reduceMotion && !isSteadyState else { return 1 }
        return isVisible ? 1 : 0.96
    }

    private func plateOffset(isVisible: Bool) -> CGFloat {
        guard !reduceMotion && !isSteadyState else { return 0 }
        return isVisible ? 0 : 4
    }

    @MainActor
    private func playPresentationSequence() async {
        if isSteadyState {
            phase = .resolved
            return
        }

        phase = reduceMotion ? .resolved : .impact
        do {
            if !reduceMotion {
                try await Task.sleep(for: .milliseconds(130))
                try Task.checkCancellation()
                phase = .damage

                if summary.hasCounterAttack {
                    try await Task.sleep(for: .milliseconds(90))
                    try Task.checkCancellation()
                    phase = .counterDamage
                }

                try await Task.sleep(for: .milliseconds(110))
                try Task.checkCancellation()
                phase = .resolved
            }

            try await Task.sleep(for: .milliseconds(2400))
            try Task.checkCancellation()
            phase = .dismissing

            try await Task.sleep(for: .milliseconds(220))
            try Task.checkCancellation()
            phase = .hidden
        } catch is CancellationError {
            return
        } catch {
            return
        }
    }

    private var combatConclusion: CombatResolutionConclusion {
        CombatResolutionConclusion(summary: summary)
    }

    private var accessibilitySummary: String {
        let conclusion = combatConclusion
        let qualifierText = conclusion.qualifier.map { "，\($0)" } ?? ""
        let counterText = summary.hasCounterAttack
            ? "，真实 RET -\(summary.counterDamage)，攻击方 HP 从 \(summary.attacker.startingHP) 降至 \(summary.attacker.endingHP)"
            : "，无反击（没有 RET）"
        let attackerDestroyedText = summary.didDestroyAttacker ? "，攻击方被反击击毁" : ""
        return "\(conclusion.title)\(qualifierText)。\(summary.attacker.name) 发起 HIT -\(summary.damage)，防守方 HP 从 \(summary.defender.startingHP) 降至 \(summary.defender.endingHP)\(counterText)\(attackerDestroyedText)。"
    }
}

private struct CombatResolutionConclusion {
    let title: String
    let systemImage: String
    let qualifier: String?
    let qualifierSystemImage: String?
    let color: Color

    init(summary: CombatResultSummary) {
        if summary.didDestroyDefender && summary.didDestroyAttacker {
            title = "双方击毁"
            systemImage = "burst.fill"
            qualifier = "反击击毁"
            qualifierSystemImage = "arrow.uturn.backward.circle.fill"
            color = BattlefieldTheme.alert
        } else if summary.didDestroyDefender {
            title = "击毁防守方"
            systemImage = "target"
            qualifier = nil
            qualifierSystemImage = nil
            color = BattlefieldTheme.alert
        } else if summary.didDestroyAttacker {
            title = "反击击毁"
            systemImage = "arrow.uturn.backward.circle.fill"
            qualifier = nil
            qualifierSystemImage = nil
            color = BattlefieldTheme.alert
        } else if summary.hasCounterAttack {
            title = "交火"
            systemImage = "arrow.left.arrow.right"
            qualifier = nil
            qualifierSystemImage = nil
            color = .orange
        } else {
            title = "压制"
            systemImage = "shield.lefthalf.filled"
            qualifier = "无反击"
            qualifierSystemImage = "shield.slash.fill"
            color = BattlefieldTheme.brass
        }
    }
}

private struct CombatResolutionConclusionView: View {
    let title: String
    let systemImage: String
    let qualifier: String?
    let qualifierSystemImage: String?
    let color: Color
    let fontSize: CGFloat

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: fontSize, weight: .black))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: fontSize, weight: .black, design: .rounded))

            if let qualifier, let qualifierSystemImage {
                Rectangle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 1, height: 11)

                Image(systemName: qualifierSystemImage)
                    .font(.system(size: max(7, fontSize - 1), weight: .bold))
                    .foregroundStyle(color.opacity(0.76))

                Text(qualifier)
                    .font(.system(size: max(7, fontSize - 1), weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.78))
            }
        }
        .foregroundStyle(.white)
        .lineLimit(1)
        .allowsTightening(true)
        .minimumScaleFactor(0.72)
        .frame(width: CombatResolutionLayout.conclusionWidth - 14)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            BattlefieldTheme.commandDeckDeep.opacity(0.88),
            in: RoundedRectangle(cornerRadius: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(color.opacity(0.78), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 1, y: 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct CombatResolutionLayout {
    static let damagePlateWidth: CGFloat = 140
    static let conclusionWidth: CGFloat = 174
    let trimmedStart: CGPoint
    let trimmedEnd: CGPoint
    let hitPlatePoint: CGPoint
    let retPlatePoint: CGPoint
    let conclusionPoint: CGPoint

    init(attackerPoint: CGPoint, defenderPoint: CGPoint, bounds: CGSize) {
        let dx = defenderPoint.x - attackerPoint.x
        let dy = defenderPoint.y - attackerPoint.y
        let rawDistance = hypot(dx, dy)
        let unitX = rawDistance > 0.001 ? dx / rawDistance : 1
        let unitY = rawDistance > 0.001 ? dy / rawDistance : 0
        let midpoint = CGPoint(
            x: (attackerPoint.x + defenderPoint.x) / 2,
            y: (attackerPoint.y + defenderPoint.y) / 2
        )
        var normal = CGPoint(x: -unitY, y: unitX)
        let towardCenter = CGPoint(
            x: bounds.width / 2 - midpoint.x,
            y: bounds.height / 2 - midpoint.y
        )
        let shouldPointDown = bounds.height > 0 && midpoint.y < bounds.height * 0.24

        if shouldPointDown {
            if normal.y < 0 || (abs(normal.y) < 0.08 && normal.x * towardCenter.x < 0) {
                normal = CGPoint(x: -normal.x, y: -normal.y)
            }
        } else if normal.y > 0 || (abs(normal.y) < 0.08 && normal.x * towardCenter.x < 0) {
            normal = CGPoint(x: -normal.x, y: -normal.y)
        }

        let inset = min(25, rawDistance * 0.30)
        let closeEngagement = rawDistance < 132
        let outwardOffset: CGFloat = closeEngagement ? 28 : 22
        let plateNormalOffset: CGFloat = closeEngagement ? 30 : 24
        let conclusionNormalOffset: CGFloat = closeEngagement ? 70 : 54

        trimmedStart = CGPoint(
            x: attackerPoint.x + unitX * inset,
            y: attackerPoint.y + unitY * inset
        )
        trimmedEnd = CGPoint(
            x: defenderPoint.x - unitX * inset,
            y: defenderPoint.y - unitY * inset
        )
        hitPlatePoint = Self.clamped(Self.offset(
            from: defenderPoint,
            axisX: unitX,
            axisY: unitY,
            axisDistance: outwardOffset,
            normal: normal,
            normalDistance: plateNormalOffset
        ), width: Self.damagePlateWidth, bounds: bounds)
        retPlatePoint = Self.clamped(Self.offset(
            from: attackerPoint,
            axisX: -unitX,
            axisY: -unitY,
            axisDistance: outwardOffset,
            normal: normal,
            normalDistance: plateNormalOffset
        ), width: Self.damagePlateWidth, bounds: bounds)
        conclusionPoint = Self.clamped(Self.offset(
            from: midpoint,
            axisX: 0,
            axisY: 0,
            axisDistance: 0,
            normal: normal,
            normalDistance: conclusionNormalOffset
        ), width: Self.conclusionWidth, bounds: bounds)
    }

    private static func clamped(_ point: CGPoint, width: CGFloat, bounds: CGSize) -> CGPoint {
        let insetX = min(bounds.width / 2, width / 2 + 4)
        let insetY = min(bounds.height / 2, 16)
        return CGPoint(x: min(max(point.x, insetX), bounds.width - insetX),
                       y: min(max(point.y, insetY), bounds.height - insetY))
    }

    private static func offset(
        from point: CGPoint,
        axisX: CGFloat,
        axisY: CGFloat,
        axisDistance: CGFloat,
        normal: CGPoint,
        normalDistance: CGFloat
    ) -> CGPoint {
        CGPoint(
            x: point.x + axisX * axisDistance + normal.x * normalDistance,
            y: point.y + axisY * axisDistance + normal.y * normalDistance
        )
    }
}

private enum CombatResolutionPhase: Int {
    case impact
    case damage
    case counterDamage
    case resolved
    case dismissing
    case hidden
}

private struct CombatImpactMarker: View {
    let color: Color
    let isImpactPhase: Bool
    let reduceMotion: Bool

    var body: some View {
        CombatImpactShape()
            .stroke(
                color.opacity(isImpactPhase ? 0.92 : 0.34),
                style: StrokeStyle(lineWidth: isImpactPhase ? 2.2 : 1.2, lineCap: .square)
            )
            .scaleEffect(reduceMotion ? 1 : (isImpactPhase ? 1.08 : 1))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: isImpactPhase)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct CombatImpactShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let ringInset = min(rect.width, rect.height) * 0.20
        let innerRadius = min(rect.width, rect.height) * 0.32
        let outerRadius = min(rect.width, rect.height) * 0.47
        var path = Path()

        path.addEllipse(in: rect.insetBy(dx: ringInset, dy: ringInset))
        for angle in stride(from: 0.0, to: 360.0, by: 45.0) {
            let radians = angle * .pi / 180
            let directionX = CGFloat(cos(radians))
            let directionY = CGFloat(sin(radians))
            path.move(to: CGPoint(
                x: center.x + directionX * innerRadius,
                y: center.y + directionY * innerRadius
            ))
            path.addLine(to: CGPoint(
                x: center.x + directionX * outerRadius,
                y: center.y + directionY * outerRadius
            ))
        }
        return path
    }
}

struct CombatDamagePlate: View {
    @ScaledMetric(relativeTo: .caption) private var iconFontSize: CGFloat = 7
    @ScaledMetric(relativeTo: .caption) private var titleFontSize: CGFloat = 8
    @ScaledMetric(relativeTo: .caption) private var hpFontSize: CGFloat = 7

    let systemImage: String
    let title: String
    let hpText: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: iconFontSize, weight: .black))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: titleFontSize, weight: .black, design: .rounded))
                .allowsTightening(true)
                .lineLimit(1)
                .minimumScaleFactor(0.70)

            Rectangle()
                .fill(Color.white.opacity(0.24))
                .frame(width: 1, height: 10)

            Text(hpText)
                .font(.system(size: hpFontSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .allowsTightening(true)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
        }
        .foregroundStyle(.white)
        .lineLimit(1)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .frame(width: CombatResolutionLayout.damagePlateWidth)
        .background(
            LinearGradient(
                colors: [
                    BattlefieldTheme.fieldGlass.opacity(0.86),
                    BattlefieldTheme.commandDeckDeep.opacity(0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(color.opacity(0.76), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.26), radius: 1.5, y: 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct TacticalCornerReticle: View {
    let color: Color

    var body: some View {
        ZStack {
            CornerReticleShape()
                .stroke(Color.black.opacity(0.78), style: StrokeStyle(lineWidth: 5, lineCap: .square, lineJoin: .miter))
            CornerReticleShape()
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .square, lineJoin: .miter))
        }
        .shadow(color: color.opacity(0.48), radius: 3)
        .accessibilityHidden(true)
    }
}

struct CornerReticleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let arm = min(rect.width, rect.height) * 0.22
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + arm))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + arm, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - arm, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + arm))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - arm))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - arm, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX + arm, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - arm))

        return path
    }
}
