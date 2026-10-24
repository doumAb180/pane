cask "pane" do
  version "0.1.0"
  sha256 "fcc8d782dd8cac04261173ccf7f930d0b85eddaed17aca86db26da977e9773d6"

  url "https://github.com/doumAb180/pane/releases/download/v#{version}/Pane-#{version}-universal.dmg"
  name "Pane"
  desc "Menu bar window manager with half and quarter size cycling"
  homepage "https://github.com/doumAb180/pane"

  depends_on macos: :ventura

  app "Pane.app"

  zap trash: "~/Library/Preferences/io.github.doumAb180.Pane.plist"
end
