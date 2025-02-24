import SwiftUI
import ElevenLabsSDK

// Simple animation for welcome screen
struct WelcomeAnimation: View {
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Image(systemName: "hand.wave.fill")
            .resizable()
            .frame(width: 100, height: 100)
            .foregroundColor(.blue)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                    scale = 1.2
                }
            }
    }
}

// Main Landing View
struct LandingView: View {
    // MARK: - State Objects and Dependencies
    @StateObject private var userProfileManager = UserProfileManager()
    @StateObject private var voiceManager: VoiceManager
    @StateObject private var onboardManager: OnboardManager
    
    // Local state
    @State private var showExerciseSelection = false
    @State private var showLottie = true
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: - Initialization
    init() {
        let userProfileManager = UserProfileManager()
        let voiceManager = VoiceManager()
        let onboardManager = OnboardManager(userProfileManager: userProfileManager, voiceManager: voiceManager)
        
        _voiceManager = StateObject(wrappedValue: voiceManager)
        _onboardManager = StateObject(wrappedValue: onboardManager)
    }
    
    // MARK: - View Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    if showLottie {
                        WelcomeAnimation()
                            .frame(width: 300, height: 300)
                    }

                    MessagesView(messages: userProfileManager.onboarded ?
                        voiceManager.messages : onboardManager.messages)
                        .animation(.easeInOut, value: userProfileManager.onboarded)

                    if shouldShowContinueButton {
                        continueButton
                    }
                }
                .padding()
            }
        }
        .onAppear(perform: startAppropriateConversation)
        .onDisappear(perform: endCurrentConversation)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Computed Properties
    private var shouldShowContinueButton: Bool {
        userProfileManager.onboarded ? voiceManager.status == .connected : onboardManager.status == .connected
    }

    // MARK: - UI Components
    private var continueButton: some View {
        Button(action: {
            showExerciseSelection = true
        }) {
            Text("Continue to Exercises")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
        }
        .navigationDestination(isPresented: $showExerciseSelection) {
            ExerciseSelectionView(userProfileManager: userProfileManager)
        }
    }

    // MARK: - Helper Methods
    private func startAppropriateConversation() {
        DispatchQueue.global(qos: .userInitiated).async {
            if userProfileManager.onboarded {
                voiceManager.startConversation()
            } else {
                onboardManager.startOnboardingConversation()
            }
        }
    }

    private func endCurrentConversation() {
        DispatchQueue.global(qos: .userInitiated).async {
            if userProfileManager.onboarded {
                voiceManager.stopConversation()
            } else {
                onboardManager.stopOnboardingConversation()
            }
        }
    }
}

// MARK: - Supporting Views
struct MessagesView: View {
    let messages: [String]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(messages, id: \.self) { message in
                    MessageBubble(message: message)
                }
            }
            .padding()
        }
        .frame(height: 200)
    }
}

struct MessageBubble: View {
    let message: String
    
    var body: some View {
        Text(message)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
