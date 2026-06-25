//
//  EmotionType.swift
//  Mova
//
//  Tujuh kelas emosi mengikuti dataset FER2013.
//

import Foundation

/// Emosi yang dapat dideteksi oleh model Core ML (kelas FER2013).
enum EmotionType: String, Codable, CaseIterable {
    case happy
    case sad
    case angry
    case neutral
    case surprised
    case disgusted
    case fearful

    /// Emoji representatif untuk ditampilkan di overlay & journal.
    var emoji: String {
        switch self {
        case .happy:     return "😄"
        case .sad:       return "😢"
        case .angry:     return "😠"
        case .neutral:   return "😐"
        case .surprised: return "😲"
        case .disgusted: return "🤢"
        case .fearful:   return "😨"
        }
    }

    /// Nama yang sudah dikapitalisasi untuk UI (mis. "Happy").
    var displayName: String {
        rawValue.capitalized
    }

    /// Warna hex unik per emosi (dipakai untuk badge/chart).
    var colorHex: String {
        switch self {
        case .happy:     return "#FFC107" // amber
        case .sad:       return "#5C7CFA" // blue
        case .angry:     return "#FA5252" // red
        case .neutral:   return "#ADB5BD" // gray
        case .surprised: return "#FAB005" // orange
        case .disgusted: return "#40C057" // green
        case .fearful:   return "#7048E8" // purple
        }
    }
}
