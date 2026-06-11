//
//  HistoryView.swift
//  LuminaryGammas
//
//  Created by Noura Alshathry on 02/06/2026.
//


import SwiftUI
import SwiftData

// MARK: - HistoryView  (Page 11)

struct HistoryView: View {
    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WalkSession.date, order: .reverse) private var sessions: [WalkSession]

    @State private var filter:          HistoryFilter = .all
    @State private var showInfo:        Bool          = false
    @State private var selectedSession: WalkSession?  = nil

    // MARK: Body

    var body: some View {
        ZStack {
            Color("AccentColor").ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header ─────────────────────────────────────────────
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .glassEffect(in: Circle())
                    }

                    Spacer()

                    Text("History")
                        .font(.title).fontWeight(.bold)
                        .foregroundStyle(.white)

                    Spacer()

                    // Info button — explains the hourglass indicator
                    Button { showInfo = true } label: {
                        Image(systemName: "info")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .glassEffect(in: Circle())
                    }
                    .alert("Hourglass Sessions", isPresented: $showInfo) {
                        Button("Got it", role: .cancel) {}
                    } message: {
                        Text("Sessions marked with an hourglass haven't been reflected on yet. Tap one to complete your reflection.")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // ── Filter chips ───────────────────────────────────────
                HStack(spacing: 10) {
                    ForEach(HistoryFilter.allCases, id: \.self) { f in
                        FilterChip(title: f.label, isSelected: filter == f) {
                            filter = f
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // ── Session list ───────────────────────────────────────
                let filtered = filteredSessions

                if filtered.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Text("🕯️")
                            .font(.system(size: 48))
                            .opacity(0.35)
                        Text("No walks yet")
                            .font(.callout).fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.40))
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filtered) { session in
                            // Button instead of NavigationLink so the List
                            // never renders the ">" disclosure chevron and
                            // never shrinks the row's trailing inset for it.
                            Button { selectedSession = session } label: {
                                SessionCard(session: session)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 7, leading: 20, bottom: 7, trailing: 20))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    modelContext.delete(session)
                                    try? modelContext.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        // Bottom breathing room
                        Color.clear
                            .frame(height: 24)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .padding(.top, 12)
                    // Tapping a session:
                    //   • No reflection yet  → WalkStatsView to pick reflection type
                    //   • Already reflected  → SessionDetailView
                    .navigationDestination(item: $selectedSession) { session in
                        let hasReflection = !session.freeReflection.isEmpty ||
                            session.guidedAnswers.contains(where: { !$0.isEmpty })

                        if hasReflection {
                            SessionDetailView(session: session)
                        } else {
                            WalkStatsView(session: session, showBackButton: true)
                        }
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Filter

    private var filteredSessions: [WalkSession] {
        let cal = Calendar.current
        let now = Date()
        switch filter {
        case .all:
            return sessions
        case .week:
            let weekAgo = cal.date(byAdding: .day, value: -7, to: now)!
            return sessions.filter { $0.date >= weekAgo }
        case .month:
            let comps = cal.dateComponents([.year, .month], from: now)
            let startOfMonth = cal.date(from: comps)!
            return sessions.filter { $0.date >= startOfMonth }
        }
    }
}

// MARK: - HistoryFilter

enum HistoryFilter: CaseIterable {
    case all, week, month

    var label: String {
        switch self {
        case .all:   return "All"
        case .week:  return "This Week"
        case .month: return "This Month"
        }
    }
}

// MARK: - FilterChip

private struct FilterChip: View {
    let title:      String
    let isSelected: Bool
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .white.opacity(0.65))
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
        }
        .glassEffect(in: Capsule())
    }
}

// MARK: - SessionCard

private struct SessionCard: View {
    let session: WalkSession

    private var hasReflection: Bool {
        !session.freeReflection.isEmpty ||
        session.guidedAnswers.contains(where: { !$0.isEmpty })
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy (h:mm a)"
        return f.string(from: session.date)
    }

    private var stepsFormatted: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        return fmt.string(from: NSNumber(value: session.steps)) ?? "\(session.steps)"
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Top: name + snippet + candle / hourglass ───────────────
            HStack(alignment: .top, spacing: 12) {

                VStack(alignment: .leading, spacing: 8) {
                    Text(session.sessionName.isEmpty ? "Untitled walk" : session.sessionName)
                        .font(.title2).fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(session.displayNote.isEmpty ? " " : session.displayNote)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.60))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                if hasReflection {
                    MoodIndicator(moodBefore: session.moodBefore, moodAfter: session.moodAfter)
                } else {
                    WaitingIndicator()
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 16)

