import AVFoundation
import UIKit

protocol CameraServiceProtocol {
    func startPreview(in view: UIView)
    func capturePhoto(completion: @escaping (UIImage?) -> Void)
    func stop()
}

final class CameraService: NSObject, CameraServiceProtocol {
    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var completion: ((UIImage?) -> Void)?

    override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video,
                                                 position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return }

        session.addInput(input)

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()
    }

    func startPreview(in view: UIView) {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.frame = view.bounds
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)

        if !session.isRunning {
            session.startRunning()
        }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    func stop() {
        session.stopRunning()
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion?(nil); return
        }
        completion?(image)
    }
}
