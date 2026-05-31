//
//  Item.swift
//  LuminaryGammas
//
//  Created by Noura Alshathry on 26/05/2026.
//

import Foundation
import SwiftData

@Model
final class WalkSession {
    var id: UUID = UUID()
    var sessionName: String = ""
    var date: Date = Date()
    var durationMinutes: Int = 0
    var steps: Int = 0
    var moodBefore: Int = 3             // 1 (Very low) → 5 (Great)
    var moodAfter: Int = 3
    var preWalkNote: String = ""
    var duringWalkNotes: [String] = []  // CloudKit compatible
    var reflectionType: String = "free"
    var freeReflection: String = ""
    var guidedAnswers: [String] = ["", "", ""]

    var displayNote: String {
        // Post-walk reflections take priority (written after the walk)
        if !freeReflection.isEmpty { return freeReflection }
        if let first = guidedAnswers.first(where: { !$0.isEmpty }) { return first }
        // During-walk quick notes are the main source shown on the home screen
        if let first = duringWalkNotes.first(where: { !$0.isEmpty }) { return first }
        // Pre-walk note as a last resort
        return preWalkNote
    }

    init(
        sessionName: String = "",
        date: Date = Date(),
        durationMinutes: Int = 0,
        steps: Int = 0,
        moodBefore: Int = 3,
        moodAfter: Int = 3,
        preWalkNote: String = "",
        duringWalkNotes: [String] = [],
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
