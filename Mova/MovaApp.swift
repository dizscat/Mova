//
//  MovaApp.swift
//  Mova
//
//  Created by 18 on 2026/6/18.
//

import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct MovaApp: App {
    init() {
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #endif

        MovaChrome.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
