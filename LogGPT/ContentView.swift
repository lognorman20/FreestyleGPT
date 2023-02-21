//
//  ContentView.swift
//  LogGPT
//
//  Created by Logan Norman on 2/20/23.
//

import SwiftUI

struct ContentView: View {
    
    let apiKey = ProcessInfo.processInfo.environment["apiKey"]
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            Task {
                let api = ChatGPTAPI(apiKey: apiKey!)
                do {
                    // speedy way
                    let text1 = "Who is Lebron?"
                    let text2 = "How many championships has he won?"
//                    let stream = try await api.sendMessageStream(text: text)
//                    for try await line in stream {
//                        print(line)
//                    }
                    
                    // slow way
                    let response1 = try await api.sendMessage(text1)
                    print(response1)
                    
                    let response2 = try await api.sendMessage(text2)
                    print(response2)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
