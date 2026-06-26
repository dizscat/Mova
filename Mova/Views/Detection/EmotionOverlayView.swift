//
//  EmotionOverlayView.swift
//  Mova
//
//  Overlay yang menampilkan emosi terdeteksi + tingkat kepercayaan (confidence).
//

import SwiftUI

struct EmotionOverlayView: View {

    let emotion: EmotionType?
    let confidence: Double
    let source: DetectionSource

    var body: some View {
        MovaGlassCard {
            VStack(spacing: 14) {
                if let emotion = emotion {
                    Text(emotion.emoji)
                        .font(.system(size: 68))
                        .transition(.scale.combined(with: .opacity))

                    Text(emotion.displayName)
                        .font(.system(.title2, design: .rounded).bold())
                        .foregroundColor(.white)

                    VStack(spacing: 8) {
                        ProgressView(value: confidence)
                            .tint(Color(hex: emotion.colorHex))
                        Text("Confidence: \(Int(confidence * 100))%")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white.opacity(0.82))

                        Text(source.displayName)
                            .font(.caption2.weight(.bold))
                            .textCase(.uppercase)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.white.opacity(source.isDemoData ? 0.18 : 0.12), in: Capsule())
                    }
                    .frame(maxWidth: 230)
                } else {
                    Image(systemName: "face.dashed")
                        .font(.system(size: 46, weight: .medium))
                        .foregroundColor(.white.opacity(0.82))
                    Text("No face detected")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .frame(maxWidth: 280)
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: emotion)
    }
}

// MARK: - Helper warna hex (fileprivate agar tidak bentrok antar file)

fileprivate extension Color {
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

struct EmotionOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            EmotionOverlayView(emotion: .happy, confidence: 0.87, source: .demoVision)
        }
    }
}
