//
//  FaceLandmarkDetector.swift
//  Mova
//
//  Deteksi wajah + landmark menggunakan Vision framework.
//

import Vision
import CoreVideo

final class FaceLandmarkDetector {

    /// Orientasi default untuk kamera depan (front camera) pada potret.
    private let imageOrientation: CGImagePropertyOrientation = .leftMirrored

    /// Mendeteksi wajah pertama pada frame. completion(nil) jika tidak ada
    /// wajah atau terjadi error (selalu graceful, tidak crash).
    func detectFace(in pixelBuffer: CVPixelBuffer,
                    completion: @escaping (VNFaceObservation?) -> Void) {

        let request = VNDetectFaceLandmarksRequest { request, error in
            if let error = error {
                print("FaceLandmarkDetector error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            let face = (request.results as? [VNFaceObservation])?.first
            completion(face)
        }

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: imageOrientation,
            options: [:]
        )

        // Jalankan di background agar tidak memblok main thread.
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("FaceLandmarkDetector perform error: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
}
