//
//  DailyJournalView.swift
//  Mova
//
//  Layar pembuatan jurnal harian dari kata kunci dan data mood.
//

import SwiftUI

struct DailyJournalView: View {

    @StateObject private var viewModel = DailyJournalViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        ZStack {
            MovaAmbientBackground()

            List {
                Section("Today's Mood") {
                    MovaGlassCard {
                        HStack(spacing: 12) {
                            MovaIconBadge(systemName: "waveform.path.ecg")
                            Text(viewModel.moodSummary)
                                .font(.subheadline)
                                .foregroundColor(MovaTimeMood.current.secondaryForeground)
                        }
                    }
                    .listRowBackground(Color.clear)

                    if viewModel.hasSavedJournalForToday {
                        Button {
                            viewModel.loadSavedJournalForToday()
                        } label: {
                            Label("Load Today's Saved Journal", systemImage: "clock.arrow.circlepath")
                        }
                        .buttonStyle(MovaSecondaryButtonStyle())
                        .listRowBackground(Color.clear)
                    }
                }

                Section("Keywords") {
                    textEditor(
                        text: $viewModel.keywords,
                        placeholder: "Example: tired, work, sleep, deadline pressure",
                        minHeight: 90
                    )
                    .listRowBackground(Color.clear)

                    Button {
                        Task { await viewModel.generateDraft(userId: currentUserId) }
                    } label: {
                        Label(
                            viewModel.isGenerating ? "Generating Draft..." : "Generate Draft",
                            systemImage: "sparkles"
                        )
                    }
                    .buttonStyle(MovaPrimaryButtonStyle())
                    .disabled(viewModel.isGenerating)
                    .listRowBackground(Color.clear)
                }

                Section("Journal Draft") {
                    textEditor(
                        text: $viewModel.draftText,
                        placeholder: "Your editable journal draft will appear here.",
                        minHeight: 220
                    )
                    .listRowBackground(Color.clear)

                    Button {
                        Task { await viewModel.save(userId: currentUserId) }
                    } label: {
                        Label("Save Journal", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(MovaSecondaryButtonStyle())
                    .disabled(viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .listRowBackground(Color.clear)
                }

                if let message = viewModel.statusMessage {
                    Section {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .listRowBackground(Color.clear)
                }

                if let message = viewModel.errorMessage {
                    Section {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Journal History") {
                    if viewModel.savedJournals.isEmpty {
                        Text("No daily journals yet.")
                            .foregroundColor(.secondary)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(viewModel.savedJournals) { journal in
                            MovaGlassCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(Self.dateFormatter.string(from: journal.date))
                                        .font(.caption.bold())
                                        .foregroundColor(MovaTimeMood.current.secondaryForeground)
                                    Text(journal.finalText)
                                        .font(.subheadline)
                                        .foregroundColor(MovaTimeMood.current.foreground)
                                        .lineLimit(3)
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                }
            }
            .movaListStyle()
        }
        .navigationTitle("Daily AI Journal")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label("Close", systemImage: "xmark")
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.startFreshDraft()
                } label: {
                    Label("New Draft", systemImage: "plus")
                }
            }
        }
        .task { await viewModel.load(userId: currentUserId) }
    }

    private var currentUserId: String {
        appState.currentUserId ?? "local"
    }

    private func textEditor(
        text: Binding<String>,
        placeholder: String,
        minHeight: CGFloat
    ) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .foregroundColor(MovaTimeMood.current.secondaryForeground)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
            }

            TextEditor(text: text)
                .frame(minHeight: minHeight)
                .scrollContentBackground(.hidden)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

struct DailyJournalView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DailyJournalView()
                .environmentObject(AppState())
        }
    }
}
