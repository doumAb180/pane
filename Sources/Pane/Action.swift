import Carbon
import PaneCore

enum Action: Int, CaseIterable {
    case left, right, top, bottom, topLeft, topRight, bottomLeft, bottomRight
    case firstThird, middleThird, lastThird, maximize, center, restore, previousScreen, nextScreen

    var shortcutID: String {
        switch self {
        case .left: return "left"
        case .right: return "right"
        case .top: return "top"
        case .bottom: return "bottom"
        case .topLeft: return "topLeft"
        case .topRight: return "topRight"
        case .bottomLeft: return "bottomLeft"
        case .bottomRight: return "bottomRight"
        case .firstThird: return "firstThird"
        case .middleThird: return "middleThird"
        case .lastThird: return "lastThird"
        case .maximize: return "maximize"
        case .center: return "center"
        case .restore: return "restore"
        case .previousScreen: return "previousScreen"
        case .nextScreen: return "nextScreen"
        }
    }

    static func defaultShortcuts(extraCommand: Bool) -> [String: Shortcut] {
        Dictionary(uniqueKeysWithValues: allCases.map {
            ($0.shortcutID, Shortcut(keyCode: $0.key.code,
                                    modifiers: extraCommand ? [.control, .option, .command] : [.control, .option]))
        })
    }

    var titleText: LocalizedText {
        switch self {
        case .left: return .key("Left half")
        case .right: return .key("Right half")
        case .top: return .key("Top half")
        case .bottom: return .key("Bottom half")
        case .topLeft: return .key("Top left")
        case .topRight: return .key("Top right")
        case .bottomLeft: return .key("Bottom left")
        case .bottomRight: return .key("Bottom right")
        case .firstThird: return .key("Left third")
        case .middleThird: return .key("Middle third")
        case .lastThird: return .key("Right third")
        case .maximize: return .key("Maximize")
        case .center: return .key("Center window")
        case .restore: return .key("Restore previous layout")
        case .previousScreen: return .key("Previous display")
        case .nextScreen: return .key("Next display")
        }
    }

    var shortTitleText: LocalizedText {
        switch self {
        case .left: return .key("Left")
        case .right: return .key("Right")
        case .top: return .key("Top")
        case .bottom: return .key("Bottom")
        default: return titleText
        }
    }

    func title(in language: AppLanguage) -> String { titleText.rendered(in: language) }

    var layout: Layout? {
        switch self {
        case .left: return .left
        case .right: return .right
        case .top: return .top
        case .bottom: return .bottom
        case .topLeft: return .topLeft
        case .topRight: return .topRight
        case .bottomLeft: return .bottomLeft
        case .bottomRight: return .bottomRight
        case .firstThird: return .firstThird
        case .middleThird: return .middleThird
        case .lastThird: return .lastThird
        case .maximize: return .maximize
        case .center: return .center
        default: return nil
        }
    }

    var key: (code: UInt32, label: String) {
        switch self {
        case .left: return (UInt32(kVK_LeftArrow), "←")
        case .right: return (UInt32(kVK_RightArrow), "→")
        case .top: return (UInt32(kVK_UpArrow), "↑")
        case .bottom: return (UInt32(kVK_DownArrow), "↓")
        case .topLeft: return (UInt32(kVK_ANSI_U), "U")
        case .topRight: return (UInt32(kVK_ANSI_I), "I")
        case .bottomLeft: return (UInt32(kVK_ANSI_J), "J")
        case .bottomRight: return (UInt32(kVK_ANSI_K), "K")
        case .firstThird: return (UInt32(kVK_ANSI_D), "D")
        case .middleThird: return (UInt32(kVK_ANSI_F), "F")
        case .lastThird: return (UInt32(kVK_ANSI_G), "G")
        case .maximize: return (UInt32(kVK_Return), "↩")
        case .center: return (UInt32(kVK_ANSI_C), "C")
        case .restore: return (UInt32(kVK_Delete), "⌫")
        case .previousScreen: return (UInt32(kVK_ANSI_P), "P")
        case .nextScreen: return (UInt32(kVK_ANSI_N), "N")
        }
    }
}
