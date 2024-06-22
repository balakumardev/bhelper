import Cocoa
import SwiftAnthropic

class SettingsWindow: NSWindow {
    private var openAIAPIKeyTextField: NSTextField?
    private var geminiApiKeyTextField: NSTextField?
    private var llamaModelTextField: NSTextField?
    private var gpt4ModelTextField: NSTextField?
    private var geminiModelTextField: NSTextField?
    private var llamaPrePromptTextView: NSTextView?
    private var gpt4PrePromptTextView: NSTextView?
    private var geminiPrePromptTextView: NSTextView?
    private var claudeApiKeyTextField: NSTextField?
    private var claudeModelPopupButton: NSPopUpButton?
    private var claudePrePromptTextView: NSTextView?

    convenience init(for apiClient: LLMAPIClient) {
        self.init(contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
                  styleMask: [.titled, .closable, .miniaturizable, .resizable],
                  backing: .buffered,
                  defer: false)

        self.title = "API Settings"
        self.contentView = createContentView(for: apiClient)
        self.center()
        self.makeKeyAndOrderFront(nil)
    }

    private func createContentView(for apiClient: LLMAPIClient) -> NSView {
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 600))
        let settings = Settings.shared

        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveSettings))
        saveButton.frame = NSRect(x: 280, y: 20, width: 100, height: 30)
        contentView.addSubview(saveButton)

        if apiClient is OpenAIClient {
            let openAIAPIKeyLabel = NSTextField(labelWithString: "OpenAI API Key:")
            openAIAPIKeyLabel.frame = NSRect(x: 20, y: 560, width: 120, height: 20)
            contentView.addSubview(openAIAPIKeyLabel)

            openAIAPIKeyTextField = NSTextField(frame: NSRect(x: 150, y: 560, width: 230, height: 20))
            openAIAPIKeyTextField?.stringValue = settings.openAIAPIKey
            contentView.addSubview(openAIAPIKeyTextField!)

            let gpt4ModelLabel = NSTextField(labelWithString: "GPT-4 Model:")
            gpt4ModelLabel.frame = NSRect(x: 20, y: 520, width: 120, height: 20)
            contentView.addSubview(gpt4ModelLabel)

            gpt4ModelTextField = NSTextField(frame: NSRect(x: 150, y: 520, width: 230, height: 20))
            gpt4ModelTextField?.stringValue = settings.gpt4Model
            contentView.addSubview(gpt4ModelTextField!)

            let gpt4PrePromptLabel = NSTextField(labelWithString: "GPT-4 Pre-Prompt:")
            gpt4PrePromptLabel.frame = NSRect(x: 20, y: 480, width: 120, height: 20)
            contentView.addSubview(gpt4PrePromptLabel)

            let gpt4PrePromptScrollView = NSScrollView(frame: NSRect(x: 150, y: 300, width: 230, height: 160))
            gpt4PrePromptTextView = NSTextView(frame: gpt4PrePromptScrollView.contentView.bounds)
            gpt4PrePromptTextView?.string = settings.gpt4PrePrompt
            gpt4PrePromptScrollView.documentView = gpt4PrePromptTextView
            contentView.addSubview(gpt4PrePromptScrollView)
        } else if apiClient is GeminiApiClient {
            let geminiApiKeyLabel = NSTextField(labelWithString: "Gemini API Key:")
            geminiApiKeyLabel.frame = NSRect(x: 20, y: 560, width: 120, height: 20)
            contentView.addSubview(geminiApiKeyLabel)

            geminiApiKeyTextField = NSTextField(frame: NSRect(x: 150, y: 560, width: 230, height: 20))
            geminiApiKeyTextField?.stringValue = settings.geminiApiKey
            contentView.addSubview(geminiApiKeyTextField!)

            let geminiModelLabel = NSTextField(labelWithString: "Gemini Model:")
            geminiModelLabel.frame = NSRect(x: 20, y: 520, width: 120, height: 20)
            contentView.addSubview(geminiModelLabel)

            geminiModelTextField = NSTextField(frame: NSRect(x: 150, y: 520, width: 230, height: 20))
            geminiModelTextField?.stringValue = settings.geminiModel
            contentView.addSubview(geminiModelTextField!)

            let geminiPrePromptLabel = NSTextField(labelWithString: "Gemini Pre-Prompt:")
            geminiPrePromptLabel.frame = NSRect(x: 20, y: 480, width: 120, height: 20)
            contentView.addSubview(geminiPrePromptLabel)

            let geminiPrePromptScrollView = NSScrollView(frame: NSRect(x: 150, y: 300, width: 230, height: 160))
            geminiPrePromptTextView = NSTextView(frame: geminiPrePromptScrollView.contentView.bounds)
            geminiPrePromptTextView?.string = settings.geminiPrePrompt
            geminiPrePromptScrollView.documentView = geminiPrePromptTextView
            contentView.addSubview(geminiPrePromptScrollView)
        } else if apiClient is LlamaAPIClient {
            let llamaModelLabel = NSTextField(labelWithString: "Llama Model:")
            llamaModelLabel.frame = NSRect(x: 20, y: 560, width: 120, height: 20)
            contentView.addSubview(llamaModelLabel)

            llamaModelTextField = NSTextField(frame: NSRect(x: 150, y: 560, width: 230, height: 20))
            llamaModelTextField?.stringValue = settings.llamaModel
            contentView.addSubview(llamaModelTextField!)

            let llamaPrePromptLabel = NSTextField(labelWithString: "Llama Pre-Prompt:")
            llamaPrePromptLabel.frame = NSRect(x: 20, y: 520, width: 120, height: 20)
            contentView.addSubview(llamaPrePromptLabel)

            let llamaPrePromptScrollView = NSScrollView(frame: NSRect(x: 150, y: 340, width: 230, height: 160))
            llamaPrePromptTextView = NSTextView(frame: llamaPrePromptScrollView.contentView.bounds)
            llamaPrePromptTextView?.string = settings.llamaPrePrompt
            llamaPrePromptScrollView.documentView = llamaPrePromptTextView
            contentView.addSubview(llamaPrePromptScrollView)
        } else if apiClient is ClaudeAPIClient {
            let claudeApiKeyLabel = NSTextField(labelWithString: "Claude API Key:")
            claudeApiKeyLabel.frame = NSRect(x: 20, y: 560, width: 120, height: 20)
            contentView.addSubview(claudeApiKeyLabel)

            claudeApiKeyTextField = NSTextField(frame: NSRect(x: 150, y: 560, width: 230, height: 20))
            claudeApiKeyTextField?.stringValue = settings.claudeApiKey
            contentView.addSubview(claudeApiKeyTextField!)

            let claudeModelLabel = NSTextField(labelWithString: "Claude Model:")
            claudeModelLabel.frame = NSRect(x: 20, y: 520, width: 120, height: 20)
            contentView.addSubview(claudeModelLabel)

            claudeModelPopupButton = NSPopUpButton(frame: NSRect(x: 150, y: 520, width: 230, height: 20))

            // Add items to the popup button from SwiftAnthropic.Model enum cases
            for model in [
                SwiftAnthropic.Model.claudeInstant12,
                SwiftAnthropic.Model.claude2,
                SwiftAnthropic.Model.claude21,
                SwiftAnthropic.Model.claude3Opus,
                SwiftAnthropic.Model.claude3Sonnet,
                SwiftAnthropic.Model.claude35Sonnet,
                SwiftAnthropic.Model.claude3Haiku
            ] {
                claudeModelPopupButton?.addItem(withTitle: model.value)
            }

            // Set the selected model
            if let selectedModelIndex = claudeModelPopupButton?.indexOfItem(withTitle: settings.claudeModel) {
                claudeModelPopupButton?.selectItem(at: selectedModelIndex)
            }

            contentView.addSubview(claudeModelPopupButton!)

            let claudePrePromptLabel = NSTextField(labelWithString: "Claude Pre-Prompt:")
            claudePrePromptLabel.frame = NSRect(x: 20, y: 480, width: 120, height: 20)
            contentView.addSubview(claudePrePromptLabel)

            let claudePrePromptScrollView = NSScrollView(frame: NSRect(x: 150, y: 300, width: 230, height: 160))
            claudePrePromptTextView = NSTextView(frame: claudePrePromptScrollView.contentView.bounds)
            claudePrePromptTextView?.string = settings.claudePrePrompt
            claudePrePromptScrollView.documentView = claudePrePromptTextView
            contentView.addSubview(claudePrePromptScrollView)
        }

        return contentView
    }

    @objc private func saveSettings() {
        let settings = Settings.shared

        if let openAIAPIKeyTextField = openAIAPIKeyTextField {
            settings.openAIAPIKey = openAIAPIKeyTextField.stringValue
        }

        if let geminiApiKeyTextField = geminiApiKeyTextField {
            settings.geminiApiKey = geminiApiKeyTextField.stringValue
            print("Settings saved: Gemini API Key: \(settings.geminiApiKey)")
        } else if let llamaModelTextField = llamaModelTextField {
            settings.llamaModel = llamaModelTextField.stringValue
            print("Settings saved: Llama Model: \(settings.llamaModel)")
        } else if let claudeApiKeyTextField = claudeApiKeyTextField,
                  let claudeModelPopupButton = claudeModelPopupButton,
                  let claudePrePromptTextView = claudePrePromptTextView {
            settings.claudeApiKey = claudeApiKeyTextField.stringValue
            settings.claudeModel = claudeModelPopupButton.titleOfSelectedItem ?? SwiftAnthropic.Model.claude21.value // Default
            settings.claudePrePrompt = claudePrePromptTextView.string
            print("Settings saved: Claude API Key: \(settings.claudeApiKey), Model: \(settings.claudeModel), PrePrompt: \(settings.claudePrePrompt)")
        }

        if let gpt4ModelTextField = gpt4ModelTextField {
            settings.gpt4Model = gpt4ModelTextField.stringValue
            print("Settings saved: GPT-4 Model: \(settings.gpt4Model)")
        }

        if let geminiModelTextField = geminiModelTextField {
            settings.geminiModel = geminiModelTextField.stringValue
            print("Settings saved: Gemini Model: \(settings.geminiModel)")
        }

        if let llamaPrePromptTextView = llamaPrePromptTextView {
            settings.llamaPrePrompt = llamaPrePromptTextView.string
            print("Settings saved: Llama Pre-Prompt: \(settings.llamaPrePrompt)")
        }

        if let claudePrePromptTextView = claudePrePromptTextView {
            settings.claudePrePrompt = claudePrePromptTextView.string
            print("Settings saved: Claude Pre-Prompt: \(settings.claudePrePrompt)")
        }

        if let gpt4PrePromptTextView = gpt4PrePromptTextView {
            settings.gpt4PrePrompt = gpt4PrePromptTextView.string
            print("Settings saved: GPT-4 Pre-Prompt: \(settings.gpt4PrePrompt)")
        }

        if let geminiPrePromptTextView = geminiPrePromptTextView {
            settings.geminiPrePrompt = geminiPrePromptTextView.string
            print("Settings saved: Gemini Pre-Prompt: \(settings.geminiPrePrompt)")
        }

        self.close()
    }
}
