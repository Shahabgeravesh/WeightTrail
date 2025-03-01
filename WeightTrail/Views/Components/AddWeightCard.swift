import SwiftUI

struct AddWeightCard: View {
    @Binding var newWeight: String
    @FocusState var isWeightFocused: Bool
    @Binding var showingError: Bool
    let errorMessage: String
    @ObservedObject var viewModel: WeightTrackerViewModel
    let onSubmit: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        VStack(spacing: horizontalSizeClass == .regular ? 24 : 20) {
            Text("Add New Weight")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    HStack {
                        TextField("Weight", text: $newWeight)
                            .submitLabel(.done)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.custom)
                            .focused($isWeightFocused)
                        
                        Picker("Unit", selection: $viewModel.preferredUnit) {
                            Text("kg").tag(WeightUnit.kg)
                            Text("lbs").tag(WeightUnit.lbs)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                    
                    if showingError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .transition(.opacity)
                    }
                }
                
                Button(action: {
                    onSubmit()
                    isWeightFocused = false
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.primary)
                        .symbolRenderingMode(.hierarchical)
                }
                .disabled(newWeight.isEmpty)
                .opacity(newWeight.isEmpty ? 0.5 : 1.0)
            }
        }
        .padding(horizontalSizeClass == .regular ? 24 : 20)
        .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.cardBackground)
                .shadow(color: Theme.cardShadow, radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
} 