//
//  LoginView.swift
//  Mova
//
//  Saat Firestore mode aktif: Login/Register asli lewat Firebase Auth
//  (email + password). Saat tidak aktif: jatuh kembali ke mode lokal lama
//  (nama saja, tanpa password) supaya app tetap bisa dipakai tanpa Firebase.
//

import SwiftUI

struct LoginView: View {

    @ObservedObject var authViewModel: AuthViewModel

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isRegisterMode = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            MovaAmbientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top, spacing: 14) {
                            MovaWordmark()
                                .scaleEffect(appeared ? 1 : 0.9, anchor: .leading)

                            MovaIconBadge(systemName: MovaTimeMood.current == .day ? "sun.max.fill" : "moon.stars.fill")
                                .scaleEffect(appeared ? 1 : 0.86)
                        }

                        Text("Your face, your music.")
                            .font(.headline)
                            .foregroundColor(MovaTimeMood.current.secondaryForeground)

                        Text(authSubtitle)
                            .font(.subheadline)
                            .foregroundColor(MovaTimeMood.current.secondaryForeground.opacity(0.95))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                    MovaGlassCard {
                        if authViewModel.usesFirebaseAuth {
                            firebaseAuthForm
                        } else {
                            localNameForm
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 22)

                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 44)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.75)) {
                appeared = true
            }
        }
    }

    // MARK: - Firebase Auth form (Login/Register asli, data ke Firestore)

    private var firebaseAuthForm: some View {
        VStack(spacing: 16) {
            Picker("Mode", selection: $isRegisterMode) {
                Text("Login").tag(false)
                Text("Register").tag(true)
            }
            .pickerStyle(.segmented)

            if isRegisterMode {
                TextField("Your name", text: $name)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.words)
                    .padding(14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            SecureField("Password", text: $password)
                .textContentType(isRegisterMode ? .newPassword : .password)
                .submitLabel(.go)
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .onSubmit(submitFirebaseAuth)

            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Button(action: submitFirebaseAuth) {
                if authViewModel.isProcessing {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Label(isRegisterMode ? "Create Account" : "Sign In", systemImage: "arrow.right.circle.fill")
                }
            }
            .buttonStyle(MovaPrimaryButtonStyle())
            .disabled(authViewModel.isProcessing || !canSubmitFirebaseAuth)
            .opacity(canSubmitFirebaseAuth ? 1 : 0.55)
        }
        .onChange(of: isRegisterMode) { _ in
            authViewModel.errorMessage = nil
        }
    }

    private var authSubtitle: String {
        if authViewModel.usesFirebaseAuth {
            return "Sign in with email and password to keep your Mova profile and emotion history ready for cloud sync."
        }
        return "This build is still using local mode, so login works with your name only until Firebase mode is enabled."
    }

    private var canSubmitFirebaseAuth: Bool {
        let hasEmailAndPassword = !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
        guard isRegisterMode else { return hasEmailAndPassword }
        return hasEmailAndPassword && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submitFirebaseAuth() {
        guard canSubmitFirebaseAuth else { return }
        Task {
            if isRegisterMode {
                await authViewModel.register(displayName: name, email: email, password: password)
            } else {
                await authViewModel.signIn(email: email, password: password)
            }
        }
    }

    // MARK: - Local fallback form (tanpa Firebase, nama saja)

    private var localNameForm: some View {
        VStack(spacing: 16) {
            TextField("Your name", text: $name)
                .font(.body)
                .submitLabel(.go)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.words)
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .onSubmit(startLocal)

            Button(action: startLocal) {
                Label("Start", systemImage: "arrow.right.circle.fill")
            }
            .buttonStyle(MovaPrimaryButtonStyle())
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.55 : 1)
        }
    }

    private func startLocal() {
        authViewModel.login(name: name)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(authViewModel: AuthViewModel())
    }
}
