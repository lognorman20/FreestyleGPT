//
//  MessageRowView.swift
//  LogGPT
//
//  Created by Logan Norman on 2/20/23.
//

import SwiftUI

struct MessageRowView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    let messageRow: MessageRow
    let retryCallback: (MessageRow) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            messageRow(text: messageRow.sendText, image: messageRow.sendImage, bgColor: colorScheme == .light ? .white : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5))
            
            if let response = messageRow.responseText {
                Divider()
                messageRow(text: response, image: "openai", bgColor: colorScheme == .light ? .gray.opacity(0.1) : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 1), responseError: messageRow.responseError, showDotLoading: messageRow.isInteractingWithChatGPT)
                Divider()
            }
        }
    }
    
    func messageRow(text: String, image: String, bgColor: Color, responseError: String? = nil, showDotLoading: Bool = false) -> some View {
        
        HStack(alignment: .center, spacing: 24) {
            Image(image)
                .resizable()
                .frame(width: 30, height: 30)
            VStack(alignment: .leading) {
                if !text.isEmpty {
                    Text(text)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                }
                
                if let error = responseError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                    
                    Button("Retry") {
                        retryCallback(messageRow)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle)
                    .padding(.top)
                }
                
                if showDotLoading {
                    DotLoadingView()
                        .frame(width: 60, height: 30)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bgColor)
    }
}

struct MessageRowView_Previews: PreviewProvider {
    
    static let text = "Who is Lebron?"
    static let streamText = "Lebron James is an American professional basketball player for the Los Angeles Lakers of the National Basketball Association (NBA). He is widely considered one of the greatest basketball players of all time."
    static let messageRow = MessageRow(isInteractingWithChatGPT: true, sendImage: "profile", sendText: text, responseImage: "openai", responseText: streamText)
    
    static let messageRow2 = MessageRow(isInteractingWithChatGPT: false, sendImage: "profile", sendText: text, responseImage: "openai", responseText: "", responseError: "MAN WHAT??")
    static var previews: some View {
        NavigationView {
            ScrollView {
                MessageRowView(messageRow: messageRow, retryCallback: { messageRow in })
                MessageRowView(messageRow: messageRow2, retryCallback: { messageRow in })
            }
            .frame(width: .infinity)
            .previewLayout(.sizeThatFits)
        }
    }
}
