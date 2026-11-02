import SwiftUI

public struct ToastView: View {
    let message: String

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 14))

            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: message)
    }
}
