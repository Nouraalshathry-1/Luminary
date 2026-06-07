//
//  SessionDetailView.swift
//  LuminaryGammas
//
//  Created by Noura Alshathry on 02/06/2026.
//






import SwiftUI
import SwiftData

// MARK: - SessionDetailView  (Page 12)

struct SessionDetailView: View {
    @Environment(\.dismiss)       private var dismiss
    @Environment(\.modelContext)  private var modelContext

    let session: WalkSession

    @State private var safeTop:    CGFloat = 59
    @State private var safeBottom: CGFloat = 34

    // ── Edit mode ──────────────────────────────────────────────────────
    @State private var isEditing = false
    @State private var editedAnswers:        [String] = ["", "", ""]
    @State private var editedFreeReflection: String   = ""
    @State private var editedPreWalkNote:    String   = ""

    // ── Questions (same order as GuidedReflectionView) ─────────────────
    private let guidedQuestions: [String] = [
        "How are you feeling right now?",
        "What did the walk bring up that you hadn\u{2019}t noticed before?",
        "What\u{2019}s one thing you want to carry forward from this walk?"
    ]

    // ── Notes most-recent → oldest ────────────────────────────────────
    private var notesWithTimestamps: [(text: String, date: Date?)] {
        session.duringWalkNotes.enumerated().compactMap { index, note in
            guard !note.isEmpty else { return nil }
            let date: Date? = index < session.duringWalkNoteTimestamps.count
                ? session.duringWalkNoteTimestamps[index] : nil
            return (text: note, date: date)
        }.reversed()
    }

