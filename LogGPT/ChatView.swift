//
//  ChatView.swift
//  LogGPT
//
//  Created by Logan Norman on 2/21/23.
//

import SwiftUI
import SwiftfulLoadingIndicators

@available(iOS 16.0, *)
struct ChatView: View {
    
    @State var inputText: String = ""
    @State var messages: [Message] = [
        Message(content: "Who is Lebron James?", response: "Lebron James is the greatest basketball player of all time. He's won 4 MVPs and got snubbed for multiple others. On top of that, he played with Russell Westbook, who is clearly the cheat code in all of basketball."),
        Message(content: "What are zero-knowledge proofs?", response: "In cryptography, a zero-knowledge proof or zero-knowledge protocol is a method by which one party can prove to another party that a given statement is true while the prover avoids conveying any additional information apart from the fact that the statement is indeed true."),
        Message(content: "Who is Jesus Christ?", response: "Jesus, also called Jesus Christ, Jesus of Galilee, or Jesus of Nazareth, (born c. 6–4 bce, Bethlehem—died c. 30 ce, Jerusalem), religious leader revered in Christianity, one of the world's major religions. He is regarded by most Christians as the Incarnation of God."),
    ]
    
    @StateObject var model: ModelView = ModelView(apiKey: "***REMOVED***")
    @FocusState var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .center) {
            topView
            Divider()
            
            Spacer()
            
            messageView
            
            Spacer()
            
            Divider()
            bottomView
        }
        .background(MyColors.background)
    }
    
    var messageView: some View {
        ZStack(alignment: .center) {
            if (model.isBusy) {
                LoadingIndicator(animation: .threeBallsBouncing, color: MyColors.mainPurple, size: .extraLarge)
                .zIndex(1)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .center, spacing: 5) {
                        ForEach(model.messages) { msg in
                            messageBlock(message: msg)
                                .id(UUID())
                        }
                    }
                    .onChange(of: model.messages.last?.content) { _ in
                        withAnimation(Animation.easeInOut(duration: 1)) {
                            guard let id = model.messages.last?.id else { return }
                            proxy.scrollTo(id, anchor: .bottomTrailing)
                        }
                    }
                }
            }
            
        }
    }
    
    var bottomView: some View {
        ZStack(alignment: .trailing) {
            TextField("What's the next bar?", text: $inputText, axis: .vertical)
                .padding()
                .focused($isTextFieldFocused)
                .multilineTextAlignment(.leading)
                .onSubmit {
                    if (!inputText.isEmpty) {
                        isTextFieldFocused = false
                        sendMsg(text: self.inputText)
                        inputText = ""
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10.0)
                        .fill(.white)
                        .shadow(radius: 2)
                )
                .frame(width:300)
                .padding(.trailing, 30)
            
            Button {
                if (!inputText.isEmpty) {
                    isTextFieldFocused = false
                    sendMsg(text: self.inputText)
                    inputText = ""
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(MyColors.mainPurple)
                    .rotationEffect(.degrees(90))
                    .padding(.trailing, -20)
            }
        }
        .padding()
    }
    
    @MainActor
    func sendMsg(text: String) {
        Task { @MainActor in
            isTextFieldFocused = false
            try await model.getResponse(text: text)
        }
    }
    
    func messageBlock(message: Message) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(MyColors.mainPurple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            HStack {
                Text(message.response)
                    .padding()
                    .background(.white)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .frame(maxWidth: 300)
                Spacer()
            }
            .padding()
        }
    }
    
    var topView: some View {
        HStack(alignment: .center) {
            
            Button {
                print("left side was clicked")
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .padding()
                    .font(.system(size: 30))
                    .foregroundColor(MyColors.mainPurple)
            }
            
            Spacer()
            
            VStack(spacing: 0) {
                Text("FreestyleGPT")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("deeppurple"))
                
                Text("from @zklogno")
                    .font(.footnote)
            }
                
            Spacer()
            
            Button {
                print("right side was clicked")
            } label: {
                Image(systemName: "camera.filters")
                    .padding()
                    .font(.system(size: 30))
                    .foregroundColor(MyColors.mainPurple)
            }
        }
    }
}

struct Message : Identifiable {
    let id = UUID()
    let content: String
    let response: String
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}

struct MyColors {
    static let mainPurple = Color("deeppurple")
    static let accentPurple = Color("lightpurple")
    static let background = Color("background")
    static let darker_background = Color("darker_background")
    
    static let radialGradient = RadialGradient(colors: [.white, mainPurple], center: .center, startRadius: 10, endRadius: 1000)
    static let linearGradient = LinearGradient(gradient: Gradient(colors: [accentPurple, .white, accentPurple]), startPoint: .topLeading, endPoint: .bottomTrailing)
}
