//
//  WalkStatsView.swift
//  LuminaryGammas
//
//  Created by Noura Alshathry on 02/06/2026.
//



import SwiftUI
import SwiftData

// MARK: - WalkStatsView

struct WalkStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var nav: HomeViewModel
    let session: WalkSession

    @State private var showFreeReflection  = false
    @State private var showGuidedReflection = false

    @State private var safeTop:    CGFloat = 59
    @State private var safeBottom: CGFloat = 34

    // MARK: Body

    var body: some View {
        ZStack {

            // ── Background: deep teal + warm amber radial glow ─────────
            Color("AccentColor")
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.92, green: 0.58, blue: 0.18).opacity(0.45),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 320
            )
            .ignoresSafeArea()

            // ── Scrollable content ─────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Dynamic title ──────────────────────────────────
                    VStack(alignment: .leading, spacing: 6) {
                        Text(dynamicTitle)
                            .font(.largeTitle).fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("Here's a look at your walk")
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.50))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 48)

                    // ── Stats banner ───────────────────────────────────
                    Text("Stats")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.horizontal, 24)
                        .padding(.top, 48)

                    StatsBannerView(session: session)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                    // ── Reflection section ─────────────────────────────
                    Text("How do you want to reflect?")
                        .font(.title3).fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.top, 65)

                    // Option cards
                    VStack(spacing: 14) {
                        ReflectionOptionCard(
                            emoji: "✍️",
                            title: "Write freely",
                            subtitle: "No rules — just your thoughts"
                        ) {
                            showFreeReflection = true
                        }

                        ReflectionOptionCard(
                            emoji: "📋",
                            title: "Answer questions",
                            subtitle: "3 guided prompts"
                        ) {
                            showGuidedReflection = true
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // ── "or" + skip link ───────────────────────────────
                    VStack(spacing: 10) {
                        Text("or")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.35))

                        Button {
                            nav.showWalkSetup = false
                        } label: {
                            Text("Reflect later from history")
                                .font(.callout).fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, safeBottom + 16)
                }
            }
            .padding(.top, safeTop + 30)
        }
        .ignoresSafeArea(.all)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { readSafeArea() }
        .navigationDestination(isPresented: $showFreeReflection) {
            AfterWalkingView(session: session, reflectionType: "free")
        }
        .navigationDestination(isPresented: $showGuidedReflection) {
            AfterWalkingView(session: session, reflectionType: "guided")
        }
    }

    // MARK: - Dynamic title

    private var dynamicTitle: String {
        switch session.durationMinutes {
        case ..<5:  return "A short spark \u{1F525}"
        case 5..<15: return "Great walk! \u{1F44F}"
        case 15..<30: return "Solid session \u{2728}"
        default:     return "Impressive walk \u{1F3C6}"
        }
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

// MARK: - StatsBannerView

private struct StatsBannerView: View {
    let session: WalkSession

    private var notesCount: Int { session.duringWalkNotes.filter { !$0.isEmpty }.count }

    var body: some View {
        HStack(spacing: 0) {

            StatColumn(emoji: "⏱️", value: "\(max(1, session.durationMinutes))", label: "Minutes")

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1, height: 44)

            StatColumn(emoji: "👟", value: "\(session.steps)", label: "Steps")

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1, height: 44)

            StatColumn(emoji: "📝", value: "\(notesCount)", label: "Notes")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - StatColumn

private struct StatColumn: View {
    let emoji: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()

            HStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 12))
                Text(label)
                    .font(.caption).fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ReflectionOptionCard

private struct ReflectionOptionCard: View {
    let emoji:    String
    let title:    String
    let subtitle: String
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Emoji circle
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.10))
                        .frame(width: 50, height: 50)
                    Text(emoji)
                        .font(.system(size: 22))
                }

                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body).fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Color("ButtonColor"), in: RoundedRectangle(cornerRadius: 26))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

private struct WalkStatsPreview: View {
    private let container: ModelContainer
    private let session:   WalkSession
    private let vm = HomeViewModel()

    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: WalkSession.self, configurations: config)
        let s = WalkSession(
            durationMinutes: 18,
            steps: 2_340,
            moodBefore: 3,
            duringWalkNotes: ["felt lighter after the bridge", "remembered to breathe"]
        )
        c.mainContext.insert(s)
        container = c
        session   = s
    }

    var body: some View {
        NavigationStack { WalkStatsView(session: session) }
            .environmentObject(vm)
            .modelContainer(container)
    }
}

