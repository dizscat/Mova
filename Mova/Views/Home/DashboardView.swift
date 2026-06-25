//
//  DashboardView.swift
//  Mova
//
//  A calm landing page before the user chooses camera, music, or journaling.
//

import SwiftUI

struct DashboardView: View {

    let displayName: String
    @Binding var selectedTab: Int

    @EnvironmentObject private var appState: AppState
    @StateObject private var journalViewModel = JournalViewModel()
    @State private var showDailyJournal = false
    @State private var appeared = false

    private let secondaryColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                MovaAmbientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        heroCard
                            .padding(.top, 18)

                        primaryAction

                        LazyVGrid(columns: secondaryColumns, spacing: 12) {
                            actionCard(
                                title: "Write",
                                subtitle: "Turn messy thoughts into a draft.",
                                icon: "sparkles",
                                height: 148
                            ) {
                                showDailyJournal = true
                            }

                            actionCard(
                                title: "Music",
                                subtitle: "Open a calm default playlist.",
                                icon: "music.note",
                                height: 148
                            ) {
                                selectedTab = 2
                            }
                        }

                        rhythmCard
                        privacyStrip
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 108)
                }
                .safeAreaInset(edge: .top) {
                    Color.clear.frame(height: 4)
                }
            }
            .navigationBarHidden(true)
            .task { await load() }
            .onAppear {
                withAnimation(.spring(response: 0.58, dampingFraction: 0.86)) {
                    appeared = true
                }
            }
            .sheet(isPresented: $showDailyJournal) {
                NavigationView {
                    DailyJournalView()
                }
            }
        }
    }

    private var heroCard: some View {
        MovaGlassCard {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    MovaIconBadge(systemName: MovaTimeMood.current == .day ? "sun.max.fill" : "moon.stars.fill")
                    Spacer()
                    statusPill
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(greeting)
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundColor(MovaTimeMood.current.foreground)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text("No rush. Start with music, write a journal, or open the camera only when you feel ready.")
                        .font(.callout)
                        .lineSpacing(3)
                        .foregroundColor(MovaTimeMood.current.secondaryForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    heroMetric(
                        value: "\(journalViewModel.todayLogs.count)",
                        label: "logs today"
                    )
                    heroMetric(
                        value: journalViewModel.dominantEmotion?.displayName ?? "Quiet",
                        label: "dominant mood"
                    )
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 18)
    }

    private var statusPill: some View {
        Label("Camera off", systemImage: "eye.slash.fill")
            .font(.caption.weight(.semibold))
            .foregroundColor(MovaTimeMood.current.foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: Capsule())
    }

    private var primaryAction: some View {
        Button {
            selectedTab = 1
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Mood Detection")
                        .font(.headline)
                    Text("Open the front camera for a quick mood check.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.78))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 92)
            .background(MovaTimeMood.current.accentGradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: Color(red: 0.20, green: 0.72, blue: 0.76).opacity(0.28), radius: 24, x: 0, y: 14)
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    private var rhythmCard: some View {
        MovaGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Today's rhythm", systemImage: "waveform.path.ecg")
                    .font(.headline)
                    .foregroundColor(MovaTimeMood.current.foreground)

                Text(rhythmText)
                    .font(.subheadline)
                    .lineSpacing(3)
                    .foregroundColor(MovaTimeMood.current.secondaryForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
    }

    private var privacyStrip: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .foregroundColor(MovaTimeMood.current.foreground)
            Text("Face data stays on your device. The camera only starts from Detect.")
                .font(.caption)
                .foregroundColor(MovaTimeMood.current.secondaryForeground)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 28)
    }

    private var rhythmText: String {
        if let emotion = journalViewModel.dominantEmotion {
            return "Your check-ins lean \(emotion.displayName.lowercased()) today. If that feels accurate, use the journal to add context before jumping into music."
        }

        return "There is no mood data yet today. That is fine: Mova starts quiet, and you choose when to check in."
    }

    private var greeting: String {
        let name = displayName.isEmpty ? "there" : displayName
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 11 { return "Good morning, \(name)" }
        if hour < 17 { return "Good afternoon, \(name)" }
        return "Good evening, \(name)"
    }

    private func heroMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(MovaTimeMood.current.foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.caption)
                .foregroundColor(MovaTimeMood.current.secondaryForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func actionCard(
        title: String,
        subtitle: String,
        icon: String,
        height: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(MovaTimeMood.current.foreground)
                    .frame(width: 42, height: 42)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Spacer(minLength: 0)

                Text(title)
                    .font(.headline)
                    .foregroundColor(MovaTimeMood.current.foreground)
                Text(subtitle)
                    .font(.caption)
                    .lineLimit(3)
                    .foregroundColor(MovaTimeMood.current.secondaryForeground)
            }
            .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 22)
    }

    private func load() async {
        let userId = appState.currentUserId ?? "local"
        await journalViewModel.loadLogs(userId: userId)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(displayName: "Nasa", selectedTab: .constant(0))
            .environmentObject(AppState())
    }
}
