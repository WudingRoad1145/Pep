import Foundation
import ElevenLabsSDK

class OnboardManager: ObservableObject {
    @Published var status: ElevenLabsSDK.Status = .disconnected
    @Published var messages: [String] = []
    
    private var conversation: ElevenLabsSDK.Conversation?
    private let onboardAgentId = "KWbkPdXsfnxAHYveDmOY" 
    private let userProfileManager: UserProfileManager
    
    init(userProfileManager: UserProfileManager) {
        self.userProfileManager = userProfileManager
        checkOnboardingStatus()
    }
    
    private func checkOnboardingStatus() {
        if !userProfileManager.onboarded {
            startOnboardingConversation()
        } else {
            // If already onboarded, start the main voice agent
            VoiceManager.shared.startConversation()
        }
    }
    
    func startOnboardingConversation() {
        Task {
            do {
                let config = ElevenLabsSDK.SessionConfig(agentId: onboardAgentId)
                var callbacks = ElevenLabsSDK.Callbacks()
                
                // Register client tools
                var clientTools = ElevenLabsSDK.ClientTools()
                clientTools.register("submit_user_info") { parameters async throws -> String? in
                    guard let userName = parameters["UserName"] as? String,
                          let age = parameters["Age"] as? Int,
                          let bodyPart = parameters["BodyPart"] as? String,
                          let motivation = parameters["Motivation"] as? String,
                          let notificationPreference = parameters["NotificationPreference"] as? Bool else {
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
                    
                    return "User information submitted successfully."
                }
                
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
                        self?.handleOnboardingMessage(message)
                    }
                }
                
                conversation = try await ElevenLabsSDK.Conversation.startSession(config: config, callbacks: callbacks, clientTools: clientTools)
            } catch {
                print("Error starting onboarding conversation: \(error)")
            }
        }
    }
    
    private func handleOnboardingMessage(_ message: String) {
        if userProfileManager.onboarded { 
            endOnboardingConversation()
            VoiceManager.shared.startConversation()
        }
    }
    
    func endOnboardingConversation() {
        conversation?.endSession()
        conversation = nil
        status = .disconnected
    }
}