#Preview { WalkStatsPreview() }


//import SwiftUI
//import SwiftData
//
//// MARK: - WalkStatsView
//
//struct WalkStatsView: View {
//    @Environment(\.modelContext) private var modelContext
//    @EnvironmentObject private var nav: HomeViewModel
//    let session: WalkSession
//
//    @State private var showFreeReflection  = false
//    @State private var showGuidedReflection = false
//
//    @State private var safeTop:    CGFloat = 59
//    @State private var safeBottom: CGFloat = 34
//
//    // MARK: Body
//
//    var body: some View {
//        ZStack {
//
//            // ── Background: deep teal + warm amber radial glow ─────────
//            Color("AccentColor")
//                .ignoresSafeArea()
//
//            RadialGradient(
//                colors: [
//                    Color(red: 0.92, green: 0.58, blue: 0.18).opacity(0.45),
//                    Color.clear
//                ],
//                center: .center,
//                startRadius: 0,
//                endRadius: 320
//            )
//            .ignoresSafeArea()
//
//            // ── Scrollable content ─────────────────────────────────────
//            ScrollView(showsIndicators: false) {
//                VStack(alignment: .leading, spacing: 0) {
//
//                    // ── Dynamic title ──────────────────────────────────
//                    VStack(alignment: .leading, spacing: 6) {
//                        Text(dynamicTitle)
//                            .font(.largeTitle).fontWeight(.bold)
//                            .foregroundStyle(.white)
//
//                        Text("Here's a look at your walk")
//                            .font(.callout)
//                            .foregroundStyle(.white.opacity(0.50))
//                    }
//                    .padding(.horizontal, 24)
//                    .padding(.top, 48)
//
//                    // ── Stats banner ───────────────────────────────────
//                    Text("Stats")
//                        .font(.subheadline).fontWeight(.medium)
//                        .foregroundStyle(.white.opacity(0.45))
//                        .padding(.horizontal, 24)
//                        .padding(.top, 48)
//
//                    StatsBannerView(session: session)
//                        .padding(.horizontal, 20)
//                        .padding(.top, 10)
//
//                    // ── Reflection section ─────────────────────────────
//                    Text("How do you want to reflect?")
//                        .font(.title3).fontWeight(.semibold)
//                        .foregroundStyle(.white)
//                        .padding(.horizontal, 24)
//                        .padding(.top, 65)
//
//                    // Option cards
//                    VStack(spacing: 14) {
//                        ReflectionOptionCard(
//                            emoji: "✍️",
//                            title: "Write freely",
//                            subtitle: "No rules — just your thoughts"
//                        ) {
//                            showFreeReflection = true
//                        }
//
//                        ReflectionOptionCard(
//                            emoji: "📋",
//                            title: "Answer questions",
//                            subtitle: "3 guided prompts"
//                        ) {
//                            showGuidedReflection = true
//                        }
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.top, 16)
//
//                    // ── "or" + skip link ───────────────────────────────
//                    VStack(spacing: 10) {
//                        Text("or")
//                            .font(.footnote)
//                            .foregroundStyle(.white.opacity(0.35))
//
//                        Button {
//                            nav.showWalkSetup = false
//                        } label: {
//                            Text("Reflect later from history")
//                                .font(.callout).fontWeight(.medium)
//                                .foregroundStyle(.white.opacity(0.55))
//                        }
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding(.top, 12)
//                    .padding(.bottom, safeBottom + 16)
//                }
//            }
//            .padding(.top, safeTop + 30)
//        }
//        .ignoresSafeArea(.all)
//        .toolbar(.hidden, for: .navigationBar)
//        .onAppear { readSafeArea() }
//        .navigationDestination(isPresented: $showFreeReflection) {
//            // Page 6a — Free reflection (coming next)
//            Text("Free Reflection — coming soon")
//                .foregroundStyle(.white)
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .background(Color("AccentColor").ignoresSafeArea())
//        }
//        .navigationDestination(isPresented: $showGuidedReflection) {
//            // Page 6b — Guided reflection (coming next)
//            Text("Guided Reflection — coming soon")
//                .foregroundStyle(.white)
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .background(Color("AccentColor").ignoresSafeArea())
//        }
//    }
//
//    // MARK: - Dynamic title
//
//    private var dynamicTitle: String {
//        switch session.durationMinutes {
//        case ..<5:  return "A short spark \u{1F525}"
//        case 5..<15: return "Great walk! \u{1F44F}"
//        case 15..<30: return "Solid session \u{2728}"
//        default:     return "Impressive walk \u{1F3C6}"
//        }
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
//// MARK: - StatsBannerView
//
//private struct StatsBannerView: View {
//    let session: WalkSession
//
//    private var notesCount: Int { session.duringWalkNotes.filter { !$0.isEmpty }.count }
//
//    var body: some View {
//        HStack(spacing: 0) {
//
//            StatColumn(emoji: "⏱️", value: "\(max(1, session.durationMinutes))", label: "Minutes")
//
//            Rectangle()
//                .fill(Color.white.opacity(0.15))
//                .frame(width: 1, height: 44)
//
//            StatColumn(emoji: "👟", value: "\(session.steps)", label: "Steps")
//
//            Rectangle()
//                .fill(Color.white.opacity(0.15))
//                .frame(width: 1, height: 44)
//
//            StatColumn(emoji: "📝", value: "\(notesCount)", label: "Notes")
//        }
//        .frame(maxWidth: .infinity)
//        .padding(.vertical, 22)
//        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
//    }
//}
//
//// MARK: - StatColumn
//
//private struct StatColumn: View {
//    let emoji: String
//    let value: String
//    let label: String
//
//    var body: some View {
//        VStack(spacing: 5) {
//            Text(value)
//                .font(.system(size: 30, weight: .bold, design: .rounded))
//                .foregroundStyle(.primary)
//                .monospacedDigit()
//
//            HStack(spacing: 4) {
//                Text(emoji)
//                    .font(.system(size: 12))
//                Text(label)
//                    .font(.caption).fontWeight(.medium)
//                    .foregroundStyle(.secondary)
//            }
//        }
//        .frame(maxWidth: .infinity)
//    }
//}
//
//// MARK: - ReflectionOptionCard
//
//private struct ReflectionOptionCard: View {
//    let emoji:    String
//    let title:    String
//    let subtitle: String
//    let action:   () -> Void
//
//    var body: some View {
//        Button(action: action) {
//            HStack(spacing: 16) {
//                // Emoji circle
//                ZStack {
//                    Circle()
//                        .fill(Color.primary.opacity(0.10))
//                        .frame(width: 50, height: 50)
//                    Text(emoji)
//                        .font(.system(size: 22))
//                }
//
//                // Text
//                VStack(alignment: .leading, spacing: 3) {
//                    Text(title)
//                        .font(.body).fontWeight(.semibold)
//                        .foregroundStyle(.primary)
//                    Text(subtitle)
//                        .font(.footnote)
//                        .foregroundStyle(.secondary)
//                }
//
//                Spacer()
//
//                Image(systemName: "chevron.right")
//                    .font(.system(size: 13, weight: .semibold))
//                    .foregroundStyle(.tertiary)
//            }
//            .padding(.horizontal, 18)
//            .padding(.vertical, 16)
//            .background(Color("ButtonColor"), in: RoundedRectangle(cornerRadius: 26))
//        }
//        .buttonStyle(.plain)
//    }
//}
//
//// MARK: - Preview
//
//private struct WalkStatsPreview: View {
//    private let container: ModelContainer
//    private let session:   WalkSession
//    private let vm = HomeViewModel()
//
//    init() {
//        let config = ModelConfiguration(isStoredInMemoryOnly: true)
//        let c = try! ModelContainer(for: WalkSession.self, configurations: config)
//        let s = WalkSession(
//            durationMinutes: 18,
//            steps: 2_340,
//            moodBefore: 3,
//            duringWalkNotes: ["felt lighter after the bridge", "remembered to breathe"]
//        )
//        c.mainContext.insert(s)
//        container = c
//        session   = s
//    }
//
//    var body: some View {
//        NavigationStack { WalkStatsView(session: session) }
//            .environmentObject(vm)
//            .modelContainer(container)
//    }
//}
//
//#Preview { WalkStatsPreview() }
