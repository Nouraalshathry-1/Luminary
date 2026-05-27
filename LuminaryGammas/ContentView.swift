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

// MARK: - HomeView

struct HomeView: View {
    @Query(sort: \WalkSession.date, order: .reverse) private var sessions: [WalkSession]
    @StateObject private var viewModel = HomeViewModel()

    private var recentSessions: [WalkSession] { Array(sessions.prefix(3)) }

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
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(14)
                        }
                        .glassEffect(in: Circle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Let's meditate")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("clear your mind")
                            .font(.system(size: 16, weight: .semibold))
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
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)

                        if recentSessions.isEmpty {
                            EmptyNotesView()
                        } else {
                            VStack(spacing: 0) {
                                ForEach(recentSessions) { session in
                                    LastWalkRowView(session: session)
                                    if session.id != recentSessions.last?.id {
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
                    Text("History — coming soon")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color("AccentColor").ignoresSafeArea())
                }
                .navigationDestination(isPresented: $viewModel.showWalkSetup) {
                    BeforeWalkingView()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
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
                    Text("walking helps you to clear your mind")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: onMeditateTap) {
                        Text("Meditate")
                            .font(.system(size: 16, weight: .semibold))
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
    let session: WalkSession

    private var formattedDate: String {
        session.date.formatted(.dateTime.month(.abbreviated).day())
    }

    private var timeAndDuration: String {
        let time = session.date.formatted(
            .dateTime
                .hour(.defaultDigits(amPM: .abbreviated))
                .minute(.twoDigits)
        )
        return "\(time) • \(session.durationMinutes) min"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {

            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 40, height: 40)
                Image(systemName: "note.text")
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.55))
            }

            // Date + time
            VStack(alignment: .leading, spacing: 3) {
                Text(formattedDate)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text(timeAndDuration)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            // Quote snippet
            Text("\u{201C}\(session.displayNote)\u{201D}")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.trailing)
                .lineLimit(3)
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
            Image(systemName: "note.text")
                .font(.system(size: 52))
                .foregroundStyle(.white.opacity(0.25))

            Text("Your notes will appear here")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.65))

            Text("Start your first mindful walk to see your reflections")
                .font(.system(size: 14, weight: .semibold))
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
