//
//  ModelView.swift
//  LogGPT
//
//  Created by Logan Norman on 2/21/23.
//

import Foundation

class ModelView : ObservableObject {
    // declaring variables that need to readable and updated constantly
    @Published var isBusy: Bool
    @Published var messages: [Message]
    
    // the api
    private let api: ChatGPTAPI
    
    init(apiKey: String) {
        self.isBusy = false
        self.messages = [Message(content: "This app's unexpected like a mixtape", response: "Catch you at yo' crib, if you're readin' this, it's too late", id: UUID())]
        self.api = ChatGPTAPI(apiKey: apiKey)
    }
    
    // send request to api
    @MainActor
    func getResponse(text: String) async throws {
        isBusy = true
        do {
            let response = try await api.sendMessage(text).trimmingCharacters(in: .whitespacesAndNewlines)
            let responseMessage = Message(content: text, response: response, id: UUID())
            print("this was the response message")
            print(response.isEmpty ? response : "The response was empty bro")
            messages.append(responseMessage)
        } catch {
            print("Error getting response from api.")
            throw error
        }
        isBusy = false
    }
    
    @MainActor
    func clear() {
        messages.removeAll()
    }
}
