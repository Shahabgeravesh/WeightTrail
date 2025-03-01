import SwiftUI

struct GoalWeightSheet: View {
    @Binding var goalWeightString: String
    @Binding var showingSheet: Bool
    @ObservedObject var viewModel: WeightTrackerViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section("Goal Weight") {
                    TextField("Enter goal weight", text: $goalWeightString)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Set Goal")
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingSheet = false
                },
                trailing: Button("Save") {
                    if let goalWeight = Double(goalWeightString),
                       goalWeight > 0 && goalWeight < 1000 {
                        viewModel.setGoalWeight(goalWeight)
                        showingSheet = false
                    }
                }
            )
        }
    }
} 