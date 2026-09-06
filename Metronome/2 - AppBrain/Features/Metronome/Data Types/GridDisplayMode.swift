import Foundation

enum GridDisplayMode: String, CaseIterable, Codable {
    case andCounting = "1&2&"
    case subdivisionCounting = "1e&a"
    
    var displayName: String {
        return self.rawValue
    }
    
    func getLabel(for position: Int, noteValue: NoteValue) -> String {
        switch self {
        case .andCounting:
            return getAndCountingLabel(for: position, noteValue: noteValue)
        case .subdivisionCounting:
            return getSubdivisionLabel(for: position, noteValue: noteValue)
        }
    }
    
    private func getAndCountingLabel(for position: Int, noteValue: NoteValue) -> String {
        if noteValue.isTriplet {
            // Triplet counting: 1 2 3 4 5 6
            return "\(position + 1)"
        } else {
            switch noteValue {
            case .quarter:
                return "\(position + 1)"
            case .eighth:
                let beat = (position / 2) + 1
                let subdivision = position % 2
                return subdivision == 0 ? "\(beat)" : "&"
            case .sixteenth:
                let beat = (position / 4) + 1
                let subdivision = position % 4
                switch subdivision {
                case 0: return "\(beat)"
                case 1: return "e"
                case 2: return "&"
                case 3: return "a"
                default: return "\(position + 1)"
                }
            default:
                return "\(position + 1)"
            }
        }
    }
    
    private func getSubdivisionLabel(for position: Int, noteValue: NoteValue) -> String {
        if noteValue.isTriplet {
            // Triplet counting: 1 trip let 2 trip let
            let tripletGroup = (position / 3) + 1
            let tripletPosition = position % 3
            switch tripletPosition {
            case 0: return "\(tripletGroup)"
            case 1: return "trip"
            case 2: return "let"
            default: return "\(position + 1)"
            }
        } else {
            switch noteValue {
            case .quarter:
                return "\(position + 1)"
            case .eighth:
                let beat = (position / 2) + 1
                let subdivision = position % 2
                return subdivision == 0 ? "\(beat)" : "&"
            case .sixteenth:
                let beat = (position / 4) + 1
                let subdivision = position % 4
                switch subdivision {
                case 0: return "\(beat)"
                case 1: return "e"
                case 2: return "&"
                case 3: return "a"
                default: return "\(position + 1)"
                }
            default:
                return "\(position + 1)"
            }
        }
    }
    
}
