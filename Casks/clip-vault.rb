cask "clip-vault" do
  version "1.0.0"
  sha256 "c3a3723756a16eb7b972134222113478cf9264dfcf9ff9066dd7dadefc804022"

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
