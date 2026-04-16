import Foundation

struct Resident: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var emoji: String
    var colorHex: String

    static let availableEmojis = [
        "😀", "😎", "🤓", "🧑", "👩", "👨", "🧒", "👧", "👦",
        "🧑‍🦱", "🧑‍🦰", "🧑‍🦳", "🧑‍🦲", "🧔", "👵", "👴"
    ]

    static let availableColors = [
        "#FF6B6B", "#FF9F43", "#FECA57", "#48DBFB",
        "#1DD1A1", "#54A0FF", "#5F27CD", "#C44569",
        "#786FA6", "#F8EFBA", "#63CDDA", "#EA2027"
    ]
}
