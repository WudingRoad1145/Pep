// import SwiftUI
// //import Lottie

// //struct LottieView: UIViewRepresentable {
// //    let name: String
// //    
// //    func makeUIView(context: Context) -> LottieAnimationView {
// //        let animationView = LottieAnimationView(name: name)
// //        animationView.loopMode = .loop
// //        animationView.contentMode = .scaleAspectFit
// //        animationView.play()
// //        return animationView
// //    }
// //    
// //    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
// //}

// struct WelcomeAnimation: View {
//     @State private var scale: CGFloat = 1.0
    
//     var body: some View {
//         Image(systemName: "hand.wave.fill")
//             .resizable()
//             .frame(width: 100, height: 100)
//             .foregroundColor(.blue)
//             .scaleEffect(scale)
//             .onAppear {
//                 withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
//                     scale = 1.2
//                 }
//             }
//     }
// }

// struct LandingView: View {
//     @StateObject private var voiceManager = VoiceManager(userProfileManager: UserProfileManager())
//     @State private var showExerciseSelection = false
//     @State private var showLottie = true
    
//     var body: some View {
//         ZStack {
//             Color.white.edgesIgnoringSafeArea(.all)
            
//             VStack {
//                 if showLottie {
//                     WelcomeAnimation()
//                         .frame(width: 300, height: 300)
// //                    LottieView(name: "greeting_dog")
// //                        .frame(width: 300, height: 300)
//                 }
                
//                 MessagesView(messages: voiceManager.messages)
                
//                 if voiceManager.status == .connected {
//                     Button("Continue to Exercises") {
//                         showExerciseSelection = true
//                     }
//                     .padding()
//                     .background(Color.blue)
//                     .foregroundColor(.white)
//                     .cornerRadius(10)
//                 }
//             }
//         }
//         .onAppear {
//             UserProfileManager().logCurrentUserProfile()
//             voiceManager.startConversation()
//             // Clear user defaults for testing onboarding
//             let defaults = UserDefaults.standard
//             if let appDomain = Bundle.main.bundleIdentifier {
//                 defaults.removePersistentDomain(forName: appDomain)
//                 defaults.synchronize()
//             }
//             UserProfileManager().logCurrentUserProfile()
//             // end of testing onboarding
//         }
//         .onDisappear {
//             voiceManager.endConversation()
//         }
//         .navigationDestination(isPresented: $showExerciseSelection) {
//             ExerciseSelectionView()
//         }
//     }
// }

// struct MessagesView: View {
//     let messages: [String]
    
//     var body: some View {
//         ScrollView {
//             VStack(alignment: .leading, spacing: 10) {
//                 ForEach(messages, id: \.self) { message in
//                     Text(message)
//                         .padding()
//                         .background(Color.gray.opacity(0.2))
//                         .cornerRadius(8)
//                         .frame(maxWidth: .infinity, alignment: .leading)
//                 }
//             }
//             .padding()
//         }
//         .frame(height: 200)
//     }
// }