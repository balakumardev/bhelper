import Cocoa
import UserNotifications
import OpenAISwift
import WebKit
import SwiftAnthropic

class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()
    private var statusItem: NSStatusItem?
    private var selectedAPIClient: LLMAPIClient = LlamaAPIClient(prePrompt: "")
    private let notificationCenter = UNUserNotificationCenter.current()
    private var settingsWindowController: NSWindowController?
    private var isTransformationInProgress = false
    private var originalFocusedApplication: NSRunningApplication?
    private let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 700, height: 450))

    private lazy var llamaMenuItem: NSMenuItem = {
        return createMenuItem(title: "Local Ollama", action: #selector(selectLlamaAPI))
    }()
    private lazy var gpt4TurboMenuItem: NSMenuItem = {
        return createMenuItem(title: "OpenAI", action: #selector(selectGPT4TurboAPI))
    }()
    private lazy var geminiMenuItem: NSMenuItem = {
        return createMenuItem(title: "Google Gemini", action: #selector(selectGeminiAPI))
    }()
    private lazy var claudeMenuItem: NSMenuItem = {
        return createMenuItem(title: "Anthropic Claude", action: #selector(selectClaudeAPI))
    }()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        DispatchQueue.main.async {
            self.notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
                if granted {
                    print("Notification authorization granted.")
                } else if let error = error {
                    print("Error requesting notifications authorization: \(error.localizedDescription)")
                }
            }
        }
        NSApplication.shared.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let size = NSSize(width: 14.4, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 15),
            .foregroundColor: NSColor.lightGray,
            .paragraphStyle: paragraphStyle
        ]

        NSAttributedString(string: "B", attributes: attrs).draw(in: CGRect(x: 0, y: 1, width: size.width, height: size.height))
        image.unlockFocus()
        statusItem?.button?.image = image
        statusItem?.button?.image?.accessibilityDescription = "Main Menu with letter B"
        statusItem?.button?.action = #selector(showMenu)
        HotKeyManager.shared.setUpGlobalHotKey()

        NotificationCenter.default.addObserver(forName: Notification.Name("TriggerTextTransformation"), object: nil, queue: nil) { [weak self] _ in
            self?.originalFocusedApplication = NSWorkspace.shared.frontmostApplication
            self?.isTransformationInProgress = true
            self?.transformSelectedText()

            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                if self?.isTransformationInProgress == true &&
                    self?.originalFocusedApplication == NSWorkspace.shared.frontmostApplication {
                    self?.isTransformationInProgress = false
                    self?.originalFocusedApplication = nil
                    self?.showErrorNotification(message: "Transformation timed out. Please try again.")
                }
            }
        }

        NotificationCenter.default.addObserver(forName: Notification.Name("TriggerPromptInput"), object: nil, queue: nil) { [weak self] _ in
            self?.originalFocusedApplication = NSWorkspace.shared.frontmostApplication
            self?.isTransformationInProgress = true
            self?.transformSelectedTextAsPrompt()

            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                if self?.isTransformationInProgress == true &&
                    self?.originalFocusedApplication == NSWorkspace.shared.frontmostApplication {
                    self?.isTransformationInProgress = false
                    self?.originalFocusedApplication = nil
                    self?.showErrorNotification(message: "Transformation timed out. Please try again.")
                }
            }
        }

        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(applicationDidActivate(_:)), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(settingsWindowWillClose), name: NSWindow.willCloseNotification, object: nil)

        if !AXIsProcessTrusted() {
            showErrorNotification(message: "BHelper needs Accessibility access to work properly. Please enable it in System Preferences -> Security & Privacy -> Privacy -> Accessibility.")
        }

        initializeSelectedAPIClient() // Initialize based on saved settings

        if !isRunningFromApplicationsFolder() {
            showMoveToApplicationsAlert()
        }
    }

    private func isRunningFromApplicationsFolder() -> Bool {
        let bundlePath = Bundle.main.bundlePath
        let applicationsFolderPath = "/Applications"
        return bundlePath.hasPrefix(applicationsFolderPath)
    }

    private func showMoveToApplicationsAlert() {
        let alert = NSAlert()
        alert.messageText = "Thanks for Installing BHelper!"
        alert.informativeText = "For BHelper to work correctly, please quit and move the BHelper application to your Applications folder.\n\nRefer to the How to Use guide for instructions."
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "How to Use")

        let modalResult = alert.runModal()
        switch modalResult {
        case .alertFirstButtonReturn:
            break
        case .alertSecondButtonReturn:
            showHowToUseAlert()
        default:
            break
        }
    }

    @objc private func settingsWindowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == settingsWindowController?.window {
            settingsWindowController = nil
            initializeSelectedAPIClient() // Re-initialize based on saved settings
        }
    }

    @objc private func applicationDidActivate(_ notification: Notification) {
        if isTransformationInProgress {
            isTransformationInProgress = false
            originalFocusedApplication = nil
        }
    }

    @objc private func showMenu() {
        let menu = NSMenu()
        
        menu.addItem(llamaMenuItem)
        menu.addItem(gpt4TurboMenuItem)
        menu.addItem(geminiMenuItem)
        menu.addItem(claudeMenuItem)

        menu.addItem(NSMenuItem.separator())
        let settingsMenuItem = NSMenuItem(title: "Settings", action: #selector(showSettingsWindow), keyEquivalent: "")
        menu.addItem(settingsMenuItem)

        let howToUseMenuItem = NSMenuItem(title: "How to Use", action: #selector(showHowToUseAlert), keyEquivalent: "")
        menu.addItem(howToUseMenuItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
    }

    @objc private func selectLlamaAPI() {
        let settings = Settings.shared
        selectedAPIClient = LlamaAPIClient(prePrompt: settings.llamaPrePrompt)
        settings.selectedLLM = "llama"
        updateMenuItemStates()
    }

    @objc private func selectGPT4TurboAPI() {
        let settings = Settings.shared
        selectedAPIClient = OpenAIClient(apiKey: settings.openAIAPIKey, prePrompt: settings.gpt4PrePrompt)
        settings.selectedLLM = "gpt4Turbo"
        updateMenuItemStates()
    }

    @objc private func selectGeminiAPI() {
        let settings = Settings.shared
        selectedAPIClient = GeminiApiClient(apiKey: settings.geminiApiKey, prePrompt: settings.geminiPrePrompt)
        settings.selectedLLM = "gemini"
        updateMenuItemStates()
    }

    @objc private func selectClaudeAPI() {
        let settings = Settings.shared
        selectedAPIClient = ClaudeAPIClient(apiKey: settings.claudeApiKey, prePrompt: settings.claudePrePrompt)
        settings.selectedLLM = "claude"
        updateMenuItemStates()
    }

    @objc private func showSettingsWindow() {
        if settingsWindowController == nil {
            let settingsWindow = SettingsWindow(for: selectedAPIClient)
            settingsWindowController = NSWindowController(window: settingsWindow)
        }
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showHowToUseAlert() {
        let alert = NSAlert()
        alert.messageText = "How to use BHelper"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        if let url = Bundle.main.url(forResource: "HowToUse", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        alert.accessoryView = webView
        alert.runModal()
    }

    func showErrorNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "BHelper"
        content.body = message
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: "BHelperError", content: content, trigger: nil)
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error showing notification: \(error.localizedDescription)")
            }
        }
    }

    func showClipboardNotification() {
        DispatchQueue.main.async {
            self.showErrorNotification(message: "Transformed text is ready in your clipboard. Paste it using (Cmd + V)")
        }
    }

    private func transformSelectedText() {
        AccessibilityManager.transformSelectedText(using: selectedAPIClient,
                                                  originalFocusedApp: originalFocusedApplication,
                                                  usePrePrompt: true) { [weak self] in
            self?.isTransformationInProgress = false
            self?.originalFocusedApplication = nil
        }
    }

    private func transformSelectedTextAsPrompt() {
        AccessibilityManager.transformSelectedText(using: selectedAPIClient,
                                                  originalFocusedApp: originalFocusedApplication,
                                                  usePrePrompt: false) { [weak self] in
            self?.isTransformationInProgress = false
            self?.originalFocusedApplication = nil
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    private func createMenuItem(title: String, action: Selector) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
        menuItem.target = self
        return menuItem
    }

    private func updateMenuItemStates() {
        llamaMenuItem.state = selectedAPIClient is LlamaAPIClient ? .on : .off
        gpt4TurboMenuItem.state = selectedAPIClient is OpenAIClient ? .on : .off
        geminiMenuItem.state = selectedAPIClient is GeminiApiClient ? .on : .off
        claudeMenuItem.state = selectedAPIClient is ClaudeAPIClient ? .on : .off
    }

    private func initializeSelectedAPIClient() {
        let settings = Settings.shared
        let selectedLLM = settings.selectedLLM

        switch selectedLLM {
        case "llama":
            selectedAPIClient = LlamaAPIClient(prePrompt: settings.llamaPrePrompt)
        case "gpt4Turbo":
            selectedAPIClient = OpenAIClient(apiKey: settings.openAIAPIKey, prePrompt: settings.gpt4PrePrompt)
        case "gemini":
            selectedAPIClient = GeminiApiClient(apiKey: settings.geminiApiKey, prePrompt: settings.geminiPrePrompt)
        case "claude":
            selectedAPIClient = ClaudeAPIClient(apiKey: settings.claudeApiKey, prePrompt: settings.claudePrePrompt)
        default:
            selectedAPIClient = LlamaAPIClient(prePrompt: settings.llamaPrePrompt) // Default
        }

        updateMenuItemStates()
    }
}

extension NSMutableAttributedString {
    func applyShortcutStyling(toOccurrencesOf keyCombination: String) {
        let inputLength = string.count
        var searchStartIndex = string.startIndex

        while searchStartIndex < string.index(string.startIndex, offsetBy: inputLength) {
            guard let range = string.range(of: keyCombination, options: [], range: searchStartIndex..<string.endIndex) else { break }

            let nsRange = NSRange(range, in: string)

            addAttribute(.font, value: NSFont.systemFont(ofSize: 13, weight: .bold), range: nsRange)

            searchStartIndex = range.upperBound
            guard let nextKbdRange = string.range(of: "<kbd>", options: [], range: searchStartIndex..<string.endIndex) else { break }
            searchStartIndex = nextKbdRange.lowerBound
        }
    }
}
