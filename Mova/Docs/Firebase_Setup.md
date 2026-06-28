# Firebase Setup for Mova

Mova is Firebase-ready, but it still runs safely with local JSON storage until Firebase is enabled.

## What is already implemented

- `MovaApp` auto-configures Firebase when `FirebaseCore` exists in the target.
- `PersistenceManager` can switch from `LocalStorageService` to `FirestoreService` without changing ViewModels or Views.
- `AuthViewModel` switches between a real Firebase Auth (email/password) flow and the old local name-only flow, based on the same `MOVA_USE_FIRESTORE` switch.
- `LoginView` shows a Login/Register form (email + password) when Firestore mode is on, or the old name-only form when it is off.
- Firestore collections prepared by the app:
  - `users` — document ID = Firebase Auth UID when Firebase Auth is active
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
FirebaseAuth
FirebaseCore
FirebaseFirestore
```

5. In Firebase Console, create an iOS app using Mova's bundle identifier.
6. Download `GoogleService-Info.plist`.
7. Drag `GoogleService-Info.plist` into `Mova/Resources` in Xcode and check `Copy items if needed` plus target membership for `Mova`.
8. In Firebase Console, go to `Authentication > Sign-in method` and enable the **Email/Password** provider. Without this, `register`/`signIn` in `AuthViewModel` will fail at runtime even though the code compiles fine.
9. Enable Firestore + Firebase Auth mode by adding this environment variable to the Run scheme:

```text
MOVA_USE_FIRESTORE=YES
```

If this variable is missing or set to `NO`, Mova will continue using local JSON storage and the old name-only login (no Firebase Auth call is made at all).

## Firestore Security Rules

Once real Firebase Auth is in use, `request.auth.uid` is reliable and rules should restrict every collection to its owner:

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /emotionLogs/{logId} {
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow read, update, delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    match /streaks/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /dailyJournals/{journalId} {
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow read, update, delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

Paste this into Firebase Console > Firestore Database > Rules before testing with `MOVA_USE_FIRESTORE=YES`. Without rules like these, the default Firestore behavior denies all reads/writes, so every call from `FirestoreService` will fail with `permission-denied`.

## Why the plist is ignored

`Mova/Resources/GoogleService-Info.plist` is ignored by Git so the real Firebase project config does not get pushed to GitHub accidentally.
