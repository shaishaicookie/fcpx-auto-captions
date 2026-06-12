import Foundation
import SwiftUI

// MARK: - Codable Color
/// A Codable wrapper for Color/NSColor
struct CodableColor: Codable, Equatable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat

    init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
        self.red = r
        self.green = g
        self.blue = b
        self.alpha = a
    }

    init(color: NSColor) {
        let converted = color.usingColorSpace(.sRGB) ?? color
        self.red = converted.redComponent
        self.green = converted.greenComponent
        self.blue = converted.blueComponent
        self.alpha = converted.alphaComponent
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    var nsColor: NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// Convert to FCPXML color string format: "r g b a"
    func toFCPXMLString() -> String {
        return "\(red) \(green) \(blue) \(alpha)"
    }

    // MARK: - Preset Colors
    static let white = CodableColor(r: 1, g: 1, b: 1, a: 1)
    static let black = CodableColor(r: 0, g: 0, b: 0, a: 1)
    static let blackShadow = CodableColor(r: 0, g: 0, b: 0, a: 0.75)
}

// MARK: - Position Preset
enum PositionPreset: String, CaseIterable, Codable, Identifiable {
    case bottomCenter = "Bottom Center"
    case topCenter = "Top Center"
    case center = "Center"
    case bottomLeft = "Bottom Left"
    case bottomRight = "Bottom Right"
    case custom = "Custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bottomCenter: return String(localized: "Bottom Center", comment: "Position preset")
        case .topCenter: return String(localized: "Top Center", comment: "Position preset")
        case .center: return String(localized: "Center", comment: "Position preset")
        case .bottomLeft: return String(localized: "Bottom Left", comment: "Position preset")
        case .bottomRight: return String(localized: "Bottom Right", comment: "Position preset")
        case .custom: return String(localized: "Custom", comment: "Position preset")
        }
    }

    /// Get default position for this preset based on resolution.
    func position(forWidth width: Int, height: Int) -> (x: CGFloat, y: CGFloat) {
        // In FCPXML, 0 is center, negative Y is down, and positive Y is up.
        // Portrait Basic Title projects still use a landscape-like title
        // coordinate space, so vertical presets use the shorter side as Y basis.
        let horizontalOffset = CGFloat(width) * (300.0 / 1920.0)
        let isPortrait = height > width
        let bottomY: CGFloat
        let topY: CGFloat

        if isPortrait {
            let portraitBottomOffset = CGFloat(width) * (485.0 / 1080.0)
            bottomY = -portraitBottomOffset
            topY = portraitBottomOffset
        } else {
            let verticalMargin = CGFloat(height) * (75.0 / 1080.0)
            bottomY = -CGFloat(height) / 2 + verticalMargin
            topY = CGFloat(height) / 2 - verticalMargin
        }

        let leftX = -horizontalOffset
        let rightX = horizontalOffset

        switch self {
        case .bottomCenter: return (0, bottomY)
        case .topCenter: return (0, topY)
        case .center: return (0, 0)
        case .bottomLeft: return (leftX, bottomY)
        case .bottomRight: return (rightX, bottomY)
        case .custom: return (0, bottomY)  // Default to bottom center for custom
        }
    }
}

// MARK: - Font Scale Mode
enum TitleFontScaleMode: String, CaseIterable, Codable, Identifiable {
    case fixed = "Fixed"
    case scaleWithResolution = "Scale With Resolution"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fixed: return String(localized: "Fixed", comment: "Font scale mode")
        case .scaleWithResolution: return String(localized: "Scale With Resolution", comment: "Font scale mode")
        }
    }
}

// MARK: - Font Weight
enum TitleFontWeight: String, CaseIterable, Codable, Identifiable {
    case regular = "Regular"
    case medium = "Medium"
    case semibold = "Semibold"
    case bold = "Bold"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .regular: return String(localized: "Regular", comment: "Font weight")
        case .medium: return String(localized: "Medium", comment: "Font weight")
        case .semibold: return String(localized: "Semibold", comment: "Font weight")
        case .bold: return String(localized: "Bold", comment: "Font weight")
        }
    }
}

// MARK: - Text Alignment
enum TitleTextAlignment: String, CaseIterable, Codable, Identifiable {
    case left = "Left"
    case center = "Center"
    case right = "Right"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .left: return String(localized: "Left", comment: "Text alignment")
        case .center: return String(localized: "Center", comment: "Text alignment")
        case .right: return String(localized: "Right", comment: "Text alignment")
        }
    }

    /// FCPXML alignment param value
    var fcpxmlParamValue: String {
        switch self {
        case .left: return "0 (Left)"
        case .center: return "1 (Center)"
        case .right: return "2 (Right)"
        }
    }

    /// FCPXML text-style alignment value
    var fcpxmlStyleValue: String {
        rawValue.lowercased()
    }
}

