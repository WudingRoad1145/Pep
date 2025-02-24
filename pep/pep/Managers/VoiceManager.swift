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
    private let exerciseAgentId = "rbkAQk5LuZYk3NeXlcGK" // "lpwQ9rz6CHbfexAY8kU3"
    
    private var currentAgentId: String
    
    init(userProfileManager: UserProfileManager) {
        self.userProfileManager = userProfileManager
        self.currentAgentId = userProfileManager.onboarded ? exerciseAgentId : onboardingAgentId
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
                    var clientTools = self.createClientTools()
                    
                    self.conversation = try await ElevenLabsSDK.Conversation.startSession(config: config, callbacks: callbacks, clientTools: clientTools)

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

    private func createClientTools() -> ElevenLabsSDK.ClientTools {
        var clientTools = ElevenLabsSDK.ClientTools()
        
        // Collect user information when onboarding (only once)
        clientTools.register("submit_user_info") { [weak self] parameters async throws -> String? in
            guard let self = self else { return nil }
            
            print("VoiceManager: 📝 Received parameters: \(parameters)")
            
            guard let userName = parameters["userName"] as? String,
                  let age = parameters["age"] as? Int,
                  let bodyPart = parameters["bodyPart"] as? String,
                  let motivation = parameters["motivation"] as? String,
                  let notificationPreference = parameters["notificationPreference"] as? String else {
                print("VoiceManager: ❌ Parameter validation failed")
                print("VoiceManager: Expected: userName (String), age (Int), bodyPart (String), motivation (String), notificationPreference (String)")
                print("VoiceManager: Received types: userName: \(type(of: parameters["userName"])), age: \(type(of: parameters["age"])), bodyPart: \(type(of: parameters["bodyPart"])), motivation: \(type(of: parameters["motivation"])), notificationPreference: \(type(of: parameters["notificationPreference"]))")
                throw ElevenLabsSDK.ClientToolError.invalidParameters
            }
            // Update UserProfileManager with the provided information
            self.userProfileManager.userName = userName
            self.userProfileManager.age = age
            self.userProfileManager.bodyPart = bodyPart
            self.userProfileManager.motivation = motivation
            self.userProfileManager.notificationPreference = notificationPreference
            // Set onboarded to true
            self.userProfileManager.onboarded = true
            self.userProfileManager.logCurrentUserProfile()
            return "VoiceManager: 🧑 User information updated successfully"
        }
        
        return clientTools
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
