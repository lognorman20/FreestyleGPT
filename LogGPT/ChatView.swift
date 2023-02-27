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
    @State var isModal: Bool = false
    @State var scrollProxy: ScrollViewProxy?
    @StateObject var model: ModelView = ModelView(apiKey: ProcessInfo.processInfo.environment["apiKey"]!)
    @ObservedObject var allMsgs = Messages()
    @FocusState var isTextFieldFocused: Bool
    
    let synthesizer = AVSpeechSynthesizer()

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
                        parseMessage(msg: model.messages.last!)
                    }
                    .onChange(of: model.messages.last?.content) { _ in
                        if (!model.messages.isEmpty) {
                            parseMessage(msg: model.messages.last!)
                            withAnimation(Animation.easeInOut(duration: 1)) {
                                guard let id = model.messages.last?.id else { return }
                                proxy.scrollTo(id, anchor: .bottomTrailing)
                            }
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
    
    func parseMessage(msg: Message) {
        self.allMsgs.addMsg(text: msg.content)
        self.allMsgs.addMsg(text: msg.response)
    }
    
    var topView: some View {
        HStack(alignment: .center) {
            
            // button to clear the messages
            Button {
                withAnimation(.easeInOut) {
                    model.clear()
                    self.allMsgs.clear()
                }
            } label: {
                Image(systemName: "arrow.uturn.forward.circle")
                    .padding()
                    .font(.system(size: 30))
                    .foregroundColor(model.messages.isEmpty ? MyColors.accentPurple : MyColors.mainPurple)
            }
            .disabled(model.messages.isEmpty)
            
            Spacer()
            
            // title text
            VStack(spacing: 0) {
                Text("FreestyleGPT")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("deeppurple"))
                
                Text("@zklogno")
                    .font(.footnote)
            }
            
            Spacer()
            
            // button to play the text aloud
            Button {
                if (!model.messages.isEmpty) {
                    self.isModal = true
                }
            } label: {
                Image(systemName: "play.circle")
                    .padding()
                    .font(.system(size: 30))
                    .foregroundColor(!model.messages.isEmpty ? MyColors.mainPurple : MyColors.accentPurple)
            }
            .sheet(isPresented: self.$isModal, content: {
                speakView
            })
            .disabled(model.messages.isEmpty)
        }
    }
    
    // TODO: Build out UI for modal view
    var speakView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .center, spacing: 3) {
                    ForEach(self.allMsgs.data, id: \.id) { msg in
                        Text(msg.text)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .font(.title)
                            .fixedSize(horizontal: false, vertical: true)
                            .fontWeight(.bold)
                            .padding()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MyColors.mainPurple)
    }
}

class Messages : ObservableObject {
    @Published var data: [ReadableMessage] = []
    
    func addMsg(text: String) {
        let newMsg: ReadableMessage = ReadableMessage(id: UUID(), text: text, isSelected: false)
        data.append(newMsg)
    }
    
    func clear() {
        self.data.removeAll()
    }
}

class ReadableMessage : ObservableObject {
    let id: UUID
    let text: String
    @Published var isSelected: Bool
    
    init(id: UUID, text: String, isSelected: Bool) {
        self.id = id
        self.text = text
        self.isSelected = isSelected
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