// MARK: - Title Preview Geometry
/// Converts between FCPXML title coordinates and preview canvas coordinates.
/// FCPXML uses the video center as origin with positive Y upward; SwiftUI uses
/// the canvas top-left as origin with positive Y downward.
struct TitlePreviewGeometry: Equatable {
    let videoWidth: CGFloat
    let videoHeight: CGFloat
    let coordinateWidth: CGFloat
    let coordinateHeight: CGFloat
    let canvasSize: CGSize

    init(videoWidth: Int, videoHeight: Int, canvasSize: CGSize) {
        self.videoWidth = CGFloat(videoWidth)
        self.videoHeight = CGFloat(videoHeight)
        let coordinateSize = Self.positionCoordinateSize(videoWidth: videoWidth, videoHeight: videoHeight)
        self.coordinateWidth = coordinateSize.width
        self.coordinateHeight = coordinateSize.height
        self.canvasSize = canvasSize
    }

    var scale: CGFloat {
        guard videoWidth > 0, videoHeight > 0, canvasSize.width > 0, canvasSize.height > 0 else {
            return 0
        }

        return min(canvasSize.width / videoWidth, canvasSize.height / videoHeight)
    }

    var positionScaleX: CGFloat {
        guard coordinateWidth > 0, canvasSize.width > 0 else { return 0 }
        return canvasSize.width / coordinateWidth
    }

    var positionScaleY: CGFloat {
        guard coordinateHeight > 0, canvasSize.height > 0 else { return 0 }
        return canvasSize.height / coordinateHeight
    }

    static func positionCoordinateSize(videoWidth: Int, videoHeight: Int) -> CGSize {
        let width = CGFloat(max(videoWidth, 1))
        let height = CGFloat(max(videoHeight, 1))
        let coordinateHeight = videoHeight > videoWidth ? width : height
        return CGSize(width: width, height: coordinateHeight)
    }

    static func fittedCanvasSize(videoWidth: Int, videoHeight: Int, in availableSize: CGSize) -> CGSize {
        guard videoWidth > 0, videoHeight > 0, availableSize.width > 0, availableSize.height > 0 else {
            return .zero
        }

        let aspectRatio = CGFloat(videoWidth) / CGFloat(videoHeight)
        var canvasWidth = availableSize.width
        var canvasHeight = canvasWidth / aspectRatio

        if canvasHeight > availableSize.height {
            canvasHeight = availableSize.height
            canvasWidth = canvasHeight * aspectRatio
        }

        return CGSize(width: canvasWidth, height: canvasHeight)
    }

    func previewPoint(forFCPXMLPosition position: CGPoint) -> CGPoint {
        guard positionScaleX > 0, positionScaleY > 0 else {
            return CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        }

        // previewX = canvasWidth / 2 + fcpxmlX * positionScaleX
        // previewY = canvasHeight / 2 - fcpxmlY * positionScaleY
        return CGPoint(
            x: canvasSize.width / 2 + position.x * positionScaleX,
            y: canvasSize.height / 2 - position.y * positionScaleY
        )
    }

    func fcpxmlPosition(forPreviewPoint point: CGPoint) -> CGPoint {
        guard positionScaleX > 0, positionScaleY > 0 else { return .zero }

        // fcpxmlX = (previewX - canvasWidth / 2) / positionScaleX
        // fcpxmlY = -(previewY - canvasHeight / 2) / positionScaleY
        return CGPoint(
            x: (point.x - canvasSize.width / 2) / positionScaleX,
            y: -(point.y - canvasSize.height / 2) / positionScaleY
        )
    }

    func clampedPreviewPoint(forFCPXMLPosition position: CGPoint) -> CGPoint {
        let point = previewPoint(forFCPXMLPosition: position)
        return CGPoint(
            x: point.x.clamped(to: 0...canvasSize.width),
            y: point.y.clamped(to: 0...canvasSize.height)
        )
    }

    func clampedFCPXMLPosition(forPreviewPoint point: CGPoint) -> CGPoint {
        let position = fcpxmlPosition(forPreviewPoint: point)
        return CGPoint(
            x: position.x.clamped(to: -coordinateWidth / 2...coordinateWidth / 2),
            y: position.y.clamped(to: -coordinateHeight / 2...coordinateHeight / 2)
        )
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Title Style Settings
struct TitleStyleSettings: Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case positionPreset
        case positionX
        case positionY
        case fontName
        case fontSize
        case fontScaleMode
        case fontWeight
        case textColor
        case strokeEnabled
        case strokeColor
        case strokeWidth
        case shadowColor
        case shadowOffsetX
        case shadowOffsetY
        case alignment
    }

