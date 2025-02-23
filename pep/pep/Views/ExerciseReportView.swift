import SwiftUI
//import Lottie

struct ExerciseReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingCongrats = true
    
    let date = Date()
    let duration: TimeInterval
    
    init(duration: TimeInterval = 30) {
        self.duration = duration
    }
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.title2)
                        }
                    }
                    .padding(.bottom)
                    
                    HeaderSection(date: date)
                    
                    FeedbackSection(title: "General Feeling",
                                  content: "Better than before, feeling fingers more flexible and can do exercise without pain.")
                    
                    FeedbackSection(title: "Tension Level",
                                  content: "MRC: scale 4/5 - still feeling tension in pinky but with good range of motion.")
                    
                    FeedbackSection(title: "Pain Report",
                                  content: "No more pain in daily activities. No more pain during exercise.")
                    
                    ExerciseStats(duration: duration,
                                completed: true)
                    
                    ProgressBoardSection(dayStreak: 4)
                    
                    MotivationalMessageSection()
                    
                    GeneratePTReportButton()
                }
                .padding()
            }
            
            if showingCongrats {
                CongratulationsOverlay {
                    withAnimation {
                        showingCongrats = false
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct HeaderSection: View {
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Exercise Report")
                .font(.title)
                .bold()
            Text(date.formatted())
                .foregroundColor(.secondary)
        }
    }
}

struct FeedbackSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            Text(content)
                .padding(.vertical, 5)
            Divider()
        }
    }
}

struct ExerciseStats: View {
    let duration: TimeInterval
    let completed: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Exercise Statistics")
                .font(.headline)
            Text("Duration: \(Int(duration)) seconds")
            Text("Completion: \(completed ? "Completed" : "Partial")")
            Divider()
        }
    }
}

struct ProgressBoardSection: View {
    let dayStreak: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Progress Board")
                .font(.headline)
            
            HStack {
                VStack {
                    Text("\(dayStreak)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Day Streak")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Image(systemName: "flame.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundColor(.orange)
                    Text("Consistency")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("🏔️")
                        .font(.largeTitle)
                    Text("Goal Tracking")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            Divider()
        }
    }
}

struct MotivationalMessageSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Motivation")
                .font(.headline)
            Text("Great progress! You are one step closer to recovering from RSI and getting back to technical mountain climbing! Hey, mountains are always there for you.")
                .foregroundColor(.secondary)
                .italic()
            Divider()
        }
    }
}

struct GeneratePTReportButton: View {
    @State private var showingPTReportAlert = false
    
    var body: some View {
        Button(action: {
            showingPTReportAlert = true
        }) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                Text("Generate PT Visit Report")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            .foregroundColor(.blue)
        }
        .alert(isPresented: $showingPTReportAlert) {
            Alert(
                title: Text("Generate PT Report"),
                message: Text("This feature will generate a comprehensive report for your Physical Therapist. Would you like to proceed?"),
                primaryButton: .default(Text("Generate")) {
                    // TODO: Implement report generation logic
                    print("Generating PT Report")
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct CongratulationsOverlay: View {
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                WelcomeAnimation()
                    .frame(width: 300, height: 300)
//                LottieView(name: "greeting_dog")
//                    .frame(width: 200, height: 200)
                
                Text("Fantastic Work!")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                onComplete()
            }
        }
    }
}


