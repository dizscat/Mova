//
//  DetectionView.swift
//  Mova
//
//  Layar inti: preview kamera + overlay emosi + tombol untuk menyimpan deteksi
//  dan menampilkan rekomendasi musik.
//

import SwiftUI

struct DetectionView: View {

    @StateObject private var viewModel = DetectionViewModel()
    @EnvironmentObject private var appState: AppState

    @State private var savedEmotion: EmotionType?
    @State private var showMusicSheet = false
    @State private var controlsVisible = false

    var body: some View {
        ZStack {
            MovaAmbientBackground()

            if viewModel.cameraManager.permissionGranted {
                // Preview kamera full screen.
                CameraPreviewView(cameraManager: viewModel.cameraManager)
                    .ignoresSafeArea()
                    .overlay(
                        LinearGradient(
                            colors: [.black.opacity(0.26), .black.opacity(0.62)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
                    .overlay(
                        FaceTrackingOverlayView(
                            faceBounds: viewModel.faceBounds,
                            source: viewModel.detectionSource,
                            landmarkConfidence: viewModel.landmarkConfidence
                        )
                        .ignoresSafeArea()
                    )
            } else {
                permissionDeniedView
            }

            VStack {
                Spacer()

                EmotionOverlayView(
                    emotion: viewModel.currentEmotion,
                    confidence: viewModel.confidence,
                    source: viewModel.detectionSource
                )
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))

                Button(action: detectAndGetMusic) {
                    Label("Detect & Get Music", systemImage: "music.note.list")
                }
                .buttonStyle(MovaPrimaryButtonStyle())
                .disabled(viewModel.currentEmotion == nil)
                .opacity(viewModel.currentEmotion == nil ? 0.55 : 1)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .opacity(controlsVisible ? 1 : 0)
            .offset(y: controlsVisible ? 0 : 18)
        }
        .animation(.easeInOut(duration: 0.32), value: viewModel.currentEmotion)
        .onAppear {
            viewModel.startDetection()
            withAnimation(.easeOut(duration: 0.55)) {
                controlsVisible = true
            }
        }
        .onDisappear { viewModel.stopDetection() }
        .sheet(isPresented: $showMusicSheet) {
            if let emotion = savedEmotion {
                NavigationView {
                    MusicRecommendationView(emotion: emotion)
                }
            }
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 14) {
            MovaIconBadge(systemName: "camera.fill")
            Text("Camera access is required")
                .font(.headline)
                .foregroundColor(.white)
            Text("Enable camera permission in Settings to detect facial emotions.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.78))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        }
        .padding(.horizontal, 28)
    }

    private func detectAndGetMusic() {
        let userId = appState.currentUserId ?? "local"
        Task {
            let emotion = await viewModel.saveCurrentDetection(userId: userId)
            if let emotion = emotion {
                savedEmotion = emotion
                showMusicSheet = true
            }
        }
    }
}

struct DetectionView_Previews: PreviewProvider {
    static var previews: some View {
        DetectionView()
            .environmentObject(AppState())
    }
}

private struct FaceTrackingOverlayView: View {

    let faceBounds: NormalizedFaceBounds?
    let source: DetectionSource
    let landmarkConfidence: Double

    var body: some View {
        GeometryReader { proxy in
            if let faceBounds {
                let rect = previewRect(for: faceBounds, in: proxy.size)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.95), .cyan.opacity(0.82), .white.opacity(0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .shadow(color: .cyan.opacity(0.38), radius: 18)

                    faceGuide(in: rect)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(source == .coreML ? "Face locked" : "Demo face lock")
                            .font(.caption.bold())
                        Text("Vision tracking \(Int(landmarkConfidence * 100))%")
                            .font(.caption2.weight(.medium))
                            .opacity(0.82)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.72), in: Capsule())
                    .position(x: rect.midX, y: max(64, rect.minY - 22))
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.easeInOut(duration: 0.24), value: faceBounds)
        .allowsHitTesting(false)
    }

    private func faceGuide(in rect: CGRect) -> some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.9))
                .frame(width: 7, height: 7)
                .position(x: rect.minX + rect.width * 0.35, y: rect.minY + rect.height * 0.38)
            Circle()
                .fill(.white.opacity(0.9))
                .frame(width: 7, height: 7)
                .position(x: rect.minX + rect.width * 0.65, y: rect.minY + rect.height * 0.38)

            Capsule()
                .fill(.white.opacity(0.72))
                .frame(width: rect.width * 0.28, height: 4)
                .position(x: rect.midX, y: rect.minY + rect.height * 0.68)

            Capsule()
                .fill(.cyan.opacity(0.42))
                .frame(width: rect.width * 0.82, height: 2)
                .position(x: rect.midX, y: rect.minY + rect.height * 0.52)
        }
    }

    private func previewRect(for bounds: NormalizedFaceBounds, in size: CGSize) -> CGRect {
        let width = CGFloat(bounds.width) * size.width
        let height = CGFloat(bounds.height) * size.height
        let x = CGFloat(bounds.x) * size.width
        let y = (1 - CGFloat(bounds.y) - CGFloat(bounds.height)) * size.height
        return CGRect(x: x, y: y, width: width, height: height).insetBy(dx: -18, dy: -24)
    }
}
