import SwiftUI

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit       // for UIKeyboardType and UITextContentType
#else
enum UIKeyboardType: Int {
    case `default` = 0
}
// Mock UITextContentType for non-iOS platforms
struct UITextContentType {
    static let emailAddress = UITextContentType()
    static let name = UITextContentType()
}
#endif

struct LabeledTextField: View {
    let label: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default      // iOS / Catalyst only
    
#if os(iOS) || targetEnvironment(macCatalyst)
    var textContentType: UITextContentType? = nil
#endif

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("", text: $text)
#if os(iOS) || targetEnvironment(macCatalyst)
                .keyboardType(keyboard)
                .textContentType(textContentType)
#endif
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.purple, lineWidth: 1)
                )
                .foregroundStyle(.white)
        }
    }
}
