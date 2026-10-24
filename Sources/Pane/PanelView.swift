import SwiftUI
import Combine
import PaneCore

private let accent = Color(red: 0.34, green: 0.40, blue: 0.94)

struct PanelView: View {
    @ObservedObject var model: AppModel
    @State private var settings = false
    private let permissionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            ScrollView {
                if settings { preferences } else { layouts }
            }
            footer
        }
        .padding(24)
        .frame(width: 420, height: settings ? 570 : 690)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.96))
        .tint(accent)
        .onReceive(permissionTimer) { _ in model.refreshPermission() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 13).fill(accent.gradient)
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 2).fill(.white)
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.5))
                        RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.75))
                    }
                }.padding(11)
            }.frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text("Pane").font(.system(size: 24, weight: .bold, design: .rounded))
                Text(settings ? "나에게 맞는 작업 공간" : "모든 창이 제자리에.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Button { withAnimation(.easeInOut(duration: 0.15)) { settings.toggle() } } label: {
                Image(systemName: settings ? "arrow.left" : "slider.horizontal.3")
                    .font(.system(size: 15, weight: .medium)).frame(width: 32, height: 32)
                    .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
            }.buttonStyle(.plain).help(settings ? "배치 화면" : "설정")
                .accessibilityLabel(settings ? "배치 화면" : "설정")
        }
    }

    private var layouts: some View {
        VStack(alignment: .leading, spacing: 18) {
            if !model.trusted { permissionCard }
            HStack(spacing: 8) {
                if let icon = model.targetIcon {
                    Image(nsImage: icon).resizable().frame(width: 20, height: 20)
                } else { Image(systemName: "macwindow").foregroundStyle(.secondary) }
                Text(model.targetName).font(.system(size: 12, weight: .medium)).lineLimit(1)
                Spacer()
                Text("선택한 앱").font(.system(size: 10)).foregroundStyle(.tertiary)
            }.padding(11).background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 9) {
                sectionLabel("나누기", detail: "같은 방향을 다시 눌러 크기 전환")
                tileRow([.left, .right, .top, .bottom])
            }
            VStack(alignment: .leading, spacing: 9) {
                sectionLabel("모서리")
                tileRow([.topLeft, .topRight, .bottomLeft, .bottomRight])
            }
            VStack(alignment: .leading, spacing: 9) {
                sectionLabel("넓게 쓰기")
                tileRow([.firstThird, .middleThird, .lastThird, .maximize])
            }
            HStack(spacing: 8) {
                utility(.center, icon: "viewfinder")
                utility(.restore, icon: "arrow.uturn.backward")
            }
            HStack {
                Label("모니터 이동", systemImage: "display.2")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                monitorButton(.previousScreen, icon: "arrow.left")
                monitorButton(.nextScreen, icon: "arrow.right")
            }
        }
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("창을 움직일 준비", systemImage: "hand.raised.fill")
                .font(.system(size: 13, weight: .semibold))
            Text("시스템 설정 → 개인정보 보호 및 보안 → 접근성에서 Pane을 켜 주세요.")
                .font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Button("접근성 설정 열기") { model.requestPermission() }
                .buttonStyle(.borderedProminent).controlSize(.small)
        }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 13))
    }

    private var preferences: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("창 사이 여백", detail: "\(model.gap) pt")
                Picker("여백", selection: $model.gap) {
                    ForEach([0, 4, 8, 12, 16], id: \.self) { Text("\($0)").tag($0) }
                }.pickerStyle(.segmented).labelsHidden()
            }
            Divider()
            Toggle("전역 단축키", isOn: $model.shortcutsEnabled).toggleStyle(.switch)
            Toggle("단축키에 Command 추가", isOn: $model.extraCommand).toggleStyle(.switch)
            Text("현재 조합  \(model.modifierLabel) + 키\n다른 창 관리 앱과 충돌하면 Command를 추가하거나 해당 앱의 단축키를 꺼 주세요.")
                .font(.system(size: 12)).foregroundStyle(.secondary).lineSpacing(4)
            if !model.shortcutFailures.isEmpty {
                Label("등록하지 못한 단축키: \(model.shortcutFailures.joined(separator: ", "))", systemImage: "exclamationmark.triangle")
                    .font(.system(size: 11)).foregroundStyle(.orange)
            }
            Divider()
            HStack {
                Label(model.trusted ? "접근성 연결됨" : "접근성 권한 필요", systemImage: model.trusted ? "checkmark.shield" : "lock")
                Spacer()
                Button("설정 열기") { model.requestPermission() }.buttonStyle(.borderless)
            }.font(.system(size: 12))
            Text("로그인할 때 실행하려면 시스템 설정 → 일반 → 로그인 항목에서 Pane을 추가하세요.")
                .font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Link("GitHub에서 Pane 보기 ↗", destination: URL(string: "https://github.com/doumAb180/pane")!)
                .font(.system(size: 12))
        }.padding(.vertical, 8)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Divider()
            HStack(alignment: .top, spacing: 7) {
                Image(systemName: model.isError ? "exclamationmark.circle.fill" : "circle.fill")
                    .font(.system(size: model.isError ? 11 : 6))
                    .foregroundStyle(model.isError ? Color.orange : accent).padding(.top, 3)
                Text(model.message).font(.system(size: 11)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }.frame(minHeight: 28, alignment: .topLeading).accessibilityElement(children: .combine)
            HStack {
                Text("\(model.modifierLabel) + 키로 더 빠르게")
                Spacer()
                Button("종료") { NSApp.terminate(nil) }.buttonStyle(.plain)
            }.font(.system(size: 10)).foregroundStyle(.tertiary)
        }
    }

    private func sectionLabel(_ text: String, detail: String = "") -> some View {
        HStack {
            Text(text).font(.system(size: 11, weight: .semibold))
            Spacer()
            Text(detail).font(.system(size: 9)).foregroundStyle(.tertiary)
        }.foregroundStyle(.secondary)
    }

    private func tileRow(_ actions: [Action]) -> some View {
        HStack(spacing: 8) {
            ForEach(actions, id: \.rawValue) { action in
                LayoutTile(action: action, shortcut: model.modifierLabel + action.key.label) { model.perform(action) }
            }
        }
    }

    private func utility(_ action: Action, icon: String) -> some View {
        Button { model.perform(action) } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(accent)
                Text(action == .restore ? "복원" : "가운데")
                Spacer(minLength: 2)
                Text(action.key.label).foregroundStyle(.tertiary)
            }.font(.system(size: 11)).padding(12)
                .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
        }.buttonStyle(.plain).help(action.title + " · " + model.modifierLabel + action.key.label)
    }

    private func monitorButton(_ action: Action, icon: String) -> some View {
        Button { model.perform(action) } label: {
            Image(systemName: icon).font(.system(size: 12)).frame(width: 32, height: 26)
                .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
        }.buttonStyle(.plain).help(action.title + " · " + model.modifierLabel + action.key.label)
            .accessibilityLabel(action.title)
    }
}

