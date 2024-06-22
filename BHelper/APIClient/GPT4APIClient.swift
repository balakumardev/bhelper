import Cocoa

struct TicketDetail: Codable {
    let accessToken: String
    let legacyAuthId: String
}

struct TokenRequest: Codable {
    let intuitTokenType: String
    let intuitAppId: String
    let intuitAppSecret: String
    let username: String
    let password: String
}

struct TokenResponse: Codable {
    let ticketDetail: TicketDetail?
    let error: String?
    let details: String?
}

class GPT4APIClient: LLMAPIClient {
    private var ticketDetail: TicketDetail? {
        didSet {
            saveTicketDetail()
        }
    }

    private let maxRetryAttempts = 3
    private let prePrompt: String // Store the prePrompt

    init(prePrompt: String) {
        self.prePrompt = prePrompt  // Initialize prePrompt
        ticketDetail = loadTicketDetail()
    }

    func sendTextToLLM(text: String, prompt: String, completion: @escaping (String?) -> Void) {
        let settings = Settings.shared
        print("Using settings - AppID: \(settings.intuitAppId), AppSecret: \(settings.intuitAppSecret), Username: \(settings.username)")

        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let truncatedText = String(encodedText.prefix(8048))

        let apiUrl = "https://genpluginregistry-e2e.api.intuit.com/v1/llmexpress/chat/completion?experience_id=5774189b-93c5-4bab-adf3-3601d9b03a12"
        guard let url = URL(string: apiUrl) else {
            print("Invalid API URL")
            DispatchQueue.main.async {
                AppDelegate.shared.showErrorNotification(message: "Invalid API URL")
            }
            completion(nil)
            return
        }

        makeLLMCall(to: url, with: truncatedText, prompt: prompt, retryCount: 0, completion: completion)
    }

    private func makeLLMCall(to url: URL, with text: String, prompt: String, retryCount: Int, completion: @escaping (String?) -> Void) {
        if retryCount >= maxRetryAttempts {
            print("API request failed after \(retryCount) retries")
            completion(nil)
            return
        }

        let settings = Settings.shared

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Intuit_IAM_Authentication intuit_token_type=\"IAM-Ticket\",intuit_appid=\(settings.intuitAppId),intuit_app_secret=\(settings.intuitAppSecret),intuit_userid=\(ticketDetail?.legacyAuthId ?? ""),intuit_token=\(ticketDetail?.accessToken ?? "")", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "conversation_id": "\(Date().timeIntervalSince1970)",
            "llm_params": [
                "llm_configuration": [
                    "top_p": 0.9,
                    "top_k": 5.962133916683182,
                    "temperature": 0.8008281904610115,
                    "context": "context",
                    "model": "gpt-4-32k"
                ],
                "messages": [[
                    "role": "user",
                    "content": "\(prePrompt)\n\(text)" // Use the stored prePrompt
                ]]
            ]
        ]

        let jsonInputString = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        request.httpBody = jsonInputString

