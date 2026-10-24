import Foundation

public struct ShortcutModifiers: OptionSet, Codable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let control = Self(rawValue: 1 << 0)
    public static let option = Self(rawValue: 1 << 1)
    public static let shift = Self(rawValue: 1 << 2)
    public static let command = Self(rawValue: 1 << 3)
    public static let supported: Self = [.control, .option, .shift, .command]
}

public struct Shortcut: Codable, Hashable {
    public let keyCode: UInt32
    public let modifiers: ShortcutModifiers

    public init(keyCode: UInt32, modifiers: ShortcutModifiers) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public var isValid: Bool {
        // Modifier keys cannot be the main key. Ordinary typing and Shift-only
        // combinations must remain available to the foreground app.
        keyCode <= 126 && !(54...63).contains(keyCode)
            && !modifiers.intersection([.control, .option, .command]).isEmpty
            && modifiers.subtracting(.supported).isEmpty
    }
}

public enum ShortcutBindingError: Error, Equatable {
    case unknownAction
    case invalidShortcut
    case conflict(action: String)
}

/// Stores overrides using stable action identifiers, independently of the UI.
public struct ShortcutBindings {
    public let defaults: [String: Shortcut]
    public private(set) var overrides: [String: Shortcut]

    public init(defaults: [String: Shortcut], savedData: Data? = nil) {
        self.defaults = defaults
        self.overrides = [:]
        if let savedData,
           let decoded = try? JSONDecoder().decode([String: Shortcut].self, from: savedData) {
            let known = decoded.filter { defaults[$0.key] != nil }
            let merged = defaults.merging(known) { _, saved in saved }
            // Validate the complete snapshot, so swapped bindings survive reload
            // and corrupt data never registers duplicate global shortcuts.
            if merged.values.allSatisfy(\.isValid), Set(merged.values).count == merged.count {
                overrides = known
            }
        }
    }

    public subscript(action: String) -> Shortcut? { overrides[action] ?? defaults[action] }

    public func validate(_ shortcut: Shortcut, for action: String) throws {
        guard defaults[action] != nil else { throw ShortcutBindingError.unknownAction }
        guard shortcut.isValid else { throw ShortcutBindingError.invalidShortcut }
        if let other = defaults.keys.sorted().first(where: { $0 != action && self[$0] == shortcut }) {
            throw ShortcutBindingError.conflict(action: other)
        }
    }

    public mutating func assign(_ shortcut: Shortcut, to action: String) throws {
        try validate(shortcut, for: action)
        overrides[action] = shortcut == defaults[action] ? nil : shortcut
    }

    public mutating func reset() { overrides.removeAll() }

    public func encoded() throws -> Data { try JSONEncoder().encode(overrides) }
}
