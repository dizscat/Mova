//
//  EmotionLog.swift
//  Mova
//
//  Satu entri "emotion journal" — disimpan sebagai JSON lokal (nanti Firestore).
//

import Foundation

struct EmotionLog: Identifiable, Codable {
    let id: String
    let userId: String
    let emotion: EmotionType
    let confidence: Double
    let timestamp: Date
    let recommendedGenre: String
    let musicMoodId: String?

    init(
        id: String = UUID().uuidString,
        userId: String,
        emotion: EmotionType,
        confidence: Double,
        timestamp: Date = Date(),
        recommendedGenre: String,
        musicMoodId: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.emotion = emotion
        self.confidence = confidence
        self.timestamp = timestamp
        self.recommendedGenre = recommendedGenre
        self.musicMoodId = musicMoodId
    }
}
