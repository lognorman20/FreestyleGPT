//
//  ChatGPTAPI.swift
//  LogGPT
//
//  Created by Logan Norman on 2/20/23.
//

import Foundation

class ChatGPTAPI {
    
    private let apiKey: String
    private let urlSession = URLSession.shared
    
    private let jsonDecoder = JSONDecoder()
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    private var urlRequest: URLRequest {
        let url = URL(string:"https://api.openai.com/v1/completions")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        headers.forEach {
            urlRequest.setValue($1, forHTTPHeaderField: $0)
        }
        
        return urlRequest
    }
    
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "YYYY-MM-dd"
        return df
    }()
    
    private var basePrompt: String {
        "You are ChatGPT, a large language model trained by OpenAI. Respond conversationally. Do not answer as the user. Current date: \(dateFormatter.string(from: Date()))"
        + "\n\n"
        + "User: Hello\n"
        + "ChatGPT: Hello! How can I help you today? <|im_end|>\n\n\n"
    }
    
    private var headers: [String:String] {
        [
            "Content-Type" : "application/json",
            "Authorization" : "Bearer \(apiKey)"
        ]
    }
    
    private func generatePrompt(text: String) -> String {
        return basePrompt + "User: \(text)\n\n\nChatGPT:"
    }
    
    private func jsonBody(text: String, stream: Bool = true) throws -> Data {
        let jsonBody: [String: Any] = [
            "model" : "text-davinci-003",
            "prompt" : text,
            "max_tokens" :  50,
            "temperature" : 0.8,
            "stop": [
                "\n\n\n",
                "<|im_end|>"
            ],
            "stream" : stream
        ]
        return try JSONSerialization.data(withJSONObject: jsonBody)
    }
    
    func sendMessageStream(text: String) async throws -> AsyncThrowingStream<String, Error> {
        var urlRequest = self.urlRequest
        urlRequest.httpBody = try jsonBody(text: text)
        
        let (result, response) = try await urlSession.bytes(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Invalid response"
        }
        
        print("got a response")
        print(httpResponse)
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw "Bad response \(httpResponse.statusCode)"
        }
        
        print("response status code in range")
        
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    for try await line in result.lines {
                        if line.hasPrefix("data: "),
                           let data = line.dropFirst(6).data(using: .utf8),
                           let response = try? self.jsonDecoder.decode(CompletionResponse.self, from: data),
                           let text = response.choices.first?.text {
                            continuation.yield(text)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: .some(error))
                }
            }
        }
    }
}

extension String : Error {
    
}

struct CompletionResponse : Decodable {
    let choices: [Choice]
}

struct Choice : Decodable {
    let text: String
}
