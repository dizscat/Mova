//
//  PersistenceManager.swift
//  Mova
//
//  Single source of truth yang dipakai seluruh ViewModel. ViewModel TIDAK
//  pernah menyentuh LocalStorageService secara langsung — hanya lewat
//  `PersistenceManager.shared.service`. Local JSON tetap menjadi fallback,
//  sedangkan Firestore bisa diaktifkan tanpa mengubah ViewModel/View.
//

import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

final class PersistenceManager {
    static let shared = PersistenceManager()

    let service: PersistenceServiceProtocol

    private init() {
        #if canImport(FirebaseFirestore)
        if FirebaseRuntimeConfig.useFirestore {
            service = FirestoreService.shared
            return
        }
        #endif

        service = LocalStorageService.shared
    }
}

enum FirebaseRuntimeConfig {
    static var useFirestore: Bool {
        if let value = ProcessInfo.processInfo.environment["MOVA_USE_FIRESTORE"] {
            return value.isTruthy
        }

        if let value = Bundle.main.object(forInfoDictionaryKey: "MovaUseFirestore") as? Bool {
            return value
        }

        if let value = Bundle.main.object(forInfoDictionaryKey: "MovaUseFirestore") as? String {
            return value.isTruthy
        }

        return false
    }
}

#if canImport(FirebaseFirestore)
final class FirestoreService: PersistenceServiceProtocol {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let calendar = Calendar.current

    private init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Emotion Logs

    func saveLog(_ log: EmotionLog) async throws {
        try await set(log, in: "emotionLogs", documentID: log.id)
    }

    func fetchLogs(forUserId userId: String) async throws -> [EmotionLog] {
        let logs: [EmotionLog] = try await fetchCollection("emotionLogs", userId: userId)
        return logs.sorted { $0.timestamp > $1.timestamp }
    }

    func fetchLogs(forUserId userId: String, since: Date) async throws -> [EmotionLog] {
        let logs = try await fetchLogs(forUserId: userId)
        return logs.filter { $0.timestamp >= since }
    }

    // MARK: - User Profile

    func saveUserProfile(_ profile: UserProfile) async throws {
        try await set(profile, in: "users", documentID: profile.id)
    }

    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        try await fetchDocument(UserProfile.self, in: "users", documentID: userId)
    }

    func fetchUserProfile(displayName: String) async throws -> UserProfile? {
        let normalizedName = displayName.normalizedForLookup
        let profiles = try await fetchUserProfiles()
        return profiles.first { $0.displayName.normalizedForLookup == normalizedName }
    }

    func fetchUserProfiles() async throws -> [UserProfile] {
        let profiles: [UserProfile] = try await fetchCollection("users")
        return profiles.sorted { $0.createdAt < $1.createdAt }
    }

    // MARK: - Streak

    func saveStreak(_ streak: Streak) async throws {
        try await set(streak, in: "streaks", documentID: streak.userId)
    }

    func fetchStreak(forUserId userId: String) async throws -> Streak? {
        try await fetchDocument(Streak.self, in: "streaks", documentID: userId)
    }

    // MARK: - Daily Journal

    func saveDailyJournal(_ journal: DailyJournal) async throws {
        let documentID = dailyJournalDocumentID(userId: journal.userId, date: journal.date)
        try await set(journal, in: "dailyJournals", documentID: documentID)
    }

    func fetchDailyJournals(forUserId userId: String) async throws -> [DailyJournal] {
        let journals: [DailyJournal] = try await fetchCollection("dailyJournals", userId: userId)
        return journals.sorted { $0.date > $1.date }
    }

    func fetchDailyJournal(forUserId userId: String, on date: Date) async throws -> DailyJournal? {
        let documentID = dailyJournalDocumentID(userId: userId, date: date)
        if let journal = try await fetchDocument(DailyJournal.self, in: "dailyJournals", documentID: documentID) {
            return journal
        }

        let journals = try await fetchDailyJournals(forUserId: userId)
        return journals.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Firestore helpers

    private func set<T: Encodable>(_ value: T, in collection: String, documentID: String) async throws {
        var dictionary = try dictionary(from: value)
        dictionary["updatedAtFirestore"] = FieldValue.serverTimestamp()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection(collection).document(documentID).setData(dictionary, merge: true) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func fetchCollection<T: Decodable>(_ collection: String, userId: String? = nil) async throws -> [T] {
        let query: Query
        if let userId {
            query = db.collection(collection).whereField("userId", isEqualTo: userId)
        } else {
            query = db.collection(collection)
        }

        let snapshot: QuerySnapshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<QuerySnapshot, Error>) in
            query.getDocuments { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: FirestoreServiceError.missingSnapshot)
                }
            }
        }

        return try snapshot.documents.compactMap { document in
            try decode(T.self, from: document.data())
        }
    }

    private func fetchDocument<T: Decodable>(_ type: T.Type, in collection: String, documentID: String) async throws -> T? {
        let snapshot: DocumentSnapshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DocumentSnapshot, Error>) in
            db.collection(collection).document(documentID).getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: FirestoreServiceError.missingSnapshot)
                }
            }
        }

        guard snapshot.exists, let data = snapshot.data() else { return nil }
        return try decode(T.self, from: data)
    }

    private func dictionary<T: Encodable>(from value: T) throws -> [String: Any] {
        let data = try encoder.encode(value)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FirestoreServiceError.encodingFailed
        }
        return dictionary
    }

    private func decode<T: Decodable>(_ type: T.Type, from dictionary: [String: Any]) throws -> T? {
        var firestoreSafeDictionary = dictionary
        firestoreSafeDictionary.removeValue(forKey: "updatedAtFirestore")

        let data = try JSONSerialization.data(withJSONObject: firestoreSafeDictionary)
        return try decoder.decode(type, from: data)
    }

    private func dailyJournalDocumentID(userId: String, date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return "\(userId)_\(year)-\(String(format: "%02d", month))-\(String(format: "%02d", day))"
    }
}

private enum FirestoreServiceError: Error {
    case encodingFailed
    case missingSnapshot
}
#endif

private extension String {
    var isTruthy: Bool {
        switch trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "true", "yes", "y", "on": return true
        default: return false
        }
    }

    var normalizedForLookup: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}
