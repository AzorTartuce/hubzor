import Foundation

struct HouseTask: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var roomId: String
    var assignedResidentId: String?
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date?
    var note: String = ""
    var priority: Priority = .medium
    var scheduledTime: Date? = nil

    enum Priority: String, Codable, CaseIterable {
        case low    = "Baixa"
        case medium = "Média"
        case high   = "Alta"

        var icon: String {
            switch self {
            case .low:    return "arrow.down.circle.fill"
            case .medium: return "minus.circle.fill"
            case .high:   return "arrow.up.circle.fill"
            }
        }

        var colorHex: String {
            switch self {
            case .low:    return "#1DD1A1"
            case .medium: return "#FECA57"
            case .high:   return "#FF6B6B"
            }
        }
    }

    mutating func complete() {
        isCompleted = true
        completedAt = Date()
    }

    mutating func reopen() {
        isCompleted = false
        completedAt = nil
    }
}