            // ── Divider ────────────────────────────────────────────────
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 18)

            // ── Bottom: date (left)  ·  steps + footprint (right) ─────
            HStack {
                Text(formattedDate)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.50))

                Spacer()

                HStack(spacing: 4) {
                    Text(stepsFormatted)
                        .font(.footnote).fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.70))
                    Text("👣")
                        .font(.footnote)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .background(Color("StatsBox"), in: RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - MoodIndicator  (mini candle + delta arrow + after-mood label)

private struct MoodIndicator: View {
    let moodBefore: Int
    let moodAfter:  Int

    private var delta: Int { moodAfter - moodBefore }

    private var arrowName: String {
        delta > 0 ? "arrow.up" : (delta < 0 ? "arrow.down" : "minus")
    }

    private var arrowColor: Color {
        delta > 0 ? Color(red: 0.27, green: 0.80, blue: 0.40) :
        delta < 0 ? Color(red: 1.00, green: 0.38, blue: 0.38) :
                    Color.white.opacity(0.45)
    }

    var body: some View {
        // Arrow sits left of the candle; label lives in the same VStack as
        // the candle so it always centers directly under the body.
        HStack(alignment: .top, spacing: 4) {
            Image(systemName: arrowName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(arrowColor)
                // flame(22) + wick(5) + half-body(17) = 44 — padding shifts
                // arrow icon to the vertical center of the candle body
                .padding(.top, 38)

            VStack(spacing: 4) {
                CandleComponent()
                    .flameScale(CandleComponent.flameScale(for: moodAfter))
                    .flickering(false)
                    .miniMode(true)

                Text(CandleComponent.label(for: moodAfter))
                    .font(.caption2).fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .offset(x: -5)
    }
}

// MARK: - WaitingIndicator  (hourglass only — tap ⓘ for explanation)

private struct WaitingIndicator: View {
    var body: some View {
        // Mirror the MoodIndicator column structure so the hourglass
        // occupies the same visual zone as the candle body:
        //   flame area  (22 + 5 = 27 pt)  →  top spacer
        //   body area   (34 pt)            →  hourglass icon
        //   label area  (4 + 14 = 18 pt)  →  bottom spacer
        VStack(spacing: 0) {
            Color.clear.frame(height: 22)   // flame height

            Image(systemName: "hourglass")
                .font(.system(size: 38, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.50))
                .frame(height: 39)          // body + wick zone

            Color.clear.frame(height: 18)   // label zone
        }
        .frame(width: 50)
    }
}

// MARK: - Preview

private struct HistoryPreview: View {
    private let container: ModelContainer
    private let vm = HomeViewModel()

    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: WalkSession.self, configurations: config)

        // Session with no reflection yet (hourglass state)
        let s1 = WalkSession(
            sessionName: "Thought home",
            durationMinutes: 20,
            steps: 1_055,
            moodBefore: 3,
            moodAfter: 3,
            duringWalkNotes: ["I had a hard time with a new employee and I thought ..."]
        )
        s1.date = Calendar.current.date(byAdding: .day, value: -12, to: Date())!
        c.mainContext.insert(s1)

        // Free reflection — mood improved
        let s2 = WalkSession(
            sessionName: "Thoughts about work",
            durationMinutes: 45,
            steps: 5_448,
            moodBefore: 2,
            moodAfter: 4,
            duringWalkNotes: ["I had a hard time with a new employee and I thought ..."],
            reflectionType: "free",
            freeReflection: "I had a hard time with a new employee and I thought about it during my walk."
        )
        s2.date = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        c.mainContext.insert(s2)

        // Guided reflection — big mood boost
        let s3 = WalkSession(
            sessionName: "Thought about work",
            durationMinutes: 12,
            steps: 589,
            moodBefore: 2,
            moodAfter: 5,
            duringWalkNotes: ["I had a hard time with a new employee and I thought ..."],
            reflectionType: "guided",
            guidedAnswers: ["Feeling much better after the walk.", "", ""]
        )
        s3.date = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        c.mainContext.insert(s3)

        container = c
    }

    var body: some View {
        NavigationStack { HistoryView() }
            .environmentObject(vm)
            .modelContainer(container)
    }
}

#Preview { HistoryPreview() }


//import SwiftUI
//import SwiftData
//
//// MARK: - HistoryView  (Page 11)
//
//struct HistoryView: View {
//    @Environment(\.dismiss)      private var dismiss
//    @Environment(\.modelContext) private var modelContext
//
//    @Query(sort: \WalkSession.date, order: .reverse) private var sessions: [WalkSession]
//
//    @State private var filter:          HistoryFilter = .all
//    @State private var showInfo:        Bool          = false
//    @State private var selectedSession: WalkSession?  = nil
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
//                HStack {
//                    Button { dismiss() } label: {
//                        Image(systemName: "chevron.left")
//                            .font(.system(size: 16, weight: .semibold))
//                            .foregroundStyle(.white)
//                            .frame(width: 44, height: 44)
//                            .glassEffect(in: Circle())
//                    }
//
//                    Spacer()
//
//                    Text("History")
//                        .font(.title).fontWeight(.bold)
//                        .foregroundStyle(.white)
//
//                    Spacer()
//
//                    // Info button — explains the hourglass indicator
//                    Button { showInfo = true } label: {
//                        Image(systemName: "info")
//                            .font(.system(size: 15, weight: .semibold))
//                            .foregroundStyle(.white)
//                            .frame(width: 44, height: 44)
//                            .glassEffect(in: Circle())
//                    }
//                    .alert("Hourglass Sessions", isPresented: $showInfo) {
//                        Button("Got it", role: .cancel) {}
//                    } message: {
//                        Text("Sessions marked with an hourglass haven't been reflected on yet. Tap one to complete your reflection.")
//                    }
//                }
//                .padding(.horizontal, 20)
//                .padding(.top, 12)
//
//                // ── "Session History" label + filter chips ─────────────
//                VStack(alignment: .leading, spacing: 14) {
//                    Text("Session History")
//                        .font(.title3).fontWeight(.semibold)
//                        .foregroundStyle(.white)
//
//                    HStack(spacing: 10) {
//                        ForEach(HistoryFilter.allCases, id: \.self) { f in
//                            FilterChip(title: f.label, isSelected: filter == f) {
//                                filter = f
//                            }
//                        }
//                        Spacer()
//                    }
//                }
//                .padding(.horizontal, 24)
//                .padding(.top, 20)
//
//                // ── Session list ───────────────────────────────────────
//                let filtered = filteredSessions
//
//                if filtered.isEmpty {
//                    Spacer()
//                    VStack(spacing: 10) {
//                        Text("🕯️")
//                            .font(.system(size: 48))
//                            .opacity(0.35)
//                        Text("No walks yet")
//                            .font(.callout).fontWeight(.semibold)
//                            .foregroundStyle(.white.opacity(0.40))
//                    }
//                    Spacer()
//                } else {
//                    List {
//                        ForEach(filtered) { session in
//                            // Button instead of NavigationLink so the List
//                            // never renders the ">" disclosure chevron and
//                            // never shrinks the row's trailing inset for it.
//                            Button { selectedSession = session } label: {
//                                SessionCard(session: session)
//                            }
//                            .buttonStyle(.plain)
//                            .listRowBackground(Color.clear)
//                            .listRowSeparator(.hidden)
//                            .listRowInsets(EdgeInsets(top: 7, leading: 20, bottom: 7, trailing: 20))
//                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                                Button(role: .destructive) {
//                                    modelContext.delete(session)
//                                    try? modelContext.save()
//                                } label: {
//                                    Label("Delete", systemImage: "trash")
//                                }
//                            }
//                        }
//                        // Bottom breathing room
//                        Color.clear
//                            .frame(height: 24)
//                            .listRowBackground(Color.clear)
//                            .listRowSeparator(.hidden)
//                    }
//                    .listStyle(.plain)
//                    .scrollContentBackground(.hidden)
//                    .padding(.top, 12)
//                    // Tapping a session:
//                    //   • No reflection yet  → WalkStatsView to pick reflection type
//                    //   • Already reflected  → SessionDetailView
//                    .navigationDestination(item: $selectedSession) { session in
//                        let hasReflection = !session.freeReflection.isEmpty ||
//                            session.guidedAnswers.contains(where: { !$0.isEmpty })
//
//                        if hasReflection {
//                            SessionDetailView(session: session)
//                        } else {
//                            WalkStatsView(session: session, showBackButton: true)
//                        }
//                    }
//                }
//            }
//        }
//        .toolbar(.hidden, for: .navigationBar)
//    }
//
//    // MARK: - Filter
//
//    private var filteredSessions: [WalkSession] {
//        let cal = Calendar.current
//        let now = Date()
//        switch filter {
//        case .all:
//            return sessions
//        case .week:
//            let weekAgo = cal.date(byAdding: .day, value: -7, to: now)!
//            return sessions.filter { $0.date >= weekAgo }
//        case .month:
//            let comps = cal.dateComponents([.year, .month], from: now)
//            let startOfMonth = cal.date(from: comps)!
//            return sessions.filter { $0.date >= startOfMonth }
//        }
//    }
//}
//
//// MARK: - HistoryFilter
//
//enum HistoryFilter: CaseIterable {
//    case all, week, month
//
//    var label: String {
//        switch self {
//        case .all:   return "All"
//        case .week:  return "This Week"
//        case .month: return "This Month"
//        }
//    }
//}
//
//// MARK: - FilterChip
//
//private struct FilterChip: View {
//    let title:      String
//    let isSelected: Bool
//    let action:     () -> Void
//
//    var body: some View {
//        Button(action: action) {
//            Text(title)
//                .font(.subheadline)
//                .fontWeight(isSelected ? .semibold : .regular)
//                .foregroundStyle(isSelected ? .white : .white.opacity(0.65))
//                .padding(.horizontal, 18)
//                .padding(.vertical, 9)
//        }
//        .glassEffect(in: Capsule())
//    }
//}
//
//// MARK: - SessionCard
//
//private struct SessionCard: View {
//    let session: WalkSession
//
//    private var hasReflection: Bool {
//        !session.freeReflection.isEmpty ||
//        session.guidedAnswers.contains(where: { !$0.isEmpty })
//    }
//
//    private var formattedDate: String {
//        let f = DateFormatter()
//        f.dateFormat = "d MMMM yyyy (h:mm a)"
//        return f.string(from: session.date)
//    }
//
//    private var stepsFormatted: String {
//        let fmt = NumberFormatter()
//        fmt.numberStyle = .decimal
//        return fmt.string(from: NSNumber(value: session.steps)) ?? "\(session.steps)"
//    }
//
//    var body: some View {
//        VStack(spacing: 0) {
//
//            // ── Top: name + snippet + candle / hourglass ───────────────
//            HStack(alignment: .top, spacing: 12) {
//
//                VStack(alignment: .leading, spacing: 8) {
//                    Text(session.sessionName.isEmpty ? "Untitled walk" : session.sessionName)
//                        .font(.title2).fontWeight(.bold)
//                        .foregroundStyle(.white)
//                        .lineLimit(1)
//
//                    Text(session.displayNote.isEmpty ? " " : session.displayNote)
//                        .font(.callout)
//                        .foregroundStyle(.white.opacity(0.60))
//                        .lineLimit(2)
//                        .fixedSize(horizontal: false, vertical: true)
//                }
//
//                Spacer(minLength: 12)
//
//                if hasReflection {
//                    MoodIndicator(moodBefore: session.moodBefore, moodAfter: session.moodAfter)
//                } else {
//                    WaitingIndicator()
//                }
//            }
//            .padding(.horizontal, 18)
//            .padding(.top, 18)
//            .padding(.bottom, 16)
//
//            // ── Divider ────────────────────────────────────────────────
//            Rectangle()
//                .fill(Color.white.opacity(0.12))
//                .frame(height: 1)
//                .padding(.horizontal, 18)
//
//            // ── Bottom: date (left)  ·  steps + footprint (right) ─────
//            HStack {
//                Text(formattedDate)
//                    .font(.footnote)
//                    .foregroundStyle(.white.opacity(0.50))
//
//                Spacer()
//
//                HStack(spacing: 4) {
//                    Text(stepsFormatted)
//                        .font(.footnote).fontWeight(.medium)
//                        .foregroundStyle(.white.opacity(0.70))
//                    Text("👣")
//                        .font(.footnote)
//                }
//            }
//            .padding(.horizontal, 18)
//            .padding(.vertical, 14)
//        }
//        .background(Color("StatsBox"), in: RoundedRectangle(cornerRadius: 22))
//    }
//}
//
//// MARK: - MoodIndicator  (mini candle + delta arrow + after-mood label)
//
//private struct MoodIndicator: View {
//    let moodBefore: Int
//    let moodAfter:  Int
//
//    private var delta: Int { moodAfter - moodBefore }
//
//    private var arrowName: String {
//        delta > 0 ? "arrow.up" : (delta < 0 ? "arrow.down" : "minus")
//    }
//
//    private var arrowColor: Color {
//        delta > 0 ? Color(red: 0.27, green: 0.80, blue: 0.40) :
//        delta < 0 ? Color(red: 1.00, green: 0.38, blue: 0.38) :
//                    Color.white.opacity(0.45)
//    }
//
//    var body: some View {
//        // Arrow sits left of the candle; label lives in the same VStack as
//        // the candle so it always centers directly under the body.
//        HStack(alignment: .top, spacing: 4) {
//            Image(systemName: arrowName)
//                .font(.system(size: 12, weight: .bold))
//                .foregroundStyle(arrowColor)
//                // flame(22) + wick(5) + half-body(17) = 44 — padding shifts
//                // arrow icon to the vertical center of the candle body
//                .padding(.top, 38)
//
//            VStack(spacing: 4) {
//                CandleComponent()
//                    .flameScale(CandleComponent.flameScale(for: moodAfter))
//                    .flickering(false)
//                    .miniMode(true)
//
//                Text(CandleComponent.label(for: moodAfter))
//                    .font(.caption2).fontWeight(.medium)
//                    .foregroundStyle(.white.opacity(0.65))
//            }
//        }
//        .offset(x: -5)
//    }
//}
//
//// MARK: - WaitingIndicator  (hourglass only — tap ⓘ for explanation)
//
//private struct WaitingIndicator: View {
//    var body: some View {
//        // Mirror the MoodIndicator column structure so the hourglass
//        // occupies the same visual zone as the candle body:
//        //   flame area  (22 + 5 = 27 pt)  →  top spacer
//        //   body area   (34 pt)            →  hourglass icon
//        //   label area  (4 + 14 = 18 pt)  →  bottom spacer
//        VStack(spacing: 0) {
//            Color.clear.frame(height: 22)   // flame height
//
//            Image(systemName: "hourglass")
//                .font(.system(size: 38, weight: .ultraLight))
//                .foregroundStyle(.white.opacity(0.50))
//                .frame(height: 39)          // body + wick zone
//
//            Color.clear.frame(height: 18)   // label zone
//        }
//        .frame(width: 50)
//    }
//}
//
//// MARK: - Preview
//
//private struct HistoryPreview: View {
//    private let container: ModelContainer
//    private let vm = HomeViewModel()
//
//    init() {
//        let config = ModelConfiguration(isStoredInMemoryOnly: true)
//        let c = try! ModelContainer(for: WalkSession.self, configurations: config)
//
//        // Session with no reflection yet (hourglass state)
//        let s1 = WalkSession(
//            sessionName: "Thought home",
//            durationMinutes: 20,
//            steps: 1_055,
//            moodBefore: 3,
//            moodAfter: 3,
//            duringWalkNotes: ["I had a hard time with a new employee and I thought ..."]
//        )
//        s1.date = Calendar.current.date(byAdding: .day, value: -12, to: Date())!
//        c.mainContext.insert(s1)
//
//        // Free reflection — mood improved
//        let s2 = WalkSession(
//            sessionName: "Thoughts about work",
//            durationMinutes: 45,
//            steps: 5_448,
//            moodBefore: 2,
//            moodAfter: 4,
//            duringWalkNotes: ["I had a hard time with a new employee and I thought ..."],
//            reflectionType: "free",
//            freeReflection: "I had a hard time with a new employee and I thought about it during my walk."
//        )
//        s2.date = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
//        c.mainContext.insert(s2)
//
//        // Guided reflection — big mood boost
//        let s3 = WalkSession(
//            sessionName: "Thought about work",
//            durationMinutes: 12,
//            steps: 589,
//            moodBefore: 2,
//            moodAfter: 5,
//            duringWalkNotes: ["I had a hard time with a new employee and I thought ..."],
//            reflectionType: "guided",
//            guidedAnswers: ["Feeling much better after the walk.", "", ""]
//        )
//        s3.date = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
//        c.mainContext.insert(s3)
//
//        container = c
//    }
//
//    var body: some View {
//        NavigationStack { HistoryView() }
//            .environmentObject(vm)
//            .modelContainer(container)
//    }
//}
//
//#Preview { HistoryPreview() }



