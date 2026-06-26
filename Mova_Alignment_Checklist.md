# Mova Alignment Checklist

Checklist ini merangkum pekerjaan yang perlu diselesaikan agar Mova benar-benar selaras dengan SRS, ERD, dan ARD proyek.

## Status Singkat

- Build project: PASS
- Arsitektur MVVM dasar: sebagian besar sesuai
- Local-first persistence: sesuai arah ARD, tetapi model data masih perlu diperkuat
- Deteksi wajah dan emosi: berjalan, tetapi pipeline ML belum sepenuhnya sesuai dokumen
- Rekomendasi musik: berjalan untuk MVP, tetapi belum otomatis penuh
- Daily AI Journal: MVP sudah ditambahkan dengan draft editable dan fallback lokal
- ERD: belum sepenuhnya terwakili dalam model dan persistence
- AI agent workflow: terdokumentasi di `Docs/AI_Agent_Workflow.md` dan `Docs/Agent_Tickets.md`

## Product Upgrade - Daily AI Journal

- [x] Tambahkan model `DailyJournal`.
  Kriteria selesai: jurnal menyimpan `userId`, tanggal, kata kunci user, ringkasan mood, draft AI, final text, dan timestamp.

- [x] Tambahkan service generator jurnal dengan prompt di kode.
  Kriteria selesai: service memiliki system prompt, menerima kata kunci + mood summary, dan tidak mengirim data wajah.

- [x] Tambahkan fallback lokal agar fitur bisa dicoba tanpa API key.
  Kriteria selesai: draft tetap bisa dibuat walaupun endpoint AI belum dikonfigurasi.

- [x] Tambahkan layar `Daily AI Journal`.
  Kriteria selesai: user bisa input kata kunci, generate draft, edit draft, simpan, dan melihat riwayat jurnal.

- [ ] Sambungkan endpoint backend AI sungguhan.
  Kriteria selesai: `MovaAIJournalEndpoint` mengarah ke backend aman yang memanggil AI API tanpa menyimpan API key di app iOS.

- [ ] Tambahkan fitur before/after mood tracking setelah sesi musik.
  Kriteria selesai: user bisa membandingkan mood sebelum dan setelah mendengarkan rekomendasi musik.

## Prioritas 1 - Wajib Untuk Sesuai SRS

- [ ] Buat rekomendasi musik otomatis mengikuti emosi terakhir yang terdeteksi.
  Kriteria selesai: setelah emosi terdeteksi, `MusicRecommendationView` menampilkan rekomendasi berdasarkan emosi aktual, bukan default `.neutral`.

- [ ] Kurangi input manual pada flow utama deteksi.
  Kriteria selesai: hasil deteksi dapat disimpan sebagai emotion log secara otomatis atau dengan aksi minimal yang jelas, sesuai diferensiator "tanpa input manual memilih mood".

- [x] Perbaiki local auth agar tidak selalu membuat user baru setiap login.
  Kriteria selesai: username yang pernah dibuat bisa dipulihkan dari local storage, bukan menimpa `userProfile.json` tunggal.

- [x] Simpan banyak user lokal sesuai ERD `USER 1-N EMOTIONLOG`.
  Kriteria selesai: persistence menyimpan `[UserProfile]` atau struktur equivalent, dan setiap log terhubung ke `userId` yang benar.

- [ ] Gunakan hasil face detection untuk input classifier.
  Kriteria selesai: classifier menerima crop wajah atau region wajah dari `VNFaceObservation`, bukan frame penuh tanpa pemanfaatan bounding box.

- [ ] Pastikan model Core ML benar-benar menghasilkan 7 kelas FER2013.
  Kriteria selesai: label model berhasil dipetakan ke `happy`, `sad`, `angry`, `neutral`, `surprised`, `disgusted`, dan `fearful`, serta fallback mock hanya dipakai saat model tidak tersedia.

## Prioritas 2 - Wajib Untuk Sesuai ERD

- [x] Tambahkan model `Track` sebagai entity terpisah, bukan hanya nested type.
  Kriteria selesai: `Track` memiliki `id`, `musicMoodId`, `title`, `artist`, dan `previewURL`.

- [x] Tambahkan model `Streak`.
  Kriteria selesai: `Streak` memiliki `id`, `userId`, `currentStreak`, `dominantEmotion`, dan `lastUpdated`.

- [x] Tambahkan relasi eksplisit `EmotionLog` ke `MusicMood`.
  Kriteria selesai: `EmotionLog` menyimpan `musicMoodId` atau mekanisme mapping stabil via `emotionType`.

- [ ] Pisahkan seed data `MusicMood` dan `Track`.
  Kriteria selesai: data rekomendasi bisa dimuat dari `PlaylistSeed.json` atau seed service, bukan hardcoded seluruhnya di ViewModel/UI.

- [ ] Update persistence protocol untuk mendukung user, mood, track, dan streak.
  Kriteria selesai: `PersistenceServiceProtocol` tidak hanya menangani log dan satu profile.

## Prioritas 3 - Penyempurnaan ARD Dan Maintainability

- [ ] Pindahkan `MovaApp.swift` ke folder `App/` atau sesuaikan dokumen struktur folder.
  Kriteria selesai: struktur project dan dokumen tidak saling bertentangan.

- [ ] Isi folder `Views/Components`.
  Kriteria selesai: tersedia minimal `EmotionBadge` dan `LoadingView`.

