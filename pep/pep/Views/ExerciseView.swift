import SwiftUI
import Vision
import AVFoundation

struct ExerciseView: View {
    let exerciseType: ExerciseType
    @StateObject private var voiceManager = VoiceManager()
    @State private var showReport = false
    
    // Camera and vision related properties
    @State private var handLandmarks: [CGPoint] = []
    @State private var fingerSpreadPercentage: Double = 0
    private let session = AVCaptureSession()
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraViewWrapper(session: session)
                .edgesIgnoringSafeArea(.all)
            
            // Hand landmarks overlay
            HandLandmarksOverlay(landmarks: handLandmarks)
            
            VStack {
                Spacer()
                // Messages overlay
                MessagesView(messages: voiceManager.messages)
                    .padding()
            }
        }
        .onAppear {
            setupAndStartCapture()
            voiceManager.startConversation()
        }
        .onDisappear {
            stopCapture()
            voiceManager.endConversation()
        }
        .navigationDestination(isPresented: $showReport) {
            ExerciseReportView()
        }
    }
    
    // MARK: - Camera Setup
    private func setupAndStartCapture() {
        // Configure camera
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(CameraDelegate(onFrame: processFrame), queue: DispatchQueue(label: "videoQueue"))
        
        session.beginConfiguration()
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        session.commitConfiguration()
        
        // Start capture
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }
    
    private func stopCapture() {
        session.stopRunning()
    }
    
    // MARK: - Vision Processing
    private func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        try? handler.perform([handPoseRequest])
        
        guard let observation = handPoseRequest.results?.first else { return }
        
        let points = try? observation.recognizedPoints(.all)
        let landmarks = points?.values.compactMap { point -> CGPoint? in
            guard point.confidence > 0.7 else { return nil }
            return CGPoint(x: point.location.x, y: 1 - point.location.y)
        }
        
        DispatchQueue.main.async {
            self.handLandmarks = landmarks ?? []
        }
    }
}

// MARK: - Supporting Views
private struct CameraViewWrapper: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}

private struct HandLandmarksOverlay: View {
    let landmarks: [CGPoint]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                for (index, point) in landmarks.enumerated() {
                    let screenPoint = CGPoint(
                        x: point.x * geometry.size.width,
                        y: point.y * geometry.size.height
                    )
                    
                    if index == 0 {
                        path.move(to: screenPoint)
                    } else {
                        path.addLine(to: screenPoint)
                    }
                }
            }
            .stroke(Color.green, lineWidth: 2)
            
            // Draw points at landmarks
            ForEach(0..<landmarks.count, id: \.self) { index in
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .position(
                        x: landmarks[index].x * geometry.size.width,
                        y: landmarks[index].y * geometry.size.height
                    )
            }
        }
    }
}

// MARK: - Camera Delegate
private class CameraDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let onFrame: (CMSampleBuffer) -> Void
    
    init(onFrame: @escaping (CMSampleBuffer) -> Void) {
        self.onFrame = onFrame
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onFrame(sampleBuffer)
    }
}
