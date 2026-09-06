import Foundation

enum NoteValue: String, CaseIterable, Codable {
    case quarter = "1/4"
    case eighth = "1/8"
    case sixteenth = "1/16"
    case quarterTriplet = "1/4T"
    case eighthTriplet = "1/8T"
    case sixteenthTriplet = "1/16T"
    
    var multiplier: Double {
        switch self {
        case .quarter: return 1.0
        case .eighth: return 2.0
        case .sixteenth: return 4.0
        case .quarterTriplet: return 3.0/2.0
        case .eighthTriplet: return 3.0
        case .sixteenthTriplet: return 6.0
        }
    }
    
    var displayName: String {
        switch self {
        case .quarter: return "♩"
        case .eighth: return "♪"
        case .sixteenth: return "♬"
        case .quarterTriplet: return "♩₃"
        case .eighthTriplet: return "♪₃"
        case .sixteenthTriplet: return "♬₃"
        }
    }
    
    var isTriplet: Bool {
        switch self {
        case .quarterTriplet, .eighthTriplet, .sixteenthTriplet:
            return true
        default:
            return false
        }
    }
    
    var beatsPerMeasure: Int {
        switch self {
        case .quarter: return 4
        case .eighth: return 8
        case .sixteenth: return 16
        case .quarterTriplet: return 3
        case .eighthTriplet: return 6
        case .sixteenthTriplet: return 12
        }
    }
}
