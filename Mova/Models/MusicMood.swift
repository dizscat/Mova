//
//  MusicMood.swift
//  Mova
//
//  Rekomendasi musik untuk sebuah emosi (data hardcode untuk MVP).
//

import Foundation

struct MusicMood: Identifiable, Codable {
    let id: String
    let emotion: EmotionType
    let genre: String
    let playlistName: String
    let trackList: [Track]

    init(
        id: String = UUID().uuidString,
        emotion: EmotionType,
        genre: String,
        playlistName: String,
        trackList: [Track]
    ) {
        self.id = id
        self.emotion = emotion
        self.genre = genre
        self.playlistName = playlistName
        self.trackList = trackList
    }
}
