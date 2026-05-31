

import SwiftUI

// MARK: - BeforeWalkingView

struct BeforeWalkingView: View {
    @Environment(\.dismiss) private var dismiss

    /// 1 = Very low  …  5 = Great   (starts at centre, not yet selected)
    @State private var moodLevel:  Int  = 3
    @State private var hasSelected       = false
    @State private var showNextPage      = false

    var body: some View {
        ZStack {
            Color("AccentColor").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // Custom nav header
                HStack(spacing: 14) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .glassEffect(in: Circle())
                    }

                    Text("Before Walking")
                        .font(.title3).fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Title + subtitle
                VStack(alignment: .leading, spacing: 8) {
                    Text("How do you feel now?")
                        .font(.largeTitle).fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text("Adjust the candle\u{2019}s flame to match your current mental energy.")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Mood candle — centred, flame driven by moodLevel
                CandleComponent()
                    .flameScale(CandleComponent.flameScale(for: moodLevel))
                    .frame(maxWidth: .infinity)
                    .animation(.easeInOut(duration: 0.35), value: moodLevel)

                Spacer(minLength: 32).frame(maxHeight: 72)

                // Level label (appears after first touch)
                Text(hasSelected ? CandleComponent.label(for: moodLevel) : " ")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .animation(.easeInOut, value: moodLevel)
                    .padding(.bottom, 10)

                // Slider
                MoodSlider(moodLevel: $moodLevel)
                    .padding(.horizontal, 28)
                    .onChange(of: moodLevel) { _, _ in
                        if !hasSelected { hasSelected = true }
                    }

                // Continue button
                Button {
                    showNextPage = true
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(Color("AccentColor"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(hasSelected ? 0.85 : 0.15))
                        )
                }
                .disabled(!hasSelected)
                .animation(.easeInOut(duration: 0.25), value: hasSelected)
                .padding(.horizontal, 24)
                .padding(.top, 64)
                .padding(.bottom, 40)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showNextPage) {
            PreWalkNoteView(moodBefore: moodLevel)
        }
    }
}

// MARK: - MoodSlider  (1–5 integer, spring snap, haptic feedback)

struct MoodSlider: View {
    @Binding var moodLevel: Int

    private let totalSteps:  Int    = 5
    private let thumbWidth:  CGFloat = 46
    private let trackHeight: CGFloat = 3
    private let sliderHeight: CGFloat = 30

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - thumbWidth
            let stepWidth      = availableWidth / CGFloat(totalSteps - 1)
            let currentX       = CGFloat(moodLevel - 1) * stepWidth

            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: trackHeight)

                // Thumb
                Capsule()
                    .fill(Color.white)
                    .frame(width: thumbWidth, height: 18)
                    .offset(x: currentX)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7),
                               value: moodLevel)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            }
            .frame(height: sliderHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let clamped = max(0, min(drag.location.x, availableWidth))
                        let step    = Int(round(clamped / stepWidth)) + 1
                        if moodLevel != step {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            moodLevel = step
                        }
                    }
            )
        }
        .frame(height: sliderHeight)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BeforeWalkingView()
    }
}

