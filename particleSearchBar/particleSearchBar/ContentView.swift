//
//  ContentView.swift
//  particleSearchBar
//
//  Created by Melson Miranda on 3/17/26.
//

import SwiftUI
import UIKit
import Combine

// MARK: - BarConfig

struct BarConfig: Codable {
    var barHeight:         Double = 60
    var cursorHeight:      Double = 32
    var triTopHex:         String = "FBB9FC"
    var triBottomHex:      String = "FBB9FC"
    var triOpacity:        Double = 1.00   // apex (top) opacity
    var triBottomOpacity:  Double = 1.00   // base (bottom) opacity
    var progBlurOpacity:   Double = 0.00  // kept for Codable compat
    var progBlurRadius:    Double = 40.0  // max blur radius at base of combined beam container
    var progBlurStart:     Double = 0.55  // fraction of bar height where blur begins (0=top, 1=bottom)
    var cursorAnimSpeed:   Double = 5.0
    var fluidity:          Double = 0.00
    var beamAngle:         Double = 60    // kept for Codable compat — not displayed
    var beamWidth:         Double = 0.08  // base width as fraction of pill width (0–1)
    var beamCurve:         Double = -0.40  // kept for Codable compat — not displayed
    var beamCurveL:        Double = -0.40  // left side curve
    var beamCurveR:        Double = -0.40  // right side curve
    var beamApexOffset:    Double = -6.0
    var beamInertia:            Double = 20.0  // kept for Codable compat — not displayed
    var beamBaseLeftInertia:    Double = 20.0  // animation strength for left corner
    var beamBaseRightInertia:   Double = 20.0  // animation strength for right corner
    var beamBaseLeftOffset:     Double = 0.0   // pt nudge for left base corner
    var beamBaseRightOffset:    Double = 0.0   // pt nudge for right base corner
    var beamCurveDrag:          Double = 20.0  // how much velocity bends the curves (broom sweep)
    var specularOpacity:        Double = 0.55  // rim + apex highlight brightness
    var specularReach:          Double = 0.30  // how far down the rim fades (0–1 of triangle height)
    // Text character animation
    var charTypeDuration:  Double = 0.80  // spring duration when typing
    var charTypeBounce:    Double = 0.60  // spring bounce when typing
    var charTypeScale:     Double = 0.55  // start scale for insertion
    var charDeleteDuration:Double = 0.12  // easeOut duration on backspace
    var borderHex:         String = "373737"
    var iconHex:           String = "373737"
    var glurRadius:        Double = 28.2
    var glurOffset:        Double = 0.77
    var glurInterp:        Double = 0.28

    // Beam 2 (rendered behind Beam 1)
    var tri2TopHex:        String = "FBB9FC"
    var tri2BottomHex:     String = "FBB9FC"
    var tri2Opacity:       Double = 0.66
    var tri2BottomOpacity: Double = 0.15
    var progBlur2Opacity:  Double = 0.63
    var progBlur2Radius:   Double = 0.0
    var beam2Angle:        Double = 90.0   // kept for Codable compat — not displayed
    var beam2Width:        Double = 0.12  // base width as fraction of pill width (0–1)
    var beam2Curve:        Double = -0.40  // kept for Codable compat — not displayed
    var beam2CurveL:       Double = -0.40
    var beam2CurveR:       Double = -0.40
    var beam2ApexOffset:   Double = -6.0
    var beam2Inertia:           Double = 20.0  // kept for Codable compat — not displayed
    var beam2BaseLeftInertia:   Double = 20.0
    var beam2BaseRightInertia:  Double = 20.0
    var beam2BaseLeftOffset:    Double = 0.0
    var beam2BaseRightOffset:   Double = 0.0
    var beam2CurveDrag:         Double = 20.0
    var spec2Opacity:           Double = 1.00
    var spec2Reach:             Double = 1.00
    var glur2Radius:       Double = 2.1
    var glur2Offset:       Double = 0.85
    var glur2Interp:       Double = 1.00

