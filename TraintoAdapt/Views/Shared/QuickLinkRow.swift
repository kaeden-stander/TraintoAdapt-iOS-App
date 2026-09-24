import SwiftUI

struct QuickLinkRow: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 28)
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(Font.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .contentShape(Rectangle())
    }
}
