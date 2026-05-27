
import SwiftUI

// MARK: - MoodComparisonView
// Displays before/after mood candles side-by-side.
// beforeMood / afterMood are 1–5 integers stored in WalkSession.

struct MoodComparisonView: View {
    let beforeMood:  Int
    let afterMood:   Int
    let beforeLabel: String
    let afterLabel:  String

    // Convenience init from a WalkSession
    init(session: WalkSession) {
        self.beforeMood  = session.moodBefore
        self.afterMood   = session.moodAfter
        self.beforeLabel = CandleComponent.label(for: session.moodBefore)
        self.afterLabel  = CandleComponent.label(for: session.moodAfter)
    }

    // Direct init (used in previews / custom contexts)
    init(beforeMood: Int, afterMood: Int, beforeLabel: String, afterLabel: String) {
        self.beforeMood  = beforeMood
        self.afterMood   = afterMood
        self.beforeLabel = beforeLabel
        self.afterLabel  = afterLabel
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Spacer()

            // Before candle
            VStack(spacing: 12) {
                CandleComponent()
                    .flameScale(CandleComponent.flameScale(for: beforeMood))
                    .flickering(false)
                    .miniMode(true)

                Text(beforeLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(width: 70)

            Spacer()

            // Arrow
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 90, height: 1.5)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .offset(x: -4)
            }
            .padding(.bottom, 20)

            Spacer()

            // After candle
            VStack(spacing: 12) {
                CandleComponent()
                    .flameScale(CandleComponent.flameScale(for: afterMood))
                    .flickering(false)
                    .miniMode(true)

                Text(afterLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(width: 70)

            Spacer()
        }
        .frame(width: 367, height: 173)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color("CardBackground"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color("AccentColor").ignoresSafeArea()
        MoodComparisonView(
            beforeMood: 2, afterMood: 5,
            beforeLabel: "Low", afterLabel: "Great"
        )
    }
}
