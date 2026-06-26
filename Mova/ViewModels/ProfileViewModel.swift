//
//  ProfileViewModel.swift
//  Mova
//
//  Statistik agregat dari riwayat emosi: total sesi, streak harian, dan
//  emosi yang paling sering muncul.
//

import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var totalSessions: Int = 0
    @Published var todaySessions: Int = 0
    @Published var journalCount: Int = 0
    @Published var currentStreak: Int = 0
    @Published var mostFrequentEmotion: EmotionType?
    @Published var lastSessionDate: Date?
    @Published var demoSessions: Int = 0
    @Published var realSessions: Int = 0

    private let service = PersistenceManager.shared.service

    func loadStats(userId: String) async {
        do {
            let logs = try await service.fetchLogs(forUserId: userId)
            let journals = try await service.fetchDailyJournals(forUserId: userId)

            totalSessions = logs.count
            demoSessions = logs.filter { $0.detectionSource.isDemoData }.count
            realSessions = logs.filter { $0.detectionSource == .coreML }.count
            todaySessions = logs.filter { Calendar.current.isDateInToday($0.timestamp) }.count
            journalCount = journals.count
            mostFrequentEmotion = computeMostFrequent(logs)
            currentStreak = computeStreak(logs)
            lastSessionDate = logs.first?.timestamp

            let streak = Streak(
                userId: userId,
                currentStreak: currentStreak,
                dominantEmotion: mostFrequentEmotion
            )
            try await service.saveStreak(streak)
        } catch {
            print("ProfileViewModel load error: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func computeMostFrequent(_ logs: [EmotionLog]) -> EmotionType? {
        guard !logs.isEmpty else { return nil }
        var counts: [EmotionType: Int] = [:]
        for log in logs { counts[log.emotion, default: 0] += 1 }
        return counts.max { $0.value < $1.value }?.key
    }

    /// Hitung jumlah hari berturut-turut (mundur dari hari ini) yang memiliki log.
    private func computeStreak(_ logs: [EmotionLog]) -> Int {
        guard !logs.isEmpty else { return 0 }
        let calendar = Calendar.current

        // Kumpulan hari unik yang memiliki minimal satu log.
        let loggedDays = Set(logs.map { calendar.startOfDay(for: $0.timestamp) })

        var streak = 0
        var day = calendar.startOfDay(for: Date())
        while loggedDays.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }
}
