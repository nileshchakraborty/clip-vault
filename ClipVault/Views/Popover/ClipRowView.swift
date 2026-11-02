import SwiftUI

public struct ClipRowView: View {
    let item: ClipboardItem
    let shortcutIndex: Int?
    let onCopy: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    @State private var isHovering: Bool = false

    public var body: some View {
        HStack(spacing: 10) {
            // Leading Thumbnail / Type Icon
            leadingIconView
                .frame(width: 32, height: 32)

            // Center Content
            VStack(alignment: .leading, spacing: 3) {
                Text(item.previewText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.metadataDescription)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            // Trailing Actions & Shortcut
            HStack(spacing: 6) {
                if isHovering {
                    // Pin Button
                    Button(action: onTogglePin) {
                        Image(systemName: item.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 11))
                            .foregroundColor(item.isPinned ? .orange : .secondary)
                            .padding(5)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(item.isPinned ? "Unpin item" : "Pin to Pin Board")

                    // Copy Button
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(5)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Copy to clipboard")

                    // Delete Button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.85))
                            .padding(5)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Delete item")
                } else if let index = shortcutIndex, index <= 9 {
                    Text("⌘\(index)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.8))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onCopy()
        }
        .contextMenu {
            Button("Copy") {
                onCopy()
            }
            Button(item.isPinned ? "Unpin from Pin Board" : "Pin to Pin Board") {
                onTogglePin()
            }
            if item.content.type == .url, let urlStr = item.content.urlString, let url = URL(string: urlStr) {
                Button("Open Link in Browser") {
                    NSWorkspace.shared.open(url)
                }
            }
            Divider()
            Button("Delete Item", role: .destructive) {
                onDelete()
            }
        }
    }

    @ViewBuilder
    private var leadingIconView: some View {
        switch item.content.type {
        case .color:
            if let hex = item.content.hexColor, let color = Color(hex: hex) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
            } else {
                defaultIconSquare(icon: "paintpalette", color: .purple)
            }

        case .image:
            if let thumbData = item.content.thumbnailData ?? item.content.imageData,
               let nsImage = NSImage(data: thumbData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .cornerRadius(6)
                    .clipped()
            } else {
                defaultIconSquare(icon: "photo", color: .green)
            }

        case .url:
            defaultIconSquare(icon: "link", color: .blue)

        case .richText:
            defaultIconSquare(icon: "doc.richtext", color: .indigo)

        case .text:
            defaultIconSquare(icon: "doc.text", color: .gray)
        }
    }

    private func defaultIconSquare(icon: String, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(color.opacity(0.15))
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(color)
            )
    }
}

// Helper to construct Color from hex string
extension Color {
    init?(hex: String) {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if clean.hasPrefix("#") {
            clean.remove(at: clean.startIndex)
        }

        guard clean.count == 6 || clean.count == 8 || clean.count == 3 else {
            return nil
        }

        var rgbValue: UInt64 = 0
        guard Scanner(string: clean).scanHexInt64(&rgbValue) else { return nil }

        if clean.count == 6 {
            let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
            let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
            let b = Double(rgbValue & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b)
        } else {
            self.init(red: 0.5, green: 0.5, blue: 0.5)
        }
    }
}
