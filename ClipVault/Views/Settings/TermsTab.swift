import SwiftUI

public struct TermsTab: View {
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service & License")
                    .font(.system(size: 14, weight: .bold))

                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Acceptance of Terms")
                        .font(.system(size: 12, weight: .semibold))
                    Text("By using ClipVault, you agree to these Terms. ClipVault is provided for personal and professional productivity on macOS systems.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Divider()

                    Text("2. License (MIT License)")
                        .font(.system(size: 12, weight: .semibold))
                    Text("""
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY.
""")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.secondary.opacity(0.08))
                        .cornerRadius(6)

                    Divider()

                    Text("3. Local Utility Scope")
                        .font(.system(size: 12, weight: .semibold))
                    Text("ClipVault functions entirely on your local Mac. It does not transmit, syndicate, or synchronize your clipboard data across external cloud infrastructure. You are responsible for ensuring that clipboard data you copy complies with your organizational and confidentiality guidelines.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Divider()

                    Text("4. Termination & Deletion")
                        .font(.system(size: 12, weight: .semibold))
                    Text("You may terminate use and discard all active clipboard state at any time by clearing the history or quitting the application.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
            .padding(16)
        }
    }
}
