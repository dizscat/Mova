//
//  DailyJournalViewModel.swift
//  Mova
//
//  Mengelola input kata kunci, draft AI, dan penyimpanan jurnal harian.
//

import Foundation
import Combine

@MainActor
final class DailyJournalViewModel: ObservableObject {

    @Published var keywords: String = ""
    @Published var draftText: String = ""
    @Published var moodSummary: String = "No mood has been recorded today yet."
    @Published var savedJournals: [DailyJournal] = []
    @Published var isGenerating: Bool = false
    @Published var statusMessage: String?
    @Published var errorMessage: String?
    @Published var hasSavedJournalForToday: Bool = false

    private let service = PersistenceManager.shared.service
    private let generator: JournalGenerationServiceProtocol
    private var todayLogs: [EmotionLog] = []
    private var currentJournal: DailyJournal?
    private var latestGeneratedDraft: String?

    init(generator: JournalGenerationServiceProtocol = AIJournalService.shared) {
        self.generator = generator
    }

    func load(userId: String) async {
        do {
            todayLogs = try await service.fetchLogs(forUserId: userId)
                .filter { Calendar.current.isDateInToday($0.timestamp) }
            savedJournals = try await service.fetchDailyJournals(forUserId: userId)
            currentJournal = try await service.fetchDailyJournal(forUserId: userId, on: Date())
            hasSavedJournalForToday = currentJournal != nil
            moodSummary = makeMoodSummary(from: todayLogs)
        } catch {
            errorMessage = "Failed to load your daily journal."
            print("DailyJournalViewModel load error: \(error.localizedDescription)")
        }
    }

    func loadSavedJournalForToday() {
        guard let currentJournal else { return }
        keywords = currentJournal.userKeywords
        draftText = currentJournal.finalText
        latestGeneratedDraft = currentJournal.aiDraft
        statusMessage = "Saved journal loaded."
        errorMessage = nil
    }

    func startFreshDraft() {
        keywords = ""
        draftText = ""
        latestGeneratedDraft = nil
        statusMessage = "Fresh draft started."
        errorMessage = nil
    }

    func generateDraft(userId: String) async {
        let trimmedKeywords = keywords.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeywords.isEmpty else {
            errorMessage = "Write a few keywords first."
            return
        }

        isGenerating = true
        errorMessage = nil
        statusMessage = nil

        do {
            let input = JournalGenerationInput(
                userKeywords: trimmedKeywords,
                moodSummary: moodSummary,
                dominantEmotion: dominantEmotion(from: todayLogs),
                date: Date()
            )
            let generatedDraft = try await generator.generateDraft(from: input)
            latestGeneratedDraft = generatedDraft
            draftText = generatedDraft
            statusMessage = "Draft is ready to edit."
        } catch {
            errorMessage = "Failed to generate the journal draft."
            print("DailyJournalViewModel generate error: \(error.localizedDescription)")
        }

        isGenerating = false
    }

    func save(userId: String) async {
        let trimmedKeywords = keywords.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDraft = draftText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedDraft.isEmpty else {
            errorMessage = "The draft is still empty."
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let createdAt = currentJournal?.createdAt ?? now
        let journal = DailyJournal(
            id: currentJournal?.id ?? UUID().uuidString,
            userId: userId,
            date: calendar.startOfDay(for: now),
            userKeywords: trimmedKeywords,
            moodSummary: moodSummary,
            aiDraft: latestGeneratedDraft ?? currentJournal?.aiDraft ?? trimmedDraft,
            finalText: trimmedDraft,
            createdAt: createdAt,
            updatedAt: now
        )

        do {
            try await service.saveDailyJournal(journal)
            currentJournal = journal
            savedJournals = try await service.fetchDailyJournals(forUserId: userId)
            statusMessage = "Journal saved."
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save the journal."
            print("DailyJournalViewModel save error: \(error.localizedDescription)")
        }
    }

    private func makeMoodSummary(from logs: [EmotionLog]) -> String {
        guard !logs.isEmpty else {
            return "No mood has been recorded today yet."
        }

        var counts: [EmotionType: Int] = [:]
        for log in logs {
            counts[log.emotion, default: 0] += 1
        }

        let parts = EmotionType.allCases.compactMap { emotion -> String? in
            guard let count = counts[emotion], count > 0 else { return nil }
            return "\(emotion.displayName.lowercased()) \(count)x"
        }

        let demoCount = logs.filter { $0.detectionSource.isDemoData }.count
        let sourceNote: String
        if demoCount == logs.count {
            sourceNote = " All entries came from Demo Vision mode."
        } else if demoCount > 0 {
            sourceNote = " \(demoCount) entries came from Demo Vision mode."
        } else {
            sourceNote = ""
        }

        return "Today's mood was recorded \(logs.count)x: \(parts.joined(separator: ", ")).\(sourceNote)"
    }

    private func dominantEmotion(from logs: [EmotionLog]) -> EmotionType? {
        var counts: [EmotionType: Int] = [:]
        for log in logs {
            counts[log.emotion, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }?.key
    }
}