- [ ] Isi folder `Utils/Extensions`.
  Kriteria selesai: helper seperti `Color+Emotion`, `Date+Formatting`, dan `Constants` dipindahkan dari view ke extension reusable.

- [ ] Hilangkan `ContentView.swift` default jika tidak dipakai.
  Kriteria selesai: tidak ada layar template "Hello, world!" yang masuk build tanpa fungsi.

- [ ] Buat `Resources/PlaylistSeed.json`.
  Kriteria selesai: playlist seed tersedia sebagai resource app dan dapat dimuat oleh service.

- [ ] Tambahkan error state yang terlihat di UI.
  Kriteria selesai: error persistence, kamera, dan classifier tidak hanya `print`, tetapi bisa ditampilkan secara ramah di view terkait.

## Prioritas 4 - Privacy, Performance, Dan Quality

- [ ] Tambahkan indikator bahwa inference berjalan on-device.
  Kriteria selesai: dokumentasi atau layar profil/settings menjelaskan data wajah tidak dikirim keluar perangkat.

- [ ] Ukur latensi inference.
  Kriteria selesai: `DetectionViewModel` atau classifier mencatat durasi proses dan memastikan target `< 200ms/frame` dapat diuji.

- [ ] Tambahkan throttle yang lebih eksplisit dan mudah dikonfigurasi.
  Kriteria selesai: interval frame tidak hardcoded di dalam `CameraManager` tanpa konfigurasi.

- [ ] Tambahkan unit test untuk mapping musik.
  Kriteria selesai: setiap `EmotionType` punya genre sesuai SRS.

- [ ] Tambahkan unit test untuk statistik journal/profile.
  Kriteria selesai: most frequent emotion, weekly breakdown, dan streak harian diuji dengan data contoh.

- [ ] Tambahkan test persistence lokal.
  Kriteria selesai: save/fetch user, save/fetch log, dan filtering by `userId` berjalan benar.

## Checklist Functional Requirements

- [x] FR-1 Auth: login lokal dengan nama
- [x] FR-1 Auth: sesi tersimpan
- [x] FR-1 Auth: logout tersedia
- [x] FR-1 Auth: registrasi/login lokal tidak menimpa user lama
- [x] FR-2 Deteksi: akses kamera depan
- [x] FR-2 Deteksi: Vision face detection
- [x] FR-2 Deteksi: label emosi dan confidence score
- [x] FR-2 Deteksi: handle tidak ada wajah
- [ ] FR-2 Deteksi: classifier memakai crop/region wajah
- [ ] FR-2 Deteksi: validasi model FER2013 7 kelas secara nyata
- [x] FR-3 Musik: mapping emosi ke genre
- [x] FR-3 Musik: tampilkan daftar lagu
- [x] FR-3 Musik: buka lagu via tautan eksternal/search
- [ ] FR-3 Musik: tautan track spesifik atau `previewURL`
- [x] FR-4 Journal: simpan hasil deteksi sebagai log
- [x] FR-4 Journal: tampilkan riwayat log
- [x] FR-4 Journal: visualisasi tren mingguan via Swift Charts
- [x] FR-4 Journal: hitung emosi paling sering
- [x] FR-5 Profil: total sesi
- [x] FR-5 Profil: mood streak harian
- [x] FR-5 Profil: emosi dominan

## Checklist Non-Functional Requirements

- [ ] NFR-1 Performance: bukti inference `< 200ms/frame`
- [x] NFR-2 Privacy: inference lokal/on-device secara arsitektur
- [ ] NFR-2 Privacy: pesan privacy eksplisit untuk user
- [x] NFR-3 Compatibility: iOS 16+, tanpa SwiftData
- [x] NFR-4 Usability: UI dasar self-explanatory
- [x] NFR-5 Maintainability: persistence via protocol
- [ ] NFR-5 Maintainability: protocol cukup lengkap untuk migrasi Firebase penuh

## Rekomendasi Urutan Pengerjaan 6 Hari

1. Hari 1: perbaiki auth multi-user lokal, model ERD dasar, dan persistence protocol.
2. Hari 2: buat `PlaylistSeed.json`, model `Track`, model `Streak`, dan seed loader.
3. Hari 3: sambungkan deteksi terakhir ke rekomendasi musik otomatis.
4. Hari 4: perbaiki pipeline classifier agar memakai crop wajah dan tambahkan error state UI.
5. Hari 5: tambah komponen reusable, utils/extensions, dan bersihkan struktur folder.
6. Hari 6: tambah test mapping, streak, persistence, lalu ukur performa inference.

## Definisi Selesai

Mova dapat dianggap sesuai dengan SRS, ERD, dan ARD jika:

- User bisa login sebagai nama yang sama tanpa membuat akun baru terus-menerus.
- Kamera depan mendeteksi wajah, classifier menghasilkan salah satu dari 7 emosi, dan UI menampilkan confidence.
- Rekomendasi musik berubah otomatis mengikuti emosi terdeteksi.
- Setiap sesi deteksi tersimpan sebagai `EmotionLog` dengan `userId` dan rekomendasi musik terkait.
- Journal menampilkan history dan tren mingguan.
- Profile menampilkan total sesi, streak, dan emosi dominan.
- Persistence tetap lewat protocol sehingga migrasi ke Firebase tidak memaksa rewrite ViewModel/View.
- Struktur model sudah mencerminkan USER, EMOTIONLOG, MUSICMOOD, TRACK, dan STREAK.
