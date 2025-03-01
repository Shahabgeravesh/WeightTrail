import SwiftUI

extension TextFieldStyle where Self == CustomTextFieldStyle {
    static var custom: CustomTextFieldStyle { .init() }
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

// Add to project
// File > New > File > Swift File
// Name: CustomStyles
// Add to WeightTrail target 