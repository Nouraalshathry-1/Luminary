//
//   FreeReflectionView.swift
//  LuminaryGammas
//
//  Created by Noura Alshathry on 02/06/2026.
//

import SwiftUI
import SwiftData

// MARK: - FreeReflectionView  (Page 7a)

struct FreeReflectionView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject           private var nav: HomeViewModel

    let session: WalkSession

    @State private var reflectionText = ""
    @FocusState private var editorFocused: Bool

    @State private var safeTop:    CGFloat = 59
    @State private var safeBottom: CGFloat = 34

    // Oldest → newest, preserving per-note timestamps
    private var notesWithTimestamps: [(text: String, date: Date?)] {
        session.duringWalkNotes.enumerated().compactMap { index, note in
            guard !note.isEmpty else { return nil }
            let date: Date? = index < session.duringWalkNoteTimestamps.count
                ? session.duringWalkNoteTimestamps[index]
                : nil
            return (text: note, date: date)
        }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Color("AccentColor")
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header: centred title, no back button ─────────────
                Text("Reflection")
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // ── Scrollable body ────────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // "Write freely" heading
                        Text("Write freely")
                            .font(.title3).fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)

                        // ── Text editor ────────────────────────────────
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("SecondColor"))

                            if reflectionText.isEmpty {
                                Text("write anything that comes to mind")
                                    .font(.body)
                                    .foregroundStyle(.white.opacity(0.25))
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                    .allowsHitTesting(false)
                            }

                            TextEditor(text: $reflectionText)
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
                        .padding(.top, 14)

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

                                NoteRow(text: entry.text, date: entry.date)

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

                // ── Save button — pinned outside scroll ────────────────
                Button { saveReflection() } label: {
                    Text("Save")
                        .font(.title3).fontWeight(.semibold)
                        .foregroundStyle(Color("AccentColor"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Capsule().fill(Color.white.opacity(0.85)))
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, safeBottom + 16)
            }
            .padding(.top, safeTop)
        }
        .ignoresSafeArea(.all)
        // Tap anywhere outside the editor → dismiss keyboard
        // simultaneousGesture lets buttons & TextEditor still receive their own taps
        .simultaneousGesture(TapGesture().onEnded { editorFocused = false })
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            readSafeArea()
            reflectionText = session.freeReflection   // pre-fill if returning
        }
        .onDisappear {
            // Auto-save so nothing is lost regardless of how the user leaves
            let trimmed = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            session.freeReflection = trimmed
            try? modelContext.save()
        }
    }

    // MARK: - Helpers

    private func saveReflection() {
        session.freeReflection = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        try? modelContext.save()
        nav.showWalkSetup = false   // collapse entire walk stack → home
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

// MARK: - NoteRow

private struct NoteRow: View {
    let text: String
    let date: Date?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {

            // Bullet
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

private struct FreeReflectionPreview: View {
    private let container: ModelContainer
    private let session:   WalkSession
    private let vm = HomeViewModel()

    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: WalkSession.self, configurations: config)
        // No sample notes — mirrors a real session where the user didn't take notes
        let s = WalkSession(moodBefore: 3)
        c.mainContext.insert(s)
        container = c
        session   = s
    }

    var body: some View {
        NavigationStack { FreeReflectionView(session: session) }
            .environmentObject(vm)
            .modelContainer(container)
    }
}

#Preview { FreeReflectionPreview() }


//import SwiftUI
//import SwiftData
//
//// MARK: - FreeReflectionView  (Page 7a)
//
//struct FreeReflectionView: View {
//    @Environment(\.modelContext) private var modelContext
//    @Environment(\.dismiss)      private var dismiss
//    @EnvironmentObject           private var nav: HomeViewModel
//
//    let session: WalkSession
//
//    @State private var reflectionText = ""
//    @FocusState private var editorFocused: Bool
//
//    @State private var safeTop:    CGFloat = 59
//    @State private var safeBottom: CGFloat = 34
//
//    // Oldest → newest, preserving per-note timestamps
//    private var notesWithTimestamps: [(text: String, date: Date?)] {
//        session.duringWalkNotes.enumerated().compactMap { index, note in
//            guard !note.isEmpty else { return nil }
//            let date: Date? = index < session.duringWalkNoteTimestamps.count
//                ? session.duringWalkNoteTimestamps[index]
//                : nil
//            return (text: note, date: date)
//        }
//    }
//
//    // MARK: Body
//
//    var body: some View {
//        ZStack {
//            Color("AccentColor")
//                .ignoresSafeArea()
//                .onTapGesture { editorFocused = false }
//
//            VStack(spacing: 0) {
//
//                // ── Header: centred title ──────────────────────────────
//                ZStack {
//                    Text("Reflection")
//                        .font(.title2).fontWeight(.bold)
//                        .foregroundStyle(.white)
//                        .frame(maxWidth: .infinity, alignment: .center)
//
//                    HStack {
//                        Button { dismiss() } label: {
//                            Image(systemName: "chevron.left")
//                                .font(.system(size: 16, weight: .semibold))
//                                .foregroundStyle(.white)
//                                .frame(width: 44, height: 44)
//                                .glassEffect(in: Circle())
//                        }
//                        Spacer()
//                    }
//                }
//                .padding(.horizontal, 20)
//                .padding(.top, 16)
//
//                // ── Scrollable body ────────────────────────────────────
//                ScrollView(showsIndicators: false) {
//                    VStack(alignment: .leading, spacing: 0) {
//
//                        // "Write freely" heading
//                        Text("Write freely")
//                            .font(.title3).fontWeight(.bold)
//                            .foregroundStyle(.white)
//                            .padding(.horizontal, 20)
//                            .padding(.top, 24)
//
//                        // ── Text editor ────────────────────────────────
//                        ZStack(alignment: .topLeading) {
//                            RoundedRectangle(cornerRadius: 16)
//                                .fill(Color("SecondColor"))
//
//                            if reflectionText.isEmpty {
//                                Text("write anything that comes to mind")
//                                    .font(.body)
//                                    .foregroundStyle(.white.opacity(0.25))
//                                    .padding(.horizontal, 16)
//                                    .padding(.top, 16)
//                                    .allowsHitTesting(false)
//                            }
//
//                            TextEditor(text: $reflectionText)
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
//                        .padding(.top, 14)
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
//                                NoteRow(text: entry.text, date: entry.date)
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
//
//                // ── Save button — pinned outside scroll ────────────────
//                Button { saveReflection() } label: {
//                    Text("Save")
//                        .font(.title3).fontWeight(.semibold)
//                        .foregroundStyle(Color("AccentColor"))
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 18)
//                        .background(Capsule().fill(Color.white.opacity(0.85)))
//                }
//                .padding(.horizontal, 24)
//                .padding(.top, 12)
//                .padding(.bottom, safeBottom + 16)
//            }
//            .padding(.top, safeTop)
//        }
//        .ignoresSafeArea(.all)
//        .toolbar(.hidden, for: .navigationBar)
//        .onAppear {
//            readSafeArea()
//            reflectionText = session.freeReflection   // pre-fill if returning
//        }
//    }
//
//    // MARK: - Helpers
//
//    private func saveReflection() {
//        session.freeReflection = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
//        try? modelContext.save()
//        nav.showWalkSetup = false   // collapse entire walk stack → home
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
//// MARK: - NoteRow
//
//private struct NoteRow: View {
//    let text: String
//    let date: Date?
//
//    var body: some View {
//        HStack(alignment: .top, spacing: 14) {
//
//            // Bullet
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
//private struct FreeReflectionPreview: View {
//    private let container: ModelContainer
//    private let session:   WalkSession
//    private let vm = HomeViewModel()
//
//    init() {
//        let config = ModelConfiguration(isStoredInMemoryOnly: true)
//        let c = try! ModelContainer(for: WalkSession.self, configurations: config)
//        let s = WalkSession(moodBefore: 3)
//        let now = Date()
//        s.duringWalkNotes          = [
//            "my manager name is Arwa and I need to tell her about the new plans",
//            "remember to book the dentist appointment"
//        ]
//        s.duringWalkNoteTimestamps = [
//            now.addingTimeInterval(-600),
//            now.addingTimeInterval(-240)
//        ]
//        c.mainContext.insert(s)
//        container = c
//        session   = s
//    }
//
//    var body: some View {
//        NavigationStack { FreeReflectionView(session: session) }
//            .environmentObject(vm)
//            .modelContainer(container)
//    }
//}
//
//#Preview { FreeReflectionPreview() }
