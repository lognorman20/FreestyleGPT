//
//  ContentView.swift
//  LogGPT
//
//  Created by Logan Norman on 2/20/23.
//

import SwiftUI

struct ContentView: View {
    
    // get the api key from environment variable
    let apiKey = "***REMOVED***"
    
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var vm = ViewModel(api: ChatGPTAPI(apiKey: ProcessInfo.processInfo.environment["apiKey"]!))
    @FocusState var isTextFieldFocused: Bool
    
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("LogGPT")
                .fontWeight(.bold)
                .font(.largeTitle)
                .padding(.bottom)
            
            Divider()
            
            chatListView
        }
    }
    
    var chatListView: some View {
        // declaring a proxy so that the messages always come from the bottom
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                // scroll view with all of the messages
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.messages) { message in
                            MessageRowView(messageRow: message) { message in
                                Task { @MainActor in
                                    await vm.retry(message: message)
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                }
                
                Divider()
                
                bottomView(proxy: proxy)
                
                Spacer()
            }
            .onChange(of: vm.messages.last?.responseText) { _ in
                scrollToBottom(proxy: proxy)
            }
        }
        .background(colorScheme == .light ? .white : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5))
    }
    
    func bottomView(proxy: ScrollViewProxy) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image("profile")
                .resizable()
                .frame(width: 40, height: 40)
            
            TextField("What's on your mind?", text: $vm.inputMessage)
                .padding(.leading)
                .padding(.trailing)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .disabled(vm.isInteractingWithGPT)
            
            if vm.isInteractingWithGPT {
                DotLoadingView()
                    .frame(width: 60, height: 30)
            } else {
                Button {
                    Task { @MainActor in
                        isTextFieldFocused = false
                        scrollToBottom(proxy: proxy)
                        await vm.sendTapped()
                    }
                } label: {
                    Image(systemName: "paperplane.circle.fill")
                        .rotationEffect(Angle(degrees: 45))
                        .font(.system(size: 30))
                }
                .disabled(vm.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let id = vm.messages.last?.id else { return }
        proxy.scrollTo(id, anchor: .bottomTrailing)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContentView()
        }
    }
}
