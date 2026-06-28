//
//  AuthViewModel.swift
//  Mova
//
//  Saat MOVA_USE_FIRESTORE aktif, auth memakai Firebase Auth (email/password)
//  dan profil tersimpan di Firestore dengan document ID = Firebase UID.
//  Saat Firestore tidak aktif, auth jatuh kembali ke mode lokal lama
//  (nama saja, tanpa password) supaya app tetap bisa dipakai tanpa Firebase.
//

import Foundation
import Combine
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var displayName: String = ""
    @Published var isLoggedIn: Bool = false
    @Published private(set) var currentUserId: String?
    @Published var errorMessage: String?
    @Published var isProcessing: Bool = false

    let usesFirebaseAuth: Bool = FirebaseRuntimeConfig.useFirestore

    private let service = PersistenceManager.shared.service
    private let userIdKey = "mova.currentUserId"

    #if canImport(FirebaseAuth)
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    #endif

    init() {
        #if canImport(FirebaseAuth)
        if usesFirebaseAuth {
            authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                guard let self else { return }
                Task { @MainActor in
                    if let user {
                        await self.restoreProfile(userId: user.uid)
                    } else {
                        self.currentUserId = nil
                        self.displayName = ""
                        self.isLoggedIn = false
                    }
                }
            }
            return
        }
        #endif

        // Fallback lokal: restore status login dari UserDefaults + persistence.
        if let savedId = UserDefaults.standard.string(forKey: userIdKey) {
            currentUserId = savedId
            Task { await restoreProfile(userId: savedId) }
        }
    }

    deinit {
        #if canImport(FirebaseAuth)
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
        #endif
    }

    private func restoreProfile(userId: String) async {
        do {
            if let profile = try await service.fetchUserProfile(userId: userId) {
                displayName = profile.displayName
                currentUserId = profile.id
                isLoggedIn = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Login lokal tanpa password — dipakai hanya saat Firestore/Firebase Auth tidak aktif.
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
                errorMessage = error.localizedDescription
                print("AuthViewModel login error: \(error.localizedDescription)")
            }
        }
    }

    /// Registrasi akun asli lewat Firebase Auth. Profil baru disimpan ke Firestore
    /// dengan document ID = Firebase UID, supaya konsisten dengan Security Rules
    /// yang membandingkan `request.auth.uid`.
    func register(displayName: String, email: String, password: String) async {
        #if canImport(FirebaseAuth)
        guard usesFirebaseAuth else {
            errorMessage = "Firestore mode is not enabled (set MOVA_USE_FIRESTORE=YES)."
            return
        }

        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Fill in your name, email, and password first."
            return
        }

        isProcessing = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().createUser(withEmail: trimmedEmail, password: password)
            let profile = UserProfile(id: result.user.uid, displayName: trimmedName, email: trimmedEmail)
            try await service.saveUserProfile(profile)
            currentUserId = profile.id
            self.displayName = profile.displayName
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
        #else
        errorMessage = "Firebase Auth is not available in this build."
        #endif
    }

    /// Sign in akun yang sudah terdaftar lewat Firebase Auth.
    func signIn(email: String, password: String) async {
        #if canImport(FirebaseAuth)
        guard usesFirebaseAuth else {
            errorMessage = "Firestore mode is not enabled (set MOVA_USE_FIRESTORE=YES)."
            return
        }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Enter your email and password."
            return
        }

        isProcessing = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().signIn(withEmail: trimmedEmail, password: password)
            await restoreProfile(userId: result.user.uid)
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
        #else
        errorMessage = "Firebase Auth is not available in this build."
        #endif
    }

    func logout() {
        #if canImport(FirebaseAuth)
        if usesFirebaseAuth {
            try? Auth.auth().signOut()
            return
        }
        #endif

        UserDefaults.standard.removeObject(forKey: userIdKey)
        currentUserId = nil
        displayName = ""
        isLoggedIn = false
    }
}
