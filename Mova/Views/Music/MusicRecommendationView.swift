//
//  MusicRecommendationView.swift
//  Mova
//
//  Menampilkan rekomendasi musik (genre, playlist, daftar track) untuk emosi.
//

import SwiftUI

struct MusicRecommendationView: View {

    let emotion: EmotionType
    @StateObject private var viewModel = MusicViewModel()
    @State private var appeared = false

    var body: some View {
        ZStack {
            MovaAmbientBackground()

            List {
                if let mood = viewModel.currentRecommendation {
                    Section {
                        MovaGlassCard {
                            HStack(spacing: 16) {
                                Text(emotion.emoji)
                                    .font(.system(size: 50))

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(emotion.displayName)
                                        .font(.system(.title2, design: .rounded).bold())
                                        .foregroundColor(MovaTimeMood.current.foreground)
                                    Text(mood.genre)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(MovaTimeMood.current.secondaryForeground)
                                    Text(mood.playlistName)
                                        .font(.caption)
                                        .foregroundColor(MovaTimeMood.current.secondaryForeground)
                                    Text("6 random picks from this mood pool")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(MovaTimeMood.current.secondaryForeground.opacity(0.9))
                                }

                                Spacer()
                            }
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        MovaGlassCard {
                            HStack(spacing: 12) {
                                MovaIconBadge(systemName: "dice.fill")
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Mood gacha shuffle")
                                        .font(.headline)
                                        .foregroundColor(MovaTimeMood.current.foreground)
                                    Text("Your scanned emotion chooses the playlist pool, then Mova shuffles a few multilingual tracks. Tap Open to search Apple Music or the web.")
                                        .font(.caption)
                                        .foregroundColor(MovaTimeMood.current.secondaryForeground)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section("Tracks") {
                        ForEach(Array(mood.trackList.enumerated()), id: \.element.id) { index, track in
                            TrackRowView(track: track) {
                                viewModel.openTrack(track)
                            }
                            .listRowBackground(Color.clear)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(.easeOut(duration: 0.35).delay(Double(index) * 0.06), value: appeared)
                        }
                    }
                } else {
                    ProgressView()
                        .listRowBackground(Color.clear)
                }
            }
            .movaListStyle()
        }
        .navigationTitle("Recommendations")
        .onAppear {
            viewModel.fetchRecommendation(for: emotion)
            withAnimation(.easeOut(duration: 0.45)) {
                appeared = true
            }
        }
    }
}

struct MusicRecommendationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MusicRecommendationView(emotion: .happy)
        }
    }
}
