cask "macscp" do
  version "0.2.6"
  sha256 "9bc8b75e3325c18190bb5902c6a7bae04fe9009d8eaf14c68420be09cbdcf1af"

  url "https://github.com/macnev2013/macSCP/releases/download/v#{version}/macSCP-#{version}.dmg"
  name "macSCP"
  desc "Native client for SFTP, S3, and SSH terminal"
  homepage "https://www.macscp.co/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sequoia"

  app "macSCP.app"

  zap trash: [
    "~/Library/Caches/com.macscp.macSCP",
    "~/Library/Preferences/com.macscp.macSCP.plist",
    "~/Library/Saved Application State/com.macscp.macSCP.savedState",
  ]
end
