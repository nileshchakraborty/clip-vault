import AppKit
import Foundation

public struct ClipboardItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public let createdAt: Date
    public let content: ClipboardContent
    public var isPinned: Bool
    public let previewText: String
    public let byteSize: Int
    public let characterCount: Int

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        content: ClipboardContent,
        isPinned: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.content = content
        self.isPinned = isPinned

        switch content.type {
        case .text:
            let text = content.textValue ?? ""
            // Cap previewText to 500 characters to keep memory footprint light
            let trimmed = text.prefix(500).trimmingCharacters(in: .whitespacesAndNewlines)
            self.previewText = content.isTruncated ? "\(trimmed) … [Truncated]" : trimmed
            self.characterCount = text.count
            self.byteSize = text.utf8.count

        case .richText:
            let text = content.textValue ?? ""
            let trimmed = text.prefix(500).trimmingCharacters(in: .whitespacesAndNewlines)
            self.previewText = content.isTruncated ? "\(trimmed) … [Truncated]" : trimmed
            self.characterCount = text.count
            self.byteSize = content.rtfData?.count ?? text.utf8.count

        case .url:
            let urlStr = content.urlString ?? content.textValue ?? ""
            self.previewText = urlStr
            self.characterCount = urlStr.count
            self.byteSize = urlStr.utf8.count

        case .color:
            let hex = content.hexColor ?? content.textValue ?? "#000000"
            self.previewText = hex.uppercased()
            self.characterCount = hex.count
            self.byteSize = hex.utf8.count

        case .image:
            let size = content.imageData?.count ?? 0
            self.previewText = "Image (\(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)))"
            self.characterCount = 0
            self.byteSize = size
        }
    }

    public var typeIcon: String {
        switch content.type {
        case .text: return "doc.text"
        case .richText: return "doc.richtext"
        case .url: return "link"
        case .color: return "paintpalette"
        case .image: return "photo"
        }
    }

    public var formattedTime: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(createdAt) {
            formatter.dateFormat = "h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        return formatter.string(from: createdAt)
    }

    public var metadataDescription: String {
        switch content.type {
        case .text, .richText:
            let truncNotice = content.isTruncated ? " • Truncated" : ""
            return "\(characterCount) chars • \(formattedTime)\(truncNotice)"
        case .url:
            if let url = URL(string: content.urlString ?? ""), let host = url.host {
                return "\(host) • \(formattedTime)"
            }
            return "URL • \(formattedTime)"
        case .color:
            return "Hex Color • \(formattedTime)"
        case .image:
            return "\(ByteCountFormatter.string(fromByteCount: Int64(byteSize), countStyle: .file)) • \(formattedTime)"
        }
    }

    public var searchString: String {
        switch content.type {
        case .text, .richText, .url, .color:
            return (content.textValue?.prefix(500) ?? "").lowercased()
        case .image:
            return "image photo"
        }
    }
}
