import Foundation
import ElevenLabsSDK
import AVFoundation

class VoiceManager: ObservableObject {
    @Published var status: ElevenLabsSDK.Status = .disconnected
    @Published var messages: [String] = []
    @Published var connectionError: String?

    private var conversation: ElevenLabsSDK.Conversation?
    private let userProfileManager: UserProfileManager
    
    private let onboardingAgentId = "KWbkPdXsfnxAHYveDmOY"
    private let exerciseAgentId = "lpwQ9rz6CHbfexAY8kU3"
    
    private var currentAgentId: String
    
    init(userProfileManager: UserProfileManager, isOnboarding: Bool = true) {
        self.userProfileManager = userProfileManager
        self.currentAgentId = isOnboarding ? onboardingAgentId : exerciseAgentId
    }
    
    /// Starts the conversation using the selected agent (either onboarding or exercise).
    func startConversation() {
        print("VoiceManager: 🎤 Starting conversation with agent \(currentAgentId)...")
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.ensureAudioSession()
            
            Task {
                do {
                    let config = self.createSessionConfig()
                    var callbacks = self.createCallbacks()
                    
                    self.conversation = try await ElevenLabsSDK.Conversation.startSession(config: config, callbacks: callbacks)

                    DispatchQueue.main.async {
                        self.status = .connected
                        print("VoiceManager: ✅ ElevenLabs session started!")
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.connectionError = "Error starting conversation: \(error.localizedDescription)"
                        print("VoiceManager: ❌ Error starting conversation: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Ends the conversation and cleans up the session.
    func endConversation() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.conversation?.endSession()
            self.conversation = nil
            
            DispatchQueue.main.async {
                self.status = .disconnected
                print("VoiceManager: 🔇 Conversation ended.")
            }
        }
    }
    
    /// Toggles conversation based on current status.
    func toggleConversation() {
        if status == .connected {
            endConversation()
        } else {
            startConversation()
        }
    }
    
    /// Ensures the AVAudioSession is configured properly.
    private func ensureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .videoRecording, options: [.allowBluetooth, .defaultToSpeaker, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("VoiceManager: 🎧 Audio session configured successfully.")
        } catch {
            print("VoiceManager: ❌ Failed to activate audio session: \(error.localizedDescription)")
        }
    }
    
    /// Creates a session configuration with the necessary dynamic variables.
    private func createSessionConfig() -> ElevenLabsSDK.SessionConfig {
        let dynamicVars: [String: ElevenLabsSDK.DynamicVariableValue] = [
            "onboarded": .string(userProfileManager.onboarded ? "Yes" : "No"),
            "userName": .string(userProfileManager.userName),
            "age": .number(Double(userProfileManager.age)),
            "bodyPart": .string(userProfileManager.bodyPart),
            "motivation": .string(userProfileManager.motivation),
            "notificationPreference": .string(userProfileManager.notificationPreference)
        ]
        
        return ElevenLabsSDK.SessionConfig(agentId: currentAgentId, dynamicVariables: dynamicVars)
    }
    
    /// Creates callbacks for handling session events.
    private func createCallbacks() -> ElevenLabsSDK.Callbacks {
        var callbacks = ElevenLabsSDK.Callbacks()
        
        callbacks.onConnect = { [weak self] _ in
            DispatchQueue.main.async {
                self?.status = .connected
                print("VoiceManager: 🟢 Connected to ElevenLabs.")
            }
        }
        
        callbacks.onDisconnect = { [weak self] in
            DispatchQueue.main.async {
                self?.status = .disconnected
                self?.messages.removeAll()
                print("VoiceManager: 🔴 Disconnected from ElevenLabs.")
            }
        }
        
        callbacks.onMessage = { [weak self] message, _ in
            DispatchQueue.main.async {
                self?.messages.append(message)
                print("VoiceManager: 💬 Received message: \(message)")
            }
        }
        
        return callbacks
    }
}
