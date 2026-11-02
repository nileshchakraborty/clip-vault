import SwiftUI

public struct AboutMeTab: View {
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header with App Icon and Title
                HStack(spacing: 14) {
                    Image(systemName: "paperclip.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("ClipVault for macOS")
                            .font(.system(size: 16, weight: .bold))

                        Text("Version 1.0.0 (Build 1)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Text("Engineered for speed, privacy, and memory control.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 6)

                Divider()

                // About the Developer
                VStack(alignment: .leading, spacing: 8) {
                    Text("About the Creator")
                        .font(.system(size: 13, weight: .bold))

                    Text("ClipVault was created by **Nilesh Chakraborty** as a fast, distraction-free macOS clipboard utility. Many existing clipboard managers are heavy, upload telemetry, or store gigabytes of clipboard history on disk unencrypted.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineSpacing(3)

                    Text("ClipVault takes the opposite approach: strict in-memory limits (capped at 50 items), zero disk footprint by default, password-manager concealment detection, and a dedicated Pin Board for high-frequency snippets.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineSpacing(3)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                // Links & Community
                VStack(alignment: .leading, spacing: 10) {
                    Text("Links & Contact")
                        .font(.system(size: 13, weight: .bold))

                    Link(destination: URL(string: "https://github.com/nileshchakraborty")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("GitHub: github.com/nileshchakraborty")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.system(size: 12))
                    }

                    Link(destination: URL(string: "https://nileshchakraborty.github.io")!) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Portfolio & Website")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.system(size: 12))
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                Text("Crafted with Swift & SwiftUI on macOS.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
            .padding(16)
        }
    }
}
