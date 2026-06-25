//
//  DailyJournal.swift
//  Mova
//
//  Draft jurnal harian yang dibuat dari kata kunci user dan ringkasan mood.
//

import Foundation

struct DailyJournal: Identifiable, Codable {
    let id: String
    let userId: String
    let date: Date
    let userKeywords: String
    let moodSummary: String
    let aiDraft: String
    let finalText: String
    let createdAt: Date
    let updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        date: Date,
        userKeywords: String,
        moodSummary: String,
        aiDraft: String,
        finalText: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.userKeywords = userKeywords
        self.moodSummary = moodSummary
        self.aiDraft = aiDraft
        self.finalText = finalText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
