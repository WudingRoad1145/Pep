import SwiftUI

// MARK: - Exercise Type Enum
enum ExerciseType: String, Identifiable {
    case fingerSpreads = "Finger Spreads"
    case mobilityTouches = "Mobility Touches"
    case fistMaking = "Make a Fist"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .fingerSpreads:
            return "Best Match - Spread your fingers wide to improve flexibility"
        case .mobilityTouches:
            return "Progression - Touch each finger to your thumb"
        case .fistMaking:
            return "Regression - Gently make a fist"
        }
    }
    
    var difficulty: String {
        switch self {
        case .fingerSpreads: return "Best Match"
        case .mobilityTouches: return "Progression"
        case .fistMaking: return "Regression"
        }
    }
}

// MARK: - Exercise Selection View
struct ExerciseSelectionView: View {
    let exercises = [
        ExerciseType.fingerSpreads,
        ExerciseType.mobilityTouches,
        ExerciseType.fistMaking
    ]
    
    let userProfileManager: UserProfileManager
    @State private var selectedExercise: ExerciseType?
    @State private var showExercise = false
    
    init(userProfileManager: UserProfileManager) {
        self.userProfileManager = userProfileManager
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Your Exercise")
                .font(.title)
                .bold()
                .padding(.top, 40)
            
            Text("Select the exercise that matches your comfort level")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(exercises) { exercise in
                        ExerciseCard(exercise: exercise) {
                            selectedExercise = exercise
                            showExercise = true
                        }
                    }
                }
                .padding()
            }
        }
        .navigationDestination(isPresented: $showExercise) {
            if let exercise = selectedExercise {
                ExerciseView(
                    exerciseType: exercise,
                    userProfileManager: userProfileManager
                )
            }
        }
    }
}

// MARK: - Exercise Card View
struct ExerciseCard: View {
    let exercise: ExerciseType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(exercise.rawValue)
                        .font(.headline)
                    Spacer()
                    Text(exercise.difficulty)
                        .font(.subheadline)
                        .foregroundColor(difficultyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(difficultyColor.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Text(exercise.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var difficultyColor: Color {
        switch exercise {
        case .fingerSpreads: return .blue
        case .mobilityTouches: return .green
        case .fistMaking: return .orange
        }
    }
}
