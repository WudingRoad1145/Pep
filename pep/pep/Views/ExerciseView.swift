import SwiftUI
import Vision
import AVFoundation

struct ExerciseView: View {
    let exerciseType: ExerciseType
    @StateObject private var voiceManager = VoiceManager()
    @StateObject private var exerciseManager = ExerciseManager()
    @State private var showReport = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera Layer
                CameraView(session: exerciseManager.session)
                    .ignoresSafeArea()
                
                // Hand Pose Layer
                HandPoseView(points: exerciseManager.handPosePoints)
                    .ignoresSafeArea()
                
                // Messages Overlay
                VStack {
                    Spacer()
                    
                    // Messages
                    ScrollView {
                        ForEach(voiceManager.messages, id: \.self) { message in
                            Text(message)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(15)
                                .padding(.horizontal)
                        }
                    }
                    .frame(maxHeight: 200)
                    
                    // Complete Exercise Button
                    Button(action: {
                        showReport = true
                    }) {
                        Text("Complete Exercise")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            exerciseManager.startSession()
            voiceManager.startConversation()
        }
        .onDisappear {
            exerciseManager.stopSession()
            voiceManager.endConversation()
        }
        .fullScreenCover(isPresented: $showReport) {
            ExerciseReportView()
        }
    }
}

// Camera Preview
struct CameraView: UIViewRepresentable {
    let session: AVCaptureSession
    
    class PreviewView: UIView {
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        var previewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.frame = uiView.frame
    }
}

// Hand Pose Visualization
struct HandPoseView: View {
    let points: [CGPoint]
    
    var body: some View {
        GeometryReader { geometry in
            if !points.isEmpty {
                ZStack {
                    // Draw lines
                    Path { path in
                        drawHandSkeleton(path: &path, points: points)
                    }
                    .stroke(Color.yellow, lineWidth: 3)
                    
                    // Draw points
                    ForEach(0..<points.count, id: \.self) { index in
                        Circle()
                            .fill(Color.green)
                            .frame(width: 15, height: 15)
                            .position(points[index])
                    }
                }
            }
        }
    }
    
    private func drawHandSkeleton(path: inout Path, points: [CGPoint]) {
        // Constants for finger indices
        let thumbIndices = 0...3
        let indexIndices = 4...7
        let middleIndices = 8...11
        let ringIndices = 12...15
        let pinkyIndices = 16...19
        
        let fingerRanges = [thumbIndices, indexIndices, middleIndices, ringIndices, pinkyIndices]
        
        for range in fingerRanges {
            if points.count > range.upperBound {
                path.move(to: points[range.lowerBound])
                for i in (range.lowerBound + 1)...range.upperBound {
                    path.addLine(to: points[i])
                }
            }
        }
        
        // Connect finger bases to wrist
        if points.count >= 21 {
            let wristPoint = points[20]
            let baseIndices = [3, 7, 11, 15, 19]
            for baseIndex in baseIndices {
                if points.count > baseIndex {
                    path.move(to: wristPoint)
                    path.addLine(to: points[baseIndex])
                }
            }
        }
    }
}
