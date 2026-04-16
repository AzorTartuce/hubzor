import Foundation

struct Room: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var icon: String
    var colorHex: String

    static let defaultRooms: [Room] = [
        Room(name: "Cozinha",    icon: "fork.knife",  colorHex: "#FF6B6B"),
        Room(name: "Sala",       icon: "tv",          colorHex: "#54A0FF"),
        Room(name: "Quarto",     icon: "bed.double",  colorHex: "#5F27CD"),
        Room(name: "Banheiro",   icon: "shower",      colorHex: "#1DD1A1"),
        Room(name: "Lavanderia", icon: "washer",      colorHex: "#48DBFB"),
        Room(name: "Garagem",    icon: "car",         colorHex: "#786FA6"),
    ]

    static let availableIcons = [
        "fork.knife", "tv", "bed.double", "shower", "washer",
        "car", "house", "leaf", "desktopcomputer", "book",
        "tray", "archivebox", "hammer", "wrench", "paintbrush",
        "lightbulb", "music.note", "gamecontroller"
    ]

    static let availableColors = [
        "#FF6B6B", "#FF9F43", "#FECA57", "#48DBFB",
        "#1DD1A1", "#54A0FF", "#5F27CD", "#C44569",
        "#786FA6", "#63CDDA", "#EA2027", "#6AB04C"
    ]
}
