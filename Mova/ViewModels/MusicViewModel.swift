//
//  MusicViewModel.swift
//  Mova
//
//  Menyediakan rekomendasi musik untuk emosi & memutar track via MusicKitService.
//

import Foundation
import Combine

@MainActor
final class MusicViewModel: ObservableObject {

    @Published var currentRecommendation: MusicMood?

    private let musicKitService = MusicKitService()

    /// Ambil rekomendasi untuk emosi tertentu (data hardcode via MusicMapper).
    func fetchRecommendation(for emotion: EmotionType) {
        currentRecommendation = MusicMapper.recommendation(for: emotion)
    }

    /// Putar / buka track di Apple Music.
    func playTrack(_ track: Track) {
        musicKitService.openInAppleMusic(trackTitle: track.title, artist: track.artist)
    }
}
