//
//  MusicMapper.swift
//  Mova
//
//  Pemetaan emosi -> rekomendasi musik (data hardcode untuk MVP).
//

import Foundation

struct MusicMapper {

    /// Kembalikan rekomendasi musik untuk sebuah emosi.
    static func recommendation(for emotion: EmotionType) -> MusicMood {
        switch emotion {
        case .happy:
            return makeMood(
                id: "mood-happy",
                emotion: .happy,
                genre: "Pop/Upbeat",
                playlistName: "Feel-Good Hits",
                tracks: [
                    ("Happy", "Pharrell Williams"),
                    ("Uptown Funk", "Mark Ronson ft. Bruno Mars"),
                    ("Can't Stop the Feeling!", "Justin Timberlake")
                ]
            )
        case .sad:
            return makeMood(
                id: "mood-sad",
                emotion: .sad,
                genre: "Lo-fi/Acoustic",
                playlistName: "Quiet Comfort",
                tracks: [
                    ("Skinny Love", "Bon Iver"),
                    ("The Night We Met", "Lord Huron"),
                    ("Fix You", "Coldplay")
                ]
            )
        case .angry:
            return makeMood(
                id: "mood-angry",
                emotion: .angry,
                genre: "Rock/Metal",
                playlistName: "Let It Out",
                tracks: [
                    ("Killing in the Name", "Rage Against the Machine"),
                    ("Bulls on Parade", "Rage Against the Machine"),
                    ("Chop Suey!", "System of a Down")
                ]
            )
        case .surprised:
            return makeMood(
                id: "mood-surprised",
                emotion: .surprised,
                genre: "Electronic/Dance",
                playlistName: "Unexpected Energy",
                tracks: [
                    ("Levels", "Avicii"),
                    ("Titanium", "David Guetta ft. Sia"),
                    ("One More Time", "Daft Punk")
                ]
            )
        case .neutral:
            return makeMood(
                id: "mood-neutral",
                emotion: .neutral,
                genre: "Jazz/Chill",
                playlistName: "Easy Afternoon",
                tracks: [
                    ("Take Five", "Dave Brubeck"),
                    ("So What", "Miles Davis"),
                    ("Feeling Good", "Nina Simone")
                ]
            )
        case .disgusted:
            return makeMood(
                id: "mood-disgusted",
                emotion: .disgusted,
                genre: "Alternative",
                playlistName: "Shake It Off",
                tracks: [
                    ("Creep", "Radiohead"),
                    ("Smells Like Teen Spirit", "Nirvana"),
                    ("Mr. Brightside", "The Killers")
                ]
            )
        case .fearful:
            return makeMood(
                id: "mood-fearful",
                emotion: .fearful,
                genre: "Ambient/Calming",
                playlistName: "Safe & Sound",
                tracks: [
                    ("Weightless", "Marconi Union"),
                    ("An Ending (Ascent)", "Brian Eno"),
                    ("Saturn", "Sleeping at Last")
                ]
            )
        }
    }

    private static func makeMood(
        id: String,
        emotion: EmotionType,
        genre: String,
        playlistName: String,
        tracks: [(title: String, artist: String)]
    ) -> MusicMood {
        MusicMood(
            id: id,
            emotion: emotion,
            genre: genre,
            playlistName: playlistName,
            trackList: tracks.map {
                Track(
                    musicMoodId: id,
                    title: $0.title,
                    artist: $0.artist
                )
            }
        )
    }
}
