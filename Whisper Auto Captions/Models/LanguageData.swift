//
//  LanguageData.swift
//  Whisper Auto Captions
//
//  Language data for Whisper transcription
//

import Foundation

/// Available languages for Whisper transcription
struct LanguageData {
    /// All supported language display names
    static let languages: [String] = [
        "Auto",  // Auto-detect language
        "Arabic", "Azerbaijani", "Armenian", "Albanian", "Afrikaans",
        "Amharic", "Assamese", "Bulgarian", "Bengali", "Breton",
        "Basque", "Bosnian", "Belarusian", "Bashkir", "Chinese Simplified",
        "Chinese Traditional", "Catalan", "Czech", "Croatian", "Dutch",
        "Danish", "English", "Estonian", "French", "Finnish",
        "Faroese", "German", "Greek", "Galician", "Georgian",
        "Gujarati", "Hindi", "Hebrew", "Hungarian", "Haitian creole",
        "Hawaiian", "Hausa", "Italian", "Indonesian", "Icelandic",
        "Japanese", "Javanese", "Korean", "Kannada", "Kazakh",
        "Khmer", "Lithuanian", "Latin", "Latvian", "Lao",
        "Luxembourgish", "Lingala", "Malay", "Maori", "Malayalam",
        "Macedonian", "Mongolian", "Marathi", "Maltese", "Myanmar",
        "Malagasy", "Norwegian", "Nepali", "Nynorsk", "Occitan",
        "Portuguese", "Polish", "Persian", "Punjabi", "Pashto",
        "Russian", "Romanian", "Spanish", "Swedish", "Slovak",
        "Serbian", "Slovenian", "Swahili", "Sinhala", "Shona",
        "Somali", "Sindhi", "Sanskrit", "Sundanese", "Turkish",
        "Tamil", "Thai", "Telugu", "Tajik", "Turkmen",
        "Tibetan", "Tagalog", "Tatar", "Ukrainian", "Urdu",
        "Uzbek", "Vietnamese", "Welsh", "Yoruba", "Yiddish"
    ]

    /// Mapping from display name to ISO 639-1 language code
    static let languageToCode: [String: String] = [
        "Auto": "auto",  // Auto-detect language
        "Arabic": "ar", "Azerbaijani": "az", "Armenian": "hy", "Albanian": "sq",
        "Afrikaans": "af", "Amharic": "am", "Assamese": "as", "Bulgarian": "bg",
        "Bengali": "bn", "Breton": "br", "Basque": "eu", "Bosnian": "bs",
        "Belarusian": "be", "Bashkir": "ba", "Chinese Simplified": "zh",
        "Chinese Traditional": "zh", "Catalan": "ca", "Czech": "cs",
        "Croatian": "hr", "Dutch": "nl", "Danish": "da", "English": "en",
        "Estonian": "et", "French": "fr", "Finnish": "fi", "Faroese": "fo",
        "German": "de", "Greek": "el", "Galician": "gl", "Georgian": "ka",
        "Gujarati": "gu", "Hindi": "hi", "Hebrew": "he", "Hungarian": "hu",
        "Haitian creole": "ht", "Hawaiian": "haw", "Hausa": "ha", "Italian": "it",
        "Indonesian": "id", "Icelandic": "is", "Japanese": "ja", "Javanese": "jw",
        "Korean": "ko", "Kannada": "kn", "Kazakh": "kk", "Khmer": "km",
        "Lithuanian": "lt", "Latin": "la", "Latvian": "lv", "Lao": "lo",
        "Luxembourgish": "lb", "Lingala": "ln", "Malay": "ms", "Maori": "mi",
        "Malayalam": "ml", "Macedonian": "mk", "Mongolian": "mn", "Marathi": "mr",
        "Maltese": "mt", "Myanmar": "my", "Malagasy": "mg", "Norwegian": "no",
        "Nepali": "ne", "Nynorsk": "nn", "Occitan": "oc", "Portuguese": "pt",
        "Polish": "pl", "Persian": "fa", "Punjabi": "pa", "Pashto": "ps",
        "Russian": "ru", "Romanian": "ro", "Spanish": "es", "Swedish": "sv",
        "Slovak": "sk", "Serbian": "sr", "Slovenian": "sl", "Swahili": "sw",
        "Sinhala": "si", "Shona": "sn", "Somali": "so", "Sindhi": "sd",
        "Sanskrit": "sa", "Sundanese": "su", "Turkish": "tr", "Tamil": "ta",
        "Thai": "th", "Telugu": "te", "Tajik": "tg", "Turkmen": "tk",
        "Tibetan": "bo", "Tagalog": "tl", "Tatar": "tt", "Ukrainian": "uk",
        "Urdu": "ur", "Uzbek": "uz", "Vietnamese": "vi", "Welsh": "cy",
        "Yoruba": "yo", "Yiddish": "yi"
    ]

    /// Get ISO code for a language name
    static func code(for language: String) -> String? {
        return languageToCode[language]
    }

    /// Get default prompt for Chinese languages
    static func defaultPrompt(for language: String) -> String {
        switch language {
        case "Chinese Simplified":
            return "以下是普通话的句子"
        case "Chinese Traditional":
            return "以下是普通話的句子"
        default:
            return ""
        }
    }

    /// Check if language requires special prompt handling
    static func requiresPrompt(_ language: String) -> Bool {
        return language == "Chinese Simplified" || language == "Chinese Traditional"
    }
}

/// Available Whisper models
struct ModelData {
    /// All available model names (display names)
    static let models: [String] = [
        // Large variants
        "Large-v3-turbo",
        "Large-v3",
        "Large-v2",
        "Large-v1",
        // Medium
        "Medium",
        "Medium.en",
        // Small
        "Small",
        "Small.en",
        // Base
        "Base",
        "Base.en",
        // Tiny
        "Tiny",
        "Tiny.en"
    ]

    /// Mapping from display name to model file name (without ggml- prefix)
    static let modelToFileName: [String: String] = [
        "Large-v3-turbo": "large-v3-turbo",
        "Large-v3": "large-v3",
        "Large-v2": "large-v2",
        "Large-v1": "large-v1",
        "Medium": "medium",
        "Medium.en": "medium.en",
        "Small": "small",
        "Small.en": "small.en",
        "Base": "base",
        "Base.en": "base.en",
        "Tiny": "tiny",
        "Tiny.en": "tiny.en"
    ]

    /// Get file name for a model
    static func fileName(for model: String) -> String? {
        return modelToFileName[model]
    }

    /// Get model size description
    static func sizeDescription(for model: String) -> String {
        switch model {
        case "Large-v3-turbo":
            return String(localized: "~1.5 GB - Fast & accurate", comment: "Large-v3-turbo model description")
        case "Large-v3", "Large-v2", "Large-v1":
            return String(localized: "~3 GB - Best accuracy", comment: "Large model description")
        case "Medium", "Medium.en":
            return String(localized: "~1.5 GB - Good balance", comment: "Medium model description")
        case "Small", "Small.en":
            return String(localized: "~500 MB - Faster", comment: "Small model description")
        case "Base", "Base.en":
            return String(localized: "~150 MB - Fast", comment: "Base model description")
        case "Tiny", "Tiny.en":
            return String(localized: "~75 MB - Fastest", comment: "Tiny model description")
        default:
            return ""
        }
    }

    /// Check if model is English-only
    static func isEnglishOnly(_ model: String) -> Bool {
        return model.hasSuffix(".en")
    }
}
