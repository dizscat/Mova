//
//  CameraManager.swift
//  Mova
//
//  Mengelola AVCaptureSession kamera DEPAN dan meneruskan frame (CVPixelBuffer)
//  untuk diproses Vision + Core ML.
//

import AVFoundation
import CoreVideo
import Combine

final class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    @Published var currentFrame: CVPixelBuffer?
    @Published var permissionGranted: Bool = false

    /// Session diekspos agar CameraPreviewView bisa memasang preview layer.
    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.mova.camera.session")
    private let videoOutput = AVCaptureVideoDataOutput()

    // Throttle: hanya proses 1 dari setiap 10 frame agar hemat CPU.
    private var frameCounter = 0
    private let frameInterval = 10

    private var isConfigured = false

    override init() {
        super.init()
    }

    // MARK: - Permission

    /// Minta izin kamera dan update `permissionGranted`.
    func requestPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setPermission(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                self?.setPermission(granted)
            }
        default:
            setPermission(false)
        }
    }

    private func setPermission(_ granted: Bool) {
        DispatchQueue.main.async { self.permissionGranted = granted }
    }

    // MARK: - Session lifecycle

    func startSession() {
        requestPermission()
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.isConfigured { self.configureSession() }
            guard self.permissionGrantedSync, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    /// Pembacaan permission yang aman dipanggil dari sessionQueue.
    private var permissionGrantedSync: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Kamera depan.
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            print("CameraManager: gagal menambahkan input kamera depan.")
            return
        }
        session.addInput(input)

        // Output frame.
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()
        isConfigured = true
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        // Throttle frame.
        frameCounter += 1
        guard frameCounter % frameInterval == 0 else { return }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        DispatchQueue.main.async { self.currentFrame = pixelBuffer }
    }
}
