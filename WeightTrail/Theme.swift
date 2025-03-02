import SwiftUI

enum Theme {
    static func scaledFont(_ style: Font.TextStyle) -> Font {
        Font.system(style, design: .rounded)
    }
    
    static let primary = Color.blue
    static let secondary = Color.gray
    static let accent = Color.orange
    static let background = Color(.systemGroupedBackground)
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    static let gradientStart = Color.blue
    static let gradientEnd = Color.cyan
    
    static let cardBackground = Color(.systemBackground)
    static let cardShadow = Color.black.opacity(0.1)
} 