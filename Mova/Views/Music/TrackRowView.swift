//
//  TrackRowView.swift
//  Mova
//
//  Satu baris track dengan tombol play.
//

import SwiftUI

struct TrackRowView: View {

    let track: Track
    let onPlay: () -> Void

    var body: some View {
        MovaGlassCard {
            HStack(spacing: 12) {
                MovaIconBadge(systemName: "music.note")
                    .scaleEffect(0.86)

                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title)
                        .font(.body.weight(.semibold))
                        .foregroundColor(MovaTimeMood.current.foreground)
                    Text(track.artist)
                        .font(.caption)
                        .foregroundColor(MovaTimeMood.current.secondaryForeground)
                }
                Spacer()
                Button(action: onPlay) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(MovaTimeMood.current.foreground)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 3)
    }
}

struct TrackRowView_Previews: PreviewProvider {
    static var previews: some View {
        TrackRowView(
            track: .init(
                musicMoodId: "mood-happy",
                title: "Happy",
                artist: "Pharrell Williams"
            ),
            onPlay: {}
        )
        .padding()
    }
}
