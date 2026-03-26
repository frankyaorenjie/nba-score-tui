import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let store = ScoreboardStore()
    private let preferences = AppPreferences()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    private var statusLabelHostingView: NSHostingView<StatusItemHostView>?
    private var detailStore = GameDetailStore()
    private var detailWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        LegacyProcessManager.terminateOlderInstances()
        NSApp.setActivationPolicy(.accessory)
        configurePopover()
        configureStatusItem()
        bindStore()
        store.start()

        if !preferences.startAndHide {
            DispatchQueue.main.async { [weak self] in
                self?.showPopover()
            }
        }
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 368, height: 540)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarContentView(
                store: store,
                onSelectGame: { [weak self] game in
                    self?.openDetailWindow(for: game)
                }
            )
                .frame(width: 368, height: 540)
        )
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.isVisible = true

        guard let button = item.button else {
            statusItem = item
            return
        }

        button.title = ""
        button.image = nil
        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        let hostingView = NSHostingView(
            rootView: StatusItemHostView(label: store.menuBarLabel)
        )
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 4),
            hostingView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -4),
            hostingView.topAnchor.constraint(equalTo: button.topAnchor, constant: 0),
            hostingView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 0)
        ])

        statusItem = item
        statusLabelHostingView = hostingView
        updateStatusItemLabel()
    }

    private func bindStore() {
        store.$menuBarLabel
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItemLabel()
            }
            .store(in: &cancellables)

        preferences.$startAndHide
            .dropFirst()
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] shouldHide in
                guard let self else {
                    return
                }

                if shouldHide {
                    popover.performClose(nil)
                } else if !popover.isShown {
                    showPopover()
                }
            }
            .store(in: &cancellables)
    }

    private func updateStatusItemLabel() {
        guard let statusItem, let button = statusItem.button, let statusLabelHostingView else {
            return
        }

        let label = store.menuBarLabel
        statusLabelHostingView.rootView = StatusItemHostView(label: label)
        statusLabelHostingView.layoutSubtreeIfNeeded()
        statusItem.length = max(40, statusLabelHostingView.fittingSize.width + 8)
        button.toolTip = GameFormatting.accessibilityMenuBarTitle(for: label)
    }

    @objc
    private func handleStatusItemClick(_ sender: AnyObject?) {
        let currentEvent = NSApp.currentEvent
        let isRightClick = currentEvent?.type == .rightMouseUp ||
            ((currentEvent?.type == .leftMouseUp) && (currentEvent?.modifierFlags.contains(.control) == true))

        if isRightClick {
            showContextMenu(currentEvent)
        } else {
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button else {
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.becomeKey()
        }
    }

    private func showPopover() {
        togglePopover(nil)
    }

    private func showContextMenu(_ event: NSEvent?) {
        guard let button = statusItem?.button else {
            return
        }

        popover.performClose(nil)

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettingsWindow), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "About", action: #selector(openAboutPanel), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }

        let menuEvent = event ?? NSEvent.mouseEvent(
            with: .rightMouseUp,
            location: NSPoint(x: button.bounds.midX, y: button.bounds.midY),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: button.window?.windowNumber ?? 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1
        )

        if let menuEvent {
            NSMenu.popUpContextMenu(menu, with: menuEvent, for: button)
        }
    }

    @objc
    private func openSettingsWindow() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 240),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "NBA Score Menubar Settings"
            window.isReleasedWhenClosed = false
            window.center()
            window.contentViewController = NSHostingController(
                rootView: SettingsView(preferences: preferences)
                    .frame(width: 420, height: 240)
            )
            settingsWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    private func openDetailWindow(for game: Game) {
        if detailWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1200, height: 760),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "NBA Game Detail"
            window.isReleasedWhenClosed = false
            window.center()
            window.delegate = self
            window.contentViewController = NSHostingController(
                rootView: GameDetailView(store: detailStore)
                    .frame(minWidth: 1200, minHeight: 760)
            )
            detailWindow = window
        }

        detailStore.show(game: game)
        detailWindow?.title = GameFormatting.primaryLine(for: game)
        popover.performClose(nil)
        NSApp.activate(ignoringOtherApps: true)
        detailWindow?.makeKeyAndOrderFront(nil)
    }

    @objc
    private func openAboutPanel() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel([
            NSApplication.AboutPanelOptionKey.applicationName: "NBA Score Menubar"
        ])
    }

    @objc
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard let closedWindow = notification.object as? NSWindow else {
            return
        }

        if closedWindow == detailWindow {
            detailStore.stopRefreshing()
        }
    }
}

private struct StatusItemHostView: View {
    let label: MenuBarLabelContent

    var body: some View {
        StatusItemLabelView(label: label)
            .allowsHitTesting(false)
    }
}

private struct StatusItemLabelView: View {
    let label: MenuBarLabelContent

    var body: some View {
        VStack(spacing: -2) {
            Text(label.topLine)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .multilineTextAlignment(.center)

            Text(label.bottomLine)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .fixedSize(horizontal: true, vertical: true)
        .foregroundStyle(.primary)
        .padding(.horizontal, 1)
    }
}
