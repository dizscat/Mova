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
                            colors: [.black.opacity(0.08), .black.opacity(0.42)],
                            startPoint: .top,
                            endPoint: .bottom
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
                    confidence: viewModel.confidence
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
        MovaGlassCard {
            VStack(spacing: 14) {
                MovaIconBadge(systemName: "camera.fill")
                Text("Camera access is required")
                    .font(.headline)
                    .foregroundColor(MovaTimeMood.current.foreground)
                Text("Enable camera permission in Settings to detect facial emotions.")
                    .font(.subheadline)
                    .foregroundColor(MovaTimeMood.current.secondaryForeground)
                    .multilineTextAlignment(.center)
            }
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