    static let `default` = BarConfig()

    // MARK: Persistence
    private static let saveKey = "barConfig_v1"

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.saveKey)
    }

    static func load() -> BarConfig {
        guard
            let data   = UserDefaults.standard.data(forKey: saveKey),
            let config = try? JSONDecoder().decode(BarConfig.self, from: data)
        else { return .default }
        return config
    }
}

// MARK: - Hex → Color helper

private func colorFromHex(_ hex: String) -> Color {
    let h = hex.filter { $0.isHexDigit }
    guard h.count == 6,
          let r = UInt8(h.prefix(2), radix: 16),
          let g = UInt8(h.dropFirst(2).prefix(2), radix: 16),
          let b = UInt8(h.dropFirst(4).prefix(2), radix: 16) else {
        return Color(red: 0.216, green: 0.216, blue: 0.216)
    }
    return Color(red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
}

// MARK: - SliderRow

struct SliderRow: View {
    let label:    String
    @Binding var value: Double
    let range:    ClosedRange<Double>
    let unit:     String
    let decimals: Int

    private var display: String {
        decimals == 0
            ? "\(Int(value))\(unit)"
            : String(format: "%.\(decimals)f\(unit)", value)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                Spacer()
                Text(display)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.45))
            }
            Slider(value: $value, in: range)
                .tint(.white.opacity(0.75))
        }
    }
}

// MARK: - ColorHexRow

struct ColorHexRow: View {
    let label: String
    @Binding var hex: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(colorFromHex(hex))
                    .frame(width: 22, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
                HStack(spacing: 3) {
                    Text("#")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.40))
                    TextField("RRGGBB", text: $hex)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.85))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .onChange(of: hex) { _, v in
                            hex = String(v.filter { $0.isHexDigit }.prefix(6)).uppercased()
                        }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

// MARK: - AccordionSection

