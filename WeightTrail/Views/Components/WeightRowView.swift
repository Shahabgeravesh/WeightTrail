import SwiftUI

struct WeightRowView: View {
    let weight: Weight
    @ObservedObject var viewModel: WeightTrackerViewModel
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(weight.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(viewModel.displayWeight(weight.weight)) \(viewModel.preferredUnit.symbol)")
                    .font(.title3)
                    .bold()
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Theme.cardShadow, radius: 4)
    }
} 