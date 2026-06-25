//
//  PersistenceManager.swift
//  Mova
//
//  Single source of truth yang dipakai seluruh ViewModel. ViewModel TIDAK
//  pernah menyentuh LocalStorageService secara langsung — hanya lewat
//  `PersistenceManager.shared.service`. Untuk migrasi ke Firebase nanti,
//  cukup ganti satu baris di sini.
//

import Foundation

final class PersistenceManager {
    static let shared = PersistenceManager()

    /// Implementasi aktif. Ganti ke `FirestoreService.shared` di tahap akhir.
    let service: PersistenceServiceProtocol = LocalStorageService.shared

    private init() {}
}
