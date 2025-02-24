import Foundation
import ElevenLabsSDK

class VoiceManager: ObservableObject {
    @Published var status: ElevenLabsSDK.Status = .disconnected
    @Published var messages: [String] = []
    
    private var conversation: ElevenLabsSDK.Conversation?
    private let agentId = "KWbkPdXsfnxAHYveDmOY" //original main agent lpwQ9rz6CHbfexAY8kU3
    private let userProfileManager: UserProfileManager

    init(userProfileManager: UserProfileManager) {
        self.userProfileManager = userProfileManager
    }
    
    func startConversation() {
        print("Starting conversation...")
        Task {
            do {
                let dynamicVars: [String: ElevenLabsSDK.DynamicVariableValue] = [
                    "onboarded": .string(userProfileManager.onboarded ? "Yes" : "No"),
                    "userName": .string(userProfileManager.userName),
                    "age": .number(Double(userProfileManager.age)),
                    "bodyPart": .string(userProfileManager.bodyPart),
                    "motivation": .string(userProfileManager.motivation),
                    "notificationPreference": .string(userProfileManager.notificationPreference)
                ]
                let config = ElevenLabsSDK.SessionConfig(agentId: agentId, dynamicVariables: dynamicVars)
                var callbacks = ElevenLabsSDK.Callbacks()

                // Register client tools
                var clientTools = ElevenLabsSDK.ClientTools()
                
                // Collect user information when onboarding (only once)
                clientTools.register("submit_user_info") { parameters async throws -> String? in
                    print("Received parameters: \(parameters)") // Debug log
                    guard let userName = parameters["userName"] as? String,
                          let age = parameters["age"] as? Int,
                          let bodyPart = parameters["bodyPart"] as? String,
                          let motivation = parameters["motivation"] as? String,
                          let notificationPreference = parameters["notificationPreference"] as? String else {
                        print("Parameter validation failed") // Debug log
                        print("Expected: userName (String), age (Int), bodyPart (String), motivation (String), notificationPreference (String)")
                        print("Received types: userName: \(type(of: parameters["userName"])), age: \(type(of: parameters["age"])), bodyPart: \(type(of: parameters["bodyPart"])), motivation: \(type(of: parameters["motivation"])), notificationPreference: \(type(of: parameters["notificationPreference"]))")
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
                    }
                }
                
                conversation = try await ElevenLabsSDK.Conversation.startSession(config: config, callbacks: callbacks, clientTools: clientTools) // Added clientTools parameter
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
