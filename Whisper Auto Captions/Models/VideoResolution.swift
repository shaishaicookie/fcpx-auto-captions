import Foundation

// MARK: - Video Resolution
enum VideoResolution: String, CaseIterable, Identifiable {
    case hd720p = "720p HD"
    case fullHD1080p = "1080p Full HD"
    case uhd4K = "4K UHD"
    case dci4K = "4K DCI"
    case vertical1080p = "1080p Vertical"
    case custom = "Custom"

    var id: String { rawValue }

    var width: Int {
        switch self {
        case .hd720p: return 1280
        case .fullHD1080p: return 1920
        case .uhd4K: return 3840
        case .dci4K: return 4096
        case .vertical1080p: return 1080
        case .custom: return 1920
        }
    }

    var height: Int {
        switch self {
        case .hd720p: return 720
        case .fullHD1080p: return 1080
        case .uhd4K, .dci4K: return 2160
        case .vertical1080p: return 1920
        case .custom: return 1080
        }
    }

    var displayName: String {
        switch self {
        case .hd720p: return "720p HD (1280×720)"
        case .fullHD1080p: return "1080p Full HD (1920×1080)"
        case .uhd4K: return "4K UHD (3840×2160)"
        case .dci4K: return "4K DCI (4096×2160)"
        case .vertical1080p: return "1080p Vertical (1080×1920)"
        case .custom: return "Custom"
        }
    }

    static func formatName(width: Int, height: Int, fps: Float) -> String {
        let fpsInt = Int(fps * 100)

        switch (width, height) {
        case (1280, 720):  return "FFVideoFormat720p\(fpsInt)"
        case (1920, 1080): return "FFVideoFormat1080p\(fpsInt)"
        case (3840, 2160): return "FFVideoFormat3840x2160p\(fpsInt)"
        case (4096, 2160): return "FFVideoFormat4096x2160p\(fpsInt)"
        case (1080, 1920): return "FFVideoFormat1080x1920p\(fpsInt)"
        default:          return "FFVideoFormatRateUndefined"
        }
    }

    static func isValidResolution(width: Int, height: Int) -> (valid: Bool, message: String?) {
        if width < 640 || width > 8192 || height < 640 || height > 8192 {
            return (false, "Resolution must be between 640 and 8192")
        }
        if width % 2 != 0 || height % 2 != 0 {
            return (true, "Odd values may cause encoding issues")
        }
        return (true, nil)
    }
}