    private var notesCount: Int { notesWithTimestamps.count }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d · h:mm a"
        return f.string(from: session.date)
    }

    private var stepsFormatted: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        return fmt.string(from: NSNumber(value: session.steps)) ?? "\(session.steps)"
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Color("AccentColor").ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header ─────────────────────────────────────────────
                HStack(spacing: 14) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .glassEffect(in: Circle())
                    }

                    Text("History")
                        .font(.title).fontWeight(.bold)
                        .foregroundStyle(.white)

                    Spacer()

                    Button {
                        if isEditing { saveEdits() } else { isEditing = true }
                    } label: {
                        Text(isEditing ? "Save" : "Edit")
                            .font(.callout).fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .glassEffect(in: Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // ── Scrollable body ────────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // Session name + date
                        VStack(alignment: .leading, spacing: 6) {
                            Text(session.sessionName.isEmpty ? "Untitled walk" : session.sessionName)
                                .font(.title2).fontWeight(.bold)
                                .foregroundStyle(.white)

                            Text(formattedDate)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.50))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        // ── Stats banner ───────────────────────────────
                        Text("stats")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.45))
                            .padding(.horizontal, 24)
                            .padding(.top, 24)

                        HStack(spacing: 0) {
                            DetailStatColumn(emoji: "⏱️",
                                             value: "\(max(1, session.durationMinutes))",
                                             label: "Minutes")
                            Rectangle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 1, height: 44)
                            DetailStatColumn(emoji: "👟",
                                             value: stepsFormatted,
                                             label: "Steps")
                            Rectangle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 1, height: 44)
                            DetailStatColumn(emoji: "📝",
                                             value: "\(notesCount)",
                                             label: "Notes")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .background(Color("StatsBox"), in: RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                        // ── Mood before & after ────────────────────────
                        Text("How You feel before and after")
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.55))
                            .padding(.horizontal, 24)
                            .padding(.top, 28)

                        MoodComparisonCard(
                            moodBefore: session.moodBefore,
                            moodAfter:  session.moodAfter
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                        // ── Reflection ─────────────────────────────────
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Reflection")
                                .font(.title3).fontWeight(.bold)
                                .foregroundStyle(.white)
                            Text("Post-walk notes")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                        if session.reflectionType == "guided" {
                            ForEach(0..<3, id: \.self) { i in
                                ReflectionEntry(
                                    question:  guidedQuestions[i],
                                    answer:    answerBinding(for: i),
                                    isEditing: isEditing
                                )
                            }
                        } else {
                            ReflectionEntry(
                                question:  "Write freely",
                                answer:    $editedFreeReflection,
                                isEditing: isEditing
                            )
                        }

                        // ── During-walk notes ──────────────────────────
                        if !notesWithTimestamps.isEmpty {

                            Text("During walk notes")
                                .font(.callout).fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.55))
                                .padding(.horizontal, 24)
                                .padding(.top, 28)

                            Rectangle()
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 1)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)

                            ForEach(
                                Array(notesWithTimestamps.enumerated()),
                                id: \.offset
                            ) { index, entry in
                                DetailNoteRow(text: entry.text, date: entry.date)
                                if index < notesWithTimestamps.count - 1 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.08))
                                        .frame(height: 1)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }

                        // ── Pre-walk note ──────────────────────────────
                        Text("pre-walk notes")
                            .font(.callout).fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.55))
                            .padding(.horizontal, 24)
                            .padding(.top, 28)

                        Text("How do you feel?")
                            .font(.callout).fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        EditableBox(
                            text:      $editedPreWalkNote,
                            isEmpty:   editedPreWalkNote.isEmpty,
                            isEditing: isEditing
                        )
                        .padding(.top, 14)

                        Spacer().frame(height: 56)
                    }
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .padding(.top, safeTop)
        }
        .ignoresSafeArea(.all)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            readSafeArea()
            loadEditable()
        }
    }

    // MARK: - Helpers

    /// Safe binding into editedAnswers without index-out-of-range.
    private func answerBinding(for i: Int) -> Binding<String> {
        Binding(
            get: { i < editedAnswers.count ? editedAnswers[i] : "" },
            set: { newVal in
                while editedAnswers.count <= i { editedAnswers.append("") }
                editedAnswers[i] = newVal
            }
        )
    }

    private func loadEditable() {
        editedAnswers        = session.guidedAnswers.count >= 3
                                    ? session.guidedAnswers
                                    : Array(session.guidedAnswers) + Array(repeating: "", count: 3 - session.guidedAnswers.count)
        editedFreeReflection = session.freeReflection
        editedPreWalkNote    = session.preWalkNote
    }

    private func saveEdits() {
        session.guidedAnswers   = editedAnswers
        session.freeReflection  = editedFreeReflection
        session.preWalkNote     = editedPreWalkNote
        try? modelContext.save()
        isEditing = false
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

// MARK: - MoodComparisonCard

private struct MoodComparisonCard: View {
    let moodBefore: Int
    let moodAfter:  Int

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {

            // Before
            VStack(spacing: 10) {
                CandleComponent()
                    .flameScale(CandleComponent.flameScale(for: moodBefore))
                    .flickering(false)

                Text(CandleComponent.label(for: moodBefore))
                    .font(.caption).fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity)

            // Arrow centred on the candle body
            Image(systemName: "arrow.right")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.bottom, 34)

            // After
            VStack(spacing: 10) {
                CandleComponent()
                    .flameScale(CandleComponent.flameScale(for: moodAfter))
                    .flickering(false)

                Text(CandleComponent.label(for: moodAfter))
                    .font(.caption).fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .background(Color("StatsBox"), in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - DetailStatColumn

private struct DetailStatColumn: View {
    let emoji: String
    let value: String
    let label: String

    @ScaledMetric private var valueFontSize: CGFloat = 30

    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: valueFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            HStack(spacing: 4) {
                Text(emoji).font(.system(size: 12))
                Text(label)
                    .font(.caption).fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ReflectionEntry

private struct ReflectionEntry: View {
    let question:  String
    @Binding var answer: String
    let isEditing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.callout).fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)

            EditableBox(text: $answer, isEmpty: answer.isEmpty, isEditing: isEditing)
        }
        .padding(.top, 32)
    }
}

// MARK: - EditableBox  (read-only or editable · 260 pt tall)

private struct EditableBox: View {
    @Binding var text: String
    let isEmpty:   Bool
    let isEditing: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("SecondColor"))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            Color.white.opacity(isEditing ? 0.70 : 0.45),
                            lineWidth: isEditing ? 1.5 : 1
                        )
                )

            if isEditing {
                TextEditor(text: $text)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .tint(.white)
            } else {
                Text(text.isEmpty ? "—" : text)
                    .font(.body)
                    .foregroundStyle(isEmpty ? .white.opacity(0.30) : .white.opacity(0.85))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 260)
        .padding(.horizontal, 20)
    }
}

