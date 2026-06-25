//
//  UserProfile.swift
//  Mova
//
//  Profil "local account" — disimpan di UserDefaults/JSON (tanpa password).
//

import Foundation

struct UserProfile: Identifiable, Codable {
    let id: String
    let displayName: String
    let email: String
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        displayName: String,
        email: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.createdAt = createdAt
    }
}
