import SwiftUI

struct JournalView: View {
    @ObservedObject var viewModel: WeightTrackerViewModel
    @State private var newEntry: String = ""
    @State private var showingEditSheet = false
    @State private var selectedEntry: JournalEntry?
    @State private var editContent: String = ""
    @FocusState private var isEditing: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        ScrollView {
            VStack(spacing: horizontalSizeClass == .regular ? 32 : 24) {
                // Add Entry Card
                VStack(spacing: 16) {
                    TextField("Write your thoughts...", text: $newEntry, axis: .vertical)
                        .textFieldStyle(.custom)
                        .frame(height: 100)
                        .focused($isEditing)
                    
                    Button(action: {
                        if !newEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            viewModel.addJournalEntry(newEntry)
                            newEntry = ""
                            isEditing = false
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }
                    }) {
                        Text("Save Entry")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.primary)
                            .cornerRadius(12)
                    }
                    .disabled(newEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(newEntry.isEmpty ? 0.6 : 1)
                }
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(16)
                .shadow(color: Theme.cardShadow, radius: 10)
                .padding(.horizontal)
                
                // Journal Entries
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.journalEntries) { entry in
                        JournalEntryRow(entry: entry, onDelete: {
                            viewModel.deleteJournalEntry(entry)
                        })
                        .onTapGesture {
                            selectedEntry = entry
                            editContent = entry.content
                            showingEditSheet = true
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .onTapGesture {
            isEditing = false // Dismiss keyboard when tapping outside
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                Form {
                    Section("Edit Entry") {
                        TextEditor(text: $editContent)
                            .frame(height: 200)
                            .onChange(of: editContent) { _ in
                                // Enable haptic feedback while typing
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                    }
                }
                .navigationTitle("Edit Entry")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingEditSheet = false
                    },
                    trailing: Button("Save") {
                        guard let entry = selectedEntry,
                              !editContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            return
                        }
                        
                        withAnimation {
                            viewModel.updateJournalEntry(entry, newContent: editContent)
                            // Success haptic
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }
                        showingEditSheet = false
                    }
                    .disabled(editContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                )
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                             to: nil, 
                                             from: nil, 
                                             for: nil)
            }
        }
    }
}

struct JournalEntryRow: View {
    let entry: JournalEntry
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(entry.content)
                .font(.body)
            
            HStack {
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Theme.cardShadow, radius: 4)
    }
} 