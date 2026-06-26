//
//  MusicMapper.swift
//  Mova
//
//  Pemetaan emosi -> rekomendasi musik. Untuk MVP, Mova memakai mood-based
//  shuffle: emosi menentukan pool lagu, lalu beberapa track diacak dari pool itu.
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
                genre: "Pop/Upbeat/C-Pop",
                playlistName: "Feel-Good Shuffle",
                tracks: [
                    ("Happy", "Pharrell Williams"),
                    ("Uptown Funk", "Mark Ronson ft. Bruno Mars"),
                    ("Can't Stop the Feeling!", "Justin Timberlake"),
                    ("Dynamite", "BTS"),
                    ("September", "Earth, Wind & Fire"),
                    ("告白气球", "Jay Chou"),
                    ("恋爱ing", "Mayday"),
                    ("阳光宅男", "Jay Chou"),
                    ("Melompat Lebih Tinggi", "Sheila On 7")
                ]
            )
        case .sad:
            return makeMood(
                id: "mood-sad",
                emotion: .sad,
                genre: "Lo-fi/Acoustic/Ballad",
                playlistName: "Quiet Comfort Shuffle",
                tracks: [
                    ("Skinny Love", "Bon Iver"),
                    ("The Night We Met", "Lord Huron"),
                    ("Fix You", "Coldplay"),
                    ("Someone Like You", "Adele"),
                    ("Let Her Go", "Passenger"),
                    ("演员", "薛之谦"),
                    ("后来", "刘若英"),
                    ("小幸运", "Hebe Tien"),
                    ("Rehat", "Kunto Aji")
                ]
            )
        case .angry:
            return makeMood(
                id: "mood-angry",
                emotion: .angry,
                genre: "Rock/Metal/Alt-Rock",
                playlistName: "Let It Out Shuffle",
                tracks: [
                    ("Killing in the Name", "Rage Against the Machine"),
                    ("Bulls on Parade", "Rage Against the Machine"),
                    ("Chop Suey!", "System of a Down"),
                    ("Numb", "Linkin Park"),
                    ("Bring Me To Life", "Evanescence"),
                    ("倔强", "Mayday"),
                    ("离开地球表面", "Mayday"),
                    ("Mimpi Yang Sempurna", "NOAH"),
                    ("Unravel", "TK from Ling Tosite Sigure")
                ]
            )
        case .surprised:
            return makeMood(
                id: "mood-surprised",
                emotion: .surprised,
                genre: "Electronic/Dance/K-Pop",
                playlistName: "Unexpected Energy Shuffle",
                tracks: [
                    ("Levels", "Avicii"),
                    ("Titanium", "David Guetta ft. Sia"),
                    ("One More Time", "Daft Punk"),
                    ("Rather Be", "Clean Bandit ft. Jess Glynne"),
                    ("How You Like That", "BLACKPINK"),
                    ("孤勇者", "Eason Chan"),
                    ("野狼Disco", "宝石Gem"),
                    ("Tokyo Drift", "Teriyaki Boyz"),
                    ("Lathi", "Weird Genius ft. Sara Fajira")
                ]
            )
        case .neutral:
            return makeMood(
                id: "mood-neutral",
                emotion: .neutral,
                genre: "Jazz/Chill/City Pop",
                playlistName: "Easy Afternoon Shuffle",
                tracks: [
                    ("Take Five", "Dave Brubeck"),
                    ("So What", "Miles Davis"),
                    ("Feeling Good", "Nina Simone"),
                    ("Sunday Morning", "Maroon 5"),
                    ("Plastic Love", "Mariya Takeuchi"),
                    ("稻香", "Jay Chou"),
                    ("平凡之路", "朴树"),
                    ("Zona Nyaman", "Fourtwnty"),
                    ("Blue in Green", "Miles Davis")
                ]
            )
        case .disgusted:
            return makeMood(
                id: "mood-disgusted",
                emotion: .disgusted,
                genre: "Alternative/Indie/Reset",
                playlistName: "Shake It Off Shuffle",
                tracks: [
                    ("Creep", "Radiohead"),
                    ("Smells Like Teen Spirit", "Nirvana"),
                    ("Mr. Brightside", "The Killers"),
                    ("Seven Nation Army", "The White Stripes"),
                    ("Take Me Out", "Franz Ferdinand"),
                    ("丑八怪", "薛之谦"),
                    ("你不是真正的快乐", "Mayday"),
                    ("Bento", "Iwan Fals"),
                    ("Do I Wanna Know?", "Arctic Monkeys")
                ]
            )
        case .fearful:
            return makeMood(
                id: "mood-fearful",
                emotion: .fearful,
                genre: "Ambient/Calming/Piano",
                playlistName: "Safe & Sound Shuffle",
                tracks: [
                    ("Weightless", "Marconi Union"),
                    ("An Ending (Ascent)", "Brian Eno"),
                    ("Saturn", "Sleeping at Last"),
                    ("River Flows in You", "Yiruma"),
                    ("Clair de Lune", "Claude Debussy"),
                    ("夜空中最亮的星", "Escape Plan"),
                    ("月亮代表我的心", "Teresa Teng"),
                    ("Amin Paling Serius", "Sal Priadi & Nadin Amizah"),
                    ("Merry-Go-Round of Life", "Joe Hisaishi")
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
            trackList: tracks
                .shuffled()
                .prefix(6)
                .map {
                    Track(
                        musicMoodId: id,
                        title: $0.title,
                        artist: $0.artist
                    )
                }
        )
    }
}
