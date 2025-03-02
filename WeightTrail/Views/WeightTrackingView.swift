import SwiftUI

struct WeightTrackingView: View {
    @ObservedObject var viewModel: WeightTrackerViewModel
    @State private var newWeight: String = ""
    @State private var showingGoalWeightSheet = false
    @State private var goalWeightString: String = ""
    @State private var showingResetAlert = false
    @State private var selectedWeight: Weight?
    @State private var showingEditSheet = false
    @State private var editWeight: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var isWeightFocused: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        ScrollView {
            VStack(spacing: horizontalSizeClass == .regular ? 32 : 24) {
                AddWeightCard(
                    newWeight: $newWeight,
                    isWeightFocused: _isWeightFocused,
                    showingError: $showingError,
                    errorMessage: errorMessage,
                    viewModel: viewModel,
                    onSubmit: validateAndAddWeight
                )
                
                WeightHistorySection(
                    viewModel: viewModel,
                    selectedWeight: $selectedWeight,
                    editWeight: $editWeight,
                    showingEditSheet: $showingEditSheet
                )
            }
            .frame(maxWidth: horizontalSizeClass == .regular ? 800 : .infinity)
            .padding(.horizontal, horizontalSizeClass == .regular ? 40 : 20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Weight Log")
                    .font(.headline)
                    .foregroundColor(Theme.primary)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        goalWeightString = viewModel.goalWeight.map { viewModel.displayWeight($0) } ?? ""
                        showingGoalWeightSheet = true
                    } label: {
                        Label("Set Goal", systemImage: "flag.fill")
                    }
                    
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Theme.primary)
                }
            }
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.resetAllData()
            }
        } message: {
            Text("This will delete all weight entries and reset your goal. This action cannot be undone.")
        }
        .sheet(isPresented: $showingGoalWeightSheet) {
            GoalWeightSheet(
                goalWeightString: $goalWeightString,
                showingSheet: $showingGoalWeightSheet,
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $showingEditSheet) {
            EditWeightSheet(
                selectedWeight: selectedWeight,
                editWeight: $editWeight,
                showingSheet: $showingEditSheet,
                viewModel: viewModel
            )
        }
        .onChange(of: newWeight) { _ in
            if showingError { withAnimation { showingError = false } }
        }
        .onTapGesture {
            isWeightFocused = false
        }
    }
    
    private func validateAndAddWeight() {
        let trimmedWeight = newWeight.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedWeight.isEmpty else {
            showError("Please enter a weight")
            return
        }
        
        guard let weight = Double(trimmedWeight) else {
            showError("Please enter a valid number")
            return
        }
        
        let (minWeight, maxWeight) = viewModel.preferredUnit == .kg ? (0.0, 453.6) : (0.0, 1000.0)
        guard weight > minWeight && weight < maxWeight else {
            showError("Please enter a reasonable weight (0-\(Int(maxWeight)) \(viewModel.preferredUnit.symbol))")
            return
        }
        
        let weightInLbs = viewModel.preferredUnit == .kg ? weight * 2.20462 : weight
        
        withAnimation {
            viewModel.addWeight(weightInLbs)
            newWeight = ""
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}