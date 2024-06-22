import Cocoa

protocol LLMAPIClient {
    func sendTextToLLM(text: String, prompt: String, completion: @escaping (String?) -> Void)
}

class AccessibilityManager {
    private var observer: AXObserver?
    private var observedElement: AXUIElement?
    private var runLoopMode: CFRunLoopMode?
    private static var isTransforming = false

    static func transformSelectedText(using apiClient: LLMAPIClient, originalFocusedApp: NSRunningApplication?, usePrePrompt: Bool, completion: @escaping () -> Void) {
            // Check if a transformation is already in progress
            guard !isTransforming else {
                AppDelegate.shared.showErrorNotification(message: "A previous transformation is still in progress. Please wait.")
                completion()
                return
            }

        isTransforming = true

        let pasteboard = NSPasteboard.general
        let originalPasteboardContents = pasteboard.string(forType: .string)

        let source = CGEventSource(stateID: .combinedSessionState)
        let copyCommand = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        copyCommand?.flags = .maskCommand
        copyCommand?.post(tap: .cgAnnotatedSessionEventTap)

        usleep(100000)

        if let selectedText = pasteboard.string(forType: .string) {
            let prompt = usePrePrompt ? "" : "Rewrite the following text:\n\(selectedText)"

            // Correct: Pass selectedText as 'text' when usePrePrompt is false
            apiClient.sendTextToLLM(text: usePrePrompt ? selectedText : selectedText, prompt: prompt) { transformedText in
                DispatchQueue.main.async {
                    if let transformedText = transformedText, !transformedText.isEmpty {
                        pasteboard.clearContents()
                        pasteboard.setString(transformedText, forType: .string)

                        if NSWorkspace.shared.frontmostApplication == originalFocusedApp {
                            let pasteCommand = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
                            pasteCommand?.flags = .maskCommand
                            pasteCommand?.post(tap: .cgAnnotatedSessionEventTap)
                            print("Text transformed and pasted using LLM API: \(transformedText)")
                        } else {
                            AppDelegate.shared.showClipboardNotification()
                        }
                    } else {
                        pasteboard.clearContents()
                        if let originalContents = originalPasteboardContents {
                            pasteboard.setString(originalContents, forType: .string)
                        }
                    }

                    isTransforming = false
                    completion()
                }
            }
        } else {
            isTransforming = false
            completion()
        }
    }

    func startObserving(element: AXUIElement) {
        observedElement = element
        let observerCallback: AXObserverCallback = { observer, element, notification, refcon in
            print("Notification: \(notification)")
            if notification == kAXUIElementDestroyedNotification as CFString {
                DispatchQueue.main.async {
                    AppDelegate.shared.showErrorNotification(message: "An error occurred with the accessibility service. The app may not function correctly.")
                }
            }
        }

        AXObserverCreate(0, observerCallback, &observer)
        guard let observer = observer else { return }

        runLoopMode = CFRunLoopMode(CFRunLoopMode.defaultMode.rawValue as CFString)

        CFRunLoopAddSource(RunLoop.current.getCFRunLoop(),
                           AXObserverGetRunLoopSource(observer),
                           runLoopMode)

        AXObserverAddNotification(observer, element, kAXUIElementDestroyedNotification as CFString, nil)
    }

    func stopObserving() {
        guard let observer = observer,
              let element = observedElement,
              let runLoopMode = runLoopMode else { return }

        AXObserverRemoveNotification(observer, element, kAXUIElementDestroyedNotification as CFString)
        CFRunLoopRemoveSource(RunLoop.current.getCFRunLoop(),
                              AXObserverGetRunLoopSource(observer),
                              runLoopMode)

        self.observer = nil
        self.observedElement = nil
        self.runLoopMode = nil
    }
}
