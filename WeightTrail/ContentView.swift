//
//  ContentView.swift
//  Habitmend
//
//  Created by Shahab Geravesh on 2/25/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WeightTrackerViewModel()
    @State private var showingSettings = false
    
    // Add deep linking support
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        TabView {
            weightTab
            progressTab
            journalTab
        }
        .tint(Theme.primary)
        // Support system appearance settings
        .preferredColorScheme(.none)
    }
    
    private var weightTab: some View {
        NavigationStack {
            WeightTrackingView(viewModel: viewModel)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .foregroundColor(Theme.primary)
                        }
                    }
                }
        }
        .tabItem {
            Label("Weight", systemImage: "scalemass.fill")
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                SettingsView(viewModel: viewModel)
                    .navigationTitle("Settings")
                    .navigationBarItems(
                        trailing: Button("Done") {
                            showingSettings = false
                        }
                    )
            }
        }
    }
    
    private var progressTab: some View {
        NavigationStack {
            WeightProgressView(viewModel: viewModel)
        .navigationBarTitleDisplayMode(.inline)
        }
        .tabItem {
            Label("Progress", systemImage: "chart.xyaxis.line")
        }
    }
    
    private var journalTab: some View {
        NavigationStack {
            JournalView(viewModel: viewModel)
        .navigationBarTitleDisplayMode(.inline)
        }
        .tabItem {
            Label("Journal", systemImage: "book.fill")
        }
    }
}

extension WeightTrackerViewModel {
    func generateInsights() -> [String] {
        var insights: [String] = []
        
        // Time of day patterns
        let morningWeights = weights.filter { 
            Calendar.current.component(.hour, from: $0.date) < 12 
        }
        if Double(morningWeights.count) > Double(weights.count) * 0.7 {
            insights.append("You're most consistent weighing in during morning hours")
        }
        
        // Progress patterns
        if let monthChange = Weight.calculateChange(from: weights, timeFrame: .month) {
            if monthChange < 0 {
                insights.append("You've lost \(String(format: "%.1f", abs(monthChange))) \(preferredUnit.symbol) this month")
            }
        }
        
        return insights
    }
}
