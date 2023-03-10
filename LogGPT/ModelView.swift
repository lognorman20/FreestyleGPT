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
        self.messages = [Message(id: UUID(), content: "This app's unexpected like a mixtape", response: "Catch you at yo' crib, if you're readin' this, it's too late")]
        self.api = ChatGPTAPI(apiKey: apiKey)
    }
    
    // send request to api
    @MainActor
    func getResponse(text: String) async throws {
        isBusy = true
        do {
            let response = try await api.sendMessage(text).trimmingCharacters(in: .whitespacesAndNewlines)
            let responseMessage = Message(id: UUID(), content: text, response: response)
            messages.append(responseMessage)
        } catch {
            print("Error getting response from api: \(error)")
            throw error
        }
        isBusy = false
    }
    
    @MainActor
    func clear() {
        messages.removeAll()
    }
}
