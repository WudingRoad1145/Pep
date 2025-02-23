import Foundation
import AVFoundation
import Vision

class ExerciseManager: NSObject, ObservableObject {
    // Published properties
    @Published var handPosePoints: [CGPoint] = []
    @Published var isAuthorized = false
    @Published var error: String?
    
    // Camera properties
    let session = AVCaptureSession()
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Configuration
    private let confidenceThreshold: Float = 0.7
    
    override init() {
        super.init()
        handPoseRequest.maximumHandCount = 1
        checkPermissions()
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                }
            }
        default:
            isAuthorized = false
            error = "Camera access denied"
        }
    }
    
    func startSession() {
        guard isAuthorized else { return }
        
        session.beginConfiguration()
        
        // Setup camera
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            error = "Failed to setup camera"
            return
        }
        
        // Configure input/output
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()
        
        // Start running
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func stopSession() {
        session.stopRunning()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension ExerciseManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        
        do {
            try handler.perform([handPoseRequest])
            processHandPoseObservation()
        } catch {
            print("Failed to perform hand pose request: \(error)")
        }
    }
    
    private func processHandPoseObservation() {
        guard let observation = handPoseRequest.results?.first,
              observation.confidence > confidenceThreshold else {
            DispatchQueue.main.async {
                self.handPosePoints = []
            }
            return
        }
        
        // Get all finger joint points
        let points = try? getAllPoints(from: observation)
        
        DispatchQueue.main.async {
            self.handPosePoints = points ?? []
        }
    }
    
    private func getAllPoints(from observation: VNHumanHandPoseObservation) throws -> [CGPoint] {
        var points: [CGPoint] = []
        
        let joints: [VNHumanHandPoseObservation.JointName] = [
            .thumbTip, .thumbIP, .thumbMP, .thumbCMC,
            .indexTip, .indexDIP, .indexPIP, .indexMCP,
            .middleTip, .middleDIP, .middlePIP, .middleMCP,
            .ringTip, .ringDIP, .ringPIP, .ringMCP,
            .littleTip, .littleDIP, .littlePIP, .littleMCP,
            .wrist
        ]
        
        for joint in joints {
            let point = try observation.recognizedPoint(joint)
            if point.confidence > confidenceThreshold {
                // Convert normalized coordinates
                points.append(CGPoint(x: point.location.x, y: 1 - point.location.y))
            }
        }
        
        return points
    }
}
