//
//   DuringWalkView.swift
//  LuminaryGammas
//
//  Created by Noura Alshathry on 31/05/2026.
//


import SwiftUI
import SwiftData
import CoreMotion
import Combine

// MARK: - WalkTracker

final class WalkTracker: ObservableObject {
    @Published var elapsedSeconds = 0
    @Published var stepCount      = 0

    private let pedometer = CMPedometer()
    private var timerRef: Timer?
    private var startDate: Date?

    func start() {
        guard startDate == nil else { return }
        let now = Date()
        startDate = now

        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: now) { [weak self] data, error in
                guard let data, error == nil else { return }
                DispatchQueue.main.async { self?.stepCount = data.numberOfSteps.intValue }
            }
        }

        timerRef = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
    }

    func stop() {
        pedometer.stopUpdates()
        timerRef?.invalidate()
        timerRef = nil
    }
}

// MARK: - DuringWalkView

struct DuringWalkView: View {
    @Environment(\.modelContext) private var modelContext
    let session: WalkSession

    @StateObject private var tracker = WalkTracker()

    @State private var showNoteSheet   = false
    @State private var pendingNoteText = ""
    @State private var showAfterWalk   = false
    @State private var showSavedToast  = false

    @State private var safeTop:    CGFloat = 59
    @State private var safeBottom: CGFloat = 34

    @ScaledMetric private var timerFontSize: CGFloat = 38

    var body: some View {
        ZStack {
            Color("AccentColor").ignoresSafeArea()

            // ── Candle layer ───────────────────────────────────────────
            // Spacer pushes the candle's layout to the screen bottom.
            // scaleEffect(anchor: .bottom) grows the visual upward from that
            // point, so the base stays flush with the screen edge.
            VStack(spacing: 0) {
                Spacer()
                CandleComponent()
                    .flameScale(1.0)
                    .scaleEffect(x: 2.3, y: 3.2, anchor: .bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)

            // ── Saved toast ────────────────────────────────────────────
            if showSavedToast {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Note saved")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, safeTop + 52)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .allowsHitTesting(false)
            }

            // ── Content overlay: hint at top, button at bottom ─────────
            VStack(spacing: 0) {
                Text("Tap the screen to take a quick note")
                    .foregroundStyle(Color("WColor"))
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    .allowsHitTesting(false)

                Spacer()

                // ── Duration overlay — sits in the middle of the candle body
                VStack(spacing: 6) {
                    Text("session duration")
                        .font(.callout)
                        .foregroundStyle(Color("AccentColor").opacity(0.55))

                    Text(formattedDuration)
                        .font(.system(size: timerFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("AccentColor"))
                        .monospacedDigit()
                }
                .allowsHitTesting(false)

                Spacer().frame(height: 80)

                Button(action: endWalk) {
                    Text("End the walk")
                        .font(.headline).fontWeight(.semibold)
                        .foregroundStyle(.black.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Capsule().fill(Color.white.opacity(0.9)))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .padding(.top, safeTop)
            .padding(.bottom, safeBottom)
        }
        .ignoresSafeArea(.all)
        .contentShape(Rectangle())
        .onTapGesture { showNoteSheet = true }
        .onAppear { readSafeArea(); tracker.start() }
        .onDisappear { tracker.stop() }
        .sheet(isPresented: $showNoteSheet, onDismiss: handleNoteDismiss) {
            WalkNoteSheet(noteText: $pendingNoteText)
        }
        .navigationDestination(isPresented: $showAfterWalk) {
            SessionTitleView(session: session)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Helpers

    private var formattedDuration: String {
        let h = tracker.elapsedSeconds / 3600
        let m = (tracker.elapsedSeconds % 3600) / 60
        let s = tracker.elapsedSeconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }

    private func endWalk() {
        tracker.stop()
        session.durationMinutes = max(1, tracker.elapsedSeconds / 60)
        session.steps           = tracker.stepCount
        try? modelContext.save()
        showAfterWalk = true
    }

    private func handleNoteDismiss() {
        let trimmed = pendingNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        pendingNoteText = ""
        guard !trimmed.isEmpty else { return }
        session.duringWalkNotes.append(trimmed)
        session.duringWalkNoteTimestamps.append(Date())
        try? modelContext.save()
        withAnimation(.easeOut(duration: 0.3)) { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeIn(duration: 0.3)) { showSavedToast = false }
        }
    }

    private func readSafeArea() {
        guard
            let scene  = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
            let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
        else { return }
        safeTop    = window.safeAreaInsets.top
        safeBottom = window.safeAreaInsets.bottom
    }
}

// MARK: - WalkNoteSheet  (native Apple look)

struct WalkNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var noteText: String
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {

                Label {
                    Text("Take a pause from walking, then write")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                }
                .padding(.top, 4)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))

                    if noteText.isEmpty {
                        Text("What's on your mind?")
                            .foregroundStyle(.tertiary)
                            .padding(14)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $noteText)
                        .scrollContentBackground(.hidden)
                        .background(.clear)
                        .padding(10)
                        .focused($focused)
                        .tint(colorScheme == .dark ? .white : .black)
                }
                .frame(height: 180)

                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationTitle("Quick Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear { focused = true }
    }
}

// MARK: - Preview

#Preview {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WalkSession.self, configurations: config)
    let session   = WalkSession(moodBefore: 3, preWalkNote: "Feeling tense today")
    container.mainContext.insert(session)
    return NavigationStack { DuringWalkView(session: session) }
        .modelContainer(container)
}

