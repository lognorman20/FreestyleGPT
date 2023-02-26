//
//  ChatView.swift
//  LogGPT
//
//  Created by Logan Norman on 2/21/23.
//

import SwiftUI
import SwiftfulLoadingIndicators
import AVFoundation

@available(iOS 16.0, *)
struct ChatView: View {
    
    @State var inputText: String = ""
    @StateObject var model: ModelView = ModelView(apiKey: "***REMOVED***")
    @FocusState var isTextFieldFocused: Bool

    let synthesizer = AVSpeechSynthesizer()
    @State var scrollProxy: ScrollViewProxy?

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
                    Text("type a lyric with more than five words to get started")
                        .font(.callout)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    LazyVStack(alignment: .center, spacing: 5) {
                        ForEach(model.messages, id: \.id) { msg in
                            messageBlock(message: msg)
                        }
                    }
                    .onAppear {
                        scrollProxy = proxy
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
                    .foregroundColor(inputText.isEmpty ? MyColors.accentPurple : MyColors.mainPurple)
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
    
    func textToSpeech(message: String) {
        let inputVoice = AVSpeechUtterance(string: message)
        inputVoice.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(inputVoice)
    }
    
    var topView: some View {
        HStack(alignment: .center) {
            
            Button {
                withAnimation(.easeInOut) {
                    model.clear()
                }
            } label: {
                Image(systemName: "arrow.uturn.forward.circle")
                    .padding()
                    .font(.system(size: 30))
                    .foregroundColor(model.messages.isEmpty ? MyColors.accentPurple : MyColors.mainPurple)
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
//                let readMessages: [Message] = []
                model.messages.forEach { message in
                    // TODO: fix scroll to
                    withAnimation(.easeInOut) {
                        scrollProxy!.scrollTo(message.id, anchor: .center)
                    }
                    
                    textToSpeech(message: message.content)
                    textToSpeech(message: message.response)
                }
            } label: {
                Image(systemName: "play.circle")
                    .padding()
                    .font(.system(size: 30))
                    .foregroundColor(model.messages.isEmpty ? MyColors.accentPurple : MyColors.mainPurple)
            }
        }
    }
}

struct Message : Identifiable {
    let id: UUID
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
