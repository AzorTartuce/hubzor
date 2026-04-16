import Foundation

struct ShoppingItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var quantity: String = "1"
    var unit: String = ""
    var category: Category = .outros
    var isChecked: Bool = false
    var addedByResidentId: String?
    var note: String = ""

    enum Category: String, Codable, CaseIterable {
        case frutas     = "Frutas e Verduras"
        case carnes     = "Carnes e Peixes"
        case laticinios = "Laticínios"
        case graos      = "Grãos e Cereais"
        case bebidas    = "Bebidas"
        case limpeza    = "Limpeza"
        case higiene    = "Higiene"
        case outros     = "Outros"

        var icon: String {
            switch self {
            case .frutas:     return "leaf"
            case .carnes:     return "fork.knife"
            case .laticinios: return "cup.and.saucer"
            case .graos:      return "bag"
            case .bebidas:    return "drop"
            case .limpeza:    return "sparkles"
            case .higiene:    return "heart"
            case .outros:     return "cart"
            }
        }

        var colorHex: String {
            switch self {
            case .frutas:     return "#6AB04C"
            case .carnes:     return "#FF6B6B"
            case .laticinios: return "#FECA57"
            case .graos:      return "#FF9F43"
            case .bebidas:    return "#48DBFB"
            case .limpeza:    return "#54A0FF"
            case .higiene:    return "#C44569"
            case .outros:     return "#786FA6"
            }
        }
    }
}
