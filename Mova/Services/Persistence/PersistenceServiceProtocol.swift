//
//  PersistenceServiceProtocol.swift
//  Mova
//
//  Persistence abstraction. The current implementation is
//  `LocalStorageService` (FileManager + JSON / UserDefaults).
//
//  Later, `FirestoreService` can implement this same protocol, including
//  Daily Journal methods, so ViewModels/Views do not need to change.
//  The app only swaps the concrete service in `PersistenceManager`.
//

import Foundation

protocol PersistenceServiceProtocol {
    // MARK: - Emotion Logs
    func saveLog(_ log: EmotionLog) async throws
    func fetchLogs(forUserId userId: String) async throws -> [EmotionLog]
    func fetchLogs(forUserId userId: String, since: Date) async throws -> [EmotionLog]

    // MARK: - User Profile
    func saveUserProfile(_ profile: UserProfile) async throws
    func fetchUserProfile(userId: String) async throws -> UserProfile?
    func fetchUserProfile(displayName: String) async throws -> UserProfile?
    func fetchUserProfiles() async throws -> [UserProfile]

    // MARK: - Streak
    func saveStreak(_ streak: Streak) async throws
    func fetchStreak(forUserId userId: String) async throws -> Streak?

    // MARK: - Daily Journal
    func saveDailyJournal(_ journal: DailyJournal) async throws
    func fetchDailyJournals(forUserId userId: String) async throws -> [DailyJournal]
    func fetchDailyJournal(forUserId userId: String, on date: Date) async throws -> DailyJournal?
}
