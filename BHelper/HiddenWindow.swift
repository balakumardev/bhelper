import Cocoa

// A hidden window to keep the application active in the background
class HiddenWindow: NSWindow {
    override var canBecomeKey: Bool {
        return false // Prevent the window from becoming the key window
    }

    override var canBecomeMain: Bool {
        return false // Prevent the window from becoming the main window
    }
}
