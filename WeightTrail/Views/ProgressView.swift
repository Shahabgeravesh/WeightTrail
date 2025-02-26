import SwiftUI
import Charts

struct WeightProgressView: View {
    @ObservedObject var viewModel: WeightTrackerViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTimeFrame: TimeFrame = .month
    
    var filteredWeights: [Weight] {
        viewModel.weights.filter { selectedTimeFrame.isInRange($0.date) }
    }
    
    var yAxisRange: ClosedRange<Double> {
        let weights = filteredWeights.map(\.weight)
        let goalWeight = viewModel.goalWeight ?? 0
        let minWeight = min((weights.min() ?? goalWeight) - 5, goalWeight - 5)
        let maxWeight = max((weights.max() ?? goalWeight) + 5, goalWeight + 5)
        return minWeight...maxWeight
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: horizontalSizeClass == .regular ? 32 : 24) {
                if !viewModel.weights.isEmpty {
                    // Time Frame Picker
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                            Text(timeFrame.rawValue).tag(timeFrame)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Weight Chart Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Weight Trend")
                            .font(.title2)
                            .bold()
                        
                        WeightChartView(
                            weights: filteredWeights,
                            timeFrame: selectedTimeFrame,
                            goalWeight: viewModel.goalWeight,
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
                
                // Make charts and content adapt to iPad
                if horizontalSizeClass == .regular {
                    // iPad layout
                    HStack(alignment: .top, spacing: 24) {
                        // Charts
                        VStack {
                            WeightChartView(
                                weights: filteredWeights,
                                timeFrame: selectedTimeFrame,
                                goalWeight: viewModel.goalWeight,
                                yAxisRange: yAxisRange
                            )
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Statistics
                        VStack {
                            StatsGridView(viewModel: viewModel, timeFrame: selectedTimeFrame)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                } else {
                    // iPhone layout (your existing layout)
                    VStack {
                        // Your existing content
                    }
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

struct StatsGridView: View {
    let viewModel: WeightTrackerViewModel
    let timeFrame: TimeFrame
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            if let currentWeight = viewModel.weights.first?.weight {
                StatCard(
                    title: "Current Weight",
                    value: String(format: "%.1f", currentWeight),
                    unit: "lbs",
                    icon: "scalemass.fill"
                )
            }
            
            if let change = Weight.calculateChange(from: viewModel.weights, timeFrame: timeFrame) {
                StatCard(
                    title: "\(timeFrame.rawValue) Change",
                    value: String(format: "%.1f", change),
                    unit: "lbs",
                    icon: "arrow.up.right",
                    tint: change < 0 ? .green : .red
                )
            }
            
            if let average = viewModel.weights.prefix(timeFrame.days).map(\.weight).average {
                StatCard(
                    title: "\(timeFrame.rawValue) Average",
                    value: String(format: "%.1f", average),
                    unit: "lbs",
                    icon: "chart.bar.fill",
                    tint: .purple
                )
            }
            
            if let goalWeight = viewModel.goalWeight,
               let currentWeight = viewModel.weights.first?.weight {
                let remaining = abs(goalWeight - currentWeight)
                StatCard(
                    title: "To Goal",
                    value: String(format: "%.1f", remaining),
                    unit: "lbs",
                    icon: "flag.fill",
                    tint: .orange
                )
            }
        }
        .padding(.horizontal)
    }
}

// Helper extension for calculating average
extension Collection where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    var tint: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(tint)
                Text(title)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title)
                    .bold()
                Text(unit)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
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