#!/usr/bin/env python3
"""Pin the custom Homebrew tap to the exact published Universal DMG."""
import hashlib
import pathlib
import re
import sys

version, image_path = sys.argv[1:]
if not re.fullmatch(r"\d+\.\d+\.\d+", version):
    raise SystemExit("Version must have the form 1.2.3")
image = pathlib.Path(image_path)
if image.name != f"Pane-{version}-universal.dmg":
    raise SystemExit("The cask requires the matching Universal DMG")
target = pathlib.Path(__file__).resolve().parent.parent / "Casks" / "pane.rb"
if target.exists():
    old = re.search(r'version "(\d+\.\d+\.\d+)"', target.read_text())
    if old and tuple(map(int, old[1].split("."))) > tuple(map(int, version.split("."))):
        print("Keeping the newer cask version")
        raise SystemExit(0)
digest = hashlib.sha256(image.read_bytes()).hexdigest()
target.parent.mkdir(exist_ok=True)
target.write_text('''cask "pane" do
  version "%s"
  sha256 "%s"

  url "https://github.com/doumAb180/pane/releases/download/v#{version}/Pane-#{version}-universal.dmg"
  name "Pane"
  desc "Menu bar window manager with half and quarter size cycling"
  homepage "https://github.com/doumAb180/pane"

  depends_on macos: ">= :ventura"

  app "Pane.app"

  zap trash: "~/Library/Preferences/io.github.doumAb180.Pane.plist"
end
''' % (version, digest))
print(f"Updated {target.name} to {version} ({digest})")
