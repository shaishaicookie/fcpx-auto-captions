import Foundation

// MARK: - Frame Rate
enum FrameRate: String, CaseIterable, Identifiable {
    case fps23_976 = "23.976"
    case fps24 = "24"
    case fps25 = "25"
    case fps29_97 = "29.97"
    case fps30 = "30"
    case fps50 = "50"
    case fps59_94 = "59.94"
    case fps60 = "60"
    case custom = "Custom"

    var id: String { rawValue }

    var value: Float {
        switch self {
        case .fps23_976: return 23.976
        case .fps24: return 24.0
        case .fps25: return 25.0
        case .fps29_97: return 29.97
        case .fps30: return 30.0
        case .fps50: return 50.0
        case .fps59_94: return 59.94
        case .fps60: return 60.0
        case .custom: return 30.0
        }
    }

    var displayName: String {
        switch self {
        case .fps23_976: return "23.976 fps (Film)"
        case .fps24: return "24 fps (Cinema)"
        case .fps25: return "25 fps (PAL)"
        case .fps29_97: return "29.97 fps (NTSC)"
        case .fps30: return "30 fps"
        case .fps50: return "50 fps (PAL HD)"
        case .fps59_94: return "59.94 fps (NTSC HD)"
        case .fps60: return "60 fps"
        case .custom: return String(localized: "Custom", comment: "Custom frame rate option")
        }
    }

    static func isValidFrameRate(_ value: Float) -> Bool {
        return value > 0 && value <= 120
    }

    /// Match a Float value to a FrameRate enum case
    /// - Parameter value: The frame rate value to match
    /// - Returns: The matching FrameRate case, or nil if no match found within tolerance
    static func fromValue(_ value: Float) -> FrameRate? {
        let tolerance: Float = 0.01

        for frameRate in FrameRate.allCases where frameRate != .custom {
            if abs(frameRate.value - value) < tolerance {
                return frameRate
            }
        }
        return nil
    }
}
