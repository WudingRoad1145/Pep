import Foundation
import ElevenLabsSDK

class OnboardManager: ObservableObject {
    @Published var status: ElevenLabsSDK.Status = .disconnected
    @Published var messages: [String] = []

    private var conversation: ElevenLabsSDK.Conversation?
    private let onboardAgentId = "KWbkPdXsfnxAHYveDmOY"
    private let userProfileManager: UserProfileManager
    private let voiceManager: VoiceManager

    init(userProfileManager: UserProfileManager, voiceManager: VoiceManager) {
        self.userProfileManager = userProfileManager
        self.voiceManager = voiceManager
        DispatchQueue.global(qos: .userInitiated).async {
            self.checkOnboardingStatus()
        }
    }

    private func checkOnboardingStatus() {
        if !userProfileManager.onboarded {
            startOnboardingConversation()
        } else {
            voiceManager.startConversation()
        }
    }

    func startOnboardingConversation() {
        Task {
            do {
                let config = ElevenLabsSDK.SessionConfig(agentId: onboardAgentId)
                let callbacks = ElevenLabsSDK.Callbacks()

                conversation = try await ElevenLabsSDK.Conversation.startSession(config: config, callbacks: callbacks)
                DispatchQueue.main.async {
                    self.status = .connected
                }
            } catch {
                print("Error starting onboarding conversation: \(error)")
            }
        }
    }
    func stopOnboardingConversation() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.conversation?.endSession()
            print("VoiceManager: Successfully ended ElevenLabs session.")
        }
    }
}
