import Foundation

struct Weight: Identifiable, Codable {
    let id: UUID
    let date: Date
    let weight: Double
    let note: String?
    
    init(id: UUID = UUID(), date: Date = Date(), weight: Double, note: String? = nil) {
        self.id = id
        self.date = date
        self.weight = weight
        self.note = note
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Add computed properties for statistics
extension Weight {
    static func calculateChange(from weights: [Weight], timeFrame: TimeFrame) -> Double? {
        guard let latestWeight = weights.first?.weight,
              let oldestWeight = weights.filter({ timeFrame.isInRange($0.date) }).last?.weight else {
            return nil
        }
        return latestWeight - oldestWeight
    }
}

enum TimeFrame: String, CaseIterable {
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    case all = "All"
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .year: return 365
        case .all: return Int.max
        }
    }
    
    func isInRange(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: date, to: now)
        guard let daysDifference = components.day else { return false }
        return daysDifference <= days
    }
} 