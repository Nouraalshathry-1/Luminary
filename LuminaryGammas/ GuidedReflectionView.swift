//
//   GuidedReflectionView.swift
//  LuminaryGammas
//
//  Created by Noura Alshathry on 02/06/2026.
//

import SwiftUI
import SwiftData

// MARK: - GuidedReflectionView  (Pages 8 / 9 / 10 — question 0, 1, 2)

struct GuidedReflectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @EnvironmentObject           private var nav: HomeViewModel

    let session:       WalkSession
    let questionIndex: Int          // 0 · 1 · 2

    // ── Questions ──────────────────────────────────────────────────────
    private let questions: [String] = [
        "How are you feeling right now?",
        "What did the walk bring up that you hadn\u{2019}t noticed before?",
        "What\u{2019}s one thing you want to carry forward from this walk?"
    ]

    private let placeholders: [String] = [
        "Right now, I feel... or Checking in with myself...",
        "I noticed that... or A thought that came to mind...",
        "I want to remember to... or Taking this with me..."
    ]

    @State private var answerText   = ""
    @FocusState private var editorFocused: Bool
    @State private var showNext     = false

    @State private var safeTop:    CGFloat = 59
    @State private var safeBottom: CGFloat = 34

    private var isLastQuestion: Bool { questionIndex == 2 }

    // Notes: oldest → newest, with captured timestamp when available
    private var notesWithTimestamps: [(text: String, date: Date?)] {
        session.duringWalkNotes.enumerated().compactMap { index, note in
            guard !note.isEmpty else { return nil }
            let date: Date? = index < session.duringWalkNoteTimestamps.count
                ? session.duringWalkNoteTimestamps[index] : nil
            return (text: note, date: date)
        }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Color("AccentColor").ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header ─────────────────────────────────────────────
                Text("Reflection")
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // ── 3-segment progress bar ─────────────────────────────
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(Color.white.opacity(i <= questionIndex ? 1.0 : 0.30))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                // ── Scrollable body ────────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // Question prompt
                        Text(questions[questionIndex])
                            .font(.callout).fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)

                        // ── Answer text editor ─────────────────────────
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color("SecondColor"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                                )

                            if answerText.isEmpty {
                                Text(placeholders[questionIndex])
                                    .font(.body)
                                    .foregroundStyle(.white.opacity(0.25))
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                    .allowsHitTesting(false)
                            }

                            TextEditor(text: $answerText)
                                .focused($editorFocused)
                                .font(.body)
                                .foregroundStyle(.white)
                                .scrollContentBackground(.hidden)
                                .background(.clear)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .tint(.white)
                        }
                        .frame(height: 260)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        // ── Notes section ──────────────────────────────
                        if !notesWithTimestamps.isEmpty {

                            Text("Notes taken during your walk")
                                .font(.callout).fontWeight(.semibold)
                                .foregroundStyle(Color("ReflectionTextColor"))
                                .padding(.horizontal, 20)
                                .padding(.top, 36)

                            Rectangle()
                                .fill(Color("ReflectionTextColor").opacity(0.25))
                                .frame(height: 1)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)

                            ForEach(
                                Array(notesWithTimestamps.enumerated()),
                                id: \.offset
                            ) { index, entry in

                                GuidedNoteRow(text: entry.text, date: entry.date)

                                if index < notesWithTimestamps.count - 1 {
                                    Rectangle()
                                        .fill(Color("ReflectionTextColor").opacity(0.15))
                                        .frame(height: 1)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }

                        Spacer().frame(height: 24)
                    }
                }
                .scrollDismissesKeyboard(.immediately)

                // ── Back + Next/Save buttons ───────────────────────────
                // HIG: secondary action (Back) uses ghost/outline style;
                // primary action (Next/Save) uses a solid filled style.
                HStack(spacing: 12) {

                    // Back — liquid glass, secondary weight
                    if questionIndex > 0 {
                        Button { dismiss() } label: {
                            Text("Back")
                                .font(.headline).fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.75))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 17)
                        }
                        .glassEffect(in: Capsule())
                    }

                    // Next / Save — solid white capsule, primary (matches Continue / Save app-wide)
                    Button {
                        saveAnswer()
                        if isLastQuestion {
                            nav.showWalkSetup = false
                        } else {
                            showNext = true
                        }
                    } label: {
                        Text(isLastQuestion ? "Save" : "Next")
                            .font(.headline).fontWeight(.semibold)
                            .foregroundStyle(Color("AccentColor"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(Capsule().fill(Color.white.opacity(0.85)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, safeBottom + 16)
            }
            .padding(.top, safeTop)
        }
        .ignoresSafeArea(.all)
        .simultaneousGesture(TapGesture().onEnded { editorFocused = false })
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showNext) {
            GuidedReflectionView(session: session, questionIndex: questionIndex + 1)
        }
        .onAppear {
            readSafeArea()
            // Pre-fill saved answer if the user returns to this question
            let answers = session.guidedAnswers
            answerText = questionIndex < answers.count ? answers[questionIndex] : ""
        }
        .onDisappear {
            // Auto-save so nothing is lost regardless of navigation path
            saveAnswer()
        }
    }

    // MARK: - Helpers

    private func saveAnswer() {
        // Each question writes ONLY to its own index.
        // guidedAnswers[0] = Q1, [1] = Q2, [2] = Q3.
        // Other slots are never touched, so all three answers
        // survive independently and are available in History.
        var answers = session.guidedAnswers
        while answers.count <= questionIndex { answers.append("") }   // safety net
        answers[questionIndex] = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        session.guidedAnswers  = answers   // replace whole array → triggers SwiftData tracking
        try? modelContext.save()
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

// MARK: - GuidedNoteRow

private struct GuidedNoteRow: View {
    let text: String
    let date: Date?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {

            Circle()
                .fill(Color("ReflectionTextColor").opacity(0.55))
                .frame(width: 7, height: 7)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 5) {
                Text(text)
                    .font(.callout)
                    .foregroundStyle(Color("ReflectionTextColor"))
                    .fixedSize(horizontal: false, vertical: true)

                if let date {
                    Text(
                        date.formatted(
                            .dateTime
                                .hour(.defaultDigits(amPM: .abbreviated))
                                .minute(.twoDigits)
                        )
                    )
                    .font(.footnote)
                    .foregroundStyle(Color("ReflectionTextColor").opacity(0.50))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - Preview

private struct GuidedReflectionPreview: View {
    private let container: ModelContainer
    private let session:   WalkSession
    private let vm = HomeViewModel()

    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: WalkSession.self, configurations: config)
        let s = WalkSession(moodBefore: 3)
        c.mainContext.insert(s)
        container = c
        session   = s
    }

    var body: some View {
        NavigationStack {
            GuidedReflectionView(session: session, questionIndex: 0)
        }
        .environmentObject(vm)
        .modelContainer(container)
    }
}

#Preview { GuidedReflectionPreview() }


//import SwiftUI
//import SwiftData
//
//// MARK: - GuidedReflectionView  (Pages 8 / 9 / 10 — question 0, 1, 2)
//
//struct GuidedReflectionView: View {
//    @Environment(\.modelContext) private var modelContext
//    @Environment(\.dismiss)      private var dismiss
//    @EnvironmentObject           private var nav: HomeViewModel
//
//    let session:       WalkSession
//    let questionIndex: Int          // 0 · 1 · 2
//
//    // ── Questions ──────────────────────────────────────────────────────
//    private let questions: [String] = [
//        "How are you feeling right now?",
//        "What did the walk bring up that you hadn\u{2019}t noticed before?",
//        "What\u{2019}s one thing you want to carry forward from this walk?"
//    ]
//
//    @State private var answerText   = ""
//    @FocusState private var editorFocused: Bool
//    @State private var showNext     = false
//
//    @State private var safeTop:    CGFloat = 59
//    @State private var safeBottom: CGFloat = 34
//
//    private var isLastQuestion: Bool { questionIndex == 2 }
//
//    // Notes: oldest → newest, with captured timestamp when available
//    private var notesWithTimestamps: [(text: String, date: Date?)] {
//        session.duringWalkNotes.enumerated().compactMap { index, note in
//            guard !note.isEmpty else { return nil }
//            let date: Date? = index < session.duringWalkNoteTimestamps.count
//                ? session.duringWalkNoteTimestamps[index] : nil
//            return (text: note, date: date)
//        }
//    }
//
//    // MARK: Body
//
//    var body: some View {
//        ZStack {
//            Color("AccentColor").ignoresSafeArea()
//
//            VStack(spacing: 0) {
//
//                // ── Header ─────────────────────────────────────────────
//                Text("Reflection")
//                    .font(.title2).fontWeight(.bold)
//                    .foregroundStyle(.white)
//                    .frame(maxWidth: .infinity, alignment: .center)
//                    .padding(.horizontal, 20)
//                    .padding(.top, 16)
//
//                // ── 3-segment progress bar ─────────────────────────────
//                HStack(spacing: 8) {
//                    ForEach(0..<3, id: \.self) { i in
//                        Capsule()
//                            .fill(Color.white.opacity(i <= questionIndex ? 1.0 : 0.30))
//                            .frame(height: 4)
//                    }
//                }
//                .padding(.horizontal, 20)
//                .padding(.top, 14)
//
//                // ── Scrollable body ────────────────────────────────────
//                ScrollView(showsIndicators: false) {
//                    VStack(alignment: .leading, spacing: 0) {
//
//                        // Question prompt
//                        Text(questions[questionIndex])
//                            .font(.callout).fontWeight(.semibold)
//                            .foregroundStyle(.white)
//                            .padding(.horizontal, 20)
//                            .padding(.top, 24)
//
//                        // ── Answer text editor ─────────────────────────
//                        ZStack(alignment: .topLeading) {
//                            RoundedRectangle(cornerRadius: 16)
//                                .fill(Color("SecondColor"))
//
//                            TextEditor(text: $answerText)
//                                .focused($editorFocused)
//                                .font(.body)
//                                .foregroundStyle(.white)
//                                .scrollContentBackground(.hidden)
//                                .background(.clear)
//                                .padding(.horizontal, 12)
//                                .padding(.vertical, 10)
//                                .tint(.white)
//                        }
//                        .frame(height: 260)
//                        .padding(.horizontal, 20)
//                        .padding(.top, 12)
//
//                        // ── Notes section ──────────────────────────────
//                        if !notesWithTimestamps.isEmpty {
//
//                            Text("Notes taken during your walk")
//                                .font(.callout).fontWeight(.semibold)
//                                .foregroundStyle(Color("ReflectionTextColor"))
//                                .padding(.horizontal, 20)
//                                .padding(.top, 36)
//
//                            Rectangle()
//                                .fill(Color("ReflectionTextColor").opacity(0.25))
//                                .frame(height: 1)
//                                .padding(.horizontal, 20)
//                                .padding(.top, 8)
//
//                            ForEach(
//                                Array(notesWithTimestamps.enumerated()),
//                                id: \.offset
//                            ) { index, entry in
//
//                                GuidedNoteRow(text: entry.text, date: entry.date)
//
//                                if index < notesWithTimestamps.count - 1 {
//                                    Rectangle()
//                                        .fill(Color("ReflectionTextColor").opacity(0.15))
//                                        .frame(height: 1)
//                                        .padding(.horizontal, 20)
//                                }
//                            }
//                        }
//
//                        Spacer().frame(height: 24)
//                    }
//                }
//                .scrollDismissesKeyboard(.immediately)
//
//                // ── Back + Next/Save buttons ───────────────────────────
//                // HIG: secondary action (Back) uses ghost/outline style;
//                // primary action (Next/Save) uses a solid filled style.
//                HStack(spacing: 12) {
//
//                    // Back — liquid glass, secondary weight
//                    if questionIndex > 0 {
//                        Button { dismiss() } label: {
//                            Text("Back")
//                                .font(.headline).fontWeight(.medium)
//                                .foregroundStyle(.white.opacity(0.75))
//                                .frame(maxWidth: .infinity)
//                                .padding(.vertical, 17)
//                        }
//                        .glassEffect(in: Capsule())
//                    }
//
//                    // Next / Save — solid white capsule, primary (matches Continue / Save app-wide)
//                    Button {
//                        saveAnswer()
//                        if isLastQuestion {
//                            nav.showWalkSetup = false
//                        } else {
//                            showNext = true
//                        }
//                    } label: {
//                        Text(isLastQuestion ? "Save" : "Next")
//                            .font(.headline).fontWeight(.semibold)
//                            .foregroundStyle(Color("AccentColor"))
//                            .frame(maxWidth: .infinity)
//                            .padding(.vertical, 17)
//                            .background(Capsule().fill(Color.white.opacity(0.85)))
//                    }
//                }
//                .padding(.horizontal, 24)
//                .padding(.top, 12)
//                .padding(.bottom, safeBottom + 16)
//            }
//            .padding(.top, safeTop)
//        }
//        .ignoresSafeArea(.all)
//        .simultaneousGesture(TapGesture().onEnded { editorFocused = false })
//        .toolbar(.hidden, for: .navigationBar)
//        .navigationDestination(isPresented: $showNext) {
//            GuidedReflectionView(session: session, questionIndex: questionIndex + 1)
//        }
//        .onAppear {
//            readSafeArea()
//            // Pre-fill saved answer if the user returns to this question
//            let answers = session.guidedAnswers
//            answerText = questionIndex < answers.count ? answers[questionIndex] : ""
//        }
//        .onDisappear {
//            // Auto-save so nothing is lost regardless of navigation path
//            saveAnswer()
//        }
//    }
//
//    // MARK: - Helpers
//
//    private func saveAnswer() {
//        // Each question writes ONLY to its own index.
//        // guidedAnswers[0] = Q1, [1] = Q2, [2] = Q3.
//        // Other slots are never touched, so all three answers
//        // survive independently and are available in History.
//        var answers = session.guidedAnswers
//        while answers.count <= questionIndex { answers.append("") }   // safety net
//        answers[questionIndex] = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
//        session.guidedAnswers  = answers   // replace whole array → triggers SwiftData tracking
//        try? modelContext.save()
//    }
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
//// MARK: - GuidedNoteRow
//
//private struct GuidedNoteRow: View {
//    let text: String
//    let date: Date?
//
//    var body: some View {
//        HStack(alignment: .top, spacing: 14) {
//
//            Circle()
//                .fill(Color("ReflectionTextColor").opacity(0.55))
//                .frame(width: 7, height: 7)
//                .padding(.top, 6)
//
//            VStack(alignment: .leading, spacing: 5) {
//                Text(text)
//                    .font(.callout)
//                    .foregroundStyle(Color("ReflectionTextColor"))
//                    .fixedSize(horizontal: false, vertical: true)
//
//                if let date {
//                    Text(
//                        date.formatted(
//                            .dateTime
//                                .hour(.defaultDigits(amPM: .abbreviated))
//                                .minute(.twoDigits)
//                        )
//                    )
//                    .font(.footnote)
//                    .foregroundStyle(Color("ReflectionTextColor").opacity(0.50))
//                }
//            }
//
//            Spacer()
//        }
//        .padding(.horizontal, 20)
//        .padding(.vertical, 14)
//    }
//}
//
//// MARK: - Preview
//
//private struct GuidedReflectionPreview: View {
//    private let container: ModelContainer
//    private let session:   WalkSession
//    private let vm = HomeViewModel()
//
//    init() {
//        let config = ModelConfiguration(isStoredInMemoryOnly: true)
//        let c = try! ModelContainer(for: WalkSession.self, configurations: config)
//        let s = WalkSession(moodBefore: 3)
//        c.mainContext.insert(s)
//        container = c
//        session   = s
//    }
//
//    var body: some View {
//        NavigationStack {
//            GuidedReflectionView(session: session, questionIndex: 0)
//        }
//        .environmentObject(vm)
//        .modelContainer(container)
//    }
//}
//
//#Preview { GuidedReflectionPreview() }
