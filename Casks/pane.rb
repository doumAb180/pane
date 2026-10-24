cask "pane" do
  version "0.2.0"
  sha256 "b38e8ed60f6445bcbf5c9d38bcd6ffa095097b96d26b04836e53476f9b24fe8c"

  url "https://github.com/doumAb180/pane/releases/download/v#{version}/Pane-#{version}-universal.dmg"
  name "Pane"
  desc "Menu bar window manager with half and quarter size cycling"
  homepage "https://github.com/doumAb180/pane"

  depends_on macos: :ventura

  app "Pane.app"

  zap trash: "~/Library/Preferences/io.github.doumAb180.Pane.plist"
end