    // MARK: - Position
    var positionPreset: PositionPreset = .bottomCenter
    var positionX: CGFloat = 0
    var positionY: CGFloat = -465

    // MARK: - Font
    var fontName: String = "Helvetica"
    var fontSize: CGFloat = 45
    var fontScaleMode: TitleFontScaleMode = .fixed
    var fontWeight: TitleFontWeight = .regular

    // MARK: - Text Color
    var textColor: CodableColor = .white

    // MARK: - Stroke (Outline)
    var strokeEnabled: Bool = false
    var strokeColor: CodableColor = .black
    var strokeWidth: CGFloat = 2

    // MARK: - Shadow
    var shadowColor: CodableColor = .blackShadow
    var shadowOffsetX: CGFloat = 4
    var shadowOffsetY: CGFloat = 315

    // MARK: - Alignment
    var alignment: TitleTextAlignment = .center

    // MARK: - Default Instance
    static let `default` = TitleStyleSettings()

    // MARK: - Methods

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        positionPreset = try container.decodeIfPresent(PositionPreset.self, forKey: .positionPreset) ?? .bottomCenter
        positionX = try container.decodeIfPresent(CGFloat.self, forKey: .positionX) ?? 0
        positionY = try container.decodeIfPresent(CGFloat.self, forKey: .positionY) ?? -465
        fontName = try container.decodeIfPresent(String.self, forKey: .fontName) ?? "Helvetica"
        fontSize = try container.decodeIfPresent(CGFloat.self, forKey: .fontSize) ?? 45
        fontScaleMode = try container.decodeIfPresent(TitleFontScaleMode.self, forKey: .fontScaleMode) ?? .fixed
        fontWeight = try container.decodeIfPresent(TitleFontWeight.self, forKey: .fontWeight) ?? .regular
        textColor = try container.decodeIfPresent(CodableColor.self, forKey: .textColor) ?? .white
        strokeEnabled = try container.decodeIfPresent(Bool.self, forKey: .strokeEnabled) ?? false
        strokeColor = try container.decodeIfPresent(CodableColor.self, forKey: .strokeColor) ?? .black
        strokeWidth = try container.decodeIfPresent(CGFloat.self, forKey: .strokeWidth) ?? 2
        shadowColor = try container.decodeIfPresent(CodableColor.self, forKey: .shadowColor) ?? .blackShadow
        shadowOffsetX = try container.decodeIfPresent(CGFloat.self, forKey: .shadowOffsetX) ?? 4
        shadowOffsetY = try container.decodeIfPresent(CGFloat.self, forKey: .shadowOffsetY) ?? 315
        alignment = try container.decodeIfPresent(TitleTextAlignment.self, forKey: .alignment) ?? .center
    }

    /// Update position based on preset and resolution
    mutating func updatePositionFromPreset(width: Int, height: Int) {
        guard positionPreset != .custom else { return }
        let position = positionPreset.position(forWidth: width, height: height)
        positionX = position.x
        positionY = position.y
    }

    /// Return the style values that should be written to FCPXML for a project size.
    func resolved(forWidth width: Int, height: Int) -> TitleStyleSettings {
        var resolvedStyle = self
        resolvedStyle.updatePositionFromPreset(width: width, height: height)
        resolvedStyle.fontSize = resolvedFontSize(forHeight: height)
        return resolvedStyle
    }

    func resolvedFontSize(forHeight height: Int) -> CGFloat {
        switch fontScaleMode {
        case .fixed:
            return fontSize
        case .scaleWithResolution:
            return fontSize * CGFloat(height) / 1080.0
        }
    }

    private static func fcpxmlNumberString(_ value: CGFloat) -> String {
        let roundedValue = (Double(value) * 1000).rounded() / 1000
        let normalizedValue = abs(roundedValue) < 0.0005 ? 0 : roundedValue

        if normalizedValue.rounded() == normalizedValue {
            return String(Int(normalizedValue))
        }

        return String(format: "%.3f", locale: Locale(identifier: "en_US_POSIX"), normalizedValue)
            .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
    }

    /// Get position string for FCPXML
    var positionString: String {
        return "\(Self.fcpxmlNumberString(positionX)) \(Self.fcpxmlNumberString(positionY))"
    }

    /// Get shadow offset string for FCPXML
    var shadowOffsetString: String {
        return "\(Self.fcpxmlNumberString(shadowOffsetX)) \(Self.fcpxmlNumberString(shadowOffsetY))"
    }
}
