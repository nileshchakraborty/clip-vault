import SwiftUI

public struct SearchBarView: View {
    @Binding var text: String
    @Binding var selectedFilter: ContentType?
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, selectedFilter: Binding<ContentType?>) {
        self._text = text
        self._selectedFilter = selectedFilter
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Search Input Field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(isFocused ? .accentColor : .secondary)
                    .font(.system(size: 13, weight: isFocused ? .semibold : .regular))
                    .animation(.easeInOut(duration: 0.15), value: isFocused)

                TextField("Search history & pinned items...", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isFocused)

                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    .help("Clear search")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isFocused ? 1.5 : 1.0)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)

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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
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
