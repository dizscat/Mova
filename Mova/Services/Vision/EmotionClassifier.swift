//
//  EmotionClassifier.swift
//  Mova
//
//  Klasifikasi emosi dari frame kamera menggunakan model Core ML
//  (FER2013, 7 kelas). Model di-bundle sebagai `EmotionClassifierModel.mlmodel`
//  (di-compile Xcode menjadi `EmotionClassifierModel.mlmodelc`). Bila model
//  tidak ditemukan di bundle, otomatis fallback ke `mockClassify`.
//
//  Catatan: nama model sengaja `EmotionClassifierModel` (bukan
//  `EmotionClassifier`) agar tidak bentrok dengan nama class service ini.
//

import Vision
import CoreML
import CoreVideo

struct EmotionClassification {
    let emotion: EmotionType?
    let confidence: Double
    let source: DetectionSource
}

final class EmotionClassifier {

    private var demoIndex = 0
    private var demoEmotion: EmotionType = .neutral
    private var demoConfidence: Double = 0.88
    private var lastDemoUpdate = Date.distantPast
    private let demoSequence: [(EmotionType, Double)] = [
        (.neutral, 0.88),
        (.happy, 0.92),
        (.sad, 0.84),
        (.surprised, 0.87),
        (.neutral, 0.90)
    ]

    static var isDemoModeEnabled: Bool {
        if let rawValue = ProcessInfo.processInfo.environment["MOVA_DEMO_EMOTION_MODE"] {
            return rawValue.isTruthy
        }

        if let rawValue = Bundle.main.object(forInfoDictionaryKey: "MovaDemoEmotionMode") as? String {
            return rawValue.isTruthy
        }

        return false
    }

    /// VNCoreMLModel di-load lazily dari bundle. Bernilai nil bila model belum
    /// ada (mis. saat di-build tanpa .mlmodel) → otomatis fallback ke mock.
    private lazy var visionModel: VNCoreMLModel? = {
        // Load via URL bundle agar tidak bergantung pada class hasil codegen
        // (menghindari konflik nama dengan class EmotionClassifier ini).
        guard let url = Bundle.main.url(forResource: "EmotionClassifierModel",
                                        withExtension: "mlmodelc") else {
            print("EmotionClassifierModel.mlmodelc tidak ditemukan di bundle — pakai mock.")
            return nil
        }
        do {
            let config = MLModelConfiguration()
            let coreMLModel = try MLModel(contentsOf: url, configuration: config)
            return try VNCoreMLModel(for: coreMLModel)
        } catch {
            print("Gagal load Core ML model: \(error)")
            return nil
        }
    }()

    // MARK: - Real classification (dipakai NANTI setelah model tersedia)

    /// Klasifikasi emosi nyata via Core ML. Saat model belum ada, otomatis
    /// fallback ke `mockClassify`.
    func classify(pixelBuffer: CVPixelBuffer,
                  completion: @escaping (EmotionClassification) -> Void) {

        if Self.isDemoModeEnabled {
            demoClassify(completion: completion)
            return
        }

        guard let visionModel = visionModel else {
            // Model belum tersedia → gunakan mock sementara.
            mockClassify(completion: completion)
            return
        }

        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let error = error {
                print("EmotionClassifier error: \(error.localizedDescription)")
                completion(EmotionClassification(emotion: nil, confidence: 0, source: .coreML))
                return
            }
            guard let results = request.results as? [VNClassificationObservation],
                  let top = results.first else {
                completion(EmotionClassification(emotion: nil, confidence: 0, source: .coreML))
                return
            }
            let emotion = Self.mapLabel(top.identifier)
            completion(EmotionClassification(emotion: emotion, confidence: Double(top.confidence), source: .coreML))
        }

        // Vision akan otomatis resize/crop sesuai input model.
        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .leftMirrored,
            options: [:]
        )

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("EmotionClassifier perform error: \(error.localizedDescription)")
                completion(EmotionClassification(emotion: nil, confidence: 0, source: .coreML))
            }
        }
    }

    /// Petakan label string keluaran model ke enum EmotionType.
    private static func mapLabel(_ label: String) -> EmotionType? {
        // Toleran terhadap variasi penamaan label dataset FER2013.
        switch label.lowercased() {
        case "happy", "happiness":         return .happy
        case "sad", "sadness":             return .sad
        case "angry", "anger":             return .angry
        case "neutral":                    return .neutral
        case "surprise", "surprised":      return .surprised
        case "disgust", "disgusted":       return .disgusted
        case "fear", "fearful", "afraid":  return .fearful
        default:                           return EmotionType(rawValue: label.lowercased())
        }
    }

    // MARK: - Mock (SEMENTARA)

    /// TODO: HAPUS / ganti ke `classify(pixelBuffer:)` setelah model Core ML
    ///       benar-benar tersedia. Sekarang mengembalikan emosi + confidence acak
    ///       supaya alur app (UI, journal, rekomendasi) bisa diuji tanpa model.
    func mockClassify(completion: @escaping (EmotionClassification) -> Void) {
        let emotion = EmotionType.allCases.randomElement()
        let confidence = Double.random(in: 0.65...0.99)
        // Tiru latensi inferensi & kembali ke main thread untuk update UI.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion(EmotionClassification(emotion: emotion, confidence: confidence, source: .mock))
        }
    }

    func demoClassify(completion: @escaping (EmotionClassification) -> Void) {
        let now = Date()
        if now.timeIntervalSince(lastDemoUpdate) > 3.2 {
            let pair = demoSequence[demoIndex % demoSequence.count]
            demoEmotion = pair.0
            demoConfidence = pair.1
            demoIndex += 1
            lastDemoUpdate = now
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            completion(EmotionClassification(emotion: self.demoEmotion, confidence: self.demoConfidence, source: .demoVision))
        }
    }
}

private extension String {
    var isTruthy: Bool {
        let normalized = trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return ["1", "true", "yes", "y", "on"].contains(normalized)
    }
}
