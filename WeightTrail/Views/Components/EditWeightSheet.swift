import SwiftUI

struct EditWeightSheet: View {
    let selectedWeight: Weight?
    @Binding var editWeight: String
    @Binding var showingSheet: Bool
    @ObservedObject var viewModel: WeightTrackerViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section("Edit Weight Entry") {
                    TextField("Weight", text: $editWeight)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingSheet = false
                },
                trailing: Button("Save") {
                    if let weight = selectedWeight,
                       let newWeight = Double(editWeight) {
                        viewModel.updateWeight(weight, newWeight: newWeight)
                    }
                    showingSheet = false
                }
            )
        }
    }
} 