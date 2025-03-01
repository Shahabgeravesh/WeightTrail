import SwiftUI

struct StatsGridView: View {
    @ObservedObject var viewModel: WeightTrackerViewModel
    let timeFrame: TimeFrame
    
    private var currentWeight: String {
        guard let weight = viewModel.weights.first?.weight else { return "No data" }
        let convertedWeight = viewModel.preferredUnit == .kg ? weight / 2.20462 : weight
        return String(format: "%.1f %@", convertedWeight, viewModel.preferredUnit.symbol)
    }
    
    private var weightChange: String {
        guard let change = Weight.calculateChange(from: viewModel.weights, timeFrame: timeFrame) else {
            return "No data"
        }
        let convertedChange = viewModel.preferredUnit == .kg ? change / 2.20462 : change
        let prefix = convertedChange >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.1f", convertedChange)) \(viewModel.preferredUnit.symbol)"
    }
    
    private var averageWeight: String {
        let filteredWeights = viewModel.weights.filter { timeFrame.isInRange($0.date) }
        guard !filteredWeights.isEmpty else { return "No data" }
        
        let totalWeight = filteredWeights.reduce(0.0) { $0 + $1.weight }
        let average = totalWeight / Double(filteredWeights.count)
        let convertedAverage = viewModel.preferredUnit == .kg ? average / 2.20462 : average
        return String(format: "%.1f %@", convertedAverage, viewModel.preferredUnit.symbol)
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(title: "Current", value: currentWeight)
            StatCard(title: "\(timeFrame.rawValue) Change", value: weightChange)
            StatCard(title: "\(timeFrame.rawValue) Average", value: averageWeight)
        }
        .padding(.horizontal)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardBackground)
                .shadow(color: Theme.cardShadow, radius: 4)
        )
    }
}