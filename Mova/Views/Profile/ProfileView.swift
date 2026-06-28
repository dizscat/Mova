//
//  ProfileView.swift
//  Mova
//
//  Ringkasan identitas, aktivitas mood, pola emosi, dan privasi pengguna.
//

import SwiftUI

struct ProfileView: View {

    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var appState: AppState

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationView {
            ZStack {
                MovaAmbientBackground()

                List {
                    profileHeader
                    quickStatsSection
                    moodPatternSection
                    privacySection
                    logoutSection
                }
                .movaListStyle()
            }
            .navigationTitle("Profile")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var profileHeader: some View {
        Section {
            MovaGlassCard {
                HStack(spacing: 14) {
                    MovaIconBadge(systemName: "person.crop.circle.fill")

                    VStack(alignment: .leading, spacing: 5) {
                        Text(authViewModel.displayName.isEmpty ? "Mova User" : authViewModel.displayName)
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundColor(MovaTimeMood.current.foreground)
                        Text(authViewModel.usesFirebaseAuth ? "Cloud-connected mood profile" : "Local mood profile")
                            .font(.caption)
                            .foregroundColor(MovaTimeMood.current.secondaryForeground)
                    }

                    Spacer()
                }

                Text("This profile summarizes your mood check-ins and journals. Think of it as a small compass, not an emotional report card.")
                    .font(.subheadline)
                    .foregroundColor(MovaTimeMood.current.secondaryForeground)
                    .padding(.top, 10)
            }
            .listRowBackground(Color.clear)
        }
    }

    private var quickStatsSection: some View {
        Section("Summary") {
            HStack(spacing: 12) {
                statTile(title: "Today", value: "\(viewModel.todaySessions)", icon: "sun.max.fill")
                statTile(title: "Total", value: "\(viewModel.totalSessions)", icon: "chart.bar.fill")
            }
            .listRowBackground(Color.clear)

            HStack(spacing: 12) {
                statTile(title: "Journals", value: "\(viewModel.journalCount)", icon: "book.pages.fill")
                statTile(title: "Streak", value: "\(viewModel.currentStreak)d", icon: "flame.fill")
            }
            .listRowBackground(Color.clear)
        }
    }

    private var moodPatternSection: some View {
        Section("Mood Pattern") {
            MovaGlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    insightRow(
                        icon: "heart.fill",
                        title: "Dominant emotion",
                        value: viewModel.mostFrequentEmotion.map { "\($0.emoji) \($0.displayName)" } ?? "Not enough data yet"
                    )

                    Divider().opacity(0.28)

                    insightRow(
                        icon: "clock.fill",
                        title: "Last session",
                        value: viewModel.lastSessionDate.map { Self.dateFormatter.string(from: $0) } ?? "No detections yet"
                    )

                    Divider().opacity(0.28)

                    insightRow(
                        icon: "waveform.path.ecg.rectangle.fill",
                        title: "Detection data",
                        value: "Demo \(viewModel.demoSessions) / Core ML \(viewModel.realSessions)"
                    )

                    Text(patternHint)
                        .font(.caption)
                        .foregroundColor(MovaTimeMood.current.secondaryForeground)
                        .padding(.top, 4)
                }
            }
            .listRowBackground(Color.clear)
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            MovaGlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    insightRow(
                        icon: "lock.shield.fill",
                        title: "Face data",
                        value: "Processed on-device"
                    )
                    insightRow(
                        icon: "externaldrive.fill",
                        title: "Storage",
                        value: authViewModel.usesFirebaseAuth
                            ? "Auth via Firebase, logs and journals synced through Firestore"
                            : "Logs and journals are stored locally"
                    )
                }
            }
            .listRowBackground(Color.clear)
        }
    }

    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                authViewModel.logout()
            } label: {
                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .listRowBackground(Color.clear)
        }
    }

    private var patternHint: String {
        guard viewModel.totalSessions > 0 else {
            return "Start from the Detect tab when you are ready. The camera is not active on this page."
        }
        if viewModel.currentStreak > 1 {
            return "You have a \(viewModel.currentStreak)-day check-in rhythm. Slow and consistent counts."
        }
        return "Check in for a few more days so Mova can show a more meaningful pattern."
    }

    private func statTile(title: String, value: String, icon: String) -> some View {
        MovaGlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(MovaTimeMood.current.foreground)
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(MovaTimeMood.current.foreground)
                Text(title)
                    .font(.caption)
                    .foregroundColor(MovaTimeMood.current.secondaryForeground)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func insightRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(MovaTimeMood.current.foreground)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(MovaTimeMood.current.secondaryForeground)
                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundColor(MovaTimeMood.current.foreground)
            }

            Spacer()
        }
    }

    private func load() async {
        let userId = appState.currentUserId ?? "local"
        await viewModel.loadStats(userId: userId)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(authViewModel: AuthViewModel())
            .environmentObject(AppState())
    }
}
