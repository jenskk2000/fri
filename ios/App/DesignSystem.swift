import SwiftUI
import UIKit

enum Ink {
    // Separate foreground accents keep small text readable in both appearances.
    static let background = adaptive(light: 0xF5F4EE, dark: 0x0B0D12)
    static let surface = adaptive(light: 0xFEFEFA, dark: 0x191D24)
    static let text = adaptive(light: 0x182820, dark: 0xFAFCFF)
    static let mint = adaptive(light: 0x176B48, dark: 0x4ADE9B)
    static let muted = adaptive(light: 0x56635B, dark: 0xB0BAC7)
    static let line = adaptive(light: 0xD8DDD5, dark: 0x2D2F33)
    /// Foreground on mint-tinted glass: paper on dark green, near-black on light green.
    static let onMint = adaptive(light: 0xFEFEFA, dark: 0x0B0D12)

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                           green: CGFloat((hex >> 8) & 255) / 255,
                           blue: CGFloat(hex & 255) / 255, alpha: 1)
        })
    }
    static func title(_ size: CGFloat) -> Font { .custom("Montserrat-ExtraBold", size: size, relativeTo: .largeTitle) }
    static func hand(_ size: CGFloat) -> Font { .custom("Inter-Regular", size: size, relativeTo: .title3).weight(.semibold) }
    static func body(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        let size: CGFloat
        switch style {
        case .largeTitle: size = 34
        case .title: size = 28
        case .title2: size = 22
        case .title3: size = 20
        case .headline, .body: size = 17
        case .callout: size = 16
        case .subheadline: size = 15
        case .footnote: size = 13
        case .caption: size = 12
        default: size = 11
        }
        return .custom("Inter-Regular", size: size, relativeTo: style).weight(weight)
    }
}

struct WaterfrontBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    let height: CGFloat
    var body: some View {
        GeometryReader { proxy in
            Image("Waterfront").resizable().scaledToFill()
                .frame(width: proxy.size.width, height: height, alignment: .center).clipped()
                .overlay(Ink.background.opacity(colorScheme == .light ? 0.58 : 0.17))
                .overlay {
                    LinearGradient(stops: [.init(color: Ink.background.opacity(0.10), location: 0), .init(color: .clear, location: 0.32), .init(color: Ink.background.opacity(0.55), location: 0.62), .init(color: Ink.background, location: 1)], startPoint: .top, endPoint: .bottom)
                }
        }.frame(height: height).accessibilityHidden(true)
    }
}

struct AppScreen<Content: View>: View {
    var photograph = false
    @ViewBuilder var content: () -> Content
    var body: some View {
        ZStack(alignment: .top) {
            Ink.background.ignoresSafeArea()
            if photograph {
                GeometryReader { proxy in
                    WaterfrontBackdrop(height: min(670, proxy.size.height * 0.75))
                        .ignoresSafeArea(edges: .top)
                }
            }
            content()
        }.foregroundStyle(Ink.text).font(Ink.body(.body)).tint(Ink.mint)
    }
}

struct BrandHeader: View {
    var settings: (() -> Void)? = nil
    var body: some View {
        HStack {
            Text("FRI").font(.custom("MarkerFelt-Wide", fixedSize: 34)).italic().rotationEffect(.degrees(-6))
                .foregroundStyle(Ink.mint).accessibilityLabel("FRI")
            Spacer()
            if let settings {
                GlassIconButton(symbol: "gearshape", label: "Indstillinger", action: settings).accessibilityIdentifier("settings")
            }
        }.padding(.horizontal, 22).padding(.top, 6).padding(.bottom, 8)
    }
}

/// Round Liquid Glass control for toolbar-like actions (settings, close).
struct GlassIconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 16, weight: .semibold)).frame(width: 26, height: 26)
        }.buttonStyle(.glass).buttonBorderShape(.circle)
            .foregroundStyle(Ink.text).accessibilityLabel(label)
    }
}

extension View {
    /// Liquid Glass capsule for small floating status chips. Keep text short: glass never carries paragraphs.
    func glassChip(tint: Color? = nil) -> some View {
        padding(.horizontal, 14).padding(.vertical, 9)
            .glassEffect(tint.map { .regular.tint($0) } ?? .regular, in: .capsule)
    }
}

struct PrimaryButton: View {
    var title: String
    var symbol: String = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(title).font(Ink.body(.headline, weight: .bold)).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Image(systemName: symbol).font(.system(size: 19, weight: .semibold))
            }.padding(.horizontal, 10).padding(.vertical, 8).frame(maxWidth: .infinity, minHeight: 40)
                .foregroundStyle(Ink.onMint)
        }.buttonStyle(.glassProminent).tint(Ink.mint).controlSize(.large)
            .sensoryFeedback(.selection, trigger: title)
    }
}

struct PressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct QuietButton: View {
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(Ink.body(.subheadline, weight: .semibold)).foregroundStyle(Ink.muted)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity, minHeight: 44)
        }.buttonStyle(.plain)
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View { Text(text.uppercased()).font(Ink.body(.caption, weight: .bold)).tracking(2).foregroundStyle(Ink.mint) }
}

struct PageHeading: View {
    var eyebrow: String
    var title: String
    var subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: eyebrow)
            Text(title).scaledTitle(33).tracking(-1.1).fixedSize(horizontal: false, vertical: true)
            if !subtitle.isEmpty { Text(subtitle).font(Ink.body(.body)).foregroundStyle(Ink.muted).fixedSize(horizontal: false, vertical: true).lineSpacing(4) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ChoiceRow: View {
    let title: String
    var detail: String = ""
    var symbol: String = ""
    var selected: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                if !symbol.isEmpty { Image(systemName: symbol).font(.system(size: 23)).frame(width: 27).foregroundStyle(selected ? Ink.mint : Ink.muted) }
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(Ink.body(.headline, weight: .semibold))
                    if !detail.isEmpty { Text(detail).font(Ink.body(.subheadline)).foregroundStyle(Ink.muted).fixedSize(horizontal: false, vertical: true) }
                }
                Spacer(minLength: 5)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle").font(.system(size: 22)).foregroundStyle(selected ? Ink.mint : Ink.muted)
            }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(Ink.text)
                .background(selected ? Ink.mint.opacity(0.08) : Ink.surface, in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(selected ? Ink.mint : Ink.line, lineWidth: 1))
        }.buttonStyle(PressStyle()).accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

struct NotePanel<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14, content: content)
            .frame(maxWidth: .infinity, alignment: .leading).padding(22)
            .background(Ink.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Ink.line))
    }
}

struct SheetHeader: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        HStack {
            Text(title).font(Ink.body(.headline, weight: .semibold))
            Spacer()
            GlassIconButton(symbol: "xmark", label: "Luk") { dismiss() }
        }.padding(.horizontal, 22).padding(.top, 18).padding(.bottom, 4)
    }
}

extension View {
    func scaledTitle(_ size: CGFloat) -> some View { font(Ink.title(size)) }
}
