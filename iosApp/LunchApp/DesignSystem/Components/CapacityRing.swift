//
//  CapacityRing.swift
//  LunchApp
//
//  Weekly budget ring: a 12pt track with an animated progress arc and a two-line centre label.
//  The tone is chosen by the caller (the budget engine decides thresholds).
//

import SwiftUI

struct CapacityRing: View {
    enum Tone {
        case healthy, caution, over

        var color: Color {
            switch self {
            case .healthy: return Tokens.Palette.primary
            case .caution: return Tokens.Palette.warning
            case .over: return Tokens.Palette.danger
            }
        }
    }

    /// 0...1; values above 1 render as a full ring.
    let progress: Double
    let label: String
    var sublabel: String? = nil
    var tone: Tone = .healthy
    var diameter: CGFloat = Tokens.Size.heroButton - Tokens.Spacing.xl

    private static let startAngle = Angle.degrees(-90)

    var body: some View {
        ZStack {
            Circle()
                .stroke(Tokens.Palette.hairline, lineWidth: Tokens.Size.capacityRingStroke)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(tone.color, style: StrokeStyle(lineWidth: Tokens.Size.capacityRingStroke, lineCap: .round))
                .rotationEffect(Self.startAngle)
                .animation(.easeOut(duration: Tokens.Motion.fadeInDurationSeconds), value: progress)
            VStack(spacing: Tokens.Spacing.xs) {
                Text(label)
                    .lunchText(.title)
                    .foregroundStyle(Tokens.Palette.text)
                if let sublabel {
                    Text(sublabel)
                        .lunchText(.caption)
                        .foregroundStyle(Tokens.Palette.textSecondary)
                }
            }
            .multilineTextAlignment(.center)
            .padding(Tokens.Size.capacityRingStroke + Tokens.Spacing.sm)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(Int((min(max(progress, 0), 1) * 100).rounded())) percent" + (sublabel.map { ", \($0)" } ?? ""))
    }
}

#Preview("Capacity rings") {
    LunchPreview {
        HStack(spacing: Tokens.Spacing.lg) {
            CapacityRing(progress: 0.62, label: PreviewData.currency(124), sublabel: Copy.Track.ringRemaining(PreviewData.currency(76)), diameter: Tokens.Size.heroRingOuter / 2)
            CapacityRing(progress: 0.9, label: PreviewData.currency(180), sublabel: Copy.Track.ringRemaining(PreviewData.currency(20)), tone: .caution, diameter: Tokens.Size.heroRingOuter / 2)
        }
        CapacityRing(progress: 1.2, label: PreviewData.currency(231), sublabel: Copy.Track.ringRemaining(PreviewData.currency(0)), tone: .over)
    }
}
