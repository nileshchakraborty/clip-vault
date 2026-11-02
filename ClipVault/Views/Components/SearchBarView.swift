import SwiftUI

public struct SearchBarView: View {
    @Binding var text: String
    @Binding var selectedFilter: ContentType?

    public init(text: Binding<String>, selectedFilter: Binding<ContentType?>) {
        self._text = text
        self._selectedFilter = selectedFilter
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Search Input Field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))

                TextField("Search history & pinned items...", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))

                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )

            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    FilterChip(
                        title: "All",
                        icon: "square.grid.2x2",
                        isSelected: selectedFilter == nil
                    ) {
                        selectedFilter = nil
                    }

                    ForEach(ContentType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.rawValue,
                            icon: iconForType(type),
                            isSelected: selectedFilter == type
                        ) {
                            selectedFilter = (selectedFilter == type) ? nil : type
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func iconForType(_ type: ContentType) -> String {
        switch type {
        case .text: return "doc.text"
        case .richText: return "doc.richtext"
        case .url: return "link"
        case .color: return "paintpalette"
        case .image: return "photo"
        }
    }
}

private struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
