//
//  MovaApp.swift
//  Mova
//
//  Created by 18 on 2026/6/18.
//

import SwiftUI

@main
struct MovaApp: App {
    init() {
        MovaChrome.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
