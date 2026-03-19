import Foundation
import SwiftUI

enum AppColors {
    static let accent = Color(hex: "59E7DA")
    static let accentSoft = Color(hex: "B2FFF8")
    static let accentStrong = Color(hex: "19B7B0")

    static let secondary = Color(hex: "86F0A6")
    static let warning = Color(hex: "FFBA6B")
    static let error = Color(hex: "FF7E93")
    static let success = Color(hex: "6DF0B3")
    static let info = Color(hex: "73C5FF")

    static let backgroundPrimary = Color(hex: "050816")
    static let backgroundSecondary = Color(hex: "0A1022")
    static let backgroundTertiary = Color(hex: "121B33")
    static let backgroundElevated = Color(hex: "182443")
    static let cardBackground = Color(hex: "0E1730")
    static let cardBackgroundStrong = Color(hex: "162442")
    static let inputBackground = Color(hex: "0C1428")

    static let textPrimary = Color(hex: "F4F7FF")
    static let textSecondary = Color(hex: "A8B3D1")
    static let textTertiary = Color(hex: "6D7A99")

    static let divider = Color.white.opacity(0.10)
    static let shadowColor = Color.black
    static let glowPrimary = accent.opacity(0.32)
    static let glowSecondary = info.opacity(0.22)

    static let tabBarBackground = Color(hex: "08101F")

    static var appGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "03050B"),
                Color(hex: "071021"),
                Color(hex: "081927"),
                Color(hex: "03050A")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [cardBackgroundStrong, cardBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentSoft, accent, info],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var headerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "13274B"),
                Color(hex: "0D1831"),
                Color(hex: "09101F")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var panelGradient: LinearGradient {
        LinearGradient(
            colors: [
                backgroundElevated.opacity(0.96),
                cardBackgroundStrong.opacity(0.92),
                cardBackground.opacity(0.96)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var inputGradient: LinearGradient {
        LinearGradient(
            colors: [
                backgroundTertiary.opacity(0.98),
                inputBackground.opacity(0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var dateBadgeGradient: LinearGradient {
        LinearGradient(
            colors: [
                accent.opacity(0.28),
                info.opacity(0.20)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64

        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppColors.panelGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                Color.white.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppColors.divider, lineWidth: 1)
            )
            .shadow(color: AppColors.shadowColor.opacity(0.45), radius: 24, x: 0, y: 16)
            .shadow(color: AppColors.glowPrimary.opacity(0.10), radius: 18, x: 0, y: 0)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundColor(AppColors.backgroundPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(AppColors.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .shadow(color: AppColors.glowPrimary.opacity(configuration.isPressed ? 0.18 : 0.32), radius: 18, x: 0, y: 10)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundColor(AppColors.textPrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(AppColors.inputGradient)
            )
            .overlay(
                Capsule()
                    .stroke(AppColors.divider, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            AppColors.appGradient

            Circle()
                .fill(AppColors.glowPrimary)
                .frame(width: 380, height: 380)
                .blur(radius: 110)
                .offset(x: -130, y: -290)

            Circle()
                .fill(AppColors.glowSecondary)
                .frame(width: 320, height: 320)
                .blur(radius: 120)
                .offset(x: 170, y: -180)

            Circle()
                .fill(AppColors.secondary.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 100)
                .offset(x: 120, y: 320)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.06),
                    Color.clear,
                    Color.black.opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
