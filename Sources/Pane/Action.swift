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

    var title: String {
        switch self {
        case .left: return "왼쪽 절반"
        case .right: return "오른쪽 절반"
        case .top: return "위쪽 절반"
        case .bottom: return "아래쪽 절반"
        case .topLeft: return "왼쪽 위"
        case .topRight: return "오른쪽 위"
        case .bottomLeft: return "왼쪽 아래"
        case .bottomRight: return "오른쪽 아래"
        case .firstThird: return "왼쪽 ⅓"
        case .middleThird: return "가운데 ⅓"
        case .lastThird: return "오른쪽 ⅓"
        case .maximize: return "최대화"
        case .center: return "가운데 정렬"
        case .restore: return "이전 배치 복원"
        case .previousScreen: return "이전 모니터"
        case .nextScreen: return "다음 모니터"
        }
    }

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
