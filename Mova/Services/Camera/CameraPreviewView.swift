//
//  CameraPreviewView.swift
//  Mova
//
//  Membungkus AVCaptureVideoPreviewLayer agar bisa dipakai di SwiftUI.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {

    let cameraManager: CameraManager

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = cameraManager.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        // Pastikan session tetap terhubung.
        uiView.videoPreviewLayer.session = cameraManager.session
    }

    /// UIView yang backing layer-nya adalah AVCaptureVideoPreviewLayer.
    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
