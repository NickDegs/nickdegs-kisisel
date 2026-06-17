import SwiftUI

// MARK: - Renkler / Tema
enum Brand {
    static let accent = Color(red: 0.04, green: 0.52, blue: 1.0)      // iOS mavisi
    static let accent2 = Color(red: 0.37, green: 0.36, blue: 0.90)
    static var gradient: LinearGradient {
        LinearGradient(colors: [accent, accent2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Basit yerelleştirme (cihaz diline göre TR/EN)
func L(_ tr: String, _ en: String) -> String {
    let code = Locale.current.language.languageCode?.identifier ?? "en"
    return code == "tr" ? tr : en
}

// MARK: - GERÇEK iOS 26 Liquid Glass modifikatörleri
// .glassEffect(.regular.interactive()) → gerçek kırılma/mercek kenarı (native materyal).
// iOS 26 altı için .ultraThinMaterial fallback.

extension View {
    /// Yuvarlatılmış dikdörtgen cam yüzey (kart/panel) — gerçek refraction + ince specular kenar.
    @ViewBuilder func glassPanel(_ radius: CGFloat = 22, tint: Color? = nil) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive().tint(tint), in: shape)
                .overlay(shape.strokeBorder(.white.opacity(0.18), lineWidth: 0.75)) // mercek/specular kenar
        } else {
            self.background(.ultraThinMaterial, in: shape)
                .overlay(shape.strokeBorder(.white.opacity(0.15), lineWidth: 0.75))
        }
    }

    /// Kapsül cam (buton/çip) — interaktif, harekete tepkili specular.
    @ViewBuilder func glassCapsule(tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive().tint(tint), in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 0.8))
        } else {
            self.background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 0.8))
        }
    }
}

// MARK: - Cam buton stili (tam saydam + parlak kenar + yay basış)
struct GlassButtonStyle: ButtonStyle {
    var tint: Color? = nil
    var prominent: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(prominent ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .padding(.vertical, 15).frame(maxWidth: .infinity)
            .glassCapsule(tint: prominent ? Brand.accent : tint)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .brightness(configuration.isPressed ? 0.06 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    static var glassy: GlassButtonStyle { GlassButtonStyle() }
    static func glassyProminent() -> GlassButtonStyle { GlassButtonStyle(prominent: true) }
}

// MARK: - Uygulama arka planı (aurora gradyan, açık/koyu uyumlu)
struct AuroraBackground: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
            RadialGradient(colors: [Brand.accent2.opacity(0.18), .clear],
                           center: .topTrailing, startRadius: 10, endRadius: 520)
            RadialGradient(colors: [Brand.accent.opacity(0.16), .clear],
                           center: .bottomLeading, startRadius: 10, endRadius: 520)
        }.ignoresSafeArea()
    }
}
