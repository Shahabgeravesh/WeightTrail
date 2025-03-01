import Foundation

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let content: String
    
    init(id: UUID = UUID(), date: Date = Date(), content: String) {
        self.id = id
        self.date = date
        self.content = content
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}