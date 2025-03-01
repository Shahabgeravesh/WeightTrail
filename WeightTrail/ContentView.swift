//
//  ContentView.swift
//  Habitmend
//
//  Created by Shahab Geravesh on 2/25/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WeightTrackerViewModel()
    
    var body: some View {
        TabView {
            weightTab
            progressTab
            journalTab
        }
        .tint(Theme.primary)
    }
    
    private var weightTab: some View {
        NavigationStack {
            WeightTrackingView(viewModel: viewModel)
                .navigationBarTitleDisplayMode(.inline)
        }
        .tabItem {
            Label("Weight", systemImage: "scalemass.fill")
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