//
//import SwiftUI
//
//// MARK: - BeforeWalkingView
//
//struct BeforeWalkingView: View {
//    @Environment(\.dismiss) private var dismiss
//
//    /// 1 = Very low  …  5 = Great   (starts at centre, not yet selected)
//    @State private var moodLevel:  Int  = 3
//    @State private var hasSelected       = false
//    @State private var showNextPage      = false
//
//    var body: some View {
//        ZStack {
//            Color("AccentColor").ignoresSafeArea()
//
//            VStack(alignment: .leading, spacing: 0) {
//
//                // Custom nav header
//                HStack(spacing: 14) {
//                    Button { dismiss() } label: {
//                        Image(systemName: "chevron.left")
//                            .font(.system(size: 16, weight: .semibold))
//                            .foregroundStyle(.white)
//                            .frame(width: 44, height: 44)
//                            .glassEffect(in: Circle())
//                    }
//
//                    Text("Before Walking")
//                        .font(.system(size: 20, weight: .semibold))
//                        .foregroundStyle(.white)
//
//                    Spacer()
//                }
//                .padding(.horizontal, 20)
//                .padding(.top, 12)
//
//                // Title + subtitle
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("How do you feel now?")
//                        .font(.largeTitle).fontWeight(.semibold)
//                        .foregroundStyle(.white)
//
//                    Text("Adjust the candle\u{2019}s flame to match your current mental energy.")
//                        .font(.system(size: 16, weight: .semibold))
//                        .foregroundStyle(.white.opacity(0.5))
//                }
//                .padding(.horizontal, 24)
//                .padding(.top, 24)
//
//                Spacer()
//
//                // Mood candle — centred, flame driven by moodLevel
//                CandleComponent()
//                    .flameScale(CandleComponent.flameScale(for: moodLevel))
//                    .frame(maxWidth: .infinity)
//                    .animation(.easeInOut(duration: 0.35), value: moodLevel)
//
//                Spacer()
//
//                // Level label (appears after first touch)
//                Text(hasSelected ? CandleComponent.label(for: moodLevel) : " ")
//                    .font(.system(size: 14, weight: .semibold))
//                    .foregroundStyle(.white.opacity(0.55))
//                    .frame(maxWidth: .infinity, alignment: .center)
//                    .animation(.easeInOut, value: moodLevel)
//                    .padding(.bottom, 10)
//
//                // Slider
//                MoodSlider(moodLevel: $moodLevel)
//                    .padding(.horizontal, 28)
//                    .onChange(of: moodLevel) { _, _ in
//                        if !hasSelected { hasSelected = true }
//                    }
//
//                // Continue button
//                Button {
//                    showNextPage = true
//                } label: {
//                    Text("Continue")
//                        .font(.system(size: 18, weight: .semibold))
//                        .foregroundStyle(Color("AccentColor"))
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 18)
//                        .background(
//                            Capsule()
//                                .fill(Color.white.opacity(hasSelected ? 0.85 : 0.15))
//                        )
//                }
//                .disabled(!hasSelected)
//                .animation(.easeInOut(duration: 0.25), value: hasSelected)
//                .padding(.horizontal, 24)
//                .padding(.top, 24)
//                .padding(.bottom, 40)
//            }
//        }
//        .toolbar(.hidden, for: .navigationBar)
//        .navigationDestination(isPresented: $showNextPage) {
//            PreWalkNoteView(moodBefore: moodLevel)
//        }
//    }
//}
//
//// MARK: - MoodSlider  (1–5 integer, spring snap, haptic feedback)
//
//struct MoodSlider: View {
//    @Binding var moodLevel: Int
//
//    private let totalSteps:  Int    = 5
//    private let thumbWidth:  CGFloat = 46
//    private let trackHeight: CGFloat = 3
//    private let sliderHeight: CGFloat = 30
//
//    var body: some View {
//        GeometryReader { geometry in
//            let availableWidth = geometry.size.width - thumbWidth
//            let stepWidth      = availableWidth / CGFloat(totalSteps - 1)
//            let currentX       = CGFloat(moodLevel - 1) * stepWidth
//
//            ZStack(alignment: .leading) {
//                // Track
//                Capsule()
//                    .fill(Color.white.opacity(0.15))
//                    .frame(height: trackHeight)
//
//                // Thumb
//                Capsule()
//                    .fill(Color.white)
//                    .frame(width: thumbWidth, height: 18)
//                    .offset(x: currentX)
//                    .animation(.spring(response: 0.3, dampingFraction: 0.7),
//                               value: moodLevel)
//                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
//            }
//            .frame(height: sliderHeight)
//            .contentShape(Rectangle())
//            .gesture(
//                DragGesture(minimumDistance: 0)
//                    .onChanged { drag in
//                        let clamped = max(0, min(drag.location.x, availableWidth))
//                        let step    = Int(round(clamped / stepWidth)) + 1
//                        if moodLevel != step {
//                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                            moodLevel = step
//                        }
//                    }
//            )
//        }
//        .frame(height: sliderHeight)
//        .frame(maxWidth: .infinity)
//    }
//}
//
//// MARK: - Preview
//
//#Preview {
//    NavigationStack {
//        BeforeWalkingView()
//    }
//}
//
//
