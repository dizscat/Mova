//
//  MusicViewModel.swift
//  Mova
//
//  Menyediakan rekomendasi musik untuk emosi dan membuka link musik eksternal.
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

    /// Buka track melalui Apple Music search atau fallback web.
    func openTrack(_ track: Track) {
        musicKitService.openExternalMusicLink(trackTitle: track.title, artist: track.artist)
    }
}
