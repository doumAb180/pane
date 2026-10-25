cask "pane" do
  version "0.3.1"
  sha256 "3d1a14b73a58ed5d8b5cc40d42a1e3f5d8480ce39c5b0a7e7073e5f4dca00464"

  url "https://github.com/doumAb180/pane/releases/download/v#{version}/Pane-#{version}-universal.dmg"
  name "Pane"
  desc "Menu bar window manager with half and quarter size cycling"
  homepage "https://github.com/doumAb180/pane"

  depends_on macos: :ventura

  app "Pane.app"

  zap trash: "~/Library/Preferences/io.github.doumAb180.Pane.plist"
end
