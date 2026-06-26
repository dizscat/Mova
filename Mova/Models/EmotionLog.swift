//
//  EmotionLog.swift
//  Mova
//
//  Satu entri "emotion journal" — disimpan sebagai JSON lokal (nanti Firestore).
//

import Foundation
import CoreGraphics

enum DetectionSource: String, Codable {
    case coreML
    case demoVision
    case mock
    case unknown

    var displayName: String {
        switch self {
        case .coreML: return "Core ML"
        case .demoVision: return "Demo Vision"
        case .mock: return "Mock"
        case .unknown: return "Legacy"
        }
    }

    var isDemoData: Bool {
        self == .demoVision || self == .mock
    }
}

struct NormalizedFaceBounds: Codable, Equatable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    init(rect: CGRect) {
        self.init(
            x: Double(rect.origin.x),
            y: Double(rect.origin.y),
            width: Double(rect.size.width),
            height: Double(rect.size.height)
        )
    }
}

struct FaceTrackingSnapshot: Codable, Equatable {
    let normalizedBounds: NormalizedFaceBounds
    let landmarkConfidence: Double
}

struct EmotionLog: Identifiable, Codable {
    let id: String
    let userId: String
    let emotion: EmotionType
    let confidence: Double
    let timestamp: Date
    let recommendedGenre: String
    let musicMoodId: String?
    let detectionSource: DetectionSource
    let faceTracking: FaceTrackingSnapshot?

    init(
        id: String = UUID().uuidString,
        userId: String,
        emotion: EmotionType,
        confidence: Double,
        timestamp: Date = Date(),
        recommendedGenre: String,
        musicMoodId: String? = nil,
        detectionSource: DetectionSource = .unknown,
        faceTracking: FaceTrackingSnapshot? = nil
    ) {
        self.id = id
        self.userId = userId
        self.emotion = emotion
        self.confidence = confidence
        self.timestamp = timestamp
        self.recommendedGenre = recommendedGenre
        self.musicMoodId = musicMoodId
        self.detectionSource = detectionSource
        self.faceTracking = faceTracking
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case emotion
        case confidence
        case timestamp
        case recommendedGenre
        case musicMoodId
        case detectionSource
        case faceTracking
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        emotion = try container.decode(EmotionType.self, forKey: .emotion)
        confidence = try container.decode(Double.self, forKey: .confidence)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        recommendedGenre = try container.decode(String.self, forKey: .recommendedGenre)
        musicMoodId = try container.decodeIfPresent(String.self, forKey: .musicMoodId)
        detectionSource = try container.decodeIfPresent(DetectionSource.self, forKey: .detectionSource) ?? .unknown
        faceTracking = try container.decodeIfPresent(FaceTrackingSnapshot.self, forKey: .faceTracking)
    }
}