private struct AccordionSection<Content: View>: View {
    let title:   String
    let content: () -> Content
    @State private var expanded = true

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title   = title
        self.content = content
    }

    private let cols = [GridItem(.flexible(), spacing: 24),
                        GridItem(.flexible(), spacing: 24)]

    var body: some View {
        VStack(spacing: 0) {
            // ── Header row ──────────────────────────────────────────────────
            Button {
                withAnimation(.spring(duration: 0.28, bounce: 0.15)) { expanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.35))
                        .rotationEffect(.degrees(expanded ? 0 : -90))
                }
                .contentShape(Rectangle())
                .padding(.vertical, 9)
            }
            .buttonStyle(.plain)

            // ── Content grid ────────────────────────────────────────────────
            if expanded {
                LazyVGrid(columns: cols, alignment: .leading, spacing: 20) {
                    content()
                }
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - ControlPanel

struct ControlPanel: View {
    @Binding var config: BarConfig

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // ── Title ────────────────────────────────────────────────────
                HStack {
                    Text("Behaviour")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                }
                .padding(.bottom, 10)

                // ── Beam ─────────────────────────────────────────────────────
                AccordionSection("Beam") {
                    ColorHexRow(label: "Top Colour",     hex: $config.triTopHex)
                    ColorHexRow(label: "Bottom Colour",  hex: $config.triBottomHex)
                    SliderRow(label: "Top Opacity",      value: $config.triOpacity,       range: 0...1,    unit: "",    decimals: 2)
                    SliderRow(label: "Bottom Opacity",   value: $config.triBottomOpacity, range: 0...1,    unit: "",    decimals: 2)
                    SliderRow(label: "Base Width",        value: $config.beamWidth,    range: 0...1,    unit: "",    decimals: 2)
                    SliderRow(label: "Left Curve",       value: $config.beamCurveL,   range: -1...1,   unit: "",    decimals: 2)
                    SliderRow(label: "Right Curve",      value: $config.beamCurveR,   range: -1...1,   unit: "",    decimals: 2)
                    SliderRow(label: "Apex Offset",      value: $config.beamApexOffset, range: -30...30, unit: "pt",  decimals: 0)
                    SliderRow(label: "Left Corner",      value: $config.beamBaseLeftOffset,     range: -200...200, unit: "pt",  decimals: 0)
                    SliderRow(label: "Right Corner",     value: $config.beamBaseRightOffset,    range: -200...200, unit: "pt",  decimals: 0)
                    SliderRow(label: "Left Inertia",     value: $config.beamBaseLeftInertia,    range: 0...20,     unit: "×",   decimals: 1)
                    SliderRow(label: "Right Inertia",    value: $config.beamBaseRightInertia,   range: 0...20,     unit: "×",   decimals: 1)
                    SliderRow(label: "Curve Drag",       value: $config.beamCurveDrag,          range: 0...20,     unit: "×",   decimals: 1)
                    SliderRow(label: "Specular",         value: $config.specularOpacity,        range: 0...1,      unit: "",    decimals: 2)
                    SliderRow(label: "Spec Reach",       value: $config.specularReach,          range: 0...1,      unit: "",    decimals: 2)
                }
                divider

                divider

                // ── Beam 2 ───────────────────────────────────────────────────
                AccordionSection("Beam 2") {
                    ColorHexRow(label: "Top Colour",     hex: $config.tri2TopHex)
                    ColorHexRow(label: "Bottom Colour",  hex: $config.tri2BottomHex)
                    SliderRow(label: "Top Opacity",      value: $config.tri2Opacity,      range: 0...1,    unit: "",    decimals: 2)
                    SliderRow(label: "Bottom Opacity",   value: $config.tri2BottomOpacity,range: 0...1,    unit: "",    decimals: 2)
                    SliderRow(label: "Base Width",        value: $config.beam2Width,    range: 0...1,    unit: "",    decimals: 2)
                    SliderRow(label: "Left Curve",       value: $config.beam2CurveL,   range: -1...1,   unit: "",    decimals: 2)
                    SliderRow(label: "Right Curve",      value: $config.beam2CurveR,   range: -1...1,   unit: "",    decimals: 2)
                    SliderRow(label: "Apex Offset",      value: $config.beam2ApexOffset, range: -30...30, unit: "pt",  decimals: 0)
                    SliderRow(label: "Left Corner",      value: $config.beam2BaseLeftOffset,    range: -200...200, unit: "pt",  decimals: 0)
                    SliderRow(label: "Right Corner",     value: $config.beam2BaseRightOffset,   range: -200...200, unit: "pt",  decimals: 0)
                    SliderRow(label: "Left Inertia",     value: $config.beam2BaseLeftInertia,   range: 0...20,     unit: "×",   decimals: 1)
                    SliderRow(label: "Right Inertia",    value: $config.beam2BaseRightInertia,  range: 0...20,     unit: "×",   decimals: 1)
                    SliderRow(label: "Curve Drag",       value: $config.beam2CurveDrag,         range: 0...20,     unit: "×",   decimals: 1)
                    SliderRow(label: "Specular",         value: $config.spec2Opacity,           range: 0...1,      unit: "",    decimals: 2)
                    SliderRow(label: "Spec Reach",       value: $config.spec2Reach,             range: 0...1,      unit: "",    decimals: 2)
                }
                divider

                // ── Progressive Blur (Metal shader — shared by both beams) ──
                AccordionSection("Prog Blur") {
                    SliderRow(label: "Max Radius",   value: $config.progBlurRadius, range: 0...60,  unit: "pt", decimals: 0)
                    SliderRow(label: "Start",        value: $config.progBlurStart,  range: 0...1,   unit: "",   decimals: 2)
                }
                divider

                // ── Edge Glow — Beam 1 ───────────────────────────────────────
                AccordionSection("Glow 1") {
                    SliderRow(label: "Edge Radius",  value: $config.glurRadius,  range: 0...30, unit: "", decimals: 1)
                    SliderRow(label: "Edge Offset",  value: $config.glurOffset,  range: 0...1,  unit: "", decimals: 2)
                    SliderRow(label: "Edge Interp",  value: $config.glurInterp,  range: 0...1,  unit: "", decimals: 2)
                }
                divider

                // ── Edge Glow — Beam 2 ───────────────────────────────────────
                AccordionSection("Glow 2") {
                    SliderRow(label: "Edge Radius",  value: $config.glur2Radius,  range: 0...30, unit: "", decimals: 1)
                    SliderRow(label: "Edge Offset",  value: $config.glur2Offset,  range: 0...1,  unit: "", decimals: 2)
                    SliderRow(label: "Edge Interp",  value: $config.glur2Interp,  range: 0...1,  unit: "", decimals: 2)
                }
                divider

                // ── Cursor ───────────────────────────────────────────────────
                AccordionSection("Cursor") {
                    SliderRow(label: "Speed",            value: $config.cursorAnimSpeed,  range: 0.1...5,  unit: "×",   decimals: 1)
                    SliderRow(label: "Fluidity",         value: $config.fluidity,         range: 0...1,    unit: "",    decimals: 2)
                }
                divider

                // ── Text ─────────────────────────────────────────────────────
                AccordionSection("Text") {
                    SliderRow(label: "Type Duration",  value: $config.charTypeDuration,   range: 0.05...0.8, unit: "s",  decimals: 2)
                    SliderRow(label: "Type Bounce",    value: $config.charTypeBounce,     range: 0...1,      unit: "",   decimals: 2)
                    SliderRow(label: "Type Scale",     value: $config.charTypeScale,      range: 0...1,      unit: "",   decimals: 2)
                    SliderRow(label: "Delete Duration",value: $config.charDeleteDuration, range: 0.03...0.5, unit: "s",  decimals: 2)
                }
                divider

                // ── Style ────────────────────────────────────────────────────
                AccordionSection("Style") {
                    ColorHexRow(label: "Border",         hex: $config.borderHex)
                    ColorHexRow(label: "Icon",           hex: $config.iconHex)
                }

                // ── Actions ──────────────────────────────────────────────────
                HStack(spacing: 12) {
                    Spacer()
                    Button("Reset") {
                        withAnimation(.spring(duration: 0.4, bounce: 0.3)) { config = .default }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 20).padding(.vertical, 9)
                    .glassEffect(.regular, in: Capsule())

                    Button("Save") { config.save() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 9)
                    .glassEffect(.regular, in: Capsule())
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .background(Color(red: 0.216, green: 0.216, blue: 0.216), in: RoundedRectangle(cornerRadius: 26))
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.07))
            .frame(height: 1)
            .padding(.horizontal, -20)   // bleed to edges
    }
}

// MARK: - UITextField wrapper (invisible native cursor)

struct ClearCursorTextField: UIViewRepresentable {
    @Binding var text: String
    let font:         UIFont
    let placeholder:  String
    let onFocus:      (Bool) -> Void

    func makeUIView(context: Context) -> UITextField {
        let tf                   = UITextField()
        tf.delegate              = context.coordinator
        tf.font                  = font
        tf.textColor             = .clear   // text rendered by animated SwiftUI overlay
        tf.backgroundColor       = .clear
        tf.tintColor             = .clear
        tf.autocorrectionType    = .no
        tf.spellCheckingType     = .no
        tf.smartQuotesType       = .no
        tf.smartDashesType       = .no
        tf.returnKeyType         = .done
        tf.attributedPlaceholder = NSAttributedString(
            string:     placeholder,
            attributes: [.foregroundColor: UIColor.placeholderText]
        )
        tf.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged(_:)),
            for: .editingChanged
        )
        return tf
    }

    func updateUIView(_ tf: UITextField, context: Context) {
        if tf.text != text { tf.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: ClearCursorTextField
        init(_ p: ClearCursorTextField) { parent = p }

        @objc func textChanged(_ tf: UITextField) {
            parent.text = tf.text ?? ""
        }
        func textFieldDidBeginEditing(_ tf: UITextField) { parent.onFocus(true) }
        func textFieldDidEndEditing(_ tf: UITextField)   { parent.onFocus(false) }
        func textFieldShouldReturn(_ tf: UITextField) -> Bool {
            tf.resignFirstResponder(); return true
        }
    }
}

// TriangleVariableBlurView and TriangleBlurUIView removed —
// replaced by the Metal shader (triangleVariableBlur in VariableBlur.metal)
// applied to the combined beam container in GlowInputBar.

// MARK: - GlowInputBar

// Each typed character gets a stable UUID so SwiftUI can animate only new insertions.
private struct CharEntry: Identifiable { let id = UUID(); let char: Character }

struct GlowInputBar: View {

    let config: BarConfig

    @State private var text:          String      = ""
    @State private var charEntries:   [CharEntry] = []
    @State private var focused:       Bool        = false
    @State private var cursorX:       CGFloat = 0
    @State private var rawTextWidth:  CGFloat = 0   // immediate (no animation) — used for text clip only
    @State private var prevCursorX:   CGFloat = 0   // for velocity tracking
    @State private var baseSkewL:     CGFloat = 0   // beam1 left corner inertia
    @State private var baseSkewR:     CGFloat = 0   // beam1 right corner inertia
    @State private var baseSkew2L:    CGFloat = 0   // beam2 left corner inertia
    @State private var baseSkew2R:    CGFloat = 0   // beam2 right corner inertia
    @State private var curveSkew:     CGFloat = 0   // beam1 broom-sweep curve offset
    @State private var curveSkew2:    CGFloat = 0   // beam2 broom-sweep curve offset
    @State private var currentHeight: CGFloat = 70  // fixed pill height

    private var barH:    CGFloat { currentHeight }
    private var cursorH: CGFloat { CGFloat(config.cursorHeight) }
    private let plusW:   CGFloat = 60
    private let inputFont        = UIFont.systemFont(ofSize: 17, weight: .regular)

    private let ticker = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {

            RoundedRectangle(cornerRadius: barH / 2)
                .strokeBorder(iridescentGradient, lineWidth: 1)

            HStack(spacing: 0) {

                // ── + button ──────────────────────────────────────────────
                Button { } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(colorFromHex(config.iconHex))
                }
                .frame(width: plusW, height: barH)

                // ── Text field + animated character overlay ───────────────
                GeometryReader { _ in
                    ClearCursorTextField(
                        text:        $text,
                        font:        inputFont,
                        placeholder: "Type something…",
                        onFocus:     { v in focused = v }
                    )
                    .frame(height: barH)
                    .onAppear { measureCursor() }
                    .onChange(of: text) { old, new in
                        measureCursor()
                        syncChars(old: old, new: new)
                    }

                    // Animated per-character rendering
                    HStack(spacing: 0) {
                        ForEach(charEntries) { entry in
                            Text(String(entry.char))
                                .font(Font(inputFont))
                                .foregroundStyle(.white)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(
                                        with: .scale(scale: config.charTypeScale, anchor: .center)),
                                    removal: .opacity
                                ))
                        }
                    }
                    // fixedSize prevents the HStack from compressing when the clip
                    // frame is narrower than its natural width (e.g. during deletion)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(width: max(0, rawTextWidth), height: barH, alignment: .leading)
                    .clipped()
                    .allowsHitTesting(false)
                }
                .padding(.trailing, 20)
            }

            if focused {

                // ── Both beams in one container — Metal progressive blur ──
                // The shader blurs the beams' own pixels, sharply at the apex
                // and progressively spreading toward the base (broom/flame look).
                beamsContainer
                    .layerEffect(
                        ShaderLibrary.triangleVariableBlur(
                            .float(Float(config.progBlurRadius)),
                            .float(Float(config.progBlurStart * barH)),
                            .float(Float(barH))
                        ),
                        maxSampleOffset: CGSize(
                            width:  config.progBlurRadius,
                            height: config.progBlurRadius
                        )
                    )
                    .allowsHitTesting(false)

                // ── Cursor (always on top, never blurred) ─────────────────
                beamCursorCanvas
            }
        }
        .frame(height: barH)
        .clipShape(RoundedRectangle(cornerRadius: barH / 2))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: barH / 2))
        .onReceive(ticker) { _ in tick() }
    }

    // MARK: - Beam canvas helpers

    /// Both beams (2 behind, 1 in front) in a single layer.
    /// The Metal shader is applied to this container so one progressive blur
    /// covers both — sharp at the apex, spreading toward the base.
    @ViewBuilder private var beamsContainer: some View {
        ZStack {
            // ── Beam 2 (behind, wider/softer) ────────────────────────────
            ZStack {
                // Glow halo — reduced opacity so it doesn't double the beam brightness
                ZStack { beamTriangle2Canvas }
                    .blur(radius: CGFloat(config.glur2Radius))
                    .opacity(0.60)
                // Sharp beam — gradient mask fades to a small residual (not fully clear)
                // so the Metal shader has visible pixels to blur at the transition zone.
                ZStack { beamTriangle2Canvas }
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: config.glur2Offset),
                                .init(color: .black.opacity(0.18),
                                      location: min(1, config.glur2Offset + config.glur2Interp))
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: barH / 2))

            // ── Beam 1 (front, narrower/sharper) ─────────────────────────
            ZStack {
                // Glow halo — reduced opacity so it doesn't double the beam brightness
                ZStack { beamTriangleCanvas }
                    .blur(radius: CGFloat(config.glurRadius))
                    .opacity(0.60)
                // Sharp beam — gradient mask fades to a small residual (not fully clear)
                ZStack { beamTriangleCanvas }
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: config.glurOffset),
                                .init(color: .black.opacity(0.18),
                                      location: min(1, config.glurOffset + config.glurInterp))
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: barH / 2))
        }
    }

    @ViewBuilder private var beamCursorCanvas: some View {
        Canvas { ctx, size in
            let midY = size.height / 2
            let cTop = midY - cursorH / 2
            let cBot = midY + cursorH / 2
            let x    = plusW + cursorX
            ctx.fill(
                Path(CGRect(x: x, y: cTop, width: 2, height: cursorH)),
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.988, green: 0.859, blue: 0.557), // #FCDB8E
                        Color(red: 0.984, green: 0.725, blue: 0.988)  // #FBB9FC
                    ]),
                    startPoint: CGPoint(x: x, y: cTop),
                    endPoint:   CGPoint(x: x, y: cBot)
                )
            )
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder private var beamTriangleCanvas: some View {
        Canvas { ctx, size in
            let midY      = size.height / 2
            let cBot      = midY + cursorH / 2
            let apexX     = plusW + cursorX + 1
            let halfW     = (size.width / 2) * CGFloat(config.beamWidth)
            let apexY     = cBot + CGFloat(config.beamApexOffset)
            let apex      = CGPoint(x: apexX, y: apexY)
            let baseL     = CGPoint(x: apexX - halfW + baseSkewL + CGFloat(config.beamBaseLeftOffset),  y: size.height)
            let baseR     = CGPoint(x: apexX + halfW + baseSkewR + CGFloat(config.beamBaseRightOffset), y: size.height)
            let sidesMidY  = (apexY + size.height) / 2
            let curvePushL = halfW * CGFloat(config.beamCurveL)
            let curvePushR = halfW * CGFloat(config.beamCurveR)
            // Broom sweep: control points move in opposite directions to create an asymmetric trail.
            // Moving right (curveSkew > 0):
            //   left control shifts RIGHT  → left (leading) side opens / flattens
            //   right control shifts LEFT  → right (trailing) side curves deeper inward, then springs back
            // Moving left: mirror — right opens, left trails.
            let controlL   = CGPoint(x: (apexX + baseL.x) / 2 - curvePushL + curveSkew, y: sidesMidY)
            let controlR   = CGPoint(x: (apexX + baseR.x) / 2 + curvePushR - curveSkew, y: sidesMidY)
            var tri = Path()
            tri.move(to: apex)
            tri.addQuadCurve(to: baseL, control: controlL)
            tri.addLine(to: baseR)
            tri.addQuadCurve(to: apex, control: controlR)
            ctx.fill(tri, with: .linearGradient(
                Gradient(stops: [
                    .init(color: colorFromHex(config.triTopHex).opacity(config.triOpacity),          location: 0),
                    .init(color: colorFromHex(config.triBottomHex).opacity(config.triBottomOpacity), location: 1)
                ]),
                startPoint: CGPoint(x: apexX, y: apexY),
                endPoint:   CGPoint(x: apexX, y: size.height)
            ))
            // ── Glass specular (tinted to beam colour) ───────────────────
            if config.specularOpacity > 0 {
                let specColor = colorFromHex(config.triTopHex)
                let rimEnd    = apexY + (size.height - apexY) * CGFloat(config.specularReach)
                ctx.stroke(tri, with: .linearGradient(
                    Gradient(stops: [
                        .init(color: specColor.opacity(config.specularOpacity), location: 0),
                        .init(color: specColor.opacity(0),                      location: 1)
                    ]),
                    startPoint: CGPoint(x: apexX, y: apexY),
                    endPoint:   CGPoint(x: apexX, y: rimEnd)
                ), lineWidth: 1.0)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder private var beamTriangle2Canvas: some View {
        Canvas { ctx, size in
            let midY      = size.height / 2
            let cBot      = midY + cursorH / 2
            let apexX     = plusW + cursorX + 1
            let halfW     = (size.width / 2) * CGFloat(config.beam2Width)
            let apexY     = cBot + CGFloat(config.beam2ApexOffset)
            let apex      = CGPoint(x: apexX, y: apexY)
            let baseL     = CGPoint(x: apexX - halfW + baseSkew2L + CGFloat(config.beam2BaseLeftOffset),  y: size.height)
            let baseR     = CGPoint(x: apexX + halfW + baseSkew2R + CGFloat(config.beam2BaseRightOffset), y: size.height)
            let sidesMidY  = (apexY + size.height) / 2
            let curvePushL = halfW * CGFloat(config.beam2CurveL)
            let curvePushR = halfW * CGFloat(config.beam2CurveR)
            let controlL   = CGPoint(x: (apexX + baseL.x) / 2 - curvePushL + curveSkew2, y: sidesMidY)
            let controlR   = CGPoint(x: (apexX + baseR.x) / 2 + curvePushR - curveSkew2, y: sidesMidY)
            var tri = Path()
            tri.move(to: apex)
            tri.addQuadCurve(to: baseL, control: controlL)
            tri.addLine(to: baseR)
            tri.addQuadCurve(to: apex, control: controlR)
            ctx.fill(tri, with: .linearGradient(
                Gradient(stops: [
                    .init(color: colorFromHex(config.tri2TopHex).opacity(config.tri2Opacity),          location: 0),
                    .init(color: colorFromHex(config.tri2BottomHex).opacity(config.tri2BottomOpacity), location: 1)
                ]),
                startPoint: CGPoint(x: apexX, y: apexY),
                endPoint:   CGPoint(x: apexX, y: size.height)
            ))
            // ── Glass specular (tinted to beam 2 colour) ─────────────────
            if config.spec2Opacity > 0 {
                let specColor = colorFromHex(config.tri2TopHex)
                let rimEnd    = apexY + (size.height - apexY) * CGFloat(config.spec2Reach)
                ctx.stroke(tri, with: .linearGradient(
                    Gradient(stops: [
                        .init(color: specColor.opacity(config.spec2Opacity), location: 0),
                        .init(color: specColor.opacity(0),                   location: 1)
                    ]),
                    startPoint: CGPoint(x: apexX, y: apexY),
                    endPoint:   CGPoint(x: apexX, y: rimEnd)
                ), lineWidth: 1.0)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Sub-views

    private var iridescentGradient: LinearGradient {
        let c = colorFromHex(config.borderHex)
        return LinearGradient(colors: [c, c], startPoint: .leading, endPoint: .trailing)
    }

    // MARK: - Physics loop (inertia only — no particles)

    private func tick() {
        // Each corner is driven by the same cursor velocity but its own inertia multiplier,
        // so left and right (and beam 1 vs beam 2) can move completely independently.
        let rawDelta     = cursorX - prevCursorX
        prevCursorX      = cursorX
        let v            = max(-12, min(12, rawDelta))   // clamped velocity

        // +v sign: trailing corner bends inward, leading corner opens outward
        // (right stays open when moving right; left stays open when moving left)
        let tL  = -v * CGFloat(config.beamBaseLeftInertia)
        let tR  = -v * CGFloat(config.beamBaseRightInertia)
        let tL2 = -v * CGFloat(config.beam2BaseLeftInertia)
        let tR2 = -v * CGFloat(config.beam2BaseRightInertia)

        baseSkewL  += (tL  - baseSkewL)  * 0.12
        baseSkewR  += (tR  - baseSkewR)  * 0.12
        baseSkew2L += (tL2 - baseSkew2L) * 0.12
        baseSkew2R += (tR2 - baseSkew2R) * 0.12

        // Broom-sweep: both control points shift in the trailing direction.
        // Positive v (moving right) → curveSkew > 0 → left opens, right compresses.
        curveSkew  += (v * CGFloat(config.beamCurveDrag)  - curveSkew)  * 0.12
        curveSkew2 += (v * CGFloat(config.beam2CurveDrag) - curveSkew2) * 0.12
    }

    // MARK: - Character sync for animated overlay

    private func syncChars(old: String, new: String) {
        let oldCount = old.count
        let newCount = new.count

        if newCount > oldCount, new.hasPrefix(old) {
            // Characters appended (normal typing)
            let added = new.dropFirst(oldCount)
            withAnimation(.spring(duration: config.charTypeDuration, bounce: config.charTypeBounce)) {
                charEntries.append(contentsOf: added.map { CharEntry(char: $0) })
            }
        } else if newCount < oldCount, new == String(old.prefix(newCount)) {
            // Characters removed from end (backspace)
            withAnimation(.easeOut(duration: config.charDeleteDuration)) {
                charEntries.removeLast(oldCount - newCount)
            }
        } else {
            // Paste, cut, or mid-string edit — rebuild without animation
            charEntries = new.map { CharEntry(char: $0) }
        }
    }

    // MARK: - Cursor measurement

    private func measureCursor() {
        let attrs: [NSAttributedString.Key: Any] = [.font: inputFont]
        let target = (text as NSString).size(withAttributes: attrs).width
        // Update clip boundary with animation explicitly disabled — so characters
        // are never squeezed by a shrinking frame on backspace, even when
        // SwiftUI batches this update alongside an animated charEntries removal.
        withAnimation(nil) { rawTextWidth = target }
        if config.fluidity < 0.05 {
            cursorX = target
        } else {
            withAnimation(.spring(
                duration: config.fluidity * 0.7,
                bounce:   config.fluidity * 0.55
            )) {
                cursorX = target
            }
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @State private var barConfig = BarConfig.load()

    var body: some View {
        ZStack {
            Color(red: 0.039, green: 0.039, blue: 0.039)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                ControlPanel(config: $barConfig)
                GlowInputBar(config: barConfig)
                    .padding(.horizontal, 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
