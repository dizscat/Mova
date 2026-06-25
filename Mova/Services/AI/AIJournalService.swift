//
//  AIJournalService.swift
//  Mova
//
//  Generates editable daily journal drafts with Groq when configured.
//  Falls back locally so the feature still works offline or without an API key.
//

import Foundation

struct JournalGenerationInput {
    let userKeywords: String
    let moodSummary: String
    let dominantEmotion: EmotionType?
    let date: Date
}

protocol JournalGenerationServiceProtocol {
    func generateDraft(from input: JournalGenerationInput) async throws -> String
}

final class AIJournalService: JournalGenerationServiceProtocol {

    static let shared = AIJournalService()

    private let endpoint = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
    private let model = "llama-3.3-70b-versatile"

    private let systemPrompt = """
    You are Mova's reflective daily journal assistant.
    Write in clear, natural English as a first-person journal draft.
    Use only the user's keywords and Mova's mood summary.
    If the user's keywords are not English, interpret them and write the final journal in English.
    Do not copy the keyword list verbatim, do not wrap keywords in parentheses, and do not write a "keywords" sentence.
    Weave the meaning of the keywords naturally into the reflection only when it helps.
    Do not invent events, names, diagnoses, or psychological claims.
    Keep the tone warm, grounded, and easy to edit.
    Return only the journal draft, with no title, no markdown, and no explanation.
    """

    private init() {}

    func generateDraft(from input: JournalGenerationInput) async throws -> String {
        guard let apiKey = Self.groqAPIKey else {
            return generateLocalDraft(input)
        }

        do {
            return try await generateGroqDraft(input: input, apiKey: apiKey)
        } catch {
            print("AIJournalService Groq error: \(error.localizedDescription)")
            return generateLocalDraft(input)
        }
    }

    private static var groqAPIKey: String? {
        if let environmentKey = ProcessInfo.processInfo.environment["MOVA_GROQ_API_KEY"]?.nonEmptyTrimmed {
            return environmentKey
        }

        if let infoKey = Bundle.main.object(forInfoDictionaryKey: "MovaGroqAPIKey") as? String,
           let trimmed = infoKey.nonEmptyTrimmed,
           !trimmed.hasPrefix("$(") {
            return trimmed
        }

        guard let url = Bundle.main.url(forResource: "MovaSecrets", withExtension: "plist"),
              let dictionary = NSDictionary(contentsOf: url),
              let plistKey = dictionary["GroqAPIKey"] as? String else {
            return nil
        }

        return plistKey.nonEmptyTrimmed
    }

    private func generateGroqDraft(input: JournalGenerationInput, apiKey: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            GroqChatRequest(
                model: model,
                messages: [
                    GroqMessage(role: "system", content: systemPrompt),
                    GroqMessage(role: "user", content: makeUserPrompt(from: input))
                ],
                temperature: 0.72,
                maxCompletionTokens: 520
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Groq request failed."
            throw AIJournalError.remoteFailure(statusCode: httpResponse.statusCode, message: message)
        }

        let decoded = try JSONDecoder().decode(GroqChatResponse.self, from: data)
        guard let draft = decoded.choices.first?.message.content.nonEmptyTrimmed else {
            throw AIJournalError.emptyResponse
        }
        return draft
    }

    private func makeUserPrompt(from input: JournalGenerationInput) -> String {
        let date = Self.dateFormatter.string(from: input.date)
        let dominantEmotion = input.dominantEmotion?.displayName ?? "Not enough data"

        return """
        Date: \(date)
        User keywords: \(input.userKeywords)
        Mova mood summary: \(input.moodSummary)
        Dominant detected emotion: \(dominantEmotion)

        Create a gentle first-person daily journal draft in English.
        Structure it as 2 short paragraphs.
        Do not quote or list the raw keywords.
        Mention uncertainty carefully when the mood data is limited.
        End with one small, realistic intention for tomorrow.
        """
    }

    private func generateLocalDraft(_ input: JournalGenerationInput) -> String {
        let keywords = input.userKeywords
            .split { character in
                character == "," || character == "\n" || character == ";"
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let keywordSentence = makeNaturalKeywordSentence(from: keywords)

        let moodSentence: String
        if let dominantEmotion = input.dominantEmotion {
            moodSentence = "From my mood check-ins, the emotion that appeared most often was \(dominantEmotion.displayName.lowercased()). \(input.moodSummary)"
        } else {
            moodSentence = input.moodSummary.isEmpty
                ? "There is not much mood data recorded for today yet."
                : input.moodSummary
        }

        return """
        Today feels like something I should understand slowly rather than rush through. \(keywordSentence)

        \(moodSentence)

        Looking back, I want to acknowledge what I went through instead of brushing past it. Tomorrow, I can start small by giving myself one quiet pause and choosing one thing that makes the day feel a little lighter.
        """
    }

    private func makeNaturalKeywordSentence(from keywords: [String]) -> String {
        guard !keywords.isEmpty else {
            return "I did not write many details about today yet."
        }

        let normalized = Set(
            keywords.map {
                $0.lowercased()
                    .trimmingCharacters(in: CharacterSet(charactersIn: ".!?()[]{} "))
            }
        )

        var themes: [String] = []
        if !normalized.isDisjoint(with: ["makan", "eat", "eating", "food", "meal"]) {
            themes.append("basic needs")
        }
        if !normalized.isDisjoint(with: ["tidur", "sleep", "sleeping", "rest"]) {
            themes.append("rest")
        }
        if !normalized.isDisjoint(with: ["kerja", "work", "working", "job"]) {
            themes.append("work")
        }
        if !normalized.isDisjoint(with: ["lelah", "capek", "tired", "exhausted", "fatigue"]) {
            themes.append("tiredness")
        }

        if themes.isEmpty {
            return "The details I wrote point to a day that had a few things worth slowing down for."
        }

        let readableThemes = themes.joined(separator: ", ")
        return "The details I wrote point to \(readableThemes), and I want to notice what those parts of the day were asking from me."
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

private struct GroqChatRequest: Encodable {
    let model: String
    let messages: [GroqMessage]
    let temperature: Double
    let maxCompletionTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxCompletionTokens = "max_completion_tokens"
    }
}

private struct GroqMessage: Codable {
    let role: String
    let content: String
}

private struct GroqChatResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: GroqMessage
    }
}

private enum AIJournalError: LocalizedError {
    case emptyResponse
    case remoteFailure(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "Groq returned an empty journal draft."
        case .remoteFailure(let statusCode, let message):
            return "Groq request failed with status \(statusCode): \(message)"
        }
    }
}

private extension String {
    var nonEmptyTrimmed: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
