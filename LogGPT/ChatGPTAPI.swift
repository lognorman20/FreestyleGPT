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
    private var historyList = [String]()
    
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
    
    private var historyListText: String {
        historyList.joined()
    }
    
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "YYYY-MM-dd"
        return df
    }()
    
    private var basePrompt: String {
        "You are ChatGPT, a large language model trained by OpenAI. Respond conversationally. Do not answer as the user. Current date: \(dateFormatter.string(from: Date()))."
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
        var prompt = basePrompt + historyListText + "User: \(text)\n\n\nChatGPT:"
        if prompt.count > (4 * 4000) {
            _ = historyList.dropFirst()
            prompt = generatePrompt(text: text)
        }
        return prompt
    }
    
    private func jsonBody(text: String, stream: Bool = true) throws -> Data {
        let jsonBody: [String: Any] = [
            "model" : "text-davinci-003",
            "prompt" : text,
            "max_tokens" :  375,
            "temperature" : 0.9,
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
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw "Bad response \(httpResponse.statusCode)"
        }
        
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    var streamText = ""
                    for try await line in result.lines {
                        if line.hasPrefix("data: "),
                           let data = line.dropFirst(6).data(using: .utf8),
                           let response = try? self.jsonDecoder.decode(CompletionResponse.self, from: data),
                           let text = response.choices.first?.text {
                            continuation.yield(text)
                            streamText += text
                        }
                    }
                    historyList.append(streamText)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: .some(error))
                }
            }
        }
    }
    
    func sendMessage(_ text: String) async throws -> String {
        var urlRequest = self.urlRequest
        urlRequest.httpBody = try jsonBody(text: text, stream: false)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Invalid response"
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw "Bad response \(httpResponse.statusCode)"
        }
        
        do {
            let response = try self.jsonDecoder.decode(CompletionResponse.self, from: data)
            let text = response.choices.first?.text ?? "Couldn't get a response."
            self.historyList.append(text)
            return text
        } catch {
            throw error
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
