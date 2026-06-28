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
    let recommendedGenre: String?
    let musicMoodId: String?
    let playlistName: String?
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
        recommendedGenre: String? = nil,
        musicMoodId: String? = nil,
        playlistName: String? = nil,
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
        self.recommendedGenre = recommendedGenre
        self.musicMoodId = musicMoodId
        self.playlistName = playlistName
        self.aiDraft = aiDraft
        self.finalText = finalText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case date
        case userKeywords
        case moodSummary
        case recommendedGenre
        case musicMoodId
        case playlistName
        case aiDraft
        case finalText
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        date = try container.decode(Date.self, forKey: .date)
        userKeywords = try container.decode(String.self, forKey: .userKeywords)
        moodSummary = try container.decode(String.self, forKey: .moodSummary)
        recommendedGenre = try container.decodeIfPresent(String.self, forKey: .recommendedGenre)
        musicMoodId = try container.decodeIfPresent(String.self, forKey: .musicMoodId)
        playlistName = try container.decodeIfPresent(String.self, forKey: .playlistName)
        aiDraft = try container.decode(String.self, forKey: .aiDraft)
        finalText = try container.decode(String.self, forKey: .finalText)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
