import Cocoa
import OpenAISwift

class OpenAIClient: LLMAPIClient {
    private let client: OpenAISwift
    private let prePrompt: String

    init(apiKey: String, prePrompt: String) {
        self.client = OpenAISwift(config: .makeDefaultOpenAI(apiKey: apiKey))
        self.prePrompt = prePrompt
    }

    func sendTextToLLM(text: String, prompt: String, completion: @escaping (String?) -> Void) {
        let fullPrompt = "\(prePrompt)\n\(text)"
        let modelName = Settings.shared.gpt4Model

        Task {
            do {
                let chatMessage = ChatMessage(role: .user, content: fullPrompt)

                let result = try await client.sendChat(with: [chatMessage], model: .other(modelName))

                if let choices = result.choices, let choice = choices.first {
                    if let cleanedMessage = choice.message.content?.trimmingCharacters(in: .whitespacesAndNewlines) {
                        completion(cleanedMessage)
                    } else {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }

            } catch {
                print("Error calling OpenAI API: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
}
