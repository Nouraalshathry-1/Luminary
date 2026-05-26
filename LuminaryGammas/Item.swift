//
//  Item.swift
//  LuminaryGammas
//
//  Created by Noura Alshathry on 26/05/2026.
//

import Foundation
import SwiftData

struct WalkNote: Codable, Identifiable {
    var id: UUID = UUID()
    var text: String
    var timestamp: Date
}

@Model
final class WalkSession {
    var id: UUID
    var sessionName: String
    var date: Date
    var durationMinutes: Int
    var steps: Int
    var moodBefore: Double         // 0.0 (low) → 1.0 (great)
    var moodAfter: Double
    var preWalkNote: String
    var duringWalkNotes: [WalkNote]
    var reflectionType: String     // "free" or "guided"
    var freeReflection: String
    var guidedAnswers: [String]    // [howFeelingNow, oneSmallStep, oneThingToCarry]

    var displayNote: String {
        if !freeReflection.isEmpty { return freeReflection }
        if let first = guidedAnswers.first(where: { !$0.isEmpty }) { return first }
        return preWalkNote
    }

    init(
        sessionName: String = "",
        date: Date = Date(),
        durationMinutes: Int = 0,
        steps: Int = 0,
        moodBefore: Double = 0.5,
        moodAfter: Double = 0.5,
        preWalkNote: String = "",
        duringWalkNotes: [WalkNote] = [],
        reflectionType: String = "free",
        freeReflection: String = "",
        guidedAnswers: [String] = ["", "", ""]
    ) {
        self.id = UUID()
        self.sessionName = sessionName
        self.date = date
        self.durationMinutes = durationMinutes
        self.steps = steps
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.preWalkNote = preWalkNote
        self.duringWalkNotes = duringWalkNotes
        self.reflectionType = reflectionType
        self.freeReflection = freeReflection
        self.guidedAnswers = guidedAnswers
    }
}
