import Cocoa

class HotKeyManager {
    static let shared = HotKeyManager()

    func setUpGlobalHotKey() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { (event) in
            if event.modifierFlags.contains([.command, .option, .control]) && event.keyCode == 32 { // Key code 32 is for 'U'
                print("Shortcut Command + Option + Control + U detected")
                NotificationCenter.default.post(name: Notification.Name("TriggerTextTransformation"), object: nil)
            } else if event.modifierFlags.contains([.command, .option, .control]) && event.keyCode == 34 { // Key code 34 is for 'I'
                print("Shortcut Command + Option + Control + I detected")
                NotificationCenter.default.post(name: Notification.Name("TriggerPromptInput"), object: nil)
            }
        }
    }
}
