import SwiftUI

struct LandingView: View {
    // MARK: - State Objects and Dependencies
    @StateObject private var userProfileManager = UserProfileManager()
    @StateObject private var voiceManager: VoiceManager
    
    // Local state
    @State private var showExerciseSelection = false
    @State private var showLottie = true
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: - Initialization
    init() {
        let userProfileManager = UserProfileManager()
        let voiceManager = VoiceManager(userProfileManager: userProfileManager, isOnboarding: true)
        
        _voiceManager = StateObject(wrappedValue: voiceManager)
        _userProfileManager = StateObject(wrappedValue: userProfileManager)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Text("Welcome to Pep!")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 40)

                    Text("Your AI-powered exercise coach.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    
                    // Show messages from the VoiceManager
                    MessagesView(messages: voiceManager.messages)
                        .padding()

                    // Button to continue to exercise selection
                    Button(action: {
                        completeOnboarding()
                    }) {
                        Text("Continue to Exercises")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 50)
                }
            }
            .onAppear {
                startOnboardingConversation()
            }
            .onDisappear {
                endOnboardingConversation()
            }
            .navigationDestination(isPresented: $showExerciseSelection) {
                ExerciseSelectionView(userProfileManager: userProfileManager)
            }
        }
    }
    
    // MARK: - Conversation Handling

    /// Starts onboarding conversation
    private func startOnboardingConversation() {
        DispatchQueue.global(qos: .userInitiated).async {
            voiceManager.startConversation()
        }
    }

    /// Ends onboarding and switches to exercise agent
    private func endOnboardingConversation() {
        DispatchQueue.global(qos: .userInitiated).async {
            voiceManager.endConversation()
        }
    }
    
    /// Completes onboarding and transitions to exercise agent
    private func completeOnboarding() {
        userProfileManager.onboarded = true
        showExerciseSelection = true
    }
}

// MARK: - Supporting Views
struct MessagesView: View {
    let messages: [String]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(messages, id: \.self) { message in
                    Text(message)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
            }
        }
    }
}
