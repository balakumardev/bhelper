import Cocoa

class LlamaAPIClient: LLMAPIClient {
    private let prePrompt: String
    private let systemPrompt = """
    You are a helpful assistant that always rewrites given text in a professional yet conversational tone, correcting any grammatical errors, and provides the rewritten text enclosed in Markdown code blocks using the following format. I will give you the text to rewrite, and you will give the rewritten text. No prompts, or asks:
    ```markdown
    Rewritten text goes here, nothing else. Just the rewritten text for the given text.
    ```
    """

    init(prePrompt: String) {
        self.prePrompt = prePrompt
    }

    func sendTextToLLM(text: String, prompt: String, completion: @escaping (String?) -> Void) {
        let apiUrl = "http://localhost:11434/api/generate"
        guard let url = URL(string: apiUrl) else {
            DispatchQueue.main.async {
                AppDelegate.shared.showErrorNotification(message: "Invalid Llama API URL")
            }
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedPreprompt = prePrompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedSystemPrompt = systemPrompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let model = Settings.shared.llamaModel

        let jsonInputString = """
            {
                "model": "\(model)",
                "prompt": "\(encodedPreprompt): \(encodedText)",
                "system": "\(encodedSystemPrompt)",
                "stream": false
            }
        """

        request.httpBody = jsonInputString.data(using: .utf8)
        print("Request to LLM: " + jsonInputString)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    AppDelegate.shared.showErrorNotification(message: "Llama API call failed - \(error?.localizedDescription ?? "Unknown error")")
                }
                completion(nil)
                return
            }

            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                do {
                    let jsonResponse = try JSONDecoder().decode(LlamaResponse.self, from: data)
                    let parsedText = self.extractTextBetweenBackticks(from: jsonResponse.response)
                    completion(parsedText)
                } catch {
                    print("Error parsing Llama API JSON response: \(error.localizedDescription)")
                    completion(nil)
                }
            } else {
                print("Llama API request failed with status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                completion(nil)
            }
        }
        task.resume()
    }

    // Function to extract text between backticks (using regex)
    private func extractTextBetweenBackticks(from text: String) -> String {
        print("Text from LLM: " + text)
        let pattern = "```(?:markdown)?\n(.*?)\n```" // Matches with or without "markdown"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
                  return text
        }

        return String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    struct LlamaResponse: Decodable {
        let model: String
        let created_at: String
        let response: String
        let done: Bool
        let done_reason: String?
        let context: [Int]
    }
}
