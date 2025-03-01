import SwiftUI
import Charts

struct WeightProgressView: View {
    @ObservedObject var viewModel: WeightTrackerViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTimeFrame: TimeFrame = .month
    
    var filteredWeights: [Weight] {
        viewModel.weights
            .filter { selectedTimeFrame.isInRange($0.date) }
            .map { weight in
                // Convert weight to preferred unit
                let convertedWeight = viewModel.preferredUnit == .kg ? 
                    weight.weight / 2.20462 : weight.weight
                return Weight(id: weight.id, date: weight.date, weight: convertedWeight)
            }
    }
    
    var yAxisRange: ClosedRange<Double> {
        let weights = filteredWeights.map(\.weight)
        let goalWeight = viewModel.goalWeight.map { 
            viewModel.preferredUnit == .kg ? $0 / 2.20462 : $0 
        } ?? 0
        let minWeight = min((weights.min() ?? goalWeight) - 5, goalWeight - 5)
        let maxWeight = max((weights.max() ?? goalWeight) + 5, goalWeight + 5)
        return minWeight...maxWeight
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: horizontalSizeClass == .regular ? 32 : 24) {
                // Unit Selector
                Picker("Unit", selection: $viewModel.preferredUnit) {
                    Text("kg").tag(WeightUnit.kg)
                    Text("lbs").tag(WeightUnit.lbs)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
                .padding(.horizontal)
                
                // Time Frame Selector
                Picker("Time Frame", selection: $selectedTimeFrame) {
                    ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                        Text(timeFrame.rawValue).tag(timeFrame)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if !viewModel.weights.isEmpty {
                    // Weight Chart Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Weight Trend")
                            .font(.title2)
                            .bold()
                        
                        WeightChartView(
                            weights: filteredWeights,
                            timeFrame: selectedTimeFrame,
                            goalWeight: viewModel.goalWeight.map { 
                                viewModel.preferredUnit == .kg ? $0 / 2.20462 : $0 
                            },
                            yAxisRange: yAxisRange
                        )
                        .frame(height: 220)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.cardBackground)
                            .shadow(color: Theme.cardShadow, radius: 10)
                    )
                    .padding(.horizontal)
                    
                    // Stats Cards
                    StatsGridView(viewModel: viewModel, timeFrame: selectedTimeFrame)
                        .id(viewModel.preferredUnit)
                } else {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "scale.3d")
                            .font(.system(size: 60))
                            .foregroundStyle(Theme.primary)
                        
                        Text("Track Your Progress")
                            .font(.title2)
                            .bold()
                        
                        Text("Add your first weight measurement to start tracking your progress")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                }
            }
            .frame(maxWidth: horizontalSizeClass == .regular ? 1000 : .infinity)
            .padding(.horizontal)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Progress")
                    .font(.headline)
                    .foregroundColor(Theme.primary)
            }
        }
    }
}

struct WeightChartView: View {
    let weights: [Weight]
    let timeFrame: TimeFrame
    let goalWeight: Double?
    let yAxisRange: ClosedRange<Double>
    @Environment(\.colorScheme) var colorScheme
    
    private var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        // If we have weights, use their date range within the selected timeframe
        if !weights.isEmpty {
            let filteredDates = weights.map(\.date).filter { timeFrame.isInRange($0) }
            if let earliest = filteredDates.min(), let latest = filteredDates.max() {
                // Add some padding to the date range
                let startDate = calendar.date(byAdding: getDateComponent(), value: -1, to: earliest) ?? earliest
                let endDate = calendar.date(byAdding: getDateComponent(), value: 1, to: latest) ?? latest
                return (startDate, endDate)
            }
        }
        
        // Fallback to default range if no weights
        let endDate = now
        let startDate: Date
        switch timeFrame {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        return (startDate, endDate)
    }
    
    private var xAxisStride: Calendar.Component {
        switch timeFrame {
        case .week: return .day
        case .month: return .day
        case .threeMonths: return .weekOfMonth
        case .sixMonths: return .month
        case .year: return .month
        case .all: return .month
        }
    }
    
    private var xAxisValues: [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        let interval: Calendar.Component
        let intervalCount: Int
        
        switch timeFrame {
        case .week:
            interval = .day
            intervalCount = 1
        case .month:
            interval = .day
            intervalCount = 5
        case .threeMonths:
            interval = .weekOfMonth
            intervalCount = 1
        case .sixMonths:
            interval = .month
            intervalCount = 1
        case .year:
            interval = .month
            intervalCount = 2
        case .all:
            interval = .month
            intervalCount = 3
        }
        
        var date = dateRange.start
        while date <= dateRange.end {
            dates.append(date)
            if let newDate = calendar.date(byAdding: interval, value: intervalCount, to: date) {
                date = newDate
            } else {
                break
            }
        }
        
        return dates
    }
    
    private func getDateComponent() -> Calendar.Component {
        switch timeFrame {
        case .week:
            return .day
        case .month:
            return .weekOfMonth
        case .threeMonths:
            return .weekOfMonth
        case .sixMonths, .year:
            return .month
        case .all:
            return .month
        }
    }
    
    private var filteredAndSortedWeights: [Weight] {
        weights
            .filter { $0.date >= dateRange.start && $0.date <= dateRange.end }
            .sorted { $0.date < $1.date }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch timeFrame {
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "MMM d"
        case .threeMonths:
            formatter.dateFormat = "MMM d"
        case .sixMonths, .year:
            formatter.dateFormat = "MMM"
        case .all:
            formatter.dateFormat = "MMM yyyy"
        }
        return formatter.string(from: date)
    }
    
    var body: some View {
        Chart {
            ForEach(filteredAndSortedWeights) { weightEntry in
                LineMark(
                    x: .value("Date", weightEntry.date),
                    y: .value("Weight", weightEntry.weight)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    Gradient(colors: [Theme.gradientStart, Theme.gradientEnd])
                )
                
                PointMark(
                    x: .value("Date", weightEntry.date),
                    y: .value("Weight", weightEntry.weight)
                )
                .foregroundStyle(Theme.primary)
                .annotation(position: .top) {
                    Text("\(weightEntry.weight, specifier: "%.1f")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if let goalWeight = goalWeight {
                RuleMark(
                    y: .value("Goal", goalWeight)
                )
                .foregroundStyle(Theme.accent)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .leading) {
                    Text("Goal: \(goalWeight, specifier: "%.1f")")
                        .font(.caption2)
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .chartXScale(domain: dateRange.start...dateRange.end)
        .chartYScale(domain: yAxisRange)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let weight = value.as(Double.self) {
                        Text("\(weight, specifier: "%.0f")")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: xAxisValues) { value in
                if let date = value.as(Date.self) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        Text(formatDate(date))
                            .font(.caption2)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// Add this extension to help with date generation
extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)
        
        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date <= interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
    }
}

#Preview {
    WeightProgressView(viewModel: WeightTrackerViewModel())
} 