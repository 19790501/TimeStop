import Foundation
import SwiftUI

struct AchievementBadge: Identifiable, Codable {
    let id: UUID
    let type: AchievementType
    let level: Int
    let earnedAt: Date
    
    init(type: AchievementType, level: Int) {
        self.id = UUID()
        self.type = type
        self.level = level
        self.earnedAt = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case level
        case earnedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(AchievementType.self, forKey: .type)
        level = try container.decode(Int.self, forKey: .level)
        earnedAt = try container.decode(Date.self, forKey: .earnedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(level, forKey: .level)
        try container.encode(earnedAt, forKey: .earnedAt)
    }
} 