import AppKit
import Foundation

public enum ContentType: String, Codable, CaseIterable {
    case text = "Text"
    case richText = "Rich Text"
    case url = "Link"
    case color = "Color"
    case image = "Image"
}

public struct ClipboardContent: Codable, Equatable {
    public let type: ContentType
    public let textValue: String?
    public let rtfData: Data?
    public let imageData: Data?
    public let urlString: String?
    public let hexColor: String?

    public init(
        type: ContentType,
        textValue: String? = nil,
        rtfData: Data? = nil,
        imageData: Data? = nil,
        urlString: String? = nil,
        hexColor: String? = nil
    ) {
        self.type = type
        self.textValue = textValue
        self.rtfData = rtfData
        self.imageData = imageData
        self.urlString = urlString
        self.hexColor = hexColor
    }

    public static func text(_ str: String) -> ClipboardContent {
        ClipboardContent(type: .text, textValue: str)
    }

    public static func url(_ url: URL) -> ClipboardContent {
        ClipboardContent(type: .url, textValue: url.absoluteString, urlString: url.absoluteString)
    }

    public static func color(hex: String) -> ClipboardContent {
        ClipboardContent(type: .color, textValue: hex, hexColor: hex)
    }

    public static func image(data: Data) -> ClipboardContent {
        ClipboardContent(type: .image, imageData: data)
    }

    public static func richText(data: Data, plainString: String) -> ClipboardContent {
        ClipboardContent(type: .richText, textValue: plainString, rtfData: data)
    }
}
