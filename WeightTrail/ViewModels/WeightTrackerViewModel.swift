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
    @Published var journalEntries: [JournalEntry] = []
    @Published var preferredUnit: WeightUnit {
        didSet {
            UserDefaults.standard.set(preferredUnit.rawValue, forKey: unitPreferenceKey)
        }
    }
    
    private let weightsKey = "savedWeights"
    private let goalWeightKey = "goalWeight"
    private let swipeHintKey = "hasSeenSwipeHint"
    private let journalKey = "savedJournalEntries"
    private let unitPreferenceKey = "weightUnitPreference"
    
    init() {
        self.hasSeenSwipeHint = UserDefaults.standard.bool(forKey: swipeHintKey)
        if let savedUnit = UserDefaults.standard.string(forKey: unitPreferenceKey),
           let unit = WeightUnit(rawValue: savedUnit) {
            self.preferredUnit = unit
        } else {
            self.preferredUnit = .lbs // Default to lbs
        }
        loadData()
        loadJournalEntries()
    }
    
    // MARK: - Weight Management
    func addWeight(_ weight: Double) {
        let newWeight = Weight(weight: weight)
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
    
    func updateWeight(_ weight: Weight, newWeight: Double) {
        if let index = weights.firstIndex(where: { $0.id == weight.id }) {
            weights[index] = Weight(id: weight.id, date: weight.date, weight: newWeight)
            saveWeights()
        }
    }
    
    // MARK: - Journal Management
    func addJournalEntry(_ content: String) {
        let entry = JournalEntry(content: content)
        journalEntries.append(entry)
        journalEntries.sort { $0.date > $1.date }
        saveJournalEntries()
    }
    
    func deleteJournalEntry(_ entry: JournalEntry) {
        withAnimation {
            journalEntries.removeAll { $0.id == entry.id }
            saveJournalEntries()
        }
    }
    
    func updateJournalEntry(_ entry: JournalEntry, newContent: String) {
        if let index = journalEntries.firstIndex(where: { $0.id == entry.id }) {
            journalEntries[index] = JournalEntry(id: entry.id, date: entry.date, content: newContent)
            saveJournalEntries()
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
    
    private func saveJournalEntries() {
        if let encoded = try? JSONEncoder().encode(journalEntries) {
            UserDefaults.standard.set(encoded, forKey: journalKey)
        }
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
    
    private func loadJournalEntries() {
        if let savedEntries = UserDefaults.standard.data(forKey: journalKey),
           let decodedEntries = try? JSONDecoder().decode([JournalEntry].self, from: savedEntries) {
            journalEntries = decodedEntries
        }
    }
    
    func dismissSwipeHint() {
        hasSeenSwipeHint = true
    }
    
    func displayWeight(_ weight: Double) -> String {
        let weightInPreferredUnit = preferredUnit == .kg ? weight / 2.20462 : weight
        return String(format: "%.1f", weightInPreferredUnit)
    }
} 