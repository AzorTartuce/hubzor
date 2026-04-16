import Foundation

struct Household: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var ownerId: String
    var inviteCode: String
    var createdAt: Date = Date()

    static func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).compactMap { _ in chars.randomElement() })
    }
}

struct HubzorUser: Codable {
    var uid: String
    var displayName: String
    var email: String
    var householdId: String?
    var createdAt: Date = Date()
}
