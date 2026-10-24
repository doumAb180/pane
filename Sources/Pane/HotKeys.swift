import Carbon
import PaneCore

final class HotKeys {
    private var handler: EventHandlerRef?
    private var registrations: [EventHotKeyRef] = []
    private let perform: (Action) -> Void
    private(set) var failures: [LocalizedText] = []
    static let signature: OSType = 0x50414E45

    init(perform: @escaping (Action) -> Void) {
        self.perform = perform
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            var identifier = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                          EventParamType(typeEventHotKeyID), nil,
                                          MemoryLayout<EventHotKeyID>.size, nil, &identifier)
            guard status == noErr, identifier.signature == HotKeys.signature,
                  let action = Action(rawValue: Int(identifier.id)) else { return OSStatus(eventNotHandledErr) }
            let owner = Unmanaged<HotKeys>.fromOpaque(context).takeUnretainedValue()
            owner.perform(action)
            return noErr
        }, 1, &type, Unmanaged.passUnretained(self).toOpaque(), &handler)
        if status != noErr { failures = [.key("Could not register keyboard events.")] }
    }

    func register(enabled: Bool, bindings: ShortcutBindings) {
        unregister()
        guard enabled else { failures = []; return }
        guard handler != nil else { failures = [.key("Could not register keyboard events.")]; return }
        failures = []
        for action in Action.allCases {
            guard let shortcut = bindings[action.shortcutID] else { continue }
            var reference: EventHotKeyRef?
            let identifier = EventHotKeyID(signature: Self.signature, id: UInt32(action.rawValue))
            let status = RegisterEventHotKey(shortcut.keyCode, shortcut.carbonModifiers, identifier,
                                             GetApplicationEventTarget(), 0, &reference)
            if status == noErr, let reference { registrations.append(reference) }
            else { failures.append(action.titleText) }
        }
    }

    private func unregister() {
        registrations.forEach { UnregisterEventHotKey($0) }
        registrations.removeAll()
    }

    deinit {
        unregister()
        if let handler { RemoveEventHandler(handler) }
    }
}
