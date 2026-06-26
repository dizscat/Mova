//
//  DetectionViewModel.swift
//  Mova
//
//  Mengorkestrasi: CameraManager -> FaceLandmarkDetector -> EmotionClassifier,
//  lalu mempublikasikan emosi terkini ke View dan menyimpan EmotionLog.
//

import Foundation
import Combine
import CoreVideo

@MainActor
final class DetectionViewModel: ObservableObject {

    @Published var currentEmotion: EmotionType?
    @Published var confidence: Double = 0
    @Published var isDetecting: Bool = false
    @Published var faceDetected: Bool = false
    @Published var faceBounds: NormalizedFaceBounds?
    @Published var landmarkConfidence: Double = 0
    @Published var detectionSource: DetectionSource = .unknown

    // Service yang dimiliki ViewModel.
    let cameraManager = CameraManager()
    private let faceDetector = FaceLandmarkDetector()
    private let classifier = EmotionClassifier()

    private let service = PersistenceManager.shared.service
    private var cancellables = Set<AnyCancellable>()
    private var isProcessingFrame = false

    init() {
        // Setiap frame baru dari kamera -> proses deteksi.
        cameraManager.$currentFrame
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] buffer in
                self?.process(buffer)
            }
            .store(in: &cancellables)
    }

    // MARK: - Control

    func startDetection() {
        isDetecting = true
        cameraManager.startSession()
    }

    func stopDetection() {
        isDetecting = false
        cameraManager.stopSession()
    }

    // MARK: - Pipeline

    private func process(_ pixelBuffer: CVPixelBuffer) {
        guard isDetecting, !isProcessingFrame else { return }
        isProcessingFrame = true

        faceDetector.detectFace(in: pixelBuffer) { [weak self] face in
            guard let self = self else { return }

            guard face != nil else {
                Task { @MainActor in
                    self.faceDetected = false
                    self.faceBounds = nil
                    self.landmarkConfidence = 0
                    self.currentEmotion = nil
                    self.confidence = 0
                    self.detectionSource = .unknown
                    self.isProcessingFrame = false
                }
                return
            }

            let bounds = NormalizedFaceBounds(rect: face!.boundingBox)
            let faceConfidence = Double(face!.confidence)

            // Wajah terdeteksi -> klasifikasi emosi. Dalam Demo Mode, Vision
            // tetap melacak wajah, tetapi label emosi berasal dari demo classifier.
            self.classifier.classify(pixelBuffer: pixelBuffer) { result in
                Task { @MainActor in
                    self.faceDetected = true
                    self.faceBounds = bounds
                    self.landmarkConfidence = faceConfidence
                    self.currentEmotion = result.emotion
                    self.confidence = result.confidence
                    self.detectionSource = result.source
                    self.isProcessingFrame = false
                }
            }
        }
    }

    // MARK: - Persistence

    /// Simpan deteksi terkini sebagai EmotionLog. Kembalikan emosi yang disimpan
    /// agar View bisa langsung menampilkan rekomendasi musik.
    @discardableResult
    func saveCurrentDetection(userId: String) async -> EmotionType? {
        guard let emotion = currentEmotion else { return nil }

        let recommendation = MusicMapper.recommendation(for: emotion)
        let log = EmotionLog(
            userId: userId,
            emotion: emotion,
            confidence: confidence,
            recommendedGenre: recommendation.genre,
            musicMoodId: recommendation.id,
            detectionSource: detectionSource,
            faceTracking: faceBounds.map {
                FaceTrackingSnapshot(
                    normalizedBounds: $0,
                    landmarkConfidence: landmarkConfidence
                )
            }
        )

        do {
            try await service.saveLog(log)
        } catch {
            print("DetectionViewModel save error: \(error.localizedDescription)")
        }
        return emotion
    }
}
