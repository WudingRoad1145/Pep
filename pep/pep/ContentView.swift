import SwiftUI
import ElevenLabsSDK
import _Concurrency

struct ContentView: View {
    @State private var conversation: ElevenLabsSDK.Conversation?
    @State private var status: ElevenLabsSDK.Status = .disconnected
    @State private var receivedMessages: [String] = []
    
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
                            receivedMessages.removeAll()
                        }
                    }
                    
                    callbacks.onMessage = { message, _ in
                        DispatchQueue.main.async {
                            receivedMessages.append(message)  // Stream messages in real-time
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
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(receivedMessages, id: \.self) { message in
                        Text(message)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(height: 300) // Adjust height as needed
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
