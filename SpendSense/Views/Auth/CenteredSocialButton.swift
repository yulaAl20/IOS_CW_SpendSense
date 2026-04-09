import SwiftUI

struct CenteredSocialButton: View {
    let icon: String
    let label: String
    let foreground: Color
    let background: Color
    let border: Color
    let action: () -> Void
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(foreground)
                Text(label)
                    .font(SSFont.body(15, weight: .medium))
                    .foregroundColor(foreground)
            }
            .frame(maxWidth: .infinity)          // centre the HStack
            .frame(height: 52)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(border, lineWidth: scheme == .dark ? 0.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
