import Cocoa
import IOKit.pwr_mgt

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var assertionID: IOPMAssertionID = 0
    private var active = false
    private var preventDisplaySleep = UserDefaults.standard.object(forKey: "preventDisplaySleep") as? Bool ?? true
    private var simulateActivity = UserDefaults.standard.bool(forKey: "simulateActivity")
    private var durationMinutes = UserDefaults.standard.integer(forKey: "durationMinutes") // 0 = forever
    private var jiggleTimer: Timer?
    private var offTimer: Timer?
    private var offDeadline: Date?

    private let toggleItem = NSMenuItem(title: "Keep Awake", action: #selector(toggle), keyEquivalent: "k")
    private let displayItem = NSMenuItem(title: "Also Keep Display On", action: #selector(toggleDisplay), keyEquivalent: "")
    private let jiggleItem = NSMenuItem(title: "Keep Teams Active (jiggle mouse)", action: #selector(toggleJiggle), keyEquivalent: "")
    private let durationRoot = NSMenuItem(title: "Turn Off After", action: nil, keyEquivalent: "")
    private var durationItems: [NSMenuItem] = []

    /// (label, minutes); 0 = never turn off
    private let durations: [(String, Int)] = [
        ("Never", 0), ("30 Minutes", 30), ("1 Hour", 60), ("2 Hours", 120),
        ("4 Hours", 240), ("8 Hours", 480), ("12 Hours", 720),
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
        toggleItem.target = self
        displayItem.target = self
        jiggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(displayItem)
        menu.addItem(jiggleItem)

        let durationMenu = NSMenu()
        for (label, minutes) in durations {
            let item = NSMenuItem(title: label, action: #selector(pickDuration(_:)), keyEquivalent: "")
            item.target = self
            item.tag = minutes
            durationMenu.addItem(item)
            durationItems.append(item)
        }
        durationRoot.submenu = durationMenu
        menu.addItem(durationRoot)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit KeepAwake", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        statusItem.menu = menu

        start() // awake by default on launch
        if simulateActivity { startJiggle() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        stop()
        jiggleTimer?.invalidate()
        offTimer?.invalidate()
    }

    // MARK: - Sleep assertion

    private func start() {
        stopAssertion()
        let type = preventDisplaySleep
            ? kIOPMAssertionTypePreventUserIdleDisplaySleep
            : kIOPMAssertionTypePreventUserIdleSystemSleep
        let ok = IOPMAssertionCreateWithName(
            type as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "KeepAwake: user requested" as CFString,
            &assertionID)
        active = (ok == kIOReturnSuccess)
        scheduleAutoOff()
        refreshUI()
    }

    private func stop() {
        stopAssertion()
        offTimer?.invalidate()
        offTimer = nil
        offDeadline = nil
        refreshUI()
    }

    private func stopAssertion() {
        if active {
            IOPMAssertionRelease(assertionID)
            active = false
        }
    }

    // MARK: - Auto-off timer

    private func scheduleAutoOff() {
        offTimer?.invalidate()
        offTimer = nil
        offDeadline = nil
        guard durationMinutes > 0 else { return }
        let deadline = Date().addingTimeInterval(TimeInterval(durationMinutes * 60))
        offDeadline = deadline
        offTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(durationMinutes * 60), repeats: false) { [weak self] _ in
            guard let self else { return }
            self.stop()
            if self.simulateActivity { self.stopJiggle() } // let Mac actually rest
        }
    }

    @objc private func pickDuration(_ sender: NSMenuItem) {
        durationMinutes = sender.tag
        UserDefaults.standard.set(durationMinutes, forKey: "durationMinutes")
        if active { scheduleAutoOff() } // restart countdown from now
        refreshUI()
    }

    // MARK: - Activity simulation (defeats "Away" in Teams/Slack)

    private func startJiggle() {
        // Posting synthetic input needs Accessibility permission; prompt if missing.
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
        jiggleTimer?.invalidate()
        jiggleTimer = Timer.scheduledTimer(withTimeInterval: 180, repeats: true) { [weak self] _ in
            self?.jiggle()
        }
        jiggle()
    }

    private func stopJiggle() {
        jiggleTimer?.invalidate()
        jiggleTimer = nil
        simulateActivity = false
        UserDefaults.standard.set(false, forKey: "simulateActivity")
        refreshUI()
    }

    private func jiggle() {
        guard AXIsProcessTrusted() else { refreshUI(); return } // silently dropped otherwise
        guard let src = CGEventSource(stateID: .hidSystemState) else { return }
        let loc = CGEvent(source: nil)?.location ?? .zero
        let nudge = CGPoint(x: loc.x + 1, y: loc.y)
        CGEvent(mouseEventSource: src, mouseType: .mouseMoved,
                mouseCursorPosition: nudge, mouseButton: .left)?.post(tap: .cghidEventTap)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            CGEvent(mouseEventSource: src, mouseType: .mouseMoved,
                    mouseCursorPosition: loc, mouseButton: .left)?.post(tap: .cghidEventTap)
        }
    }

    // MARK: - UI

    private func refreshUI() {
        if active, let deadline = offDeadline {
            let fmt = DateFormatter()
            fmt.timeStyle = .short
            toggleItem.title = "Keep Awake (until \(fmt.string(from: deadline)))"
        } else {
            toggleItem.title = "Keep Awake"
        }
        toggleItem.state = active ? .on : .off
        displayItem.state = preventDisplaySleep ? .on : .off
        jiggleItem.state = simulateActivity ? .on : .off
        jiggleItem.title = (simulateActivity && !AXIsProcessTrusted())
            ? "Keep Teams Active — ⚠️ Grant Accessibility!"
            : "Keep Teams Active (jiggle mouse)"
        for item in durationItems {
            item.state = (item.tag == durationMinutes) ? .on : .off
        }
        if let button = statusItem?.button {
            let symbol = active ? "cup.and.saucer.fill" : "cup.and.saucer"
            button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "KeepAwake")
            button.toolTip = active ? "KeepAwake: on" : "KeepAwake: off"
        }
    }

    @objc private func toggle() {
        active ? stop() : start()
    }

    @objc private func toggleDisplay() {
        preventDisplaySleep.toggle()
        UserDefaults.standard.set(preventDisplaySleep, forKey: "preventDisplaySleep")
        if active { start() } // re-create assertion with new type
        refreshUI()
    }

    @objc private func toggleJiggle() {
        if simulateActivity {
            stopJiggle()
        } else {
            simulateActivity = true
            UserDefaults.standard.set(true, forKey: "simulateActivity")
            startJiggle()
        }
        refreshUI()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // menu bar only, no dock icon
let delegate = AppDelegate()
app.delegate = delegate
app.run()
