//
//  JournalView.swift
//  Mova
//
//  Emotion journal: ringkasan mood, chart mingguan, dan riwayat deteksi.
//

import SwiftUI

struct JournalView: View {

    @StateObject private var viewModel = JournalViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var showDailyJournal = false

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
                    Section {
                        MovaGlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 12) {
                                    MovaIconBadge(systemName: "calendar")
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Today's Mood")
                                            .font(.headline)
                                            .foregroundColor(MovaTimeMood.current.foreground)
                                        Text(todaySummary)
                                            .font(.caption)
                                            .foregroundColor(MovaTimeMood.current.secondaryForeground)
                                    }
                                }

                                HStack(spacing: 12) {
                                    overviewTile(title: "Logs", value: "\(viewModel.todayLogs.count)")
                                    overviewTile(title: "Journals", value: "\(viewModel.dailyJournals.count)")
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        Button {
                            showDailyJournal = true
                        } label: {
                            HStack(spacing: 12) {
                                MovaIconBadge(systemName: "sparkles")
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Daily AI Journal")
                                        .font(.headline)
                                        .foregroundColor(MovaTimeMood.current.foreground)
                                    Text("Write keywords, generate a draft, edit it, then save.")
                                        .font(.caption)
                                        .foregroundColor(MovaTimeMood.current.secondaryForeground)
                                }
                                Spacer()
                                Image(systemName: "chevron.up.right")
                                    .foregroundColor(MovaTimeMood.current.secondaryForeground)
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        MovaGlassCard {
                            EmotionChartView(breakdown: viewModel.weeklyBreakdown)
                                .padding(.vertical, 2)
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section("Detection History") {
                        if viewModel.logs.isEmpty {
                            Text("No emotion logs yet.")
                                .foregroundColor(.secondary)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(Array(viewModel.logs.prefix(8))) { log in
                                MovaGlassCard {
                                    HStack(spacing: 12) {
                                        Text(log.emotion.emoji)
                                            .font(.title2)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(log.emotion.displayName)
                                                .font(.body.weight(.semibold))
                                                .foregroundColor(MovaTimeMood.current.foreground)
                                            Text(Self.dateFormatter.string(from: log.timestamp))
                                                .font(.caption)
                                                .foregroundColor(MovaTimeMood.current.secondaryForeground)
                                        }
                                        Spacer()
                                        Text("\(Int(log.confidence * 100))%")
                                            .font(.caption.bold())
                                            .foregroundColor(MovaTimeMood.current.secondaryForeground)
                                    }
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                }
                .movaListStyle()
            }
            .navigationTitle("Journal")
            .task { await load() }
            .refreshable { await load() }
            .sheet(isPresented: $showDailyJournal, onDismiss: {
                Task { await load() }
            }) {
                NavigationView {
                    DailyJournalView()
                }
            }
        }
    }

    private var todaySummary: String {
        if let emotion = viewModel.dominantEmotion {
            return "Dominant so far: \(emotion.displayName)."
        }
        return "No mood has been recorded yet."
    }

    private func overviewTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(MovaTimeMood.current.foreground)
            Text(title)
                .font(.caption)
                .foregroundColor(MovaTimeMood.current.secondaryForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func load() async {
        let userId = appState.currentUserId ?? "local"
        await viewModel.loadLogs(userId: userId)
    }
}

struct JournalView_Previews: PreviewProvider {
    static var previews: some View {
        JournalView()
            .environmentObject(AppState())
    }
}
