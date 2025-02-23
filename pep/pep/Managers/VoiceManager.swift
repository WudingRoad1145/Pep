import Foundation
import ElevenLabsSDK

class VoiceManager: ObservableObject {
    @Published var status: ElevenLabsSDK.Status = .disconnected
    @Published var messages: [String] = []
    
    private var conversation: ElevenLabsSDK.Conversation?
    private let agentId = "lpwQ9rz6CHbfexAY8kU3"
    
    func startConversation() {
        Task {
            do {
                let config = ElevenLabsSDK.SessionConfig(agentId: agentId)
                var callbacks = ElevenLabsSDK.Callbacks()
                
                callbacks.onConnect = { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.status = .connected
                    }
                }
                
                callbacks.onDisconnect = { [weak self] in
                    DispatchQueue.main.async {
                        self?.status = .disconnected
                        self?.messages.removeAll()
                    }
                }
                
                callbacks.onMessage = { [weak self] message, _ in
                    DispatchQueue.main.async {
                        self?.messages.append(message)
                    }
                }
                
                conversation = try await ElevenLabsSDK.Conversation.startSession(config: config, callbacks: callbacks)
            } catch {
                print("Error starting conversation: \(error)")
            }
        }
    }
    
    func endConversation() {
        conversation?.endSession()
        conversation = nil
        status = .disconnected
    }
    
    func toggleConversation() {
        if status == .connected {
            endConversation()
        } else {
            startConversation()
        }
    }
}
