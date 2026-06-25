//
//  EmotionChartView.swift
//  Mova
//
//  Bar chart breakdown emosi 7 hari terakhir (Swift Charts, iOS 16+).
//

import SwiftUI
import Charts

struct EmotionChartView: View {

    let breakdown: [EmotionType: Int]

    /// Urutkan mengikuti urutan deklarasi enum agar konsisten.
    private var data: [(emotion: EmotionType, count: Int)] {
        EmotionType.allCases.map { ($0, breakdown[$0] ?? 0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mood Trend (7 Days)")
                .font(.headline)

            if breakdown.values.reduce(0, +) == 0 {
                Text("No data this week yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(data, id: \.emotion) { item in
                    BarMark(
                        x: .value("Emotion", item.emotion.displayName),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(Color(hex: item.emotion.colorHex))
                }
                .frame(height: 200)
            }
        }
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

struct EmotionChartView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionChartView(breakdown: [.happy: 4, .sad: 2, .neutral: 3])
            .padding()
    }
}
