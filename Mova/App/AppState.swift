//
//  AppState.swift
//  Mova
//
//  Shared state lintas tab. Minimal dulu: hanya menyimpan userId aktif agar
//  setiap tab bisa memuat data milik user yang benar.
//

import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var currentUserId: String?
}
