import Cocoa
import SwiftAnthropic

class ClaudeAPIClient: LLMAPIClient {
    private let service: AnthropicService
    private let prePrompt: String

    init(apiKey: String, prePrompt: String) {
        self.service = AnthropicServiceFactory.service(apiKey: apiKey)
        self.prePrompt = prePrompt
    }

    func sendTextToLLM(text: String, prompt: String, completion: @escaping (String?) -> Void) {
        let fullPrompt = "\(prePrompt)\n\(text)"
        let modelString = Settings.shared.claudeModel

        guard let model = modelFromString(modelString) else {
            print("Invalid Claude model selected in settings: \(modelString)")
            DispatchQueue.main.async {
                AppDelegate.shared.showErrorNotification(message: "Invalid Claude model selected. Please check your settings.")
            }
            completion(nil)
            return
        }

        Task {
            do {
                let messageParameter = MessageParameter.Message(role: .user, content: .text(fullPrompt))

                let parameters = MessageParameter(
                    model: model,
                    messages: [messageParameter],
                    maxTokens: 2048,
                    stream: false
                )

                let response = try await service.createMessage(parameters)

                // Correctly extract completion text
                for contentBlock in response.content {
                    if case .text(let completionText) = contentBlock {
                        let parsedText = extractTextBetweenBackticks(from: completionText)
                        completion(parsedText)
                        return // Exit the loop after finding the text block
                    }
                }

                print("Claude API response did not contain a text content block.")
                completion(nil)

            } catch {
                print("Claude API call failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    AppDelegate.shared.showErrorNotification(message: "Claude API call failed: \(error.localizedDescription)")
                }
                completion(nil)
            }
        }
    }

    // Helper function to get Model enum case from String (no changes)
    private func modelFromString(_ modelString: String) -> SwiftAnthropic.Model? {
        switch modelString {
        case SwiftAnthropic.Model.claudeInstant12.value: return .claudeInstant12
        case SwiftAnthropic.Model.claude2.value: return .claude2
        case SwiftAnthropic.Model.claude21.value: return .claude21
        case SwiftAnthropic.Model.claude3Opus.value: return .claude3Opus
        case SwiftAnthropic.Model.claude3Sonnet.value: return .claude3Sonnet
        case SwiftAnthropic.Model.claude35Sonnet.value: return .claude35Sonnet
        case SwiftAnthropic.Model.claude3Haiku.value: return .claude3Haiku
        default: return nil
        }
    }

    // Function to extract text between backticks (no changes)
    private func extractTextBetweenBackticks(from text: String) -> String {
        let pattern = "```markdown\n(.*?)\n```" // Regular expression pattern

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
                  return text // Return original text if pattern not found
        }
        
        return String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
