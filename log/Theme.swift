import SwiftUI

enum AppColors {
    static let accent = Color(hex: "79B8FF")
    static let accentSoft = Color(hex: "B9D8FF")
    static let accentStrong = Color(hex: "4A84C4")

    static let secondary = Color(hex: "8FB58A")
    static let warning = Color(hex: "C98A64")
    static let error = Color(hex: "FF6B6B")
    static let success = Color(hex: "8FCEB2")
    static let info = Color(hex: "8BA7C8")

    static let backgroundPrimary = Color(hex: "090C12")
    static let backgroundSecondary = Color(hex: "111722")
    static let backgroundTertiary = Color(hex: "1A2330")
    static let cardBackground = Color(hex: "151E2A")
    static let cardBackgroundStrong = Color(hex: "1E2A3A")

    static let textPrimary = Color(hex: "EEF1F5")
    static let textSecondary = Color(hex: "B4BDC9")
    static let textTertiary = Color(hex: "7E8A99")

    static let tabBarBackground = Color(hex: "0B1018")

    static var appGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "070B12"),
                Color(hex: "101828"),
                Color(hex: "26241F")
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
            colors: [accentSoft, accentStrong],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var headerGradient: LinearGradient {
        LinearGradient(
            colors: [accentStrong.opacity(0.34), Color(hex: "403729").opacity(0.9)],
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
                    .fill(AppColors.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 10)
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
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
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
                    .fill(AppColors.backgroundTertiary)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
