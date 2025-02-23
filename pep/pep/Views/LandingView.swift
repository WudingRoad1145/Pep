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
    // Use StateObject for objects that should persist throughout the view's lifecycle
    @StateObject private var userProfileManager = UserProfileManager()
    @StateObject private var onboardManager: OnboardManager
    @StateObject private var voiceManager: VoiceManager
    
    // Local state
    @State private var showExerciseSelection = false
    @State private var showLottie = true
    @State private var showError = false
    @State private var errorMessage = ""
    
    // MARK: - Initialization
    init() {
        // Create managers with shared UserProfileManager
        let userProfileManager = UserProfileManager()
        let voiceManager = VoiceManager(userProfileManager: userProfileManager)
        _voiceManager = StateObject(wrappedValue: voiceManager)
        let onboardManager = OnboardManager(
            userProfileManager: userProfileManager,
            voiceManager: voiceManager
        )
        _onboardManager = StateObject(wrappedValue: onboardManager)
    }
    
    // MARK: - View Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.white.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Welcome Animation
                    if showLottie {
                        WelcomeAnimation()
                            .frame(width: 300, height: 300)
                    }
                    
                    // Message Display
                    MessagesView(messages: userProfileManager.onboarded ?
                               voiceManager.messages : onboardManager.messages)
                        .animation(.easeInOut, value: userProfileManager.onboarded)
                    
                    // Navigation Button
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
        if userProfileManager.onboarded {
            return voiceManager.status == .connected
        } else {
            return onboardManager.status == .connected
        }
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
        if userProfileManager.onboarded {
            voiceManager.startConversation()
        } else {
            onboardManager.startOnboardingConversation()
        }
    }
    
    private func endCurrentConversation() {
        if userProfileManager.onboarded {
            voiceManager.endConversation()
        } else {
            onboardManager.endOnboardingConversation()
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

