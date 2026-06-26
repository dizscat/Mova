# Firebase Setup for Mova

Mova is Firebase-ready, but it still runs safely with local JSON storage until Firebase is enabled.

## What is already implemented

- `MovaApp` auto-configures Firebase when `FirebaseCore` exists in the target.
- `PersistenceManager` can switch from `LocalStorageService` to `FirestoreService` without changing ViewModels or Views.
- Firestore collections prepared by the app:
  - `users`
  - `emotionLogs`
  - `streaks`
  - `dailyJournals`

## Xcode steps

1. Open `Mova.xcodeproj` in Xcode.
2. Go to `File > Add Package Dependencies...`.
3. Add this package URL:

```text
https://github.com/firebase/firebase-ios-sdk
```

4. Select these products for the `Mova` target:

```text
FirebaseCore
FirebaseFirestore
```

5. In Firebase Console, create an iOS app using Mova's bundle identifier.
6. Download `GoogleService-Info.plist`.
7. Drag `GoogleService-Info.plist` into `Mova/Resources` in Xcode and check `Copy items if needed` plus target membership for `Mova`.
8. Enable Firestore mode by adding this environment variable to the Run scheme:

```text
MOVA_USE_FIRESTORE=YES
```

If this variable is missing or set to `NO`, Mova will continue using local JSON storage.

## Why the plist is ignored

`Mova/Resources/GoogleService-Info.plist` is ignored by Git so the real Firebase project config does not get pushed to GitHub accidentally.
