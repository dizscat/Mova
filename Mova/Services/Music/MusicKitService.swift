//
//  MusicKitService.swift
//  Mova
//
//  Versi SIMPLIFIED untuk MVP: alih-alih otentikasi MusicKit penuh, kita cukup
//  membuka pencarian di aplikasi Apple Music (atau fallback ke web).
//

import UIKit

final class MusicKitService: ObservableObject {

    /// Buka lagu di Apple Music via URL pencarian. Fallback ke web search bila
    /// Apple Music tidak terpasang.
    func openInAppleMusic(trackTitle: String, artist: String) {
        let term = "\(trackTitle) \(artist)"
        let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // Skema Apple Music (membuka app jika terpasang).
        let appleMusicURL = URL(string: "music://music.apple.com/search?term=\(encoded)")
        // Fallback: situs Apple Music di browser.
        let webURL = URL(string: "https://music.apple.com/search?term=\(encoded)")

        if let appleMusicURL = appleMusicURL, UIApplication.shared.canOpenURL(appleMusicURL) {
            UIApplication.shared.open(appleMusicURL)
        } else if let webURL = webURL {
            UIApplication.shared.open(webURL)
        }
    }
}
