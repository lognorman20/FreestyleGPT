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
                    let stream = try await api.sendMessageStream(text: "Why is Lebron James the best basketball player of all time?")
                    for try await line in stream {
                        print(line)
                    }
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
