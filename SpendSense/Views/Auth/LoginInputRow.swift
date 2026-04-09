import SwiftUI

struct LoginInputRow<F: Hashable>: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let field: F
    @FocusState.Binding var focused: F?
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(focused == field ? .ssAccent : .ssTextTertiary)
                .frame(width: 20)
                .padding(.leading, 16)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }
            .font(SSFont.body(15))
            .foregroundColor(.ssTextPrimary)
            .accentColor(.ssAccent)
            .focused($focused, equals: field)
            .padding(.vertical, 16)
            .padding(.trailing, 16)
        }
    }
}
