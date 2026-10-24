cask "pane" do
  version "0.3.0"
  sha256 "c8a64745b129bee122ba81304b83153761f6de719b3b822b46e02986d8c3c38f"

  url "https://github.com/doumAb180/pane/releases/download/v#{version}/Pane-#{version}-universal.dmg"
  name "Pane"
  desc "Menu bar window manager with half and quarter size cycling"
  homepage "https://github.com/doumAb180/pane"

  depends_on macos: :ventura

  app "Pane.app"

  zap trash: "~/Library/Preferences/io.github.doumAb180.Pane.plist"
end
