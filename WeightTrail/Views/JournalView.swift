import SwiftUI

struct JournalView: View {
    @ObservedObject var viewModel: WeightTrackerViewModel
    @State private var newEntry: String = ""
    @State private var editState: EditState?
    @FocusState private var isEditing: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    struct EditState: Identifiable {
        let id: UUID
        let entry: JournalEntry
        var content: String
        
        init(entry: JournalEntry) {
            self.id = entry.id
            self.entry = entry
            self.content = entry.content
        }
    }
    
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
                            editState = EditState(entry: entry)
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
        .sheet(item: $editState) { state in
            NavigationView {
                Form {
                    Section("Edit Entry") {
                        TextEditor(text: Binding(
                            get: { state.content },
                            set: { editState?.content = $0 }
                        ))
                            .frame(height: 200)
                            .onChange(of: state.content) { _ in
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                    }
                }
                .navigationTitle("Edit Entry")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        editState = nil
                    },
                    trailing: Button("Save") {
                        guard !state.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            return
                        }
                        
                        withAnimation {
                            viewModel.updateJournalEntry(state.entry, newContent: state.content)
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }
                        editState = nil
                    }
                    .disabled(state.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                )
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