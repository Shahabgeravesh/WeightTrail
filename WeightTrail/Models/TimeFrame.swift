import Foundation

enum TimeFrame: String, CaseIterable, Identifiable {
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    case all = "All"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
    
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

extension Weight {
    static func calculateChange(from weights: [Weight], timeFrame: TimeFrame) -> Double? {
        guard let latestWeight = weights.first?.weight,
              let oldestWeight = weights.filter({ timeFrame.isInRange($0.date) }).last?.weight else {
            return nil
        }
        return latestWeight - oldestWeight
    }
} 