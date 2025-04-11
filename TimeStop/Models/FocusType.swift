import Foundation

enum FocusType: String, CaseIterable {
    case work = "工作"
    case study = "学习"
    case reading = "阅读"
    case exercise = "运动"
    case meditation = "冥想"
    case other = "其他"
    
    var description: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .work:
            return "briefcase"
        case .study:
            return "book"
        case .reading:
            return "book.closed"
        case .exercise:
            return "figure.run"
        case .meditation:
            return "sparkles"
        case .other:
            return "circle"
        }
    }
    
    var color: String {
        switch self {
        case .work:
            return "blue"
        case .study:
            return "pink"
        case .reading:
            return "orange"
        case .exercise:
            return "green"
        case .meditation:
            return "indigo"
        case .other:
            return "gray"
        }
    }
} 