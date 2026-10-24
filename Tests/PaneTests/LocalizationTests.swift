import AppKit
import XCTest
import PaneCore
@testable import Pane

final class LocalizationTests: XCTestCase {
    func testSystemLanguageResolutionAndFallback() {
        XCTAssertEqual(AppLanguage.system.resolved(preferredLanguages: ["pt-BR", "es-MX"]), .spanish)
        XCTAssertEqual(AppLanguage.system.resolved(preferredLanguages: ["zh-Hant-TW"]), .chinese)
        XCTAssertEqual(AppLanguage.system.resolved(preferredLanguages: ["ko_KR"]), .korean)
        XCTAssertEqual(AppLanguage.system.resolved(preferredLanguages: ["it-IT"]), .english)
        XCTAssertEqual(AppLanguage.system.resolved(preferredLanguages: []), .english)
        XCTAssertEqual(AppLanguage.german.resolved(preferredLanguages: ["ja-JP"]), .german)
    }

    func testCatalogHasEveryLanguageAndMatchingPlaceholders() {
        let pattern = try! NSRegularExpression(pattern: #"\{\d+\}"#)
        func tokens(_ text: String) -> [String] {
            pattern.matches(in: text, range: NSRange(text.startIndex..., in: text)).map {
                String(text[Range($0.range, in: text)!])
            }.sorted()
        }
        for (key, translations) in Localization.catalog {
            XCTAssertEqual(translations.count, 7, key)
            XCTAssertEqual(translations.first, key)
            for translation in translations {
                XCTAssertFalse(translation.isEmpty, key)
                XCTAssertEqual(tokens(translation), tokens(key), key)
            }
        }
        for action in Action.allCases {
            for language in AppLanguage.allCases {
                XCTAssertFalse(action.title(in: language).isEmpty)
            }
        }
    }

    func testLanguageAndCustomBindingsSurviveReloadAndRemainIndependent() throws {
        let suite = "PaneLocalizationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(false, forKey: "shortcutsEnabled")
        // An existing 0.2.0 installation has custom shortcuts but no language preference.
        var bindings = ShortcutBindings(defaults: Action.defaultShortcuts(extraCommand: false))
        try bindings.assign(Shortcut(keyCode: 0, modifiers: [.command, .shift]), to: "left")
        defaults.set(try bindings.encoded(), forKey: "shortcutBindings.v1")
        defaults.set(12, forKey: "gap")
        let model = AppModel(defaults: defaults)
        XCTAssertEqual(model.language, .system)
        for language in AppLanguage.allCases {
            model.language = language
            let reloaded = AppModel(defaults: UserDefaults(suiteName: suite)!)
            XCTAssertEqual(reloaded.language, language)
            XCTAssertEqual(reloaded.bindings["left"], bindings["left"])
            XCTAssertEqual(reloaded.gap, 12)
            XCTAssertFalse(reloaded.shortcutsEnabled)
        }
        model.language = .french
        model.resetShortcuts()
        let reloaded = AppModel(defaults: UserDefaults(suiteName: suite)!)
        XCTAssertEqual(reloaded.language, .french)
        XCTAssertEqual(reloaded.shortcutLabel(for: .left), "⌃⌥←")
        defaults.set("unknown-language", forKey: "appLanguage.v1")
        XCTAssertEqual(AppModel(defaults: defaults).language, .system)
    }

    func testVisibleFeedbackAndDuplicateWarningChangeLanguageImmediately() {
        let suite = "PaneLocalizationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(false, forKey: "shortcutsEnabled")
        let model = AppModel(defaults: defaults)
        model.language = .english
        XCTAssertEqual(model.targetName, "Select a window")
        model.startRecording(.left)
        let event = NSEvent.keyEvent(with: .keyDown, location: .zero,
                                    modifierFlags: [.control, .option], timestamp: 0,
                                    windowNumber: 0, context: nil, characters: "",
                                    charactersIgnoringModifiers: "", isARepeat: false, keyCode: 124)!
        _ = model.handleRecordingEvent(event)
        XCTAssertTrue(model.recordingMessage.contains("Right half"))
        model.language = .japanese
        XCTAssertEqual(model.targetName, "ウインドウを選択してください")
        XCTAssertTrue(model.recordingMessage.contains("右半分"))
        XCTAssertFalse(model.recordingMessage.contains("Right half"))
        XCTAssertEqual(model.recordingAction, .left)
        XCTAssertTrue(model.recordingError)
        model.cancelRecording()
        model.resetShortcuts()
        model.language = .korean
        XCTAssertEqual(model.recordingMessage, "모든 단축키를 기본값으로 복원했습니다")
        XCTAssertEqual(model.message, "배치할 창을 선택하고 Pane을 열어 주세요")
    }

    func testWindowFeedbackUsesLocalizedActionAndPreservesLiteralArguments() {
        let result = LocalizedText.key("{0} {1} applied", [Action.left.shortTitleText, .verbatim("¼")])
        XCTAssertEqual(result.rendered(in: .english), "Left ¼ applied")
        XCTAssertEqual(result.rendered(in: .korean), "왼쪽 ¼ 배치 완료")
        XCTAssertEqual(WindowFailure.message("No display found.").text.rendered(in: .german),
                       "Kein Bildschirm gefunden.")
        let literal = LocalizedText.key("{0} · {1} saved", [.verbatim("{1}"), .verbatim("⌘A")])
        XCTAssertEqual(literal.rendered(in: .english), "{1} · ⌘A saved")
    }
}
