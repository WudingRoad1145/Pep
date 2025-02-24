import Foundation
import ElevenLabsSDK
import AVFoundation

class VoiceManager: ObservableObject {
    @Published var status: ElevenLabsSDK.Status = .disconnected
    @Published var messages: [String] = []
    @Published var connectionError: String?

    var conversation: ElevenLabsSDK.Conversation?
    private let agentId = "lpwQ9rz6CHbfexAY8kU3"

    func startConversation() {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.5) {
            self.ensureAudioSession()
            Task {
                do {
                    let config = ElevenLabsSDK.SessionConfig(agentId: self.agentId)
                    let callbacks = ElevenLabsSDK.Callbacks()

                    self.conversation = try await ElevenLabsSDK.Conversation.startSession(config: config, callbacks: callbacks)

                    DispatchQueue.main.async {
                        self.status = .connected
                    }
                } catch {
                    print("VoiceManager: ❌ Error starting conversation: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func stopConversation() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.conversation?.endSession()
            print("VoiceManager: Successfully ended ElevenLabs session.")
        }
    }

    private func ensureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .videoRecording, options: [.allowBluetooth, .defaultToSpeaker, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("VoiceManager: ❌ Failed to activate audio session: \(error.localizedDescription)")
        }
    }
}
