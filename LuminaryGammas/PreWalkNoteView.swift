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

    @State private var noteText       = ""
    @State private var showDuringWalk = false
    @State private var currentSession: WalkSession?
    @FocusState private var editorFocused: Bool

    @State private var safeTop:    CGFloat = 59
    @State private var safeBottom: CGFloat = 34

    private var hasText: Bool {
        !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color("AccentColor")
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Nav header ───────────────────────────────────────────
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

                // ── Scrollable body (keyboard never shifts this) ──────────
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // Title + subtitle
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How do you feel?")
                                .font(.largeTitle).fontWeight(.semibold)
                                .foregroundStyle(.white)

                            Text("Briefly write your thoughts out here")
                                .font(.callout)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        // ── Text editor card ──────────────────────────────
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color("SecondColor"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                                )

                            if noteText.isEmpty {
                                Text("Right now, I am feeling...")
                                    .font(.callout)
                                    .foregroundStyle(.white.opacity(0.25))
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                                    .allowsHitTesting(false)
                            }

                            TextEditor(text: $noteText)
                                .focused($editorFocused)
                                .font(.body)
                                .foregroundStyle(.white)
                                .scrollContentBackground(.hidden)
                                .background(.clear)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .tint(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .padding(.horizontal, 20)
                        .padding(.top, 32)

                        Spacer().frame(height: 24)
                    }
                }
                .scrollDismissesKeyboard(.immediately)

                // ── Buttons — pinned outside scroll, never move ───────────
                VStack(spacing: 10) {
                    Button {
                        startWalk(skipping: false)
                    } label: {
                        Text("Start walking")
                            .font(.headline)
                            .foregroundStyle(Color("AccentColor").opacity(hasText ? 1 : 0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                Capsule().fill(Color.white.opacity(hasText ? 1 : 0.2))
                            )
                    }
                    .disabled(!hasText)
                    .animation(.easeInOut(duration: 0.2), value: hasText)
                    .padding(.horizontal, 24)

                    VStack(spacing: 8) {
                        Text("or")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.35))

                        Button {
                            startWalk(skipping: true)
                        } label: {
                            Text("Skip text and start walking")
                                .font(.callout).fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                    .padding(.bottom, safeBottom + 16)
                }
                .padding(.top, 12)
            }
            .padding(.top, safeTop)
        }
        .ignoresSafeArea(.all)
        .onAppear(perform: readSafeArea)
        .simultaneousGesture(TapGesture().onEnded { editorFocused = false })
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showDuringWalk) {
            if let session = currentSession {
                DuringWalkView(session: session)
            }
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
        currentSession = session
        showDuringWalk = true
    }

    // MARK: - Safe Area

    private func readSafeArea() {
        guard
            let scene  = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
            let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
        else { return }
        safeTop    = window.safeAreaInsets.top
        safeBottom = window.safeAreaInsets.bottom
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PreWalkNoteView(moodBefore: 3)
    }
    .modelContainer(for: WalkSession.self, inMemory: true)
}

