cask "clip-vault" do
  version "1.0.0"
  sha256 "086240fe3348aee46e333728e3982d177e208bfadde296dba0e2ec2d843de77a"

  url "https://github.com/nileshchakraborty/clip-vault/releases/download/v#{version}/ClipVault-#{version}.dmg"
  name "ClipVault"
  desc "Lightweight, privacy-first, RAM-only clipboard history manager"
  homepage "https://github.com/nileshchakraborty/clip-vault"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :macos

  app "ClipVault.app"

  postflight_steps do
    run "/usr/bin/xattr", args: ["-d", "com.apple.quarantine", "{{appdir}}/ClipVault.app"], must_succeed: false
  end

  zap trash: [
    "~/Library/Application Support/com.clipvault.mac",
    "~/Library/Preferences/com.clipvault.mac.plist",
  ]
end
