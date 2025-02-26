//
//  ContentView.swift
//  Habitmend
//
//  Created by Shahab Geravesh on 2/25/25.
//

import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var viewModel = WeightTrackerViewModel()
    @StateObject private var storeManager = StoreManager.shared
    
    var body: some View {
        TabView {
            // First Tab - Weight Logging
            NavigationStack {
                WeightTrackingView(viewModel: viewModel)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Log Weight")
                                .font(.headline)
                                .foregroundColor(Theme.primary)
                        }
                    }
            }
            .tabItem {
                Label("Log", systemImage: "square.and.pencil")
            }
            
            // Second Tab - Progress
            NavigationStack {
                if storeManager.isProgressUnlocked {
                    WeightProgressView(viewModel: viewModel)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text("Progress")
                                    .font(.headline)
                                    .foregroundColor(Theme.primary)
                            }
                        }
                } else {
                    PurchaseView(viewModel: viewModel)
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
            .tabItem {
                Label("Progress", systemImage: "chart.xyaxis.line")
            }
        }
        .tint(Theme.primary)
    }
}

struct WeightTrackingView: View {
    @ObservedObject var viewModel: WeightTrackerViewModel
    @State private var newWeight: String = ""
    @State private var newNote: String = ""
    @State private var showingGoalWeightSheet = false
    @State private var goalWeightString: String = ""
    @State private var showingResetAlert = false
    @State private var selectedWeight: Weight?
    @State private var showingEditSheet = false
    @State private var editWeight: String = ""
    @State private var editNote: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isNoteFocused: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private func validateAndAddWeight() {
        // Remove any whitespace
        let trimmedWeight = newWeight.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedWeight.isEmpty else {
            showError("Please enter a weight")
            return
        }
        
        guard let weight = Double(trimmedWeight) else {
            showError("Please enter a valid number")
            return
        }
        
        guard weight > 0 && weight < 1000 else {
            showError("Please enter a reasonable weight (0-1000 lbs)")
            return
        }
        
        withAnimation {
            viewModel.addWeight(weight, note: newNote.isEmpty ? nil : newNote)
            newWeight = ""
            newNote = ""
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: horizontalSizeClass == .regular ? 32 : 24) {
                // Add Weight Card
                VStack(spacing: horizontalSizeClass == .regular ? 24 : 20) {
                    Text("Add New Weight")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        VStack(spacing: 8) {
                            TextField("Weight", text: $newWeight)
                                .submitLabel(.done)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(CustomTextFieldStyle())
                                .frame(maxWidth: .infinity)
                                .focused($isWeightFocused)
                                .onChange(of: newWeight) { newValue in
                                    // Only allow numbers and decimal point
                                    let filtered = newValue.filter { "0123456789.".contains($0) }
                                    if filtered != newValue {
                                        newWeight = filtered
                                    }
                                    // Only allow one decimal point
                                    if filtered.filter({ $0 == "." }).count > 1 {
                                        newWeight = String(filtered.prefix(while: { $0 != "." })) + "."
                                    }
                                }
                            
                            if showingError {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .transition(.opacity)
                            }
                            
                            TextField("Note (optional)", text: $newNote)
                                .textFieldStyle(CustomTextFieldStyle())
                                .frame(maxWidth: .infinity)
                                .focused($isNoteFocused)
                        }
                        
                        Button(action: {
                            validateAndAddWeight()
                            isWeightFocused = false
                            isNoteFocused = false
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
                
                // History Section
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
                        if !viewModel.hasSeenSwipeHint {
                            HintView(
                                icon: "trash.circle.fill",
                                title: "Quick Tip",
                                subtitle: "Tap the trash icon to delete • Tap anywhere else to edit"
                            ) {
                                withAnimation(.easeOut) {
                                    viewModel.dismissSwipeHint()
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.weights) { weight in
                                    WeightRowView(weight: weight) {
                                        viewModel.deleteWeight(weight)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedWeight = weight
                                        editWeight = String(format: "%.1f", weight.weight)
                                        editNote = weight.note ?? ""
                                        showingEditSheet = true
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
            }
            .frame(maxWidth: .infinity)
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
                    Button(action: {
                        showingGoalWeightSheet = true
                    }) {
                        Label("Set Goal", systemImage: "flag.fill")
                    }
                    
                    Button(role: .destructive, action: {
                        showingResetAlert = true
                    }) {
                        Label("Reset All Data", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundStyle(Theme.primary)
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
            NavigationView {
                Form {
                    Section("Goal Weight") {
                        TextField("Enter goal weight", text: $goalWeightString)
                            .keyboardType(.decimalPad)
                            .onChange(of: goalWeightString) { newValue in
                                let filtered = newValue.filter { "0123456789.".contains($0) }
                                if filtered != newValue {
                                    goalWeightString = filtered
                                }
                                if filtered.filter({ $0 == "." }).count > 1 {
                                    goalWeightString = String(filtered.prefix(while: { $0 != "." })) + "."
                                }
                            }
                    }
                }
                .navigationTitle("Set Goal")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingGoalWeightSheet = false
                    },
                    trailing: Button("Save") {
                        if let goalWeight = Double(goalWeightString),
                           goalWeight > 0 && goalWeight < 1000 {
                            viewModel.setGoalWeight(goalWeight)
                            showingGoalWeightSheet = false
                        } else {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.error)
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                Form {
                    Section("Edit Weight Entry") {
                        TextField("Weight", text: $editWeight)
                            .keyboardType(.decimalPad)
                        TextField("Note (optional)", text: $editNote)
                    }
                }
                .navigationTitle("Edit Entry")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingEditSheet = false
                    },
                    trailing: Button("Save") {
                        if let weight = selectedWeight,
                           let newWeight = Double(editWeight) {
                            viewModel.updateWeight(weight, newWeight: newWeight, newNote: editNote.isEmpty ? nil : editNote)
                        }
                        showingEditSheet = false
                    }
                )
            }
        }
        .onChange(of: newWeight) { _ in
            // Clear error when user starts typing again
            if showingError {
                withAnimation {
                    showingError = false
                }
            }
        }
        .onTapGesture {
            isWeightFocused = false
            isNoteFocused = false
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "scale.3d")
                .font(.system(size: 60))
                .foregroundStyle(Theme.primary.opacity(0.8))
                .symbolRenderingMode(.hierarchical)
            
            Text("No Entries Yet")
                .font(.title3)
                .bold()
            
            Text("Add your first weight measurement to start tracking your progress")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.cardBackground)
                .shadow(color: Theme.cardShadow, radius: 8)
        )
        .padding(.horizontal)
    }
}

struct WeightRowView: View {
    let weight: Weight
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "%.1f lbs", weight.weight))
                    .font(.headline)
                
                Text(weight.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let note = weight.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            
            Button(action: {
                withAnimation {
                    onDelete()
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(8)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(12)
    }
}

struct HintView: View {
    let icon: String
    let title: String
    let subtitle: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.primary)
                .padding(8)
                .background(
                    Circle()
                        .fill(Theme.primary.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Got it") {
                onDismiss()
            }
            .font(.subheadline)
            .foregroundColor(Theme.primary)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(Theme.primary.opacity(0.1))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardBackground)
                .shadow(color: Theme.cardShadow, radius: 4)
        )
    }
}

struct PurchaseView: View {
    @ObservedObject var viewModel: WeightTrackerViewModel
    @StateObject private var storeManager = StoreManager.shared
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.primary)
                    .symbolRenderingMode(.hierarchical)
                
                Text("Unlock Progress Tracking")
                    .font(.title2)
                    .bold()
                
                Text("Track your weight journey with beautiful charts and detailed statistics")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "chart.xyaxis.line", text: "Interactive Weight Charts")
                    FeatureRow(icon: "arrow.up.right.circle", text: "Progress Statistics")
                    FeatureRow(icon: "calendar", text: "Time-based Analysis")
                    FeatureRow(icon: "flag.fill", text: "Goal Tracking")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.cardBackground)
                )
                .padding(.horizontal)
                
                if let product = storeManager.products.first {
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                isPurchasing = true
                                do {
                                    try await storeManager.purchase(product)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                                isPurchasing = false
                            }
                        } label: {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Unlock for \(product.displayPrice)")
                                    .bold()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.primary)
                        .disabled(isPurchasing || isRestoring)
                        
                        Button {
                            Task {
                                isRestoring = true
                                do {
                                    try await storeManager.restorePurchases()
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                                isRestoring = false
                            }
                        } label: {
                            if isRestoring {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.primary))
                            } else {
                                Text("Restore Purchase")
                                    .font(.subheadline)
                            }
                        }
                        .disabled(isPurchasing || isRestoring)
                    }
                } else if storeManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.primary))
                }
            }
        }
        .padding()
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
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

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Theme.primary)
            Text(text)
                .foregroundColor(.primary)
        }
    }
}

struct WeightProgressView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = WeightTrackerViewModel()
        NavigationView {
            WeightProgressView(viewModel: viewModel)
        }
    }
}