        print("Sending text to GPT-4 API: \(text)")
        print("Request payload: \(requestBody)")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("API Error: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    AppDelegate.shared.showErrorNotification(message: "API call failed - \(error?.localizedDescription ?? "Unknown error")")
                }
                completion(nil)
                return
            }

            let responseString = String(data: data, encoding: .utf8) ?? ""
            print("API response payload: \(responseString)")

            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if statusCode == 200 {
                    if let responseJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let answerJson = responseJson["answer"] as? [String: Any],
                       let commitMessage = answerJson["content"] as? String {
                        
                        // Extract content between backticks:
                        let extractedText = self.extractTextBetweenBackticks(from: commitMessage)
                        completion(extractedText)

                    } else {
                        print("Failed to parse API response")
                        DispatchQueue.main.async {
                            AppDelegate.shared.showErrorNotification(message: "Failed to parse API response")
                        }
                        completion(nil)
                    }
                } else if statusCode == 401 || statusCode == 403 {
                    self.generateToken { success in
                        if success {
                            print("Retrying LLM API call after generating a new token")
                            if retryCount > 0 {
                                DispatchQueue.main.async {
                                    AppDelegate.shared.showErrorNotification(message: "Token expired, retrying...")
                                }
                            }
                            self.makeLLMCall(to: url, with: text, prompt: prompt, retryCount: retryCount + 1, completion: completion)
                        } else {
                            print("Failed to generate token, aborting LLM API call")
                            DispatchQueue.main.async {
                                AppDelegate.shared.showErrorNotification(message: "Token generation failed")
                            }
                            completion(nil)
                        }
                    }
                } else {
                    print("API request failed with status code: \(statusCode), \(String(describing: response))")
                    DispatchQueue.main.async {
                        AppDelegate.shared.showErrorNotification(message: "API request failed with status code: \(statusCode)")
                    }
                    completion(nil)
                }
            } else {
                print("Invalid API response")
                DispatchQueue.main.async {
                    AppDelegate.shared.showErrorNotification(message: "Invalid API response")
                }
                completion(nil)
            }
        }
        task.resume()
    }

    private func extractTextBetweenBackticks(from text: String) -> String {
        let components = text.components(separatedBy: "```")
        if components.count >= 3 {
            return components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return text
        }
    }

    private func generateToken(completion: @escaping (Bool) -> Void) {
        let settings = Settings.shared
        let tokenRequest = TokenRequest(
            intuitTokenType: "IAM-Ticket",
            intuitAppId: settings.intuitAppId,
            intuitAppSecret: settings.intuitAppSecret,
            username: settings.username,
            password: settings.password
        )

        print("Token request payload: \(tokenRequest)")
        makeTokenCall(request: tokenRequest) { response in
            if let ticketDetail = response.ticketDetail {
                self.ticketDetail = ticketDetail
                print("Generated new token: \(ticketDetail)")
                completion(true)
            } else {
                print("Failed to generate token: \(response.error ?? "Unknown error")")
                print("Error details: \(response.details ?? "No details available")")
                DispatchQueue.main.async {
                    AppDelegate.shared.showErrorNotification(message: "Failed to generate token: \(response.error ?? "Unknown error"). \(response.details ?? "")")
                }
                completion(false)
            }
        }
    }

    private func makeTokenCall(request: TokenRequest, completion: @escaping (TokenResponse) -> Void) {
        let graphqlRequest = """
            mutation identityTestSignInWithPassword($input: Identity_TestSignInWithPasswordInput!) {
                identityTestSignInWithPassword(input: $input) {
                    accessToken
                    legacyAuthId
                }
            }
        """

        let variables: [String: Any] = [
            "input": [
                "username": request.username,
                "password": request.password,
                "intent": [
                    "appGroup": "Identity",
                    "assetAlias": request.intuitAppId
                ]
            ]
        ]

        let requestBody: [String: Any] = [
            "query": graphqlRequest,
            "operationName": "identityTestSignInWithPassword",
            "variables": variables
        ]

        let apiUrl = "https://identityinternal-e2e.api.intuit.com/signin/graphql"
        guard let url = URL(string: apiUrl) else {
            print("Invalid token API URL")
            DispatchQueue.main.async {
                AppDelegate.shared.showErrorNotification(message: "Invalid token API URL")
            }
            completion(TokenResponse(ticketDetail: nil, error: "Invalid URL", details: nil))
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Intuit_IAM_Authentication intuit_appid=\(request.intuitAppId), intuit_app_secret=\(request.intuitAppSecret)", forHTTPHeaderField: "Authorization")
        req.setValue("identityinternal-e2e.api.intuit.com", forHTTPHeaderField: "Host")

        let jsonInputString = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        req.httpBody = jsonInputString

        print("Token API request payload: \(String(data: req.httpBody ?? Data(), encoding: .utf8) ?? "")")

        let task = URLSession.shared.dataTask(with: req) { data, response, error in
            guard let data = data, error == nil else {
                print("Token API Error: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    AppDelegate.shared.showErrorNotification(message: "Token API call failed - \(error?.localizedDescription ?? "Unknown error")")
                }
                completion(TokenResponse(ticketDetail: nil, error: "API Error", details: error?.localizedDescription))
                return
            }

            let responseString = String(data: data, encoding: .utf8) ?? ""
            print("Token API response payload: \(responseString)")

            let responseJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            if let dataJson = responseJson?["data"] as? [String: Any] {
                if let errors = dataJson["errors"] as? [[String: Any]] {
                    let errorJson = errors.first
                    print("Token API Error: \(errorJson?.description ?? "Unknown error")")
                    DispatchQueue.main.async {
                        AppDelegate.shared.showErrorNotification(message: "Token API call failed - \(errorJson?.description ?? "Unknown error")")
                    }
                    completion(TokenResponse(ticketDetail: nil, error: "API Error", details: errorJson?.description))
                } else if let resultJson = dataJson["identityTestSignInWithPassword"] as? [String: Any],
                          let accessToken = resultJson["accessToken"] as? String,
                          let legacyAuthId = resultJson["legacyAuthId"] as? String {
                    let ticketDetail = TicketDetail(accessToken: accessToken, legacyAuthId: legacyAuthId)
                    completion(TokenResponse(ticketDetail: ticketDetail, error: nil, details: nil))
                } else {
                    print("Invalid token response format")
                    DispatchQueue.main.async {
                        AppDelegate.shared.showErrorNotification(message: "Invalid token response format")
                    }
                    completion(TokenResponse(ticketDetail: nil, error: "Invalid Response", details: nil))
                }
            } else {
                print("Invalid token response")
                DispatchQueue.main.async {
                    AppDelegate.shared.showErrorNotification(message: "Invalid token response")
                }
                completion(TokenResponse(ticketDetail: nil, error: "Invalid Response", details: nil))
            }
        }
        task.resume()
    }

    private func saveTicketDetail() {
        guard let ticketDetail = ticketDetail else { return }

        let encoder = JSONEncoder()
        if let data = try? encoder.encode(ticketDetail) {
            UserDefaults.standard.set(data, forKey: "ticketDetail")
            print("Saved ticket detail")
        } else {
            print("Failed to save ticket detail")
        }
    }

    private func loadTicketDetail() -> TicketDetail? {
        guard let data = UserDefaults.standard.data(forKey: "ticketDetail") else {
            print("No saved ticket detail found")
            return nil
        }

        let decoder = JSONDecoder()
        if let ticketDetail = try? decoder.decode(TicketDetail.self, from: data) {
            print("Loaded ticket detail")
            return ticketDetail
        } else {
            print("Failed to load ticket detail")
            return nil
        }
    }
}
