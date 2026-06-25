//
//  Track.swift
//  Mova
//
//  Lagu dalam playlist rekomendasi. Dipisahkan dari MusicMood agar struktur
//  model lebih dekat dengan ERD.
//

import Foundation

struct Track: Identifiable, Codable {
    let id: String
    let musicMoodId: String
    let title: String
    let artist: String
    let previewURL: String?

    init(
        id: String = UUID().uuidString,
        musicMoodId: String,
        title: String,
        artist: String,
        previewURL: String? = nil
    ) {
        self.id = id
        self.musicMoodId = musicMoodId
        self.title = title
        self.artist = artist
        self.previewURL = previewURL
    }
}