// MARK: - DetailNoteRow

private struct DetailNoteRow: View {
    let text: String
    let date: Date?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(Color.white.opacity(0.45))
                .frame(width: 7, height: 7)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.80))
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
                    .foregroundStyle(.white.opacity(0.40))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - Preview

private struct SessionDetailPreview: View {
    private let container: ModelContainer
    private let session:   WalkSession

    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: WalkSession.self, configurations: config)
        let s = WalkSession(
            sessionName: "Thought about work",
            durationMinutes: 45,
            steps: 4_231,
            moodBefore: 2,
            moodAfter: 5,
            preWalkNote: "Feeling tense about the project meeting.",
            duringWalkNotes: [
                "my manager name is Arwa and I need to tell her about the new plans",
                "remembered to breathe deeply on the hill"
            ],
            reflectionType: "guided",
            guidedAnswers: [
                "I'm feeling much calmer after the walk.",
                "I noticed how tense my shoulders were — I hadn't realized until I started moving.",
                "I want to carry the calm breathing I found today."
            ]
        )
        s.duringWalkNoteTimestamps = [
            Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
            Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
        ]
        c.mainContext.insert(s)
        container = c
        session   = s
    }

    var body: some View {
        NavigationStack { SessionDetailView(session: session) }
            .modelContainer(container)
    }
}

#Preview { SessionDetailPreview() }





