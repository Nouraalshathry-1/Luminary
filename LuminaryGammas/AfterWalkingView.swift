//
//  AfterWalkingView.swift
//  LuminaryGammas
//
//  Created by Noura Alshathry on 02/06/2026.
//

import SwiftUI
import SwiftData

// MARK: - AfterWalkingView  (Page 6)

struct AfterWalkingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    let session:        WalkSession
    let reflectionType: String       // "free" | "guided"

    @State private var moodLevel:      Int  = 3
    @State private var hasSelected          = false
    @State private var showReflection       = false

    // MARK: Body

    var body: some View {
        ZStack {
            Color("AccentColor").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // ── Custom nav header ──────────────────────────────────
                HStack(spacing: 14) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .glassEffect(in: Circle())
                    }

                    Text("After Walking")
                        .font(.title3).fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // ── Title + subtitle ───────────────────────────────────
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

                // ── Mood candle ────────────────────────────────────────
                CandleComponent()
                    .flameScale(CandleComponent.flameScale(for: moodLevel))
                    .frame(maxWidth: .infinity)
                    .animation(.easeInOut(duration: 0.35), value: moodLevel)

                Spacer(minLength: 32).frame(maxHeight: 72)

                // ── Level label (visible after first interaction) ──────
                Text(hasSelected ? CandleComponent.label(for: moodLevel) : " ")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .animation(.easeInOut, value: moodLevel)
                    .padding(.bottom, 10)

                // ── Slider — value committed only on Continue ──────────
                MoodSlider(moodLevel: $moodLevel)
                    .padding(.horizontal, 28)
                    .onChange(of: moodLevel) { _, _ in
                        if !hasSelected { hasSelected = true }
                    }

                // ── Continue button ────────────────────────────────────
                Button {
                    saveMood()
                    showReflection = true
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
        .navigationDestination(isPresented: $showReflection) {
            if reflectionType == "guided" {
                // Page 7b — Guided reflection (coming next)
                Text("Guided Reflection — coming soon")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("AccentColor").ignoresSafeArea())
            } else {
                // Page 7a — Free reflection (coming next)
                Text("Free Reflection — coming soon")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("AccentColor").ignoresSafeArea())
            }
        }
    }

    // MARK: - Save  (fires only on Continue tap)

    private func saveMood() {
        session.moodAfter      = moodLevel
        session.reflectionType = reflectionType
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WalkSession.self, configurations: config)
    let session   = WalkSession(moodBefore: 3)
    container.mainContext.insert(session)
    return NavigationStack {
        AfterWalkingView(session: session, reflectionType: "free")
    }
    .modelContainer(container)
}
