cask "clip-vault" do
  version "1.0.0"
  sha256 "705c2223b74af34d68fbaefd1c9b36a1525d3ae08e1cd1a600d4951267fc792e"

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
