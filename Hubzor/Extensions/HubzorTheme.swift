import SwiftUI

// MARK: - Hubzor Visual Theme

enum HubzorTheme {

    // ── Backgrounds ──────────────────────────────────────────────────────────
    static let background     = Color(hex: "0D0D14")   // página
    static let cardBackground = Color(hex: "14141F")   // cartão padrão
    static let cardAlt        = Color(hex: "1C1C2C")   // cartão alternativo / trilha de progresso

    // ── Neon accents ─────────────────────────────────────────────────────────
    static let neonPurple     = Color(hex: "A855F7")
    static let neonCyan       = Color(hex: "22D3EE")

    // ── Semantic ─────────────────────────────────────────────────────────────
    static let success        = Color(hex: "10B981")   // verde esmeralda
    static let warning        = Color(hex: "F59E0B")   // âmbar

    // ── Texto ────────────────────────────────────────────────────────────────
    static let textSecondary  = Color(hex: "94A3B8")

    // ── Desabilitado ─────────────────────────────────────────────────────────
    static let disabled       = Color(hex: "252535")

    // ── Gradientes ───────────────────────────────────────────────────────────
    static let accentGradient = LinearGradient(
        colors: [neonPurple, neonCyan],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let accentGradientDiag = LinearGradient(
        colors: [neonPurple, neonCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - NeonCard Modifier

struct NeonCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 18
    var glowOpacity: Double   = 0.38

    func body(content: Content) -> some View {
        content
            .background(HubzorTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                HubzorTheme.neonPurple.opacity(glowOpacity),
                                HubzorTheme.neonCyan.opacity(glowOpacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: HubzorTheme.neonPurple.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func neonCard(cornerRadius: CGFloat = 18, glowOpacity: Double = 0.38) -> some View {
        modifier(NeonCardStyle(cornerRadius: cornerRadius, glowOpacity: glowOpacity))
    }
}
