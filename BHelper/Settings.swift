import Foundation
import SwiftAnthropic

class Settings {
    static let shared = Settings()

    let defaults: NSDictionary

    private init() {
        guard let path = Bundle.main.path(forResource: "Defaults", ofType: "plist"),
              let defaults = NSDictionary(contentsOfFile: path) else {
            fatalError("Unable to load Defaults.plist")
        }
        self.defaults = defaults
    }

    var geminiApiKey: String {
        get {
            return UserDefaults.standard.string(forKey: "geminiApiKey") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "geminiApiKey")
        }
    }

    var openAIAPIKey: String {
        get {
            return UserDefaults.standard.string(forKey: "openAIAPIKey") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "openAIAPIKey")
        }
    }

    var claudeApiKey: String {
        get {
            return UserDefaults.standard.string(forKey: "claudeApiKey") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "claudeApiKey")
        }
    }

    var claudeModel: String {
        get {
            return UserDefaults.standard.string(forKey: "claudeModel") ?? SwiftAnthropic.Model.claude21.value
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "claudeModel")
        }
    }

    var llamaModel: String {
        get {
            return UserDefaults.standard.string(forKey: "llamaModel") ?? defaults["llamaModel"] as? String ?? "llama2"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "llamaModel")
        }
    }

    var gpt4Model: String {
        get {
            return UserDefaults.standard.string(forKey: "gpt4Model") ?? defaults["gpt4Model"] as? String ?? "gpt-4o"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "gpt4Model")
        }
    }

    var geminiModel: String {
        get {
            return UserDefaults.standard.string(forKey: "geminiModel") ?? defaults["geminiModel"] as? String ?? "gemini-1.5-pro-latest"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "geminiModel")
        }
    }

    var llamaPrePrompt: String {
        get {
            return UserDefaults.standard.string(forKey: "llamaPrePrompt") ?? defaults["llamaPrePrompt"] as? String ??  "You are a helpful and professional assistant. You will be given a piece of text. Your task is to rewrite this text to make it more professional and suitable for a formal setting.  Please ensure the following:\n\n* Use a polite and courteous tone.\n* Correct any grammatical errors or typos.\n* Improve the clarity and conciseness of the writing. \n* Do not change the meaning of the original text.\n\nPlease return only the rewritten text, enclosed in Markdown code blocks, using the following format:\n\n```markdown\nRewritten text goes here\n```"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "llamaPrePrompt")
        }
    }

    var claudePrePrompt: String {
        get {
            return UserDefaults.standard.string(forKey: "claudePrePrompt") ?? defaults["claudePrePrompt"] as? String ?? "You will be given text in Markdown format. Please rewrite this text in a professional yet conversational tone, correcting any grammatical errors, and provide your response in Markdown format. Ensure no additional content is added, only the given text is re-written. "
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "claudePrePrompt")
        }
    }

    var gpt4PrePrompt: String {
        get {
            return UserDefaults.standard.string(forKey: "gpt4PrePrompt") ?? defaults["gpt4PrePrompt"] as? String ?? "You will be given text in Markdown format. Please rewrite this text in a professional yet conversational tone, correcting any grammatical errors, and provide your response in Markdown format. Ensure no additional content is added, only the given text is re-written. "
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "gpt4PrePrompt")
        }
    }

    var geminiPrePrompt: String {
        get {
            return UserDefaults.standard.string(forKey: "geminiPrePrompt") ?? defaults["geminiPrePrompt"] as? String ?? "You will be given url encoded text in Markdown format. Please rewrite this text in a professional yet conversational tone, correcting any grammatical errors, capitalized appropriately, added punctuations and provide only the rewritten text in Markdown format and nothing else. No additional text or symbols (other than comma dot and question mark) in your response, only the given text re-written."
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "geminiPrePrompt")
        }
    }

    // Selected LLM
    var selectedLLM: String {
        get {
            return UserDefaults.standard.string(forKey: "selectedLLM") ?? defaults["selectedLLM"] as? String ?? "gpt4Turbo"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "selectedLLM")
        }
    }
}
