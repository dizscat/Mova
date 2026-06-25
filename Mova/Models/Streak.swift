//
//  Streak.swift
//  Mova
//
//  Ringkasan streak mood harian milik user.
//

import Foundation

struct Streak: Identifiable, Codable {
    let id: String
    let userId: String
    let currentStreak: Int
    let dominantEmotion: EmotionType?
    let lastUpdated: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        currentStreak: Int,
        dominantEmotion: EmotionType?,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.currentStreak = currentStreak
        self.dominantEmotion = dominantEmotion
        self.lastUpdated = lastUpdated
    }
}
