//
//  LocalStorageService.swift
//  Mova
//
//  Implementasi LOKAL dari PersistenceServiceProtocol menggunakan
//  FileManager + JSON (Codable) di Documents directory.
//

import Foundation

final class LocalStorageService: PersistenceServiceProtocol {

    static let shared = LocalStorageService()

    private let fileManager = FileManager.default
    private let logsFileName = "emotionLogs.json"
    private let profileFileName = "userProfile.json"
    private let usersFileName = "users.json"
    private let streaksFileName = "streaks.json"
    private let dailyJournalsFileName = "dailyJournals.json"

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Paths

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var logsURL: URL { documentsURL.appendingPathComponent(logsFileName) }
    private var profileURL: URL { documentsURL.appendingPathComponent(profileFileName) }
    private var usersURL: URL { documentsURL.appendingPathComponent(usersFileName) }
    private var streaksURL: URL { documentsURL.appendingPathComponent(streaksFileName) }
    private var dailyJournalsURL: URL { documentsURL.appendingPathComponent(dailyJournalsFileName) }

    // MARK: - Generic helpers

    /// Baca & decode file. Mengembalikan nil jika file belum ada (bukan error).
    private func read<T: Decodable>(_ type: T.Type, from url: URL) throws -> T? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }

    private func write<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try encoder.encode(value)
        try data.write(to: url, options: [.atomic])
    }

    // MARK: - Emotion Logs

    func saveLog(_ log: EmotionLog) async throws {
        // Append ke array yang sudah ada (atau buat baru jika belum ada).
        var logs = (try read([EmotionLog].self, from: logsURL)) ?? []
        logs.append(log)
        try write(logs, to: logsURL)
    }

    func fetchLogs(forUserId userId: String) async throws -> [EmotionLog] {
        let logs = (try read([EmotionLog].self, from: logsURL)) ?? []
        return logs
            .filter { $0.userId == userId }
            .sorted { $0.timestamp > $1.timestamp } // terbaru dahulu
    }

    func fetchLogs(forUserId userId: String, since: Date) async throws -> [EmotionLog] {
        let logs = try await fetchLogs(forUserId: userId)
        return logs.filter { $0.timestamp >= since }
    }

    // MARK: - User Profile

    func saveUserProfile(_ profile: UserProfile) async throws {
        var profiles = try fetchAllProfilesWithLegacyMigration()
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        try write(profiles, to: usersURL)
    }

    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        let profiles = try fetchAllProfilesWithLegacyMigration()
        return profiles.first { $0.id == userId }
    }

    func fetchUserProfile(displayName: String) async throws -> UserProfile? {
        let normalizedName = displayName.normalizedForLookup
        let profiles = try fetchAllProfilesWithLegacyMigration()
        return profiles.first { $0.displayName.normalizedForLookup == normalizedName }
    }

    func fetchUserProfiles() async throws -> [UserProfile] {
        try fetchAllProfilesWithLegacyMigration()
            .sorted { $0.createdAt < $1.createdAt }
    }

    private func fetchAllProfilesWithLegacyMigration() throws -> [UserProfile] {
        if let profiles = try read([UserProfile].self, from: usersURL) {
            return profiles
        }

        guard let legacyProfile = try read(UserProfile.self, from: profileURL) else {
            return []
        }

        let profiles = [legacyProfile]
        try write(profiles, to: usersURL)
        return profiles
    }

    // MARK: - Streak

    func saveStreak(_ streak: Streak) async throws {
        var streaks = (try read([Streak].self, from: streaksURL)) ?? []
        if let index = streaks.firstIndex(where: { $0.userId == streak.userId }) {
            streaks[index] = streak
        } else {
            streaks.append(streak)
        }
        try write(streaks, to: streaksURL)
    }

    func fetchStreak(forUserId userId: String) async throws -> Streak? {
        let streaks = (try read([Streak].self, from: streaksURL)) ?? []
        return streaks.first { $0.userId == userId }
    }

    // MARK: - Daily Journal

    func saveDailyJournal(_ journal: DailyJournal) async throws {
        var journals = (try read([DailyJournal].self, from: dailyJournalsURL)) ?? []
        let calendar = Calendar.current

        if let index = journals.firstIndex(where: {
            $0.userId == journal.userId && calendar.isDate($0.date, inSameDayAs: journal.date)
        }) {
            journals[index] = journal
        } else {
            journals.append(journal)
        }

        try write(journals, to: dailyJournalsURL)
    }

    func fetchDailyJournals(forUserId userId: String) async throws -> [DailyJournal] {
        let journals = (try read([DailyJournal].self, from: dailyJournalsURL)) ?? []
        return journals
            .filter { $0.userId == userId }
            .sorted { $0.date > $1.date }
    }

    func fetchDailyJournal(forUserId userId: String, on date: Date) async throws -> DailyJournal? {
        let calendar = Calendar.current
        let journals = try await fetchDailyJournals(forUserId: userId)
        return journals.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

private extension String {
    var normalizedForLookup: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}
