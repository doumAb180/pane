import Carbon

final class HotKeys {
    private var handler: EventHandlerRef?
    private var registrations: [EventHotKeyRef] = []
    private let perform: (Action) -> Void
    private(set) var failures: [String] = []
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
        if status != noErr { failures = ["단축키 이벤트 등록 실패 (\(status))"] }
    }

    func register(enabled: Bool, extraCommand: Bool) {
        unregister()
        guard enabled else { failures = []; return }
        guard handler != nil else { failures = ["단축키 이벤트를 등록할 수 없습니다."]; return }
        failures = []
        let modifiers = UInt32(controlKey | optionKey | (extraCommand ? cmdKey : 0))
        for action in Action.allCases {
            var reference: EventHotKeyRef?
            let identifier = EventHotKeyID(signature: Self.signature, id: UInt32(action.rawValue))
            let status = RegisterEventHotKey(action.key.code, modifiers, identifier,
                                             GetApplicationEventTarget(), 0, &reference)
            if status == noErr, let reference { registrations.append(reference) }
            else { failures.append(action.title) }
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
