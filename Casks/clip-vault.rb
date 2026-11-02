cask "clip-vault" do
  version "1.0.0"
  sha256 "35b6a63381b899e24229f69e3b713a62ef3406a33e2f366ffd06757c9424b60e"

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
