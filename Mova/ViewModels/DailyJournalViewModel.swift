//
//  DailyJournalViewModel.swift
//  Mova
//
//  Mengelola input kata kunci, draft AI, dan penyimpanan jurnal harian.
//

import Foundation
import Combine
import AVFoundation

@MainActor
final class DailyJournalViewModel: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

    @Published var keywords: String = ""
    @Published var draftText: String = ""
    @Published var moodSummary: String = "No mood has been recorded today yet."
    @Published var savedJournals: [DailyJournal] = []
    @Published var isGenerating: Bool = false
    @Published var statusMessage: String?
    @Published var errorMessage: String?
    @Published var hasSavedJournalForToday: Bool = false
    @Published var isReadingJournal: Bool = false

    private let service = PersistenceManager.shared.service
    private let generator: JournalGenerationServiceProtocol
    private var todayLogs: [EmotionLog] = []
    private var currentJournal: DailyJournal?
    private var latestGeneratedDraft: String?
    private let speechSynthesizer = AVSpeechSynthesizer()

    init(generator: JournalGenerationServiceProtocol = AIJournalService.shared) {
        self.generator = generator
        super.init()
        speechSynthesizer.delegate = self
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

    func readJournalAloud() {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            errorMessage = "Write or generate a journal first."
            return
        }

        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier = 0.96
        utterance.volume = 0.95

        isReadingJournal = true
        statusMessage = "Reading your journal aloud."
        errorMessage = nil
        speechSynthesizer.speak(utterance)
    }

    func pauseJournalReading() {
        guard speechSynthesizer.isSpeaking else { return }
        speechSynthesizer.pauseSpeaking(at: .word)
        isReadingJournal = false
        statusMessage = "Journal reading paused."
    }

    func stopJournalReading() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        isReadingJournal = false
        statusMessage = "Journal reading stopped."
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isReadingJournal = false
            self.statusMessage = "Finished reading your journal."
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isReadingJournal = false
        }
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
