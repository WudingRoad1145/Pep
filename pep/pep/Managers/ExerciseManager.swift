import Foundation
import AVFoundation
import Vision

class ExerciseManager: NSObject, ObservableObject {
    @Published var handPosePoints: [CGPoint] = []
    @Published var isAuthorized = false
    @Published var error: String?

    let session = AVCaptureSession()
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private let confidenceThreshold: Float = 0.7
    private let captureQueue = DispatchQueue(label: "cameraProcessingQueue", qos: .userInitiated)
    
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
        guard isAuthorized else {
            print("Camera access not authorized")
            return
        }

        session.beginConfiguration()

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            error = "Failed to setup camera"
            print("Failed to setup camera input")
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: captureQueue)

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()

        captureQueue.async { [weak self] in
            print("ExerciseManager: Starting camera session...")
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
        captureQueue.async {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                print("Failed to get pixel buffer")
                return
            }

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
            
            do {
                try handler.perform([self.handPoseRequest])
                self.processHandPoseObservation()
            } catch {
                print("Failed to perform hand pose request: \(error)")
            }
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

        do {
            let points = try getAllPoints(from: observation)
            DispatchQueue.main.async {
                self.handPosePoints = points
            }
        } catch {
            print("Error extracting hand pose points: \(error)")
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
                let transformedPoint = CGPoint(x: 1 - point.location.y, y: point.location.x)
                points.append(transformedPoint)
            }
        }
        return points
    }
}
