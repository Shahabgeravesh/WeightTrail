import Foundation

enum WeightUnit: String, Codable {
    case kg
    case lbs
    
    func convert(_ value: Double, to unit: WeightUnit) -> Double {
        switch (self, unit) {
        case (.kg, .lbs):
            return value * 2.20462
        case (.lbs, .kg):
            return value / 2.20462
        default:
            return value
        }
    }
    
    var symbol: String {
        switch self {
        case .kg: return "kg"
        case .lbs: return "lbs"
        }
    }
}

struct Weight: Identifiable, Codable {
    let id: UUID
    let date: Date
    let weight: Double
    
    init(id: UUID = UUID(), date: Date = Date(), weight: Double) {
        self.id = id
        self.date = date
        self.weight = weight
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 