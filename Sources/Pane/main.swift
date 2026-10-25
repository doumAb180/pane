import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var model: AppModel!
    private var toast: NSPanel?
    private var dismissToast: DispatchWorkItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Reopening a second copy should not silently steal all hotkeys.
        if let id = Bundle.main.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: id).count > 1 {
            NSApp.terminate(nil)
            return
        }
        model = AppModel()
        model.onHotKeyResult = { [weak self] message, error in self?.showToast(message, error: error) }
        model.onBeginRecording = { [weak self] in
            NSApp.activate(ignoringOtherApps: true)
            self?.popover.contentViewController?.view.window?.makeKey()
        }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "rectangle.split.2x1", accessibilityDescription: model.text("Pane window layouts"))
            button.target = self
            button.action = #selector(togglePopover)
            button.toolTip = model.text("Pane · Every window in its place")
        }
        model.onLanguageChange = { [weak self] in
            guard let self else { return }
            self.statusItem.button?.toolTip = self.model.text("Pane · Every window in its place")
            self.statusItem.button?.setAccessibilityLabel(self.model.text("Pane window layouts"))
        }
        popover.behavior = .transient
        popover.delegate = self
        popover.animates = false
        popover.contentViewController = NSHostingController(rootView: PanelView(model: model))
        if !UserDefaults.standard.bool(forKey: "hasLaunched") {
            UserDefaults.standard.set(true, forKey: "hasLaunched")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.togglePopover() }
        }
    }

    func popoverDidClose(_ notification: Notification) {
        model.cancelRecording()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown { popover.performClose(nil) }
        else {
            model.captureTarget()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func showToast(_ message: String, error: Bool) {
        if popover.isShown { return }
        dismissToast?.cancel()
        toast?.orderOut(nil)
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 360, height: 52),
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView:
            HStack(spacing: 9) {
                Image(systemName: error ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(error ? Color.orange : Color.indigo)
                Text(message).font(.system(size: 12, weight: .medium)).lineLimit(2)
            }.padding(14).frame(width: 360, height: 52)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
        )
        let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }) ?? NSScreen.main
        if let frame = screen?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: frame.midX - 180, y: frame.minY + 38))
        }
        panel.orderFrontRegardless()
        toast = panel
        let work = DispatchWorkItem { [weak panel] in panel?.orderOut(nil) }
        dismissToast = work
        DispatchQueue.main.asyncAfter(deadline: .now() + (error ? 3.5 : 1.6), execute: work)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
