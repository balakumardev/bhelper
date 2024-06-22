import Cocoa
import GoogleGenerativeAI

class GeminiApiClient: LLMAPIClient {
    private let apiKey: String
    private let prePrompt: String
    private var client: GoogleGenerativeAI.GenerativeModel?

    init(apiKey: String, prePrompt: String) {
        self.apiKey = apiKey
        self.prePrompt = prePrompt
        initializeClient()
    }

    private func initializeClient() {
        Task {
            do {
                self.client = try await GoogleGenerativeAI.GenerativeModel(name: Settings.shared.geminiModel, apiKey: apiKey) // Use parameterized model
            } catch {
                print("GeminiApiClient: Failed to initialize Gemini client: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    AppDelegate.shared.showErrorNotification(message: "Gemini API client initialization failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func sendTextToLLM(text: String, prompt: String, completion: @escaping (String?) -> Void) {
        print("GeminiApiClient: Sending request with text: \(text)")

        guard let client = client else {
            print("GeminiApiClient: Gemini client not initialized.")
            DispatchQueue.main.async {
                completion(nil)
                AppDelegate.shared.showErrorNotification(message: "Gemini API client is not yet initialized. Please try again later.")
            }
            return
        }

        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let fullPrompt = "\(prePrompt) \(encodedText)"

        Task {
            do {
                let response = try await client.generateContent(fullPrompt)
                if let generatedText = response.text {
                    print("GeminiApiClient: Output: \(generatedText)")
                    let cleanedText = generatedText.replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    DispatchQueue.main.async {
                        completion(cleanedText)
                    }
                } else {
                    print("GeminiApiClient: Response text is nil.")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                print("GeminiApiClient: Error calling Gemini API: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                    AppDelegate.shared.showErrorNotification(message: "Gemini API call failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
