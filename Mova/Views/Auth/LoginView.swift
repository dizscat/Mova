//
//  LoginView.swift
//  Mova
//
//  Login lokal sederhana: cukup masukkan nama untuk membuat "local account".
//

import SwiftUI

struct LoginView: View {

    @ObservedObject var authViewModel: AuthViewModel
    @State private var name: String = ""
    @State private var appeared = false

    var body: some View {
        ZStack {
            MovaAmbientBackground()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 12) {
                    MovaIconBadge(systemName: MovaTimeMood.current == .day ? "sun.max.fill" : "moon.stars.fill")
                        .scaleEffect(appeared ? 1 : 0.86)

                    Text("Mova")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(MovaTimeMood.current.foreground)

                    Text("Your face, your music.")
                        .font(.headline)
                        .foregroundColor(MovaTimeMood.current.secondaryForeground)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

                Spacer()

                MovaGlassCard {
                    VStack(spacing: 16) {
                        TextField("Your name", text: $name)
                            .font(.body)
                            .submitLabel(.go)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.words)
                            .padding(14)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .onSubmit(start)

                        Button(action: start) {
                            Label("Start", systemImage: "arrow.right.circle.fill")
                        }
                        .buttonStyle(MovaPrimaryButtonStyle())
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.55 : 1)
                    }
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 22)

                Spacer()
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.75)) {
                appeared = true
            }
        }
    }

    private func start() {
        authViewModel.login(name: name)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(authViewModel: AuthViewModel())
    }
}
