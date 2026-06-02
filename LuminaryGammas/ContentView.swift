//
//  ContentView.swift
//  LuminaryGammas
//
//  Created by Noura Alshathry on 26/05/2026.
//


import SwiftUI
import SwiftData
import Combine

// MARK: - ViewModel

class HomeViewModel: ObservableObject {
    @Published var showHistory = false
    @Published var showWalkSetup = false
}

// MARK: - RecentNote

struct RecentNote: Identifiable {
    let id = UUID()
    let text: String
    let date: Date
    let sessionDuration: Int
}

// MARK: - HomeView

struct HomeView: View {
    @Query(sort: \WalkSession.date, order: .reverse) private var sessions: [WalkSession]
    @StateObject private var viewModel = HomeViewModel()

    private var recentNotes: [RecentNote] {
        var notes: [RecentNote] = []
        for session in sessions {
            for (index, note) in session.duringWalkNotes.enumerated() {
                guard !note.isEmpty else { continue }
                let date = index < session.duringWalkNoteTimestamps.count
                    ? session.duringWalkNoteTimestamps[index]
                    : session.date
                notes.append(RecentNote(text: note, date: date, sessionDuration: session.durationMinutes))
            }
        }
        return Array(notes.sorted { $0.date > $1.date }.prefix(3))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AccentColor").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {

                    // History button — liquid glass
                    HStack {
                        Spacer()
                        Button {
                            viewModel.showHistory = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(14)
                        }
                        .glassEffect(in: Circle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Let's take a walk")
                            .font(.largeTitle).fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Text("Clear your mind with every step")
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Meditate card
                    MeditateCardView {
                        viewModel.showWalkSetup = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 80)

                    // Last Walks
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Last Walks")
                            .font(.title2).fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)

                        if recentNotes.isEmpty {
                            EmptyNotesView()
                        } else {
                            VStack(spacing: 0) {
                                ForEach(recentNotes) { note in
                                    LastWalkRowView(note: note)
                                    if note.id != recentNotes.last?.id {
                                        Divider()
                                            .background(Color.white.opacity(0.12))
                                            .padding(.horizontal, 24)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 36)

                    Spacer()
                }
                .navigationDestination(isPresented: $viewModel.showHistory) {
                    HistoryView()
                }
                .navigationDestination(isPresented: $viewModel.showWalkSetup) {
                    BeforeWalkingView()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .environmentObject(viewModel)   // lets WalkStatsView reach nav.showWalkSetup
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - MeditateCardView

struct MeditateCardView: View {
    let onMeditateTap: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("FirstBox"))

            HStack(alignment: .bottom, spacing: 0) {

                // Left: text + button
                VStack(alignment: .leading, spacing: 35) {
                    Spacer()
                    Text("Light a candle and begin your mindful journey")
                        .font(.callout).fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: onMeditateTap) {
                        Text("Start Session")
                            .font(.callout).fontWeight(.semibold)
                            .foregroundStyle(Color("AccentColor"))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(.white))
                    }
                }
                .padding(.leading, 20)
                .padding(.bottom, 22)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right: candle, bottom-clipped by card's clipShape
                CandleComponent()
                    .flameScale(1.0)
                    .offset(y: 28)
                    .padding(.trailing, 12)
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// FlameShape and the animated candle are defined in CandleComponent.swift

// MARK: - LastWalkRowView

struct LastWalkRowView: View {
    let note: RecentNote

    private var formattedDate: String {
        note.date.formatted(.dateTime.month(.abbreviated).day())
    }

    private var formattedTimeDuration: String {
        let time = note.date.formatted(
            .dateTime
                .hour(.defaultDigits(amPM: .abbreviated))
                .minute(.twoDigits)
        )
        let duration = note.sessionDuration > 0 ? "\(note.sessionDuration) min" : "< 1 min"
        return "\(time) • \(duration)"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {

            // Icon
            Text("📝")
                .font(.system(size: 28))
                .frame(width: 40, height: 40)

            // Date + time • duration  (left column)
            VStack(alignment: .leading, spacing: 3) {
                Text(formattedDate)
                    .font(.callout).fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(formattedTimeDuration)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            // Note text  (right column)
            Text("\u{201C}\(note.text)\u{201D}")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .frame(maxWidth: 160, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }
}

// MARK: - EmptyNotesView

struct EmptyNotesView: View {
    var body: some View {
        VStack(spacing: 14) {
            Text("📝")
                .font(.system(size: 52))
                .opacity(0.4)

            Text("Your notes will appear here")
                .font(.callout).fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.65))

            Text("Start your first mindful walk to see your reflections")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
        .padding(.horizontal, 40)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: WalkSession.self, inMemory: true)
}


//import SwiftUI
//import SwiftData
//import Combine
//
//// MARK: - ViewModel
//
//class HomeViewModel: ObservableObject {
//    @Published var showHistory = false
//    @Published var showWalkSetup = false
//}
//
//// MARK: - HomeView
//
//struct HomeView: View {
//    @Query(sort: \WalkSession.date, order: .reverse) private var sessions: [WalkSession]
//    @StateObject private var viewModel = HomeViewModel()
//
//    private var recentSessions: [WalkSession] { Array(sessions.prefix(3)) }
//
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                Color("AccentColor").ignoresSafeArea()
//
//                VStack(alignment: .leading, spacing: 0) {
//
//                    // History button — liquid glass
//                    HStack {
//                        Spacer()
//                        Button {
//                            viewModel.showHistory = true
//                        } label: {
//                            Image(systemName: "clock.arrow.circlepath")
//                                .font(.system(size: 20, weight: .semibold))
//                                .foregroundStyle(.white)
//                                .padding(14)
//                        }
//                        .glassEffect(in: Circle())
//                    }
//                    .padding(.horizontal, 24)
//                    .padding(.top, 12)
//
//                    // Title
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("Let's take a walk")
//                            .font(.largeTitle).fontWeight(.semibold)
//                            .foregroundStyle(.white)
//                        Text("Clear your mind with every step")
//                            .font(.callout)
//                            .foregroundStyle(.white.opacity(0.55))
//                    }
//                    .padding(.horizontal, 24)
//                    .padding(.top, 16)
//
//                    // Meditate card
//                    MeditateCardView {
//                        viewModel.showWalkSetup = true
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.top, 80)
//
//                    // Last Walks
//                    VStack(alignment: .leading, spacing: 0) {
//                        Text("Last Walks")
//                            .font(.title2).fontWeight(.semibold)
//                            .foregroundStyle(.white)
//                            .padding(.horizontal, 24)
//                            .padding(.bottom, 16)
//
//                        if recentSessions.isEmpty {
//                            EmptyNotesView()
//                        } else {
//                            VStack(spacing: 0) {
//                                ForEach(recentSessions) { session in
//                                    LastWalkRowView(session: session)
//                                    if session.id != recentSessions.last?.id {
//                                        Divider()
//                                            .background(Color.white.opacity(0.12))
//                                            .padding(.horizontal, 24)
//                                    }
//                                }
//                            }
//                        }
//                    }
//                    .padding(.top, 36)
//
//                    Spacer()
//                }
//                .navigationDestination(isPresented: $viewModel.showHistory) {
//                    HistoryView()
//                }
//                .navigationDestination(isPresented: $viewModel.showWalkSetup) {
//                    BeforeWalkingView()
//                }
//            }
//            .toolbar(.hidden, for: .navigationBar)
//        }
//        .environmentObject(viewModel)   // lets WalkStatsView reach nav.showWalkSetup
//        .ignoresSafeArea(.keyboard)
//    }
//}
//
//// MARK: - MeditateCardView
//
//struct MeditateCardView: View {
//    let onMeditateTap: () -> Void
//
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color("FirstBox"))
//
//            HStack(alignment: .bottom, spacing: 0) {
//
//                // Left: text + button
//                VStack(alignment: .leading, spacing: 35) {
//                    Spacer()
//                    Text("Light a candle and begin your mindful journey")
//                        .font(.callout).fontWeight(.semibold)
//                        .foregroundStyle(.white)
//                        .fixedSize(horizontal: false, vertical: true)
//
//                    Button(action: onMeditateTap) {
//                        Text("Start Session")
//                            .font(.callout).fontWeight(.semibold)
//                            .foregroundStyle(Color("AccentColor"))
//                            .padding(.horizontal, 24)
//                            .padding(.vertical, 10)
//                            .background(Capsule().fill(.white))
//                    }
//                }
//                .padding(.leading, 20)
//                .padding(.bottom, 22)
//                .frame(maxWidth: .infinity, alignment: .leading)
//
//                // Right: candle, bottom-clipped by card's clipShape
//                CandleComponent()
//                    .flameScale(1.0)
//                    .offset(y: 28)
//                    .padding(.trailing, 12)
//            }
//        }
//        .frame(height: 180)
//        .clipShape(RoundedRectangle(cornerRadius: 20))
//    }
//}
//
//// FlameShape and the animated candle are defined in CandleComponent.swift
//
//// MARK: - LastWalkRowView
//
//struct LastWalkRowView: View {
//    let session: WalkSession
//
//    private var formattedDate: String {
//        session.date.formatted(.dateTime.month(.abbreviated).day())
//    }
//
//    private var formattedTime: String {
//        session.date.formatted(
//            .dateTime
//                .hour(.defaultDigits(amPM: .abbreviated))
//                .minute(.twoDigits)
//        )
//    }
//
//    private var durationLabel: String {
//        session.durationMinutes > 0 ? "\(session.durationMinutes) min" : "< 1 min"
//    }
//
//    var body: some View {
//        HStack(alignment: .center, spacing: 14) {
//
//            // Icon
//            Text("📝")
//                .font(.system(size: 28))
//                .frame(width: 40, height: 40)
//
//            // Date + time  (left column)
//            VStack(alignment: .leading, spacing: 3) {
//                Text(formattedDate)
//                    .font(.callout).fontWeight(.semibold)
//                    .foregroundStyle(.white)
//                Text(formattedTime)
//                    .font(.footnote)
//                    .foregroundStyle(.white.opacity(0.45))
//            }
//
//            Spacer()
//
//            // Note snippet + duration  (right column)
//            VStack(alignment: .trailing, spacing: 5) {
//                if !session.displayNote.isEmpty {
//                    Text("\u{201C}\(session.displayNote)\u{201D}")
//                        .font(.footnote)
//                        .foregroundStyle(.white.opacity(0.65))
//                        .multilineTextAlignment(.trailing)
//                        .lineLimit(2)
//                }
//                Text(durationLabel)
//                    .font(.caption2).fontWeight(.medium)
//                    .foregroundStyle(.white.opacity(0.35))
//            }
//            .frame(maxWidth: 160, alignment: .trailing)
//        }
//        .padding(.horizontal, 24)
//        .padding(.vertical, 14)
//    }
//}
//
//// MARK: - EmptyNotesView
//
//struct EmptyNotesView: View {
//    var body: some View {
//        VStack(spacing: 14) {
//            Text("📝")
//                .font(.system(size: 52))
//                .opacity(0.4)
//
//            Text("Your notes will appear here")
//                .font(.callout).fontWeight(.semibold)
//                .foregroundStyle(.white.opacity(0.65))
//
//            Text("Start your first mindful walk to see your reflections")
//                .font(.footnote)
//                .foregroundStyle(.white.opacity(0.35))
//                .multilineTextAlignment(.center)
//        }
//        .frame(maxWidth: .infinity)
//        .padding(.top, 48)
//        .padding(.horizontal, 40)
//    }
//}
//
//// MARK: - Preview
//
//#Preview {
//    HomeView()
//        .modelContainer(for: WalkSession.self, inMemory: true)
//}
//
