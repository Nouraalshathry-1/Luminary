//
//   SessionTitleView.swift
//  LuminaryGammas
//
//  Created by Noura Alshathry on 01/06/2026.
//


import SwiftUI
import SwiftData

// MARK: - SessionTitleView

struct SessionTitleView: View {
    @Environment(\.modelContext) private var modelContext
    let session: WalkSession

    @State private var titleText  = ""
    @State private var showStats  = false
    @FocusState private var editorFocused: Bool

    // Frozen layout — nothing moves when keyboard appears
    @State private var safeTop:    CGFloat = 59
    @State private var safeBottom: CGFloat = 34

    // MARK: Body

    var body: some View {
        ZStack {
            Color("AccentColor")
                .ignoresSafeArea()
                .onTapGesture { editorFocused = false }

            VStack(alignment: .leading, spacing: 0) {

                // ── Header: centred title + Save button ────────────────
                ZStack {
                    Text("Session Title")
                        .font(.title2).fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack {
                        Spacer()
                        Button { save() } label: {
                            Text("Save")
                                .font(.callout).fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 10)
                                .glassEffect(in: Capsule())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // ── Subtitle ───────────────────────────────────────────
                Text("Use a descriptive name for this session so you can easily find it in your history later.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // ── Text editor — 3 lines max ──────────────────────────
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color("SecondColor"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.45), lineWidth: 1)
                        )

                    if titleText.isEmpty {
                        Text("e.g., \u{201C}Unpacking today\u{2019}s event\u{201D} or \u{201C}Breaking the creative block\u{201D}")
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.25))
                            .padding(.horizontal, 16)
                            .padding(.top, 14)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $titleText)
                        .focused($editorFocused)
                        .font(.body)
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .background(.clear)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .tint(.white)
                        .onChange(of: titleText) { _, newValue in
                            // Strip newlines — session names stay on one flow
                            let cleaned = newValue.replacingOccurrences(of: "\n", with: " ")
                            // Cap at 80 chars so text never exceeds 3 visible lines
                            let capped  = String(cleaned.prefix(80))
                            if capped != newValue { titleText = capped }
                        }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Spacer()
            }
            .padding(.top, safeTop)
            .padding(.bottom, safeBottom + 20)
        }
        .ignoresSafeArea(.all)
        .onAppear {
            readSafeArea()
            titleText    = session.sessionName   // pre-fill if returning to this page
            editorFocused = true                  // keyboard up immediately, like the mockup
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showStats) {
            WalkStatsView(session: session)
        }
    }

    // MARK: - Save

    private func save() {
        session.sessionName = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        try? modelContext.save()
        showStats = true
    }

    // MARK: - Safe area

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
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WalkSession.self, configurations: config)
    let session   = WalkSession(moodBefore: 3)
    container.mainContext.insert(session)
    return NavigationStack { SessionTitleView(session: session) }
        .modelContainer(container)
}



//import SwiftUI
//import SwiftData
//
//// MARK: - SessionTitleView
//
//struct SessionTitleView: View {
//    @Environment(\.modelContext) private var modelContext
//    let session: WalkSession
//
//    @State private var titleText  = ""
//    @State private var showStats  = false
//    @FocusState private var editorFocused: Bool
//
//    // Frozen layout — nothing moves when keyboard appears
//    @State private var safeTop:    CGFloat = 59
//    @State private var safeBottom: CGFloat = 34
//
//    // MARK: Body
//
//    var body: some View {
//        ZStack {
//            Color("AccentColor")
//                .ignoresSafeArea()
//                .onTapGesture { editorFocused = false }
//
//            VStack(alignment: .leading, spacing: 0) {
//
//                // ── Header: centred title + Save button ────────────────
//                ZStack {
//                    Text("Session Title")
//                        .font(.title2).fontWeight(.bold)
//                        .foregroundStyle(.white)
//                        .frame(maxWidth: .infinity, alignment: .center)
//
//                    HStack {
//                        Spacer()
//                        Button { save() } label: {
//                            Text("Save")
//                                .font(.callout).fontWeight(.semibold)
//                                .foregroundStyle(.white)
//                                .padding(.horizontal, 22)
//                                .padding(.vertical, 10)
//                                .glassEffect(in: Capsule())
//                        }
//                    }
//                }
//                .padding(.horizontal, 20)
//                .padding(.top, 16)
//
//                // ── Subtitle ───────────────────────────────────────────
//                Text("Use a descriptive name for this session so you can easily find it in your history later.")
//                    .font(.callout)
//                    .foregroundStyle(.white.opacity(0.5))
//                    .padding(.horizontal, 20)
//                    .padding(.top, 20)
//
//                // ── Text editor ────────────────────────────────────────
//                // Fixed height so it looks correct with AND without keyboard.
//                // When the keyboard is up it slides over the bottom of the
//                // box without moving anything (.ignoresSafeArea(.all)).
//                ZStack(alignment: .topLeading) {
//                    RoundedRectangle(cornerRadius: 20)
//                        .fill(Color("SecondColor"))
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 20)
//                                .stroke(Color.white.opacity(0.45), lineWidth: 1)
//                        )
//
//                    if titleText.isEmpty {
//                        Text("e.g., \u{201C}Unpacking today\u{2019}s event\u{201D} or \u{201C}Breaking the creative block\u{201D}")
//                            .font(.callout)
//                            .foregroundStyle(.white.opacity(0.25))
//                            .padding(.horizontal, 16)
//                            .padding(.top, 16)
//                            .allowsHitTesting(false)
//                    }
//
//                    TextEditor(text: $titleText)
//                        .focused($editorFocused)
//                        .font(.body)
//                        .foregroundStyle(.white)
//                        .scrollContentBackground(.hidden)
//                        .background(.clear)
//                        .padding(.horizontal, 12)
//                        .padding(.vertical, 10)
//                        .tint(.white)
//                }
//                .frame(maxWidth: .infinity)
//                .frame(height: 260)
//                .padding(.horizontal, 20)
//                .padding(.top, 24)
//
//                Spacer()
//            }
//            .padding(.top, safeTop)
//            .padding(.bottom, safeBottom + 20)
//        }
//        .ignoresSafeArea(.all)
//        .onAppear {
//            readSafeArea()
//            titleText    = session.sessionName   // pre-fill if returning to this page
//            editorFocused = true                  // keyboard up immediately, like the mockup
//        }
//        .toolbar(.hidden, for: .navigationBar)
//        .navigationDestination(isPresented: $showStats) {
//            WalkStatsView(session: session)
//        }
//    }
//
//    // MARK: - Save
//
//    private func save() {
//        session.sessionName = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
//        try? modelContext.save()
//        showStats = true
//    }
//
//    // MARK: - Safe area
//
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
//    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
//    let container = try! ModelContainer(for: WalkSession.self, configurations: config)
//    let session   = WalkSession(moodBefore: 3)
//    container.mainContext.insert(session)
//    return NavigationStack { SessionTitleView(session: session) }
//        .modelContainer(container)
//}
