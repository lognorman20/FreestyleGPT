//
//  MessageRow.swift
//  LogGPT
//
//  Created by Logan Norman on 2/20/23.
//

import SwiftUI

struct MessageRow : Identifiable {
    
    let id = UUID()
    var isInteractingWithChatGPT: Bool
    let sendImage: String
    let sendText: String
    
    let responseImage: String
    var responseText: String
    
    var responseError: String?
}
