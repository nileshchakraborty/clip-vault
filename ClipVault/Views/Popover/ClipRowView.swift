import SwiftUI

public struct ClipRowView: View {
    let item: ClipboardItem
    let shortcutIndex: Int?
    var searchQuery: String = ""
    let onCopy: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    @State private var isRowHovered: Bool = false
    @State private var isPinHovered: Bool = false
    @State private var isCopyHovered: Bool = false
    @State private var isDeleteHovered: Bool = false

    public init(
        item: ClipboardItem,
        shortcutIndex: Int? = nil,
        searchQuery: String = "",
        onCopy: @escaping () -> Void,
        onTogglePin: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.item = item
        self.shortcutIndex = shortcutIndex
        self.searchQuery = searchQuery
        self.onCopy = onCopy
        self.onTogglePin = onTogglePin
        self.onDelete = onDelete
    }

    public var body: some View {
        HStack(spacing: 10) {
            // Leading Thumbnail / Type Icon
            leadingIconView
                .frame(width: 32, height: 32)

            // Center Content
            VStack(alignment: .leading, spacing: 3) {
                if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(item.previewText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    highlightedText(item.previewText, query: searchQuery)
                        .font(.system(size: 12, weight: .regular))
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text(item.metadataDescription)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            // Trailing Actions & Shortcut
            HStack(spacing: 5) {
                if isRowHovered {
                    // 1. PIN LOGO & BUTTON
                    Button(action: onTogglePin) {
                        Image(systemName: item.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isPinHovered ? .white : (item.isPinned ? .orange : .secondary))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(isPinHovered ? Color.orange : (item.isPinned ? Color.orange.opacity(0.18) : Color.secondary.opacity(0.12)))
                            )
                            .scaleEffect(isPinHovered ? 1.15 : 1.0)
                            .shadow(color: isPinHovered ? Color.orange.opacity(0.4) : Color.clear, radius: 4, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .help(item.isPinned ? "Unpin item" : "Pin to Pin Board")
                    .onHover { h in
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            isPinHovered = h
                        }
                    }

                    // 2. COPY LOGO & BUTTON
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isCopyHovered ? .white : .secondary)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(isCopyHovered ? Color.blue : Color.secondary.opacity(0.12))
                            )
                            .scaleEffect(isCopyHovered ? 1.15 : 1.0)
                            .shadow(color: isCopyHovered ? Color.blue.opacity(0.4) : Color.clear, radius: 4, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .help("Copy to clipboard")
                    .onHover { h in
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            isCopyHovered = h
                        }
                    }

                    // 3. DELETE LOGO & BUTTON
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isDeleteHovered ? .white : Color.red.opacity(0.85))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(isDeleteHovered ? Color.red : Color.red.opacity(0.12))
                            )
                            .scaleEffect(isDeleteHovered ? 1.15 : 1.0)
                            .shadow(color: isDeleteHovered ? Color.red.opacity(0.4) : Color.clear, radius: 4, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .help("Delete item")
                    .onHover { h in
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            isDeleteHovered = h
                        }
                    }
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
                .fill(isRowHovered ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isRowHovered = hovering
                if !hovering {
                    isPinHovered = false
                    isCopyHovered = false
                    isDeleteHovered = false
                }
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

    // Helper to highlight matching search tokens in text
    private func highlightedText(_ text: String, query: String) -> Text {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return Text(text) }

        var attributed = AttributedString(text)
        let lowerText = text.lowercased()
        let lowerQuery = cleanQuery.lowercased()

        var searchRange = lowerText.startIndex..<lowerText.endIndex
        while let matchRange = lowerText.range(of: lowerQuery, range: searchRange) {
            if let attrRange = Range(matchRange, in: attributed) {
                attributed[attrRange].backgroundColor = Color.yellow.opacity(0.35)
                attributed[attrRange].foregroundColor = Color.primary
                attributed[attrRange].inlinePresentationIntent = .stronglyEmphasized
            }
            searchRange = matchRange.upperBound..<lowerText.endIndex
        }

        return Text(attributed)
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
               let nsImage = ThumbnailCache.shared.image(for: item.id, data: thumbData) {
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
