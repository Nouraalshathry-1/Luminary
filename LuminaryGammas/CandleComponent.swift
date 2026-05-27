
import SwiftUI

// MARK: - CandleComponent

struct CandleComponent: View {
    private var flameScale: CGFloat = 1.0
    private var isFlickering: Bool  = true
    private var isMiniMode: Bool    = false

    init() {}

    private init(flameScale: CGFloat, isFlickering: Bool, isMiniMode: Bool) {
        self.flameScale    = flameScale
        self.isFlickering  = isFlickering
        self.isMiniMode    = isMiniMode
    }

    var body: some View {
        VStack(spacing: 0) {
            // 1. Flame
            IsolatedFlameView(
                baseScale: flameScale,
                isAnimated: isMiniMode ? false : isFlickering,
                isMiniMode: isMiniMode
            )

            // 2. Wick
            Rectangle()
                .fill(Color("WickColor"))
                .frame(width: isMiniMode ? 1.5 : 3,
                       height: isMiniMode ? 5  : 14)

            // 3. Candle body
            RoundedRectangle(cornerRadius: isMiniMode ? 6 : 18, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color("CandleTop"), Color("CandleBottom")],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width:  isMiniMode ? 24 :  90,
                       height: isMiniMode ? 34 : 130)
                .overlay(
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.08)],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: isMiniMode ? 6 : 20)
                        .clipShape(
                            RoundedRectangle(cornerRadius: isMiniMode ? 6 : 18,
                                             style: .continuous)
                        )
                    }
                )
        }
        // Soft ambient glow behind the flame (hidden in mini mode to protect card text)
        .background(
            Group {
                if !isMiniMode {
                    Circle()
                        .fill(RadialGradient(
                            gradient: Gradient(colors: [
                                Color("FlameOrange").opacity(0.35 * flameScale),
                                Color("FlameLight").opacity(0.15 * flameScale),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 60 * flameScale
                        ))
                        .frame(width:  150 * flameScale,
                               height: 150 * flameScale)
                        .offset(y: -65)
                        .blur(radius: 15)
                }
            }
        )
    }

    // MARK: - Fluent modifiers
    func flameScale(_ scale: CGFloat) -> CandleComponent {
        var c = self; c.flameScale = scale; return c
    }
    func flickering(_ enabled: Bool) -> CandleComponent {
        var c = self; c.isFlickering = enabled; return c
    }
    func miniMode(_ enabled: Bool) -> CandleComponent {
        var c = self; c.isMiniMode = enabled; return c
    }
}

// MARK: - IsolatedFlameView

private struct IsolatedFlameView: View {
    var baseScale: CGFloat
    var isAnimated: Bool
    var isMiniMode: Bool

    @State private var flicker: CGFloat = 1.0
    @State private var swaying = false

    var body: some View {
        FlameShape()
            .fill(LinearGradient(
                colors: [
                    Color("FlameLight"),
                    Color("FlameOrange"),
                    Color("FlameRed").opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            ))
            // Fixed layout frame — animation never shifts sibling views
            .frame(
                width:  (isMiniMode ? 12 : 22) * baseScale,
                height: (isMiniMode ? 22 : 42) * baseScale
            )
            .scaleEffect(flicker, anchor: .bottom)   // visual-only flicker, no layout change
            .rotationEffect(.degrees(swaying ? -6 : 6), anchor: .bottom)
            .shadow(
                color: Color("FlameOrange").opacity(0.6),
                radius: isMiniMode ? 4 : 8,
                x: 0, y: -2
            )
            .onAppear {
                guard isAnimated else { return }
                withAnimation(
                    .easeInOut(duration: 0.15).repeatForever(autoreverses: true)
                ) {
                    flicker = CGFloat.random(in: 0.95...1.05)
                }
                withAnimation(
                    .easeInOut(duration: 1.1).repeatForever(autoreverses: true)
                ) {
                    swaying = true
                }
            }
    }
}

// MARK: - FlameShape

struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Tip at top-center
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        // Right curve — wide belly around 35 % from top
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX * 1.1, y: rect.height * 0.35),
            control2: CGPoint(x: rect.maxX * 1.2, y: rect.maxY * 0.85)
        )
        // Left curve — mirror back to tip
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.minX - (rect.width * 0.2), y: rect.maxY * 0.85),
            control2: CGPoint(x: rect.minX * -0.1, y: rect.height * 0.35)
        )
        return path
    }
}

// MARK: - Mood scale helper  (1 = Very low … 5 = Great)

extension CandleComponent {
    /// Maps a 1–5 mood integer to a flame scale factor.
    static func flameScale(for mood: Int) -> CGFloat {
        switch mood {
        case 5:  return 1.1
        case 4:  return 0.9
        case 3:  return 0.7
        case 2:  return 0.5
        default: return 0.0   // level 1 — extinguished
        }
    }

    /// Human-readable label for a 1–5 mood integer.
    static func label(for mood: Int) -> String {
        switch mood {
        case 1:  return "Very low"
        case 2:  return "Low"
        case 3:  return "Medium"
        case 4:  return "Good"
        default: return "Great"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color("AccentColor").ignoresSafeArea()
        HStack(spacing: 40) {
            CandleComponent().flameScale(1.0)
            CandleComponent().flameScale(0.5)
            CandleComponent().flameScale(0.0)
        }
    }
}