//import SwiftUI
//import SwiftData
//
//// MARK: - PreWalkNoteView
//
//struct PreWalkNoteView: View {
//    @Environment(\.dismiss) private var dismiss
//    @Environment(\.modelContext) private var modelContext
//
//    let moodBefore: Int
//
//    @State private var noteText       = ""
//    @State private var showDuringWalk = false
//    @State private var currentSession: WalkSession?
//    @FocusState private var editorFocused: Bool
//
//    // Read once from the UIWindow on appear — these are hardware-only insets
//    // (status bar / Dynamic Island + home indicator).  UIKit never touches
//    // UIWindow.safeAreaInsets when the keyboard shows, so these stay fixed
//    // no matter what happens below.
//    @State private var safeTop:    CGFloat = 59   // Dynamic Island fallback
//    @State private var safeBottom: CGFloat = 34   // Home-indicator fallback
//
//    private var hasText: Bool {
//        !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//    }
//
//    // MARK: - Body
//
//    var body: some View {
//        ZStack {
//            // Full-bleed background — tap outside box dismisses keyboard
//            Color("AccentColor")
//                .ignoresSafeArea()
//                .onTapGesture { editorFocused = false }
//
//            // All content lives in one VStack with FIXED explicit padding.
//            // Nothing here reads .safeAreaInsets from the environment, so
//            // SwiftUI cannot re-layout this in response to UIKit's
//            // additionalSafeAreaInsets.bottom change.
//            VStack(alignment: .leading, spacing: 0) {
//
//                // ── Nav header ───────────────────────────────────────────
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
//                        .font(.title3).fontWeight(.semibold)
//                        .foregroundStyle(.white)
//
//                    Spacer()
//                }
//                .padding(.horizontal, 20)
//                .padding(.top, 12)
//
//                // ── Title + subtitle ─────────────────────────────────────
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("How do you feel?")
//                        .font(.largeTitle).fontWeight(.semibold)
//                        .foregroundStyle(.white)
//
//                    Text("Briefly write your thoughts out here")
//                        .font(.callout)
//                        .foregroundStyle(.white.opacity(0.5))
//                }
//                .padding(.horizontal, 24)
//                .padding(.top, 24)
//
//                // ── Text editor card ──────────────────────────────────────
//                ZStack(alignment: .topLeading) {
//                    RoundedRectangle(cornerRadius: 20)
//                        .fill(Color("SecondColor"))
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 20)
//                                .stroke(Color.white.opacity(0.45), lineWidth: 1)
//                        )
//
//                    if noteText.isEmpty {
//                        Text("Right now, I am feeling...")
//                            .font(.callout)
//                            .foregroundStyle(.white.opacity(0.25))
//                            .padding(.horizontal, 20)
//                            .padding(.top, 20)
//                            .allowsHitTesting(false)
//                    }
//
//                    TextEditor(text: $noteText)
//                        .focused($editorFocused)
//                        .font(.body)
//                        .foregroundStyle(.white)
//                        .scrollContentBackground(.hidden)
//                        .background(.clear)
//                        .padding(.horizontal, 14)
//                        .padding(.vertical, 12)
//                        .tint(.white)
//                }
//                .frame(maxWidth: .infinity)
//                .frame(height: 260)
//                .padding(.horizontal, 20)
//                .padding(.top, 32)
//
//                Spacer()
//
//                // ── Buttons ───────────────────────────────────────────────
//                VStack(spacing: 10) {
//                    Button {
//                        startWalk(skipping: false)
//                    } label: {
//                        Text("Start walking")
//                            .font(.headline)
//                            .foregroundStyle(Color("AccentColor").opacity(hasText ? 1 : 0.5))
//                            .frame(maxWidth: .infinity)
//                            .padding(.vertical, 18)
//                            .background(
//                                Capsule().fill(Color.white.opacity(hasText ? 1 : 0.2))
//                            )
//                    }
//                    .disabled(!hasText)
//                    .animation(.easeInOut(duration: 0.2), value: hasText)
//                    .padding(.horizontal, 24)
//
//                    VStack(spacing: 8) {
//                        Text("or")
//                            .font(.footnote)
//                            .foregroundStyle(.white.opacity(0.35))
//
//                        Button {
//                            startWalk(skipping: true)
//                        } label: {
//                            Text("Skip text and start walking")
//                                .font(.callout).fontWeight(.medium)
//                                .foregroundStyle(.white.opacity(0.55))
//                        }
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding(.bottom, 48)
//                }
//            }
//            // safeTop / safeBottom are set once on appear and never change.
//            .padding(.top, safeTop)
//            .padding(.bottom, safeBottom)
//        }
//        // This is the whole fix: the ZStack is always full-screen.
//        // Safe-area changes from UIKit never resize it, so nothing inside moves.
//        .ignoresSafeArea(.all)
//        .onAppear(perform: readSafeArea)
//        .toolbar(.hidden, for: .navigationBar)
//        .navigationDestination(isPresented: $showDuringWalk) {
//            if let session = currentSession {
//                DuringWalkView(session: session)
//            }
//        }
//    }
//
//    // MARK: - Save & Navigate
//
//    private func startWalk(skipping: Bool) {
//        let session = WalkSession(
//            moodBefore: moodBefore,
//            preWalkNote: skipping ? "" : noteText.trimmingCharacters(in: .whitespacesAndNewlines)
//        )
//        modelContext.insert(session)
//        try? modelContext.save()
//        currentSession = session
//        showDuringWalk = true
//    }
//
//    // MARK: - Safe Area
//
//    // UIWindow.safeAreaInsets = hardware-only (notch/Dynamic Island + home
//    // indicator).  UIKit's additionalSafeAreaInsets on view controllers is a
//    // separate layer and does NOT modify this value, so reading it once here
//    // gives us a number that never changes when the keyboard appears.
//    private func readSafeArea() {
//        guard
//            let scene  = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
//            let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
//        else { return }
//        safeTop    = window.safeAreaInsets.top
//        safeBottom = window.safeAreaInsets.bottom
//    }
//}
//
//// MARK: - Preview
//
//#Preview {
//    NavigationStack {
//        PreWalkNoteView(moodBefore: 3)
//    }
//    .modelContainer(for: WalkSession.self, inMemory: true)
//}
