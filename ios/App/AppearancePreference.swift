import SwiftUI
import UIKit

enum AppAppearance: String, CaseIterable, Identifiable {
    case light, dark, system
    var id: String { rawValue }
    var title: String {
        switch self {
        case .light: "Lys"
        case .dark: "Mørk"
        case .system: "System"
        }
    }
    var symbol: String {
        switch self {
        case .light: "sun.max"
        case .dark: "moon"
        case .system: "circle.lefthalf.filled"
        }
    }
    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: .unspecified
        }
    }
}

enum AppearancePreference {
    // Keep UI tests independent of the user's real appearance preference.
    static let defaults: UserDefaults = {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
            let defaults = UserDefaults(suiteName: "dk.fri.appearance.uitests")!
            if ProcessInfo.processInfo.arguments.contains("-reset-state") {
                defaults.removeObject(forKey: "appearance")
            }
            return defaults
        }
        #endif
        return .standard
    }()
}

struct AppearancePicker: View {
    @AppStorage("appearance", store: AppearancePreference.defaults) private var appearance: AppAppearance = .light

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "Udseende")
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { choices }
                VStack(spacing: 10) { choices }
            }
            Text(appearance == .system ? "Følger telefonens lyse eller mørke udseende." : "Dit valg gemmes automatisk på denne telefon.")
                .font(Ink.body(.footnote)).foregroundStyle(Ink.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var choices: some View {
        ForEach(AppAppearance.allCases) { option in
            Button { appearance = option } label: {
                VStack(spacing: 8) {
                    Image(systemName: option.symbol).font(.system(size: 21))
                    Text(option.title).font(Ink.body(.subheadline, weight: .semibold))
                        .fixedSize(horizontal: true, vertical: true)
                }
                .frame(maxWidth: .infinity).padding(.horizontal, 14).padding(.vertical, 16)
                .foregroundStyle(appearance == option ? Ink.mint : Ink.muted)
                .background(appearance == option ? Ink.mint.opacity(0.08) : Ink.surface, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(appearance == option ? Ink.mint : Ink.line, lineWidth: appearance == option ? 2 : 1))
            }
            .buttonStyle(PressStyle())
            .accessibilityIdentifier("appearance-\(option.rawValue)")
            .accessibilityLabel(option == .system ? "Følg systemet" : "\(option.title) tilstand")
            .accessibilityValue(appearance == option ? "Valgt" : "Ikke valgt")
            .accessibilityAddTraits(appearance == option ? [.isSelected] : [])
        }
    }
}

// Apply the preference to this scene's window, including presented sheets.
// Returning to .unspecified lets live system changes propagate naturally.
struct AppearanceOverride: UIViewRepresentable {
    let appearance: AppAppearance

    func makeUIView(context: Context) -> AppearanceView {
        let view = AppearanceView()
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
        view.style = appearance.interfaceStyle
        return view
    }

    func updateUIView(_ uiView: AppearanceView, context: Context) {
        uiView.style = appearance.interfaceStyle
        uiView.apply()
    }

    final class AppearanceView: UIView {
        var style: UIUserInterfaceStyle = .light
        override func didMoveToWindow() {
            super.didMoveToWindow()
            apply()
        }
        func apply() {
            guard let window, window.overrideUserInterfaceStyle != style else { return }
            window.overrideUserInterfaceStyle = style
        }
    }
}
