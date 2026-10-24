import XCTest
@testable import PaneCore

final class ShortcutTests: XCTestCase {
    private let left = Shortcut(keyCode: 123, modifiers: [.control, .option])
    private let right = Shortcut(keyCode: 124, modifiers: [.control, .option])
    private let custom = Shortcut(keyCode: 0, modifiers: [.command, .shift])
    private var defaults: [String: Shortcut] { ["left": left, "right": right] }

    func testConflictDoesNotChangeEitherBinding() throws {
        var bindings = ShortcutBindings(defaults: defaults)
        XCTAssertThrowsError(try bindings.assign(right, to: "left")) {
            XCTAssertEqual($0 as? ShortcutBindingError, .conflict(action: "right"))
        }
        XCTAssertEqual(bindings["left"], left)
        XCTAssertEqual(bindings["right"], right)
        try bindings.assign(custom, to: "right")
        XCTAssertThrowsError(try bindings.assign(custom, to: "left"))
        XCTAssertEqual(bindings["left"], left)
    }

    func testSelfAssignmentAndModifierDifferencesAreAllowed() throws {
        var bindings = ShortcutBindings(defaults: defaults)
        try bindings.assign(left, to: "left")
        XCTAssertTrue(bindings.overrides.isEmpty)
        let differentModifiers = Shortcut(keyCode: 124, modifiers: [.command, .shift])
        try bindings.assign(differentModifiers, to: "left")
        XCTAssertEqual(bindings["left"], differentModifiers)
    }

    func testReassignmentFreesPreviousCombinationAndSurvivesReload() throws {
        var bindings = ShortcutBindings(defaults: defaults)
        try bindings.assign(custom, to: "left")
        try bindings.assign(left, to: "right")
        try bindings.assign(right, to: "left")
        let loaded = ShortcutBindings(defaults: defaults, savedData: try bindings.encoded())
        XCTAssertEqual(loaded["left"], right)
        XCTAssertEqual(loaded["right"], left)
    }

    func testResetRestoresAllBindingsAndPersists() throws {
        var bindings = ShortcutBindings(defaults: defaults)
        try bindings.assign(custom, to: "left")
        bindings.reset()
        let loaded = ShortcutBindings(defaults: defaults, savedData: try bindings.encoded())
        XCTAssertEqual(loaded["left"], left)
        XCTAssertEqual(loaded["right"], right)
        XCTAssertTrue(loaded.overrides.isEmpty)
    }

    func testInvalidInputsAndUnknownActionsDoNotMutateBindings() {
        var bindings = ShortcutBindings(defaults: defaults)
        let invalid = [
            Shortcut(keyCode: 0, modifiers: []), Shortcut(keyCode: 0, modifiers: [.shift]),
            Shortcut(keyCode: 55, modifiers: [.command]), Shortcut(keyCode: 200, modifiers: [.control]),
            Shortcut(keyCode: 0, modifiers: [.control, ShortcutModifiers(rawValue: 128)])
        ]
        for shortcut in invalid {
            XCTAssertThrowsError(try bindings.assign(shortcut, to: "left")) {
                XCTAssertEqual($0 as? ShortcutBindingError, .invalidShortcut)
            }
        }
        XCTAssertThrowsError(try bindings.assign(custom, to: "missing"))
        XCTAssertTrue(bindings.overrides.isEmpty)
    }

    func testCorruptOrConflictingSavedDataFallsBackToDefaults() throws {
        let snapshots = [Data("broken".utf8), try JSONEncoder().encode(["left": right]),
                         try JSONEncoder().encode(["left": Shortcut(keyCode: 0, modifiers: [])])]
        for data in snapshots {
            let loaded = ShortcutBindings(defaults: defaults, savedData: data)
            XCTAssertEqual(loaded["left"], left)
            XCTAssertEqual(loaded["right"], right)
        }
        let data = try JSONEncoder().encode(["removed-action": right, "left": custom])
        let loaded = ShortcutBindings(defaults: defaults, savedData: data)
        XCTAssertEqual(loaded["left"], custom)
        XCTAssertNil(loaded["removed-action"])
    }
}
