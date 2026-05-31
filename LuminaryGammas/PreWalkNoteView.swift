//
//  PreWalkNoteView.swift
//  LuminaryGammas
//
//  Created by Noura Alshathry on 31/05/2026.
//

import SwiftUI
import SwiftData

// MARK: - PreWalkNoteView

struct PreWalkNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let moodBefore: Int

    @State private var noteText      = ""
    @State private var showDuringWalk = false
    @FocusState private var editorFocused: Bool

    // MARK: - Body

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
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Title + subtitle
                VStack(alignment: .leading, spacing: 8) {
                    Text("How do you feel?")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Briefly write your thoughts out here")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                // Text editor card
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color("SecondColor"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )

                    // Placeholder
                    if noteText.isEmpty {
                        Text("Right now, I am feeling...")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.25))
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $noteText)
                        .focused($editorFocused)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .background(.clear)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .tint(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .padding(.horizontal, 24)
                .padding(.top, 32)

                Spacer()

                // Start walking button
                Button {
                    startWalk(skipping: false)
                } label: {
                    Text("Start walking")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color("AccentColor"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Capsule().fill(Color.white))
                }
                .padding(.horizontal, 24)

                // "or" + skip link
                VStack(spacing: 10) {
                    Text("or")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.35))

                    Button {
                        startWalk(skipping: true)
                    } label: {
                        Text("Skip text and start walking")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.55))
                            .underline()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
                .padding(.bottom, 48)
            }
            .onTapGesture {
                editorFocused = false
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showDuringWalk) {
            Text("During Walk — coming soon")
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("AccentColor").ignoresSafeArea())
        }
    }

    // MARK: - Save & Navigate

    private func startWalk(skipping: Bool) {
        let session = WalkSession(
            moodBefore: moodBefore,
            preWalkNote: skipping ? "" : noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        modelContext.insert(session)
        try? modelContext.save()
        showDuringWalk = true
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PreWalkNoteView(moodBefore: 3)
    }
    .modelContainer(for: WalkSession.self, inMemory: true)
}
