import Foundation
import SwiftUI

class WeightTrackerViewModel: ObservableObject {
    @Published var weights: [Weight] = []
    @Published var goalWeight: Double? {
        didSet {
            saveGoalWeight()
        }
    }
    @Published var hasSeenSwipeHint: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenSwipeHint, forKey: "hasSeenSwipeHint")
        }
    }
    
    private let weightsKey = "savedWeights"
    private let goalWeightKey = "goalWeight"
    private let swipeHintKey = "hasSeenSwipeHint"
    
    init() {
        self.hasSeenSwipeHint = UserDefaults.standard.bool(forKey: swipeHintKey)
        loadData()
    }
    
    // MARK: - Weight Management
    func addWeight(_ weight: Double, note: String? = nil) {
        let newWeight = Weight(weight: weight, note: note)
        weights.append(newWeight)
        weights.sort { $0.date > $1.date }
        saveWeights()
    }
    
    func deleteWeight(_ weight: Weight) {
        withAnimation {
            weights.removeAll { $0.id == weight.id }
            saveWeights()
        }
    }
    
    func setGoalWeight(_ weight: Double?) {
        goalWeight = weight
    }
    
    func resetAllData() {
        weights.removeAll()
        goalWeight = nil
        UserDefaults.standard.removeObject(forKey: weightsKey)
        UserDefaults.standard.removeObject(forKey: goalWeightKey)
    }
    
    func updateWeight(_ weight: Weight, newWeight: Double, newNote: String?) {
        if let index = weights.firstIndex(where: { $0.id == weight.id }) {
            weights[index] = Weight(id: weight.id, date: weight.date, weight: newWeight, note: newNote)
            saveWeights()
        }
    }
    
    // MARK: - Persistence
    private func saveWeights() {
        if let encoded = try? JSONEncoder().encode(weights) {
            UserDefaults.standard.set(encoded, forKey: weightsKey)
        }
    }
    
    private func saveGoalWeight() {
        UserDefaults.standard.set(goalWeight, forKey: goalWeightKey)
    }
    
    private func loadData() {
        // Load weights
        if let savedWeights = UserDefaults.standard.data(forKey: weightsKey),
           let decodedWeights = try? JSONDecoder().decode([Weight].self, from: savedWeights) {
            weights = decodedWeights
        }
        
        // Load goal weight
        goalWeight = UserDefaults.standard.object(forKey: goalWeightKey) as? Double
    }
    
    func dismissSwipeHint() {
        hasSeenSwipeHint = true
    }
} 