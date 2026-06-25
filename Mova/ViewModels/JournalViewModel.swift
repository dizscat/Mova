//
//  JournalViewModel.swift
//  Mova
//
//  Memuat riwayat EmotionLog & menghitung breakdown emosi 7 hari terakhir
//  untuk visualisasi tren mood (Swift Charts).
//

import Foundation
import Combine

@MainActor
final class JournalViewModel: ObservableObject {

    @Published var logs: [EmotionLog] = []
    @Published var todayLogs: [EmotionLog] = []
    @Published var weeklyBreakdown: [EmotionType: Int] = [:]
    @Published var dominantEmotion: EmotionType?
    @Published var dailyJournals: [DailyJournal] = []

    private let service = PersistenceManager.shared.service

    /// Muat semua log user + hitung breakdown 7 hari terakhir.
    func loadLogs(userId: String) async {
        do {
            let allLogs = try await service.fetchLogs(forUserId: userId)
            logs = allLogs
            todayLogs = allLogs.filter { Calendar.current.isDateInToday($0.timestamp) }
            dominantEmotion = computeDominantEmotion(from: allLogs)
            dailyJournals = try await service.fetchDailyJournals(forUserId: userId)

            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let recent = allLogs.filter { $0.timestamp >= sevenDaysAgo }

            var breakdown: [EmotionType: Int] = [:]
            for log in recent {
                breakdown[log.emotion, default: 0] += 1
            }
            weeklyBreakdown = breakdown
        } catch {
            print("JournalViewModel load error: \(error.localizedDescription)")
        }
    }

    private func computeDominantEmotion(from logs: [EmotionLog]) -> EmotionType? {
        var counts: [EmotionType: Int] = [:]
        for log in logs {
            counts[log.emotion, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }?.key
    }
}