private struct LayoutTile: View {
    let action: Action
    let shortcut: String
    let perform: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: perform) {
            VStack(spacing: 8) {
                LayoutGlyph(layout: action.layout ?? .maximize).frame(width: 44, height: 29)
                Text(action.title.replacingOccurrences(of: " 절반", with: ""))
                    .font(.system(size: 10, weight: .medium)).lineLimit(1)
            }.frame(maxWidth: .infinity).padding(.vertical, 13)
                .background(hover ? accent.opacity(0.12) : Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(hover ? accent.opacity(0.35) : .primary.opacity(0.065)))
                .contentShape(RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain).onHover { hover = $0 }.help(action.title + " · " + shortcut)
            .accessibilityLabel(action.title).accessibilityHint("단축키 " + shortcut)
    }
}

private struct LayoutGlyph: View {
    let layout: PaneCore.Layout
    var body: some View {
        GeometryReader { proxy in
            let bounds = CGRect(origin: .zero, size: proxy.size)
            let rect = layout.frame(in: bounds.insetBy(dx: 3, dy: 3), current: bounds, gap: 1)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 4).strokeBorder(.primary.opacity(0.18), lineWidth: 1.2)
                RoundedRectangle(cornerRadius: 2).fill(accent.opacity(0.8))
                    .frame(width: rect.width, height: rect.height).offset(x: rect.minX, y: rect.minY)
            }
        }.accessibilityHidden(true)
    }
}
