import Foundation

// Stable language codes are persisted independently of translated display names.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, english = "en", korean = "ko", spanish = "es"
    case chinese = "zh-Hans", japanese = "ja", french = "fr", german = "de"

    var id: String { rawValue }
    var nativeName: String {
        switch self {
        case .system: return "Follow system"
        case .english: return "English"
        case .korean: return "한국어"
        case .spanish: return "Español"
        case .chinese: return "简体中文"
        case .japanese: return "日本語"
        case .french: return "Français"
        case .german: return "Deutsch"
        }
    }

    func resolved(preferredLanguages: [String] = Locale.preferredLanguages) -> AppLanguage {
        guard self == .system else { return self }
        for identifier in preferredLanguages {
            switch identifier.lowercased().split(whereSeparator: { $0 == "-" || $0 == "_" }).first {
            case "en": return .english
            case "ko": return .korean
            case "es": return .spanish
            case "zh": return .chinese
            case "ja": return .japanese
            case "fr": return .french
            case "de": return .german
            default: continue
            }
        }
        return .english
    }

    var column: Int {
        switch resolved() {
        case .korean: return 1
        case .spanish: return 2
        case .chinese: return 3
        case .japanese: return 4
        case .french: return 5
        case .german: return 6
        default: return 0
        }
    }
}

// Keep messages as keys and arguments, so already-visible feedback changes language too.
indirect enum LocalizedText {
    case key(String, [LocalizedText] = [])
    case verbatim(String)

    func rendered(in language: AppLanguage) -> String {
        switch self {
        case .verbatim(let value): return value
        case .key(let key, let arguments):
            let template = Localization.catalog[key]?[language.column] ?? key
            // Substitute in a single pass: user text containing {0} is never reinterpreted.
            let parts = template.components(separatedBy: "{")
            return parts.enumerated().map { offset, part in
                guard offset > 0 else { return part }
                guard let end = part.firstIndex(of: "}"),
                      let index = Int(part[..<end]), arguments.indices.contains(index) else { return "{" + part }
                return arguments[index].rendered(in: language) + part[part.index(after: end)...]
            }.joined()
        }
    }
}

enum Localization {
    // English, Korean, Spanish, Simplified Chinese, Japanese, French, German.
    // Compiled into the executable so CLI tests and packaged apps use the same catalog.
    static let catalog: [String: [String]] = [
        "Follow system": [
            "Follow system",
            "시스템 설정 따르기",
            "Usar idioma del sistema",
            "跟随系统",
            "システム設定に従う",
            "Suivre le système",
            "Systemsprache verwenden"
        ],
        "Language": [
            "Language",
            "언어",
            "Idioma",
            "语言",
            "言語",
            "Langue",
            "Sprache"
        ],
        "Changes apply immediately and stay saved after restarting Pane.": [
            "Changes apply immediately and stay saved after restarting Pane.",
            "변경 즉시 적용되며 Pane을 다시 실행해도 유지됩니다.",
            "Los cambios se aplican al instante y se conservan al reiniciar Pane.",
            "更改立即生效，重启 Pane 后仍会保留。",
            "変更はすぐに反映され、Pane を再起動しても保持されます。",
            "Les changements sont immédiats et conservés après le redémarrage de Pane.",
            "Änderungen gelten sofort und bleiben nach einem Neustart von Pane erhalten."
        ],
        "Left half": [
            "Left half",
            "왼쪽 절반",
            "Mitad izquierda",
            "左半屏",
            "左半分",
            "Moitié gauche",
            "Linke Hälfte"
        ],
        "Right half": [
            "Right half",
            "오른쪽 절반",
            "Mitad derecha",
            "右半屏",
            "右半分",
            "Moitié droite",
            "Rechte Hälfte"
        ],
        "Top half": [
            "Top half",
            "위쪽 절반",
            "Mitad superior",
            "上半屏",
            "上半分",
            "Moitié supérieure",
            "Obere Hälfte"
        ],
        "Bottom half": [
            "Bottom half",
            "아래쪽 절반",
            "Mitad inferior",
            "下半屏",
            "下半分",
            "Moitié inférieure",
            "Untere Hälfte"
        ],
        "Left": [
            "Left",
            "왼쪽",
            "Izquierda",
            "左侧",
            "左",
            "Gauche",
            "Links"
        ],
        "Right": [
            "Right",
            "오른쪽",
            "Derecha",
            "右侧",
            "右",
            "Droite",
            "Rechts"
        ],
        "Top": [
            "Top",
            "위쪽",
            "Arriba",
            "上方",
            "上",
            "Haut",
            "Oben"
        ],
        "Bottom": [
            "Bottom",
            "아래쪽",
            "Abajo",
            "下方",
            "下",
            "Bas",
            "Unten"
        ],
        "Top left": [
            "Top left",
            "왼쪽 위",
            "Arriba izq.",
            "左上角",
            "左上",
            "En haut à g.",
            "Oben links"
        ],
        "Top right": [
            "Top right",
            "오른쪽 위",
            "Arriba der.",
            "右上角",
            "右上",
            "En haut à d.",
            "Oben rechts"
        ],
        "Bottom left": [
            "Bottom left",
            "왼쪽 아래",
            "Abajo izq.",
            "左下角",
            "左下",
            "En bas à g.",
            "Unten links"
        ],
        "Bottom right": [
            "Bottom right",
            "오른쪽 아래",
            "Abajo der.",
            "右下角",
            "右下",
            "En bas à d.",
            "Unten rechts"
        ],
        "Left third": [
            "Left third",
            "왼쪽 ⅓",
            "Izquierda ⅓",
            "左侧 ⅓",
            "左 ⅓",
            "Gauche ⅓",
            "Links ⅓"
        ],
        "Middle third": [
            "Middle third",
            "가운데 ⅓",
            "Centro ⅓",
            "中间 ⅓",
            "中央 ⅓",
            "Centre ⅓",
            "Mitte ⅓"
        ],
        "Right third": [
            "Right third",
            "오른쪽 ⅓",
            "Derecha ⅓",
            "右侧 ⅓",
            "右 ⅓",
            "Droite ⅓",
            "Rechts ⅓"
        ],
        "Maximize": [
            "Maximize",
            "최대화",
            "Maximizar",
            "最大化",
            "最大化",
            "Agrandir",
            "Maximieren"
        ],
        "Center window": [
            "Center window",
            "가운데 정렬",
            "Centrar ventana",
            "窗口居中",
            "ウインドウを中央に配置",
            "Centrer la fenêtre",
            "Fenster zentrieren"
        ],
        "Restore previous layout": [
            "Restore previous layout",
            "이전 배치 복원",
            "Restaurar posición anterior",
            "恢复上次布局",
            "前の配置に戻す",
            "Rétablir la disposition précédente",
            "Vorherige Anordnung wiederherstellen"
        ],
        "Previous display": [
            "Previous display",
            "이전 모니터",
            "Pantalla anterior",
            "上一个显示器",
            "前のディスプレイ",
            "Écran précédent",
            "Vorheriger Bildschirm"
        ],
        "Next display": [
            "Next display",
            "다음 모니터",
            "Pantalla siguiente",
            "下一个显示器",
            "次のディスプレイ",
            "Écran suivant",
            "Nächster Bildschirm"
        ],
        "Restore": [
            "Restore",
            "복원",
            "Restaurar",
            "恢复",
            "復元",
            "Rétablir",
            "Wiederherstellen"
        ],
        "Center": [
            "Center",
            "가운데",
            "Centrar",
            "居中",
            "中央",
            "Centrer",
            "Zentrieren"
        ],
        "Reset all shortcuts to defaults?": [
            "Reset all shortcuts to defaults?",
            "모든 단축키를 기본값으로 되돌릴까요?",
            "¿Restablecer todos los atajos?",
            "要恢复所有默认快捷键吗？",
            "すべてのショートカットを初期設定に戻しますか？",
            "Rétablir tous les raccourcis par défaut ?",
            "Alle Tastenkürzel zurücksetzen?"
        ],
        "Cancel": [
            "Cancel",
            "취소",
            "Cancelar",
            "取消",
            "キャンセル",
            "Annuler",
            "Abbrechen"
        ],
        "Restore defaults": [
            "Restore defaults",
            "기본값 복원",
            "Restablecer",
            "恢复默认设置",
            "初期設定に戻す",
            "Rétablir les valeurs par défaut",
            "Standard wiederherstellen"
        ],
        "Your custom shortcuts will be replaced with the default Control + Option combinations.": [
            "Your custom shortcuts will be replaced with the default Control + Option combinations.",
            "직접 지정한 단축키가 모두 Control + Option 기본 조합으로 바뀝니다.",
            "Tus atajos personalizados se sustituirán por las combinaciones predeterminadas de Control + Option.",
            "自定义快捷键将被替换为默认的 Control + Option 组合。",
            "カスタムショートカットは Control + Option の初期設定に置き換わります。",
            "Vos raccourcis seront remplacés par les combinaisons Control + Option par défaut.",
            "Eigene Tastenkürzel werden durch die Standardkombinationen mit Control + Option ersetzt."
        ],
        "Your workspace, your way": [
            "Your workspace, your way",
            "나에게 맞는 작업 공간",
            "Tu espacio, a tu manera",
            "你的工作空间，由你做主",
            "自分に合ったワークスペース",
            "Votre espace, à votre façon",
            "Dein Arbeitsbereich, wie du ihn magst"
        ],
        "Every window in its place.": [
            "Every window in its place.",
            "모든 창이 제자리에.",
            "Cada ventana en su sitio.",
            "让每个窗口各就各位。",
            "すべてのウインドウを、あるべき場所へ。",
            "Chaque fenêtre à sa place.",
            "Jedes Fenster an seinem Platz."
        ],
        "Layouts": [
            "Layouts",
            "배치 화면",
            "Distribuciones",
            "布局",
            "配置",
            "Dispositions",
            "Anordnungen"
        ],
        "Settings": [
            "Settings",
            "설정",
            "Ajustes",
            "设置",
            "設定",
            "Réglages",
            "Einstellungen"
        ],
        "Selected app": [
            "Selected app",
            "선택한 앱",
            "App seleccionada",
            "所选应用",
            "選択中のアプリ",
            "App sélectionnée",
            "Ausgewählte App"
        ],
        "Split": [
            "Split",
            "나누기",
            "Dividir",
            "分屏",
            "分割",
            "Diviser",
            "Aufteilen"
        ],
        "Repeat a direction to resize": [
            "Repeat a direction to resize",
            "같은 방향을 다시 눌러 크기 전환",
            "Repite la dirección para redimensionar",
            "重复同一方向可切换大小",
            "同じ方向を繰り返してサイズ切替",
            "Répétez la direction pour redimensionner",
            "Richtung wiederholen, um die Größe zu ändern"
        ],
        "Corners": [
            "Corners",
            "모서리",
            "Esquinas",
            "四角",
            "四隅",
            "Coins",
            "Ecken"
        ],
        "More room": [
            "More room",
            "넓게 쓰기",
            "Más espacio",
            "更多空间",
            "広く使う",
            "Plus d’espace",
            "Mehr Platz"
        ],
        "Move to display": [
            "Move to display",
            "모니터 이동",
            "Mover a otra pantalla",
            "移至其他显示器",
            "ディスプレイ間を移動",
            "Déplacer vers un écran",
            "Auf anderen Bildschirm verschieben"
        ],
        "Ready to move windows": [
            "Ready to move windows",
            "창을 움직일 준비",
            "Prepara tus ventanas",
            "准备移动窗口",
            "ウインドウを動かす準備",
            "Prêt à déplacer les fenêtres",
            "Bereit zum Verschieben"
        ],
        "Enable Pane in System Settings → Privacy & Security → Accessibility.": [
            "Enable Pane in System Settings → Privacy & Security → Accessibility.",
            "시스템 설정 → 개인정보 보호 및 보안 → 접근성에서 Pane을 켜 주세요.",
            "Activa Pane en Ajustes del Sistema → Privacidad y seguridad → Accesibilidad.",
            "请在系统设置 → 隐私与安全性 → 辅助功能中启用 Pane。",
            "システム設定 → プライバシーとセキュリティ → アクセシビリティで Pane を有効にしてください。",
            "Activez Pane dans Réglages Système → Confidentialité et sécurité → Accessibilité.",
            "Aktiviere Pane unter Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen."
        ],
        "Open accessibility settings": [
            "Open accessibility settings",
            "접근성 설정 열기",
            "Abrir ajustes de accesibilidad",
            "打开辅助功能设置",
            "アクセシビリティ設定を開く",
            "Ouvrir les réglages d’accessibilité",
            "Bedienungshilfen öffnen"
        ],
        "Window gap": [
            "Window gap",
            "창 사이 여백",
            "Espacio entre ventanas",
            "窗口间距",
            "ウインドウの間隔",
            "Espacement des fenêtres",
            "Fensterabstand"
        ],
        "Gap": [
            "Gap",
            "여백",
            "Espacio",
            "间距",
            "間隔",
            "Espacement",
            "Abstand"
        ],
        "Global shortcuts": [
            "Global shortcuts",
            "전역 단축키",
            "Atajos globales",
            "全局快捷键",
            "グローバルショートカット",
            "Raccourcis globaux",
            "Globale Tastenkürzel"
        ],
        "Could not register shortcuts: {0}": [
            "Could not register shortcuts: {0}",
            "등록하지 못한 단축키: {0}",
            "No se pudieron registrar los atajos: {0}",
            "无法注册快捷键：{0}",
            "登録できなかったショートカット：{0}",
            "Impossible d’enregistrer les raccourcis : {0}",
            "Tastenkürzel konnten nicht registriert werden: {0}"
        ],
        "Accessibility connected": [
            "Accessibility connected",
            "접근성 연결됨",
            "Accesibilidad activada",
            "辅助功能已启用",
            "アクセシビリティ有効",
            "Accessibilité activée",
            "Bedienungshilfen aktiviert"
        ],
        "Accessibility permission needed": [
            "Accessibility permission needed",
            "접근성 권한 필요",
            "Se necesita permiso de accesibilidad",
            "需要辅助功能权限",
            "アクセシビリティの許可が必要",
            "Autorisation d’accessibilité requise",
            "Bedienungshilfen-Zugriff erforderlich"
        ],
        "Open settings": [
            "Open settings",
            "설정 열기",
            "Abrir ajustes",
            "打开设置",
            "設定を開く",
            "Ouvrir les réglages",
            "Einstellungen öffnen"
        ],
        "To launch at login, add Pane in System Settings → General → Login Items.": [
            "To launch at login, add Pane in System Settings → General → Login Items.",
            "로그인할 때 실행하려면 시스템 설정 → 일반 → 로그인 항목에서 Pane을 추가하세요.",
            "Para iniciar al acceder, añade Pane en Ajustes del Sistema → General → Ítems de inicio.",
            "如需登录时启动，请在系统设置 → 通用 → 登录项中添加 Pane。",
            "ログイン時に起動するには、システム設定 → 一般 → ログイン項目に Pane を追加してください。",
            "Pour lancer Pane à la connexion, ajoutez-le dans Réglages Système → Général → Ouverture.",
            "Für den Start bei der Anmeldung füge Pane unter Systemeinstellungen → Allgemein → Anmeldeobjekte hinzu."
        ],
        "View Pane on GitHub ↗": [
            "View Pane on GitHub ↗",
            "GitHub에서 Pane 보기 ↗",
            "Ver Pane en GitHub ↗",
            "在 GitHub 上查看 Pane ↗",
            "GitHub で Pane を見る ↗",
            "Voir Pane sur GitHub ↗",
            "Pane auf GitHub ansehen ↗"
        ],
        "Recording · Window actions paused": [
            "Recording · Window actions paused",
            "단축키 녹음 중 · 창 배치 일시 정지",
            "Grabando · Acciones en pausa",
            "正在录制 · 窗口操作已暂停",
            "記録中 · ウインドウ操作を一時停止",
            "Enregistrement · Actions en pause",
            "Aufnahme · Fensteraktionen pausiert"
        ],
        "Customize shortcuts in settings": [
            "Customize shortcuts in settings",
            "설정에서 나만의 단축키를 지정하세요",
            "Personaliza los atajos en ajustes",
            "在设置中自定义快捷键",
            "設定でショートカットをカスタマイズ",
            "Personnalisez les raccourcis dans les réglages",
            "Tastenkürzel in den Einstellungen anpassen"
        ],
        "Quit": [
            "Quit",
            "종료",
            "Salir",
            "退出",
            "終了",
            "Quitter",
            "Beenden"
        ],
        "Record shortcuts": [
            "Record shortcuts",
            "단축키 녹음",
            "Grabar atajos",
            "录制快捷键",
            "ショートカットを記録",
            "Enregistrer les raccourcis",
            "Tastenkürzel aufnehmen"
        ],
        "Press a combination to change": [
            "Press a combination to change",
            "키 조합을 눌러 변경",
            "Pulsa una combinación para cambiar",
            "按下组合键以更改",
            "キーの組み合わせで変更",
            "Appuyez sur une combinaison",
            "Zum Ändern Tastenkombination drücken"
        ],
        "Click a shortcut, then press a new combination with Control, Option, or Command.": [
            "Click a shortcut, then press a new combination with Control, Option, or Command.",
            "오른쪽 단축키를 클릭한 뒤 새 조합을 누르세요. Control·Option·Command 중 하나 이상을 포함해야 합니다.",
            "Haz clic en un atajo y pulsa una combinación nueva que incluya Control, Option o Command.",
            "点击快捷键，然后按下包含 Control、Option 或 Command 的新组合键。",
            "ショートカットをクリックし、Control・Option・Command のいずれかを含む新しい組み合わせを押してください。",
            "Cliquez sur un raccourci, puis saisissez une combinaison avec Control, Option ou Command.",
            "Klicke auf ein Tastenkürzel und drücke eine neue Kombination mit Control, Option oder Command."
        ],
        "Press keys…": [
            "Press keys…",
            "키를 눌러 주세요…",
            "Pulsa las teclas…",
            "请按下按键…",
            "キーを押してください…",
            "Appuyez sur les touches…",
            "Tasten drücken…"
        ],
        "Change shortcut for {0}": [
            "Change shortcut for {0}",
            "{0} 단축키 변경",
            "Cambiar atajo de {0}",
            "更改“{0}”的快捷键",
            "「{0}」のショートカットを変更",
            "Modifier le raccourci pour {0}",
            "Tastenkürzel für {0} ändern"
        ],
        "Restore all shortcut defaults": [
            "Restore all shortcut defaults",
            "모든 단축키 기본값 복원",
            "Restablecer todos los atajos",
            "恢复所有默认快捷键",
            "すべてのショートカットを初期設定に戻す",
            "Rétablir tous les raccourcis par défaut",
            "Alle Tastenkürzel zurücksetzen"
        ],
        "Combinations already saved in Pane are rejected. Check separately for conflicts with macOS or other apps.": [
            "Combinations already saved in Pane are rejected. Check separately for conflicts with macOS or other apps.",
            "Pane에 저장된 단축키와 중복되면 저장하지 않습니다. macOS나 다른 앱이 사용하는 조합은 직접 확인해 주세요.",
            "No se guardan combinaciones que Pane ya usa. Comprueba por separado los conflictos con macOS u otras apps.",
            "与 Pane 中已有快捷键重复的组合不会保存。请另行检查与 macOS 或其他应用的冲突。",
            "Pane に保存済みの組み合わせは重複登録できません。macOS や他のアプリとの競合は別途ご確認ください。",
            "Les combinaisons déjà utilisées par Pane sont refusées. Vérifiez séparément les conflits avec macOS ou d’autres apps.",
            "Bereits in Pane gespeicherte Kombinationen werden abgelehnt. Prüfe Konflikte mit macOS oder anderen Apps separat."
        ],
        "Shortcut {0}": [
            "Shortcut {0}",
            "단축키 {0}",
            "Atajo {0}",
            "快捷键 {0}",
            "ショートカット {0}",
            "Raccourci {0}",
            "Tastenkürzel {0}"
        ],
        "Select a window": [
            "Select a window",
            "창을 선택해 주세요",
            "Selecciona una ventana",
            "请选择窗口",
            "ウインドウを選択してください",
            "Sélectionnez une fenêtre",
            "Wähle ein Fenster"
        ],
        "Select a window to arrange, then open Pane": [
            "Select a window to arrange, then open Pane",
            "배치할 창을 선택하고 Pane을 열어 주세요",
            "Selecciona una ventana y abre Pane",
            "选择要排列的窗口，然后打开 Pane",
            "配置するウインドウを選んで Pane を開いてください",
            "Sélectionnez une fenêtre à disposer, puis ouvrez Pane",
            "Wähle ein Fenster und öffne dann Pane"
        ],
        "Not set": [
            "Not set",
            "미설정",
            "Sin asignar",
            "未设置",
            "未設定",
            "Non défini",
            "Nicht festgelegt"
        ],
        "Press a new combination · Esc to cancel": [
            "Press a new combination · Esc to cancel",
            "새 조합을 눌러 주세요 · Esc로 취소",
            "Pulsa una nueva combinación · Esc para cancelar",
            "按下新组合键 · Esc 取消",
            "新しい組み合わせを押してください · Esc でキャンセル",
            "Saisissez une combinaison · Échap pour annuler",
            "Neue Kombination drücken · Esc zum Abbrechen"
        ],
        "{0} · {1} saved": [
            "{0} · {1} saved",
            "{0} · {1} 저장됨",
            "{0} · {1} guardado",
            "{0} · {1} 已保存",
            "{0} · {1} を保存しました",
            "{0} · {1} enregistré",
            "{0} · {1} gespeichert"
        ],
        "{0} · Release the key to save": [
            "{0} · Release the key to save",
            "{0} · 키를 놓으면 저장됩니다",
            "{0} · Suelta la tecla para guardar",
            "{0} · 松开按键以保存",
            "{0} · キーを離すと保存します",
            "{0} · Relâchez la touche pour enregistrer",
            "{0} · Zum Speichern Taste loslassen"
        ],
        "Already used by “{0}”. Try another combination.": [
            "Already used by “{0}”. Try another combination.",
            "‘{0}’에서 사용 중이에요. 다른 조합을 눌러 주세요.",
            "«{0}» ya usa este atajo. Prueba otra combinación.",
            "“{0}”已使用此快捷键。请尝试其他组合。",
            "「{0}」で使用中です。別の組み合わせを試してください。",
            "Déjà utilisé par « {0} ». Essayez une autre combinaison.",
            "Wird bereits für „{0}“ verwendet. Probiere eine andere Kombination."
        ],
        "Include Control, Option, or Command with another key.": [
            "Include Control, Option, or Command with another key.",
            "Control, Option, Command 중 하나 이상과 다른 키를 함께 눌러 주세요.",
            "Incluye Control, Option o Command junto con otra tecla.",
            "请将 Control、Option 或 Command 与其他按键组合使用。",
            "Control・Option・Command のいずれかと別のキーを同時に押してください。",
            "Combinez Control, Option ou Command avec une autre touche.",
            "Kombiniere Control, Option oder Command mit einer weiteren Taste."
        ],
        "All shortcuts restored to defaults": [
            "All shortcuts restored to defaults",
            "모든 단축키를 기본값으로 복원했습니다",
            "Se restablecieron todos los atajos",
            "已恢复所有默认快捷键",
            "すべてのショートカットを初期設定に戻しました",
            "Tous les raccourcis ont été rétablis",
            "Alle Tastenkürzel wurden zurückgesetzt"
        ],
        "Choose a layout": [
            "Choose a layout",
            "원하는 배치를 골라 주세요",
            "Elige una distribución",
            "请选择布局",
            "配置を選んでください",
            "Choisissez une disposition",
            "Wähle eine Anordnung"
        ],
        "Accessibility permission is needed to get started": [
            "Accessibility permission is needed to get started",
            "처음 한 번, 접근성 권한이 필요해요",
            "Para empezar, se necesita permiso de accesibilidad",
            "首次使用需要辅助功能权限",
            "最初にアクセシビリティの許可が必要です",
            "Une autorisation d’accessibilité est nécessaire pour commencer",
            "Zum Start ist der Zugriff auf Bedienungshilfen erforderlich"
        ],
        "Ready. Select a window and reopen Pane": [
            "Ready. Select a window and reopen Pane",
            "준비됐어요. 배치할 창에서 Pane을 다시 열어 주세요",
            "Listo. Selecciona una ventana y vuelve a abrir Pane",
            "已就绪。请选择窗口并重新打开 Pane",
            "準備完了。ウインドウを選んで Pane を開き直してください",
            "Prêt. Sélectionnez une fenêtre et rouvrez Pane",
            "Bereit. Wähle ein Fenster und öffne Pane erneut"
        ],
        "Enable accessibility permission to arrange windows.": [
            "Enable accessibility permission to arrange windows.",
            "접근성 권한을 켜면 창을 배치할 수 있어요.",
            "Activa el permiso de accesibilidad para organizar ventanas.",
            "启用辅助功能权限后即可排列窗口。",
            "アクセシビリティを許可するとウインドウを配置できます。",
            "Autorisez l’accessibilité pour disposer les fenêtres.",
            "Aktiviere den Zugriff auf Bedienungshilfen, um Fenster anzuordnen."
        ],
        "Select an app window first.": [
            "Select an app window first.",
            "배치할 앱의 창을 먼저 선택해 주세요.",
            "Selecciona primero la ventana de una app.",
            "请先选择应用窗口。",
            "先にアプリのウインドウを選択してください。",
            "Sélectionnez d’abord une fenêtre d’app.",
            "Wähle zuerst ein App-Fenster."
        ],
        "The selected app has no window to arrange.": [
            "The selected app has no window to arrange.",
            "선택한 앱에 배치할 수 있는 창이 없어요.",
            "La app seleccionada no tiene ventanas que organizar.",
            "所选应用没有可排列的窗口。",
            "選択したアプリには配置できるウインドウがありません。",
            "L’app sélectionnée n’a aucune fenêtre à disposer.",
            "Die ausgewählte App hat kein Fenster zum Anordnen."
        ],
        "App": [
            "App",
            "앱",
            "App",
            "应用",
            "アプリ",
            "App",
            "App"
        ],
        "Check accessibility permission.": [
            "Check accessibility permission.",
            "접근성 권한을 확인해 주세요.",
            "Comprueba el permiso de accesibilidad.",
            "请检查辅助功能权限。",
            "アクセシビリティの許可を確認してください。",
            "Vérifiez l’autorisation d’accessibilité.",
            "Prüfe den Zugriff auf Bedienungshilfen."
        ],
        "Exit full-screen mode and try again.": [
            "Exit full-screen mode and try again.",
            "전체 화면 모드를 해제한 뒤 다시 시도해 주세요.",
            "Sal del modo de pantalla completa e inténtalo de nuevo.",
            "请退出全屏模式后重试。",
            "フルスクリーンを解除して、もう一度お試しください。",
            "Quittez le mode plein écran et réessayez.",
            "Beende den Vollbildmodus und versuche es erneut."
        ],
        "No display found.": [
            "No display found.",
            "화면을 찾을 수 없어요.",
            "No se encontró ninguna pantalla.",
            "未找到显示器。",
            "ディスプレイが見つかりません。",
            "Aucun écran trouvé.",
            "Kein Bildschirm gefunden."
        ],
        "No previous layout to restore for this window.": [
            "No previous layout to restore for this window.",
            "이 창에는 복원할 배치가 아직 없어요.",
            "Esta ventana aún no tiene una posición anterior que restaurar.",
            "此窗口尚无可恢复的布局。",
            "このウインドウには復元できる前の配置がありません。",
            "Aucune disposition précédente à rétablir pour cette fenêtre.",
            "Für dieses Fenster gibt es keine vorherige Anordnung."
        ],
        "Only one display is connected.": [
            "Only one display is connected.",
            "연결된 모니터가 하나뿐이에요.",
            "Solo hay una pantalla conectada.",
            "仅连接了一个显示器。",
            "接続されているディスプレイは1台だけです。",
            "Un seul écran est connecté.",
            "Es ist nur ein Bildschirm angeschlossen."
        ],
        "Already in the selected position": [
            "Already in the selected position",
            "이미 선택한 위치에 있어요",
            "Ya está en la posición seleccionada",
            "已处于所选位置",
            "すでに選択した位置にあります",
            "Déjà à la position sélectionnée",
            "Bereits an der gewählten Position"
        ],
        "Arranged · This app limits its window size": [
            "Arranged · This app limits its window size",
            "배치했어요 · 앱의 창 크기 제한이 적용됐어요",
            "Colocada · La app limita el tamaño de su ventana",
            "已排列 · 此应用限制了窗口大小",
            "配置しました · アプリのウインドウサイズ制限が適用されました",
            "Disposition appliquée · Cette app limite la taille de sa fenêtre",
            "Angeordnet · Die App begrenzt ihre Fenstergröße"
        ],
        "{0} {1} applied": [
            "{0} {1} applied",
            "{0} {1} 배치 완료",
            "{0} {1} aplicado",
            "已应用{0} {1} 布局",
            "{0} {1} に配置しました",
            "{0} {1} appliqué",
            "{0} {1} angewendet"
        ],
        "{0} complete": [
            "{0} complete",
            "{0} 완료",
            "{0} completado",
            "{0}已完成",
            "{0}が完了しました",
            "{0} terminé",
            "{0} abgeschlossen"
        ],
        "Could not read window information. Select the window again.": [
            "Could not read window information. Select the window again.",
            "창 정보를 읽지 못했어요. 창을 다시 선택해 주세요.",
            "No se pudo leer la información de la ventana. Vuelve a seleccionarla.",
            "无法读取窗口信息。请重新选择窗口。",
            "ウインドウ情報を読み取れません。ウインドウを選び直してください。",
            "Impossible de lire les informations de la fenêtre. Sélectionnez-la à nouveau.",
            "Fensterinformationen konnten nicht gelesen werden. Wähle das Fenster erneut."
        ],
        "Could not read the window position.": [
            "Could not read the window position.",
            "창 위치를 읽을 수 없어요.",
            "No se pudo leer la posición de la ventana.",
            "无法读取窗口位置。",
            "ウインドウの位置を読み取れません。",
            "Impossible de lire la position de la fenêtre.",
            "Fensterposition konnte nicht gelesen werden."
        ],
        "This window does not support moving or resizing.": [
            "This window does not support moving or resizing.",
            "이 창은 이동 또는 크기 변경을 지원하지 않아요.",
            "Esta ventana no permite moverse ni cambiar de tamaño.",
            "此窗口不支持移动或调整大小。",
            "このウインドウは移動またはサイズ変更に対応していません。",
            "Cette fenêtre ne peut pas être déplacée ou redimensionnée.",
            "Dieses Fenster kann nicht verschoben oder in der Größe geändert werden."
        ],
        "Could not register keyboard events.": [
            "Could not register keyboard events.",
            "단축키 이벤트를 등록할 수 없습니다.",
            "No se pudieron registrar los eventos de teclado.",
            "无法注册键盘事件。",
            "キーボードイベントを登録できません。",
            "Impossible d’enregistrer les événements du clavier.",
            "Tastaturereignisse konnten nicht registriert werden."
        ],
        "Pane window layouts": [
            "Pane window layouts",
            "Pane 창 배치",
            "Distribuciones de Pane",
            "Pane 窗口布局",
            "Pane ウインドウ配置",
            "Dispositions de fenêtres Pane",
            "Pane Fensteranordnung"
        ],
        "Pane · Every window in its place": [
            "Pane · Every window in its place",
            "Pane · 창을 제자리에",
            "Pane · Cada ventana en su sitio",
            "Pane · 让窗口各就各位",
            "Pane · ウインドウをあるべき場所へ",
            "Pane · Chaque fenêtre à sa place",
            "Pane · Jedes Fenster an seinem Platz"
        ],
    ]
}
