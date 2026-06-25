//
//  RootView.swift
//  Mova
//
//  Titik masuk UI: tampilkan LoginView bila belum login, atau TabView 4 tab
//  bila sudah login.
//

import SwiftUI

struct RootView: View {

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
                mainTabs
            } else {
                LoginView(authViewModel: authViewModel)
            }
        }
        .environmentObject(appState)
        // Jaga agar userId aktif selalu sinkron dengan status auth.
        .onChange(of: authViewModel.currentUserId) { newValue in
            appState.currentUserId = newValue
        }
        .onAppear {
            appState.currentUserId = authViewModel.currentUserId
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            DashboardView(
                displayName: authViewModel.displayName,
                selectedTab: $selectedTab
            )
            .tabItem { Label("Home", systemImage: "sparkles") }
            .tag(0)

            DetectionView()
                .tabItem { Label("Detect", systemImage: "camera.fill") }
                .tag(1)

            // Tab musik mandiri menampilkan rekomendasi untuk emosi default.
            MusicRecommendationView(emotion: .neutral)
                .tabItem { Label("Music", systemImage: "music.note") }
                .tag(2)

            JournalView()
                .tabItem { Label("Journal", systemImage: "book.fill") }
                .tag(3)

            ProfileView(authViewModel: authViewModel)
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(4)
        }
        .tint(Color(red: 0.20, green: 0.72, blue: 0.76))
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
