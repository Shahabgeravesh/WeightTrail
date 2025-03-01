import SwiftUI

struct WeightHistorySection: View {
    @ObservedObject var viewModel: WeightTrackerViewModel
    @Binding var selectedWeight: Weight?
    @Binding var editWeight: String
    @Binding var showingEditSheet: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("History")
                    .font(.title2)
                    .bold()
                Spacer()
                if !viewModel.weights.isEmpty {
                    Text("\(viewModel.weights.count) entries")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            if viewModel.weights.isEmpty {
                EmptyStateView()
            } else {
                weightsList
            }
        }
        .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
    }
    
    private var weightsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.weights) { weight in
                WeightRowView(weight: weight, viewModel: viewModel) {
                    viewModel.deleteWeight(weight)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedWeight = weight
                    editWeight = viewModel.displayWeight(weight.weight)
                    showingEditSheet = true
                }
            }
        }
        .padding(.horizontal)
    }
} 