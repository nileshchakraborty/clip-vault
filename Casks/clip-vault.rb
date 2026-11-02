cask "clip-vault" do
  version "1.0.0"
  sha256 "44b963a02c1f943533eaa8ac6034eb81bdbbfcb26be75b99bd5fb550b163effb"

  url "https://github.com/nileshchakraborty/clip-vault/releases/download/v#{version}/ClipVault-#{version}.dmg"
  name "ClipVault"
  desc "Lightweight, privacy-first, RAM-only macOS clipboard history manager"
  homepage "https://github.com/nileshchakraborty/clip-vault"

  depends_on macos: ">= :sonoma"

  app "ClipVault.app"

  zap trash: [
    "~/Library/Application Support/com.clipvault.mac",
    "~/Library/Preferences/com.clipvault.mac.plist",
  ]
end
