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
                
                // Hand Pose Visualization Layer
                if !exerciseManager.handPosePoints.isEmpty {
                    ZStack {
                        // Draw skeleton connections
                        Path { path in
                            drawHandSkeleton(path: &path, points: exerciseManager.handPosePoints, in: geometry)
                        }
                        .stroke(Color.yellow, lineWidth: 3)
                        
                        // Draw joint points
                        ForEach(0..<exerciseManager.handPosePoints.count, id: \.self) { index in
                            Circle()
                                .fill(Color.green)
                                .frame(width: 15, height: 15)
                                .position(convertPoint(exerciseManager.handPosePoints[index], in: geometry))
                        }
                    }
                    .ignoresSafeArea()
                }
                
                // Messages Overlay
                VStack {
                    Spacer()
                    
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
            print("🚀 Starting ExerciseManager and VoiceManager concurrently...")
            
            DispatchQueue.global(qos: .userInitiated).async {
                exerciseManager.startSession()
            }

            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.5) {
                print("🎙 Starting VoiceManager...")
                voiceManager.startConversation()
            }
        }
        .onDisappear {
            exerciseManager.stopSession()
        }
        .fullScreenCover(isPresented: $showReport) {
            ExerciseReportView()
        }
    }
    
    // ✅ Convert Vision coordinates to SwiftUI coordinates
    private func convertPoint(_ point: CGPoint, in geometry: GeometryProxy) -> CGPoint {
        let transformedX = point.x * geometry.size.width
        let transformedY = (1 - point.y) * geometry.size.height  // Adjusted for correct orientation
        return CGPoint(x: transformedX, y: transformedY)
    }

    // ✅ Draw hand skeleton with correctly mapped coordinates
    private func drawHandSkeleton(path: inout Path, points: [CGPoint], in geometry: GeometryProxy) {
        let fingerIndices = [
            [0, 1, 2, 3],    // Thumb
            [4, 5, 6, 7],    // Index
            [8, 9, 10, 11],  // Middle
            [12, 13, 14, 15], // Ring
            [16, 17, 18, 19]  // Pinky
        ]

        for indices in fingerIndices {
            if points.count > indices.last! {
                path.move(to: convertPoint(points[indices.first!], in: geometry))
                for i in indices {
                    path.addLine(to: convertPoint(points[i], in: geometry))
                }
            }
        }

        if points.count >= 21 {
            let wrist = convertPoint(points[20], in: geometry)
            let bases = [3, 7, 11, 15, 19]

            for base in bases {
                if points.count > base {
                    path.move(to: wrist)
                    path.addLine(to: convertPoint(points[base], in: geometry))
                }
            }
        }
    }
}

// ✅ Camera Preview Layer
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
