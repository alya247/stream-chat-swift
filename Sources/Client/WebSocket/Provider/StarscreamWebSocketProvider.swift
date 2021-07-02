//
//  StarscreamWebSocketProvider.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 30/04/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import Starscream

final class StarscreamWebSocketProvider: WebSocketProvider {
    private let webSocket: Starscream.WebSocket
    
    var request: URLRequest {
        get { webSocket.request }
        set {
            disconnect()
            webSocket.request = newValue
        }
    }
    
    private(set) var isConnected = false
    var callbackQueue: DispatchQueue { webSocket.callbackQueue }
    weak var delegate: WebSocketProviderDelegate?
    
    init(request: URLRequest, callbackQueue: DispatchQueue) {
        webSocket = Starscream.WebSocket(request: request)
        webSocket.delegate = self
        webSocket.callbackQueue = callbackQueue
    }
    
    func connect() {
        webSocket.connect()
    }
    
    func disconnect() {
        webSocket.disconnect()
    }
    
    func sendPing() {
        webSocket.write(ping: .empty)
    }
}

extension StarscreamWebSocketProvider: Starscream.WebSocketDelegate {
    
    func websocketDidConnect(socket: WebSocketClient) {
        didConnect()
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        var webSocketProviderError: WebSocketProviderError?

        if let error = error {
            webSocketProviderError = .init(reason: error.localizedDescription,
                                           code: (error as? WSError)?.code ?? 0,
                                           providerType: StarscreamWebSocketProvider.self,
                                           providerError: error)
        }
        
        didDisconnect(error: webSocketProviderError)
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        delegate?.websocketDidReceiveMessage(text)
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) { }
    
    private func didConnect() {
        isConnected = true
        delegate?.websocketDidConnect()
    }
    
    private func didDisconnect(error: WebSocketProviderError?) {
        isConnected = false
        delegate?.websocketDidDisconnect(error: error)
    }
    
}
