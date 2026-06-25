//
//  AuthViewModel.swift
//  Mova
//
//  Auth lokal sederhana (tanpa password). Profil disimpan via PersistenceManager,
//  dan userId di-cache di UserDefaults agar bisa di-restore saat app dibuka lagi.
//

import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var displayName: String = ""
    @Published var isLoggedIn: Bool = false
    @Published private(set) var currentUserId: String?

    private let service = PersistenceManager.shared.service
    private let userIdKey = "mova.currentUserId"

    init() {
        // Restore status login dari UserDefaults + persistence.
        if let savedId = UserDefaults.standard.string(forKey: userIdKey) {
            currentUserId = savedId
            Task { await restoreProfile(userId: savedId) }
        }
    }

    private func restoreProfile(userId: String) async {
        do {
            if let profile = try await service.fetchUserProfile(userId: userId) {
                displayName = profile.displayName
                isLoggedIn = true
            }
        } catch {
            print("AuthViewModel restore error: \(error.localizedDescription)")
        }
    }

    /// Login lokal: pakai profile lama bila nama sudah pernah dibuat.
    func login(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        Task {
            do {
                let profile = try await service.fetchUserProfile(displayName: trimmed)
                    ?? UserProfile(displayName: trimmed)

                try await service.saveUserProfile(profile)
                currentUserId = profile.id
                displayName = profile.displayName
                UserDefaults.standard.set(profile.id, forKey: userIdKey)
                isLoggedIn = true
            } catch {
                print("AuthViewModel login error: \(error.localizedDescription)")
            }
        }
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: userIdKey)
        currentUserId = nil
        displayName = ""
        isLoggedIn = false
    }
}
