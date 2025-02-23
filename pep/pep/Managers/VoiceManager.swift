import Foundation
import ElevenLabsSDK
import AVFoundation

class VoiceManager: ObservableObject {
    @Published var status: ElevenLabsSDK.Status = .disconnected
    @Published var messages: [String] = []
    @Published var connectionError: String?
    
    private var conversation: ElevenLabsSDK.Conversation?
    private let agentId = "lpwQ9rz6CHbfexAY8kU3"
    private let userProfileManager: UserProfileManager
    
    init(userProfileManager: UserProfileManager) {
        print("VoiceManager: Initializing...")
        self.userProfileManager = userProfileManager
        setupAudio()
    }
    
    private func setupAudio() {
        print("VoiceManager: Setting up audio session...")
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord,
                                       mode: .default,
                                       options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("VoiceManager: Audio session configured successfully")
        } catch {
            print("VoiceManager: Failed to configure audio session: \(error)")
            connectionError = "Audio setup failed: \(error.localizedDescription)"
        }
    }
    
    func startConversation() {
        print("VoiceManager: Starting conversation...")
        Task {
            do {
                print("VoiceManager: Creating session config with agentId: \(agentId)")
                let dynamicVars: [String: ElevenLabsSDK.DynamicVariableValue] = [
                    "userName": .string(userProfileManager.userName),
                    "age": .int(userProfileManager.age),
                    "bodyPart": .string(userProfileManager.bodyPart),
                    "motivation": .string(userProfileManager.motivation),
                    "notificationPreference": .boolean(userProfileManager.notificationPreference)
                ]
                print("VoiceManager: Dynamic variables prepared: \(dynamicVars)")
                
                let config = ElevenLabsSDK.SessionConfig(
                    agentId: agentId,
                    dynamicVariables: dynamicVars
                )
                
                var callbacks = ElevenLabsSDK.Callbacks()
                
                callbacks.onConnect = { [weak self] _ in
                    print("VoiceManager: Connected to ElevenLabs")
                    DispatchQueue.main.async {
                        self?.status = .connected
                        self?.connectionError = nil
                    }
                }
                
                callbacks.onDisconnect = { [weak self] in
                    print("VoiceManager: Disconnected from ElevenLabs")
                    DispatchQueue.main.async {
                        self?.status = .disconnected
                        self?.messages.removeAll()
                    }
                }
                
                callbacks.onMessage = { [weak self] message, _ in
                    print("VoiceManager: Received message: \(message)")
                    DispatchQueue.main.async {
                        self?.messages.append(message)
                    }
                }
                
                print("VoiceManager: Attempting to start session...")
                conversation = try await ElevenLabsSDK.Conversation.startSession(
                    config: config,
                    callbacks: callbacks
                )
                
                if conversation != nil {
                    print("VoiceManager: Session started successfully")
                } else {
                    print("VoiceManager: Session creation failed - conversation is nil")
                    connectionError = "Failed to create conversation session"
                }
                
            } catch {
                print("VoiceManager: Error starting conversation: \(error)")
                DispatchQueue.main.async {
                    self.connectionError = "Connection error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func endConversation() {
        print("VoiceManager: Ending conversation...")
        conversation?.endSession()
        conversation = nil
        status = .disconnected
        print("VoiceManager: Conversation ended")
    }
    
    // Optional: Add method to check audio session status
    private func checkAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        print("VoiceManager: Audio Session status:")
        print("- Category: \(audioSession.category)")
        print("- Mode: \(audioSession.mode)")
        print("- Is Active: \(audioSession.isOtherAudioPlaying)")
        print("- Sample Rate: \(audioSession.sampleRate)")
        print("- IO Buffer Duration: \(audioSession.ioBufferDuration)")
    }
}
