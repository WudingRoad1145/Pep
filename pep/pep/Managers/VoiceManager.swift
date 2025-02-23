import Foundation
import ElevenLabsSDK

class VoiceManager: ObservableObject {
    static let shared = VoiceManager()
    
    private init() {
        // Private initialization to ensure just one instance is created.
    }
    
    @Published var status: ElevenLabsSDK.Status = .disconnected
    @Published var messages: [String] = []
    
    private var conversation: ElevenLabsSDK.Conversation?
    private let agentId = "lpwQ9rz6CHbfexAY8kU3"
    private let userProfileManager: UserProfileManager
    
    init(userProfileManager: UserProfileManager) {
        self.userProfileManager = userProfileManager
    }
    
    func startConversation() {
        Task {
            do {
                let dynamicVars = [
                    "userName": .string(userProfileManager.userName),
                    "age": .number(userProfileManager.age),
                    "bodyPart": .string(userProfileManager.bodyPart),
                    "motivation": .string(userProfileManager.motivation),
                    "notificationPreference": .string(userProfileManager.notificationPreference)
                ]
                
                let config = ElevenLabsSDK.SessionConfig(
                    agentId: agentId,
                    dynamicVariables: dynamicVars
                )
                
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