//import SwiftUI
//import SwiftData
//
//// MARK: - SessionDetailView  (Page 12)
//
//struct SessionDetailView: View {
//    @Environment(\.dismiss)       private var dismiss
//    @Environment(\.modelContext)  private var modelContext
//
//    let session: WalkSession
//
//    @State private var safeTop:    CGFloat = 59
//    @State private var safeBottom: CGFloat = 34
//
//    // ── Edit mode ──────────────────────────────────────────────────────
//    @State private var isEditing = false
//    @State private var editedAnswers:        [String] = ["", "", ""]
//    @State private var editedFreeReflection: String   = ""
//    @State private var editedPreWalkNote:    String   = ""
//
//    // ── Questions (same order as GuidedReflectionView) ─────────────────
//    private let guidedQuestions: [String] = [
//        "How are you feeling right now?",
//        "What did the walk bring up that you hadn\u{2019}t noticed before?",
//        "What\u{2019}s one thing you want to carry forward from this walk?"
//    ]
//
//    // ── Notes most-recent → oldest ────────────────────────────────────
//    private var notesWithTimestamps: [(text: String, date: Date?)] {
//        session.duringWalkNotes.enumerated().compactMap { index, note in
//            guard !note.isEmpty else { return nil }
//            let date: Date? = index < session.duringWalkNoteTimestamps.count
//                ? session.duringWalkNoteTimestamps[index] : nil
//            return (text: note, date: date)
//        }.reversed()
//    }
//
//    private var notesCount: Int { notesWithTimestamps.count }
//
//    private var formattedDate: String {
//        let f = DateFormatter()
//        f.dateFormat = "EEE MMM d · h:mm a"
//        return f.string(from: session.date)
//    }
//
//    private var stepsFormatted: String {
//        let fmt = NumberFormatter()
//        fmt.numberStyle = .decimal
//        return fmt.string(from: NSNumber(value: session.steps)) ?? "\(session.steps)"
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
//                HStack(spacing: 14) {
//                    Button { dismiss() } label: {
//                        Image(systemName: "chevron.left")
//                            .font(.system(size: 16, weight: .semibold))
//                            .foregroundStyle(.white)
//                            .frame(width: 44, height: 44)
//                            .glassEffect(in: Circle())
//                    }
//
//                    Text("History")
//                        .font(.title).fontWeight(.bold)
//                        .foregroundStyle(.white)
//
//                    Spacer()
//
//                    Button {
//                        if isEditing { saveEdits() } else { isEditing = true }
//                    } label: {
//                        Text(isEditing ? "Save" : "Edit")
//                            .font(.callout).fontWeight(.semibold)
//                            .foregroundStyle(.white)
//                            .padding(.horizontal, 18)
//                            .padding(.vertical, 9)
//                            .glassEffect(in: Capsule())
//                    }
//                }
//                .padding(.horizontal, 20)
//                .padding(.top, 12)
//
//                // ── Scrollable body ────────────────────────────────────
//                ScrollView(showsIndicators: false) {
//                    VStack(alignment: .leading, spacing: 0) {
//
//                        // Session name + date
//                        VStack(alignment: .leading, spacing: 6) {
//                            Text(session.sessionName.isEmpty ? "Untitled walk" : session.sessionName)
//                                .font(.title2).fontWeight(.bold)
//                                .foregroundStyle(.white)
//
//                            Text(formattedDate)
//                                .font(.subheadline)
//                                .foregroundStyle(.white.opacity(0.50))
//                        }
//                        .padding(.horizontal, 24)
//                        .padding(.top, 24)
//
//                        // ── Stats banner ───────────────────────────────
//                        Text("stats")
//                            .font(.subheadline).fontWeight(.medium)
//                            .foregroundStyle(.white.opacity(0.45))
//                            .padding(.horizontal, 24)
//                            .padding(.top, 24)
//
//                        HStack(spacing: 0) {
//                            DetailStatColumn(emoji: "⏱️",
//                                             value: "\(max(1, session.durationMinutes))",
//                                             label: "Minutes")
//                            Rectangle()
//                                .fill(Color.white.opacity(0.15))
//                                .frame(width: 1, height: 44)
//                            DetailStatColumn(emoji: "👟",
//                                             value: stepsFormatted,
//                                             label: "Steps")
//                            Rectangle()
//                                .fill(Color.white.opacity(0.15))
//                                .frame(width: 1, height: 44)
//                            DetailStatColumn(emoji: "📝",
//                                             value: "\(notesCount)",
//                                             label: "Notes")
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 22)
//                        .background(Color("StatsBox"), in: RoundedRectangle(cornerRadius: 20))
//                        .padding(.horizontal, 20)
//                        .padding(.top, 14)
//
//                        // ── Mood before & after ────────────────────────
//                        Text("How You feel before and after")
//                            .font(.callout)
//                            .foregroundStyle(.white.opacity(0.55))
//                            .padding(.horizontal, 24)
//                            .padding(.top, 28)
//
//                        MoodComparisonCard(
//                            moodBefore: session.moodBefore,
//                            moodAfter:  session.moodAfter
//                        )
//                        .padding(.horizontal, 20)
//                        .padding(.top, 14)
//
//                        // ── Reflection ─────────────────────────────────
//                        VStack(alignment: .leading, spacing: 5) {
//                            Text("Reflection")
//                                .font(.title3).fontWeight(.bold)
//                                .foregroundStyle(.white)
//                            Text("Post-walk notes")
//                                .font(.footnote)
//                                .foregroundStyle(.white.opacity(0.45))
//                        }
//                        .padding(.horizontal, 24)
//                        .padding(.top, 28)
//
//                        if session.reflectionType == "guided" {
//                            ForEach(0..<3, id: \.self) { i in
//                                ReflectionEntry(
//                                    question:  guidedQuestions[i],
//                                    answer:    answerBinding(for: i),
//                                    isEditing: isEditing
//                                )
//                            }
//                        } else {
//                            ReflectionEntry(
//                                question:  "Write freely",
//                                answer:    $editedFreeReflection,
//                                isEditing: isEditing
//                            )
//                        }
//
//                        // ── During-walk notes ──────────────────────────
//                        if !notesWithTimestamps.isEmpty {
//
//                            Text("During walk notes")
//                                .font(.callout).fontWeight(.semibold)
//                                .foregroundStyle(.white.opacity(0.55))
//                                .padding(.horizontal, 24)
//                                .padding(.top, 28)
//
//                            Rectangle()
//                                .fill(Color.white.opacity(0.12))
//                                .frame(height: 1)
//                                .padding(.horizontal, 20)
//                                .padding(.top, 10)
//
//                            ForEach(
//                                Array(notesWithTimestamps.enumerated()),
//                                id: \.offset
//                            ) { index, entry in
//                                DetailNoteRow(text: entry.text, date: entry.date)
//                                if index < notesWithTimestamps.count - 1 {
//                                    Rectangle()
//                                        .fill(Color.white.opacity(0.08))
//                                        .frame(height: 1)
//                                        .padding(.horizontal, 20)
//                                }
//                            }
//                        }
//
//                        // ── Pre-walk note ──────────────────────────────
//                        Text("pre-walk notes")
//                            .font(.callout).fontWeight(.semibold)
//                            .foregroundStyle(.white.opacity(0.55))
//                            .padding(.horizontal, 24)
//                            .padding(.top, 28)
//
//                        Text("How do you feel?")
//                            .font(.callout).fontWeight(.semibold)
//                            .foregroundStyle(.white)
//                            .padding(.horizontal, 24)
//                            .padding(.top, 16)
//
//                        EditableBox(
//                            text:      $editedPreWalkNote,
//                            isEmpty:   editedPreWalkNote.isEmpty,
//                            isEditing: isEditing
//                        )
//                        .padding(.top, 14)
//
//                        Spacer().frame(height: 56)
//                    }
//                }
//                .scrollDismissesKeyboard(.immediately)
//            }
//            .padding(.top, safeTop)
//        }
//        .ignoresSafeArea(.all)
//        .toolbar(.hidden, for: .navigationBar)
//        .onAppear {
//            readSafeArea()
//            loadEditable()
//        }
//    }
//
//    // MARK: - Helpers
//
//    /// Safe binding into editedAnswers without index-out-of-range.
//    private func answerBinding(for i: Int) -> Binding<String> {
//        Binding(
//            get: { i < editedAnswers.count ? editedAnswers[i] : "" },
//            set: { newVal in
//                while editedAnswers.count <= i { editedAnswers.append("") }
//                editedAnswers[i] = newVal
//            }
//        )
//    }
//
//    private func loadEditable() {
//        editedAnswers        = session.guidedAnswers.count >= 3
//                                    ? session.guidedAnswers
//                                    : Array(session.guidedAnswers) + Array(repeating: "", count: 3 - session.guidedAnswers.count)
//        editedFreeReflection = session.freeReflection
//        editedPreWalkNote    = session.preWalkNote
//    }
//
//    private func saveEdits() {
//        session.guidedAnswers   = editedAnswers
//        session.freeReflection  = editedFreeReflection
//        session.preWalkNote     = editedPreWalkNote
//        try? modelContext.save()
//        isEditing = false
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
//// MARK: - MoodComparisonCard
//
//private struct MoodComparisonCard: View {
//    let moodBefore: Int
//    let moodAfter:  Int
//
//    var body: some View {
//        HStack(alignment: .bottom, spacing: 0) {
//
//            // Before
//            VStack(spacing: 10) {
//                CandleComponent()
//                    .flameScale(CandleComponent.flameScale(for: moodBefore))
//                    .flickering(false)
//
//                Text(CandleComponent.label(for: moodBefore))
//                    .font(.caption).fontWeight(.medium)
//                    .foregroundStyle(.white.opacity(0.65))
//            }
//            .frame(maxWidth: .infinity)
//
//            // Arrow centred on the candle body
//            Image(systemName: "arrow.right")
//                .font(.system(size: 18, weight: .regular))
//                .foregroundStyle(.white.opacity(0.55))
//                .padding(.bottom, 34)
//
//            // After
//            VStack(spacing: 10) {
//                CandleComponent()
//                    .flameScale(CandleComponent.flameScale(for: moodAfter))
//                    .flickering(false)
//
//                Text(CandleComponent.label(for: moodAfter))
//                    .font(.caption).fontWeight(.medium)
//                    .foregroundStyle(.white.opacity(0.65))
//            }
//            .frame(maxWidth: .infinity)
//        }
//        .padding(.horizontal, 24)
//        .padding(.vertical, 24)
//        .background(Color("StatsBox"), in: RoundedRectangle(cornerRadius: 20))
//    }
//}
//
//// MARK: - DetailStatColumn
//
//private struct DetailStatColumn: View {
//    let emoji: String
//    let value: String
//    let label: String
//
//    var body: some View {
//        VStack(spacing: 5) {
//            Text(value)
//                .font(.system(size: 30, weight: .bold, design: .rounded))
//                .foregroundStyle(.white)
//                .monospacedDigit()
//                .minimumScaleFactor(0.7)
//                .lineLimit(1)
//
//            HStack(spacing: 4) {
//                Text(emoji).font(.system(size: 12))
//                Text(label)
//                    .font(.caption).fontWeight(.medium)
//                    .foregroundStyle(.white.opacity(0.55))
//            }
//        }
//        .frame(maxWidth: .infinity)
//    }
//}
//
//// MARK: - ReflectionEntry
//
//private struct ReflectionEntry: View {
//    let question:  String
//    @Binding var answer: String
//    let isEditing: Bool
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text(question)
//                .font(.callout).fontWeight(.semibold)
//                .foregroundStyle(.white)
//                .padding(.horizontal, 24)
//
//            EditableBox(text: $answer, isEmpty: answer.isEmpty, isEditing: isEditing)
//        }
//        .padding(.top, 32)
//    }
//}
//
//// MARK: - EditableBox  (read-only or editable · 260 pt tall)
//
//private struct EditableBox: View {
//    @Binding var text: String
//    let isEmpty:   Bool
//    let isEditing: Bool
//
//    var body: some View {
//        ZStack(alignment: .topLeading) {
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color("SecondColor"))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 20)
//                        .stroke(
//                            Color.white.opacity(isEditing ? 0.70 : 0.45),
//                            lineWidth: isEditing ? 1.5 : 1
//                        )
//                )
//
//            if isEditing {
//                TextEditor(text: $text)
//                    .font(.body)
//                    .foregroundStyle(.white.opacity(0.85))
//                    .scrollContentBackground(.hidden)
//                    .background(.clear)
//                    .padding(.horizontal, 12)
//                    .padding(.vertical, 10)
//                    .tint(.white)
//            } else {
//                Text(text.isEmpty ? "—" : text)
//                    .font(.body)
//                    .foregroundStyle(isEmpty ? .white.opacity(0.30) : .white.opacity(0.85))
//                    .padding(.horizontal, 16)
//                    .padding(.vertical, 14)
//            }
//        }
//        .frame(maxWidth: .infinity)
//        .frame(height: 260)
//        .padding(.horizontal, 20)
//    }
//}
//
//// MARK: - DetailNoteRow
//
//private struct DetailNoteRow: View {
//    let text: String
//    let date: Date?
//
//    var body: some View {
//        HStack(alignment: .top, spacing: 14) {
//            Circle()
//                .fill(Color.white.opacity(0.45))
//                .frame(width: 7, height: 7)
//                .padding(.top, 6)
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text(text)
//                    .font(.callout)
//                    .foregroundStyle(.white.opacity(0.80))
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
//                    .foregroundStyle(.white.opacity(0.40))
//                }
//            }
//            Spacer()
//        }
//        .padding(.horizontal, 20)
//        .padding(.vertical, 14)
//    }
//}
//
//// MARK: - Preview
//
//private struct SessionDetailPreview: View {
//    private let container: ModelContainer
//    private let session:   WalkSession
//
//    init() {
//        let config = ModelConfiguration(isStoredInMemoryOnly: true)
//        let c = try! ModelContainer(for: WalkSession.self, configurations: config)
//        let s = WalkSession(
//            sessionName: "Thought about work",
//            durationMinutes: 45,
//            steps: 4_231,
//            moodBefore: 2,
//            moodAfter: 5,
//            preWalkNote: "Feeling tense about the project meeting.",
//            duringWalkNotes: [
//                "my manager name is Arwa and I need to tell her about the new plans",
//                "remembered to breathe deeply on the hill"
//            ],
//            reflectionType: "guided",
//            guidedAnswers: [
//                "I'm feeling much calmer after the walk.",
//                "I noticed how tense my shoulders were — I hadn't realized until I started moving.",
//                "I want to carry the calm breathing I found today."
//            ]
//        )
//        s.duringWalkNoteTimestamps = [
//            Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
//            Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
//        ]
//        c.mainContext.insert(s)
//        container = c
//        session   = s
//    }
//
//    var body: some View {
//        NavigationStack { SessionDetailView(session: session) }
//            .modelContainer(container)
//    }
//}
//
//#Preview { SessionDetailPreview() }
//





