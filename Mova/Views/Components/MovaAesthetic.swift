//
//  MovaAesthetic.swift
//  Mova
//
//  Visual system ringan untuk nuansa chill, lembut, dan adaptif siang/malam.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum MovaTimeMood {
    case day
    case night

    static var current: MovaTimeMood {
        let hour = Calendar.current.component(.hour, from: Date())
        return (6..<18).contains(hour) ? .day : .night
    }

    var baseGradient: LinearGradient {
        switch self {
        case .day:
            return LinearGradient(
                colors: [
                    Color(red: 0.89, green: 0.96, blue: 0.98),
                    Color(red: 0.98, green: 0.94, blue: 0.84),
                    Color(red: 0.92, green: 0.96, blue: 0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .night:
            return LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.14),
                    Color(red: 0.09, green: 0.13, blue: 0.23),
                    Color(red: 0.12, green: 0.10, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var foreground: Color {
        self == .day ? Color(red: 0.10, green: 0.14, blue: 0.19) : .white
    }

    var secondaryForeground: Color {
        self == .day ? Color(red: 0.32, green: 0.39, blue: 0.45) : .white.opacity(0.72)
    }

    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.20, green: 0.72, blue: 0.76),
                Color(red: 0.96, green: 0.66, blue: 0.45)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct MovaAmbientBackground: View {
    var mood: MovaTimeMood = .current

    @State private var drift = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                mood.baseGradient

                RoundedRectangle(cornerRadius: 120, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.20, green: 0.72, blue: 0.76).opacity(mood == .day ? 0.32 : 0.20),
                                Color(red: 0.96, green: 0.66, blue: 0.45).opacity(mood == .day ? 0.28 : 0.16)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * 1.35, height: 220)
                    .rotationEffect(.degrees(-12))
                    .offset(x: drift ? 70 : -60, y: proxy.size.height * 0.12)
                    .blur(radius: 32)

                RoundedRectangle(cornerRadius: 100, style: .continuous)
                    .fill(Color.white.opacity(mood == .day ? 0.22 : 0.07))
                    .frame(width: proxy.size.width * 1.1, height: 180)
                    .rotationEffect(.degrees(18))
                    .offset(x: drift ? -80 : 60, y: proxy.size.height * 0.63)
                    .blur(radius: 38)
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                    drift.toggle()
                }
            }
        }
    }
}

struct MovaGlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.10), radius: 24, x: 0, y: 16)
    }
}

enum MovaChrome {
    static func configure() {
        #if canImport(UIKit)
        let accent = UIColor(red: 0.20, green: 0.72, blue: 0.76, alpha: 1)
        let muted = UIColor.secondaryLabel

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        tabAppearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.42)
        tabAppearance.shadowColor = UIColor.black.withAlphaComponent(0.08)
        tabAppearance.stackedLayoutAppearance.selected.iconColor = accent
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: accent]
        tabAppearance.stackedLayoutAppearance.normal.iconColor = muted
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: muted]
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithTransparentBackground()
        navigationAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        navigationAppearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.20)
        navigationAppearance.shadowColor = .clear
        navigationAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 34, weight: .heavy)
        ]
        navigationAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        #endif
    }
}

struct MovaIconBadge: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 42, height: 42)
            .background(MovaTimeMood.current.accentGradient, in: Circle())
            .shadow(color: Color(red: 0.20, green: 0.72, blue: 0.76).opacity(0.28), radius: 16, x: 0, y: 8)
    }
}

struct MovaWordmark: View {
    var mood: MovaTimeMood = .current

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(mood.accentGradient)

                VStack(spacing: 2) {
                    Text("M")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Circle()
                        .fill(Color.white.opacity(0.88))
                        .frame(width: 7, height: 7)
                }
            }
            .frame(width: 64, height: 64)
            .shadow(color: Color(red: 0.20, green: 0.72, blue: 0.76).opacity(0.24), radius: 18, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text("Mova")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundColor(mood.foreground)

                Text("Face-aware mood companion")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(mood.secondaryForeground)
            }

            Spacer(minLength: 0)
        }
    }
}

struct MovaPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundColor(.white)
            .background(MovaTimeMood.current.accentGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .shadow(color: Color(red: 0.20, green: 0.72, blue: 0.76).opacity(configuration.isPressed ? 0.14 : 0.26), radius: 18, x: 0, y: 10)
            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

struct MovaSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(MovaTimeMood.current.foreground)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

extension View {
    func movaListStyle() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(MovaAmbientBackground())
            .listRowSeparator(.hidden)
    }
}
