import SwiftUI
import ElevenLabsSDK
import _Concurrency

struct ContentView: View {
    @State private var conversation: ElevenLabsSDK.Conversation?
    @State private var status: ElevenLabsSDK.Status = .disconnected
    
    let agentId = "lpwQ9rz6CHbfexAY8kU3"
    
    private func toggleConversation() {
        if status == .connected {
            conversation?.endSession()
            conversation = nil
            status = .disconnected
        } else {
            Task {
                do {
                    let config = ElevenLabsSDK.SessionConfig(agentId: agentId)
                    var callbacks = ElevenLabsSDK.Callbacks()
                    
                    callbacks.onConnect = { _ in
                        DispatchQueue.main.async {
                            status = .connected
                        }
                    }
                    callbacks.onDisconnect = {
                        DispatchQueue.main.async {
                            status = .disconnected
                        }
                    }
                    
                    conversation = try await ElevenLabsSDK.Conversation.startSession(config: config, callbacks: callbacks)
                } catch {
                    print("Error starting conversation: \(error)")
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            Text(status == .connected ? "Connected to Agent" : "Disconnected")
                .font(.title)
                .padding()
            
            Button(action: toggleConversation) {
                Text(status == .connected ? "End Conversation" : "Start Conversation")
                    .padding()
                    .background(status == .connected ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}
