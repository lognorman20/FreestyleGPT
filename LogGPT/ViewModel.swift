//
//  ViewModel.swift
//  LogGPT
//
//  Created by Logan Norman on 2/20/23.
//

import Foundation
import SwiftUI

class ViewModel : ObservableObject {
    
    @Published var isInteractingWithGPT = false
    @Published var messages: [MessageRow] = []
    @Published var inputMessage: String = ""
    
    private let api: ChatGPTAPI
    
    init(api: ChatGPTAPI) {
        self.api = api
    }
    
    @MainActor
    func sendTapped() async {
        let text = inputMessage
        inputMessage = ""
        await send(text: text)
    }
    
    @MainActor
    func retry(message: MessageRow) async {
        // gets the index of the faulty message. if it can't be found, that tuff
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        // get rid of the message at the current index
        self.messages.remove(at: index)
        // try again
        await send(text: message.sendText)
    }
    
    @MainActor
    private func send(text: String) async {
        isInteractingWithGPT = true
        var streamText = ""
        var messageRow = MessageRow(isInteractingWithChatGPT: true, sendImage: "profile", sendText: text, responseImage: "openai", responseText: streamText)
        
        self.messages.append(messageRow)
        
        do {
            let stream = try await api.sendMessageStream(text: text)
            for try await line in stream {
                streamText += line
                messageRow.responseText = streamText.trimmingCharacters(in: .whitespacesAndNewlines)
                self.messages[self.messages.count - 1] = messageRow
            }
        } catch {
            messageRow.responseError = error.localizedDescription
            print("caught an error in send function")
        }
        
        messageRow.isInteractingWithChatGPT = false
        self.messages[self.messages.count - 1] = messageRow
        isInteractingWithGPT = false
    }
    
}
