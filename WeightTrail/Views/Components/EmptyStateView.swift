import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "scale.3d")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No weight entries yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Add your first weight entry using the form above")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
} 