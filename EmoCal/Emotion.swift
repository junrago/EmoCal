import SwiftUI

enum Emotion: CaseIterable, Hashable {
    case joy, sadness, anger, fun

    var color: Color {
        switch self {
        case .joy:     return Color("JoyColor")
        case .sadness: return Color("SadColor")
        case .anger:   return Color("AngColor")
        case .fun:     return Color("FunColor")
        }
    }
    var label: String {
        switch self {
        case .joy: "Joy"
        case .sadness: "Sadness"
        case .anger: "Anger"
        case .fun: "Fun"
        }
    }
}

/// 4段階（とても=1.0, 75%=0.75, 50%=0.5, 25%=0.25）
enum Intensity: Double, CaseIterable, Hashable {
    case very = 1.0
    case high = 0.75
    case mid  = 0.5
    case low  = 0.25

    var label: String {
        switch self {
        case .very: "Very"
        case .high: "High"
        case .mid:  "Medium"
        case .low:  "Low"
        }
    }
}

struct Feeling: Hashable {
    var emotion: Emotion
    var intensity: Intensity
}
