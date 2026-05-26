//
//  LuminaryGammasApp.swift
//  LuminaryGammas
//
//  Created by Noura Alshathry on 26/05/2026.
//

import SwiftUI
import SwiftData

@main
struct LuminaryGammasApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([WalkSession.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
