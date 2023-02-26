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
    private var lastResponse = ""
    private var lastInput = ""
    
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
    
    //    private var basePrompt: String {
    //        "You are ChatGPT, a large language model trained by OpenAI. Respond conversationally. Do not answer as the user. Current date: \(dateFormatter.string(from: Date()))."
    //        + "\n\n"
    //        + "User: Hello\n"
    //        + "ChatGPT: Hello! How can I help you today? <|im_end|>\n\n\n"
    //    }
    
    //    private var basePrompt2: String {
    //        "You are a dynamic rapper with witty rhymes, metaphors, and similies. Your answer must be a song lyric. "
    //        + "Your answer must finish with a rhyme on the input. Limit your response to 10 words. Do not repeat anything "
    //        + "from the input text."
    //        + "\n\n"
    //        + "Human: I'm grindin' all day like a dude at a skate park\n"
    //        + "AI: I put the P's in the back of a racecar\n"
    //        + "Human: I don't lie about the price cuz I got the receipts\n"
    //        + "AI: Some money older, some may got a crease\n"
    //        + "Human: I'm like a dollar that's fresh, that's my niche\n"
    //        + "AI: Bought mama a car and I told her, \"No biggie\"\n"
    //        + "AI: I just pour up the syrup, got that AP ready\n"
    //        + "Human: I write with my pencil, I keep it steady\n"
    //        + "AI: Word on the street, I'm a legend already <|im_end|>\n\n\n"
    //    }
    
    private var basePrompt3: String {
//        "Reply with a rap lyric that rhymes with the last input from the human. Stop after the word that rhymes with the input. "
//        + "Don't repeat the last word from the input. The last word of your response must rhyme with the last word from the input. "
//        + "\n\n"
        "Reply with a rhyming rap lyric in less than ten words. Don't repeat the last word from the input.\n\n\n"
        + "Human: In 1402, Columbus sailed the ocean blue\n"
        + "AI: I'm the coldest AI in the world, and in the metaverse too\n"
        + "Human: I'm grinding all day like a dude at the skate park\n"
        + "AI: You can catch me flipping and spinning even when it gets dark\n"
        + "Human: I always stack my cheese, I get to the cheddar\n"
        + "AI: I'm about my dough, I ain't looking for no debtors\n"
        + "Human: Whenever I'm on the beat, you know I always spit that heat\n"
        + "AI: That's how I stay fresh, rap flow on repeat.\n"
        + "Human: I put my bags into back of a race car\n"
        + "AI: I'm out here racing, never gonna miss my tar <|im_end|>\n\n\n"
    }
    
    private var headers: [String:String] {
        [
            "Content-Type" : "application/json",
            "Authorization" : "Bearer \(apiKey)"
        ]
    }
    
    private func generatePrompt(text: String) -> String {
        // take into account the last message
        let prompt = basePrompt3 + "Human: \(lastInput)\n" + "AI: \(lastResponse)\n" + "Human: \(text)\nAI: "
        return prompt
    }
    
    private func jsonBody(text: String, stream: Bool = true) throws -> Data {
        let jsonBody: [String: Any] = [
            "model" : "text-davinci-003",
            "prompt" : generatePrompt(text: text),
            "max_tokens" :  2000,
            "temperature" : 1,
            "top_p" : 0.5,
            "frequency_penalty" : 2,
            "best_of": 3,
            "presence_penalty" : 0,
            "stop": [
                "\n",
                "\n\n\n",
                "<|im_end|>"
            ],
            "stream" : stream
        ]
        return try JSONSerialization.data(withJSONObject: jsonBody)
    }
    
    // TODO: Make a function to handle duplicate rhyme words
    // TODO: Handle when the api returns nothing
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
            let responseText = response.choices.first?.text ?? "Couldn't get a response."
            lastResponse = responseText
            lastInput = text
            
            return responseText
        } catch {
            print("Error: \(error)")
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
