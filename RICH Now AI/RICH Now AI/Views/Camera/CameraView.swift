//
//  CameraView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import SwiftUI
import AVFoundation
import UIKit
import Vision

/// 相機視圖 - 用於拍照記帳和發票識別
struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isPresented: Bool
    let onImageCaptured: ((UIImage) -> Void)?
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // 不需要更新
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage) {
            parent.capturedImage = image
            parent.onImageCaptured?(image)
            parent.isPresented = false
        }
        
        func cameraViewControllerDidCancel(_ controller: CameraViewController) {
            parent.isPresented = false
        }
    }
}

/// 相機視圖控制器協議
protocol CameraViewControllerDelegate: AnyObject {
    func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage)
    func cameraViewControllerDidCancel(_ controller: CameraViewController)
}

/// 相機視圖控制器
class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var currentDevice: AVCaptureDevice?
    
    // QR Code 掃描相關
    private var qrCodeRequest: VNDetectBarcodesRequest?
    private var isScanningQRCode = false
    private var detectedQRCodeFrame: CGRect?
    
    // 自動對焦和光線檢測
    private var focusIndicator: UIView?
    private var lightLevelIndicator: UIView?
    private var receiptFrameGuide: UIView?
    
    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 35
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.white.cgColor
        button.frame = CGRect(x: 0, y: 0, width: 70, height: 70)
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("取消", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    private let switchCameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        button.tintColor = .white
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 22
        return button
    }()
    
    // QR Code 檢測指示器
    private let qrCodeIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.green.withAlphaComponent(0.3)
        view.layer.borderColor = UIColor.green.cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 8
        view.isHidden = true
        return view
    }()
    
    // 發票邊框引導線
    private let receiptGuideView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.blue.withAlphaComponent(0.5).cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 8
        view.isHidden = false
        return view
    }()
    
    // 光線水平指示器
    private let lightLevelLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    // MARK: - 相機設置
    
    private func setupCamera() {
        // 檢查相機權限
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus {
        case .authorized:
            configureCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureCaptureSession()
                    } else {
                        self?.showPermissionAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert()
        @unknown default:
            showPermissionAlert()
        }
    }
    
    private func configureCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let captureSession = captureSession else { return }
        
        // 配置輸入設備（後置相機）
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("無法訪問後置相機")
            return
        }
        
        currentDevice = backCamera
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            // 配置輸出
            photoOutput = AVCapturePhotoOutput()
            if let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            // 配置視頻輸出用於即時 QR Code 掃描
            videoOutput = AVCaptureVideoDataOutput()
            videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            
            if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            // 配置預覽層
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            
            if let previewLayer = videoPreviewLayer {
                view.layer.addSublayer(previewLayer)
            }
            
            // 設置自動對焦
            setupAutoFocus()
            
            // 初始化 QR Code 掃描
            setupQRCodeScanning()
            
        } catch {
            print("配置相機失敗: \(error.localizedDescription)")
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // 取消按鈕
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        // 拍照按鈕
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureButton)
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70)
        ])
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        
        // 切換相機按鈕
        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(switchCameraButton)
        NSLayoutConstraint.activate([
            switchCameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            switchCameraButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 44),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        switchCameraButton.addTarget(self, action: #selector(switchCameraButtonTapped), for: .touchUpInside)
        
        // QR Code 指示器
        qrCodeIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(qrCodeIndicator)
        
        // 發票邊框引導線
        receiptGuideView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(receiptGuideView)
        NSLayoutConstraint.activate([
            receiptGuideView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            receiptGuideView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            receiptGuideView.widthAnchor.constraint(equalToConstant: 300),
            receiptGuideView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        // 光線水平指示器
        lightLevelLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lightLevelLabel)
        NSLayoutConstraint.activate([
            lightLevelLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            lightLevelLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            lightLevelLabel.widthAnchor.constraint(equalToConstant: 80),
            lightLevelLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // 添加點擊手勢用於手動對焦
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusAtPoint(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - 按鈕動作
    
    @objc private func cancelButtonTapped() {
        delegate?.cameraViewControllerDidCancel(self)
    }
    
    @objc private func captureButtonTapped() {
        guard let photoOutput = photoOutput else { return }
        
        // 使用預設的相機設定
        // 注意：AVCapturePhotoSettings 不直接支援 photoCodecType
        // 相機會自動選擇最佳的編碼格式
        let settings = AVCapturePhotoSettings()
        
        photoOutput.capturePhoto(with: settings, delegate: self)
        
        // 觸覺反饋
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    @objc private func switchCameraButtonTapped() {
        guard let captureSession = captureSession else { return }
        
        captureSession.beginConfiguration()
        
        // 移除當前輸入
        if let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput {
            captureSession.removeInput(currentInput)
        }
        
        // 切換到另一個相機
        let newPosition: AVCaptureDevice.Position = currentDevice?.position == .back ? .front : .back
        
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            captureSession.commitConfiguration()
            return
        }
        
        currentDevice = newDevice
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
            }
            
            // 重新設置自動對焦
            setupAutoFocus()
        } catch {
            print("切換相機失敗: \(error.localizedDescription)")
        }
        
        captureSession.commitConfiguration()
        
        // 觸覺反饋
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - 會話管理
    
    private func startSession() {
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }
    
    private func stopSession() {
        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.stopRunning()
            }
        }
    }
    
    // MARK: - 權限處理
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "需要相機權限",
            message: "請在設定中允許應用程式使用相機來拍照記帳",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "前往設定", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { [weak self] _ in
            self?.delegate?.cameraViewControllerDidCancel(self!)
        })
        
        present(alert, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = view.layer.bounds
    }
    
    // MARK: - QR Code 掃描設置
    
    private func setupQRCodeScanning() {
        qrCodeRequest = VNDetectBarcodesRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("QR Code 掃描錯誤: \(error.localizedDescription)")
                return
            }
            
            guard let results = request.results as? [VNBarcodeObservation],
                  let firstResult = results.first else {
                DispatchQueue.main.async {
                    self.qrCodeIndicator.isHidden = true
                    self.detectedQRCodeFrame = nil
                }
                return
            }
            
            // 轉換座標到預覽層座標
            guard let previewLayer = self.videoPreviewLayer else { return }
            
            // Vision 框架使用標準化座標（0,0 在左下角），需要轉換到 UIKit 座標系統
            let normalizedRect = firstResult.boundingBox
            let layerSize = previewLayer.bounds.size
            
            // 轉換標準化座標到預覽層座標
            let previewRect = CGRect(
                x: normalizedRect.origin.x * layerSize.width,
                y: (1 - normalizedRect.origin.y - normalizedRect.height) * layerSize.height,
                width: normalizedRect.width * layerSize.width,
                height: normalizedRect.height * layerSize.height
            )
            
            DispatchQueue.main.async {
                self.detectedQRCodeFrame = previewRect
                self.updateQRCodeIndicator(frame: previewRect)
            }
        }
        
        // 設置 QR Code 類型
        qrCodeRequest?.symbologies = [.QR]
        qrCodeRequest?.revision = VNDetectBarcodesRequestRevision2
    }
    
    private func updateQRCodeIndicator(frame: CGRect) {
        qrCodeIndicator.isHidden = false
        qrCodeIndicator.frame = frame
        
        // 添加動畫效果
        UIView.animate(withDuration: 0.3) {
            self.qrCodeIndicator.alpha = 1.0
        }
        
        // 觸覺反饋
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - 自動對焦設置
    
    private func setupAutoFocus() {
        guard let device = currentDevice else { return }
        
        do {
            try device.lockForConfiguration()
            
            // 啟用自動對焦
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            
            // 啟用自動曝光
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
            // 啟用自動白平衡
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            device.unlockForConfiguration()
        } catch {
            print("設置自動對焦失敗: \(error.localizedDescription)")
        }
    }
    
    @objc private func focusAtPoint(_ gesture: UITapGestureRecognizer) {
        guard let device = currentDevice,
              let previewLayer = videoPreviewLayer else { return }
        
        let point = gesture.location(in: view)
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
        
        do {
            try device.lockForConfiguration()
            
            // 設置對焦點
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = devicePoint
                device.focusMode = .autoFocus
            }
            
            // 設置曝光點
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = devicePoint
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
            
            // 顯示對焦指示器
            showFocusIndicator(at: point)
            
        } catch {
            print("手動對焦失敗: \(error.localizedDescription)")
        }
    }
    
    private func showFocusIndicator(at point: CGPoint) {
        // 移除舊的指示器
        focusIndicator?.removeFromSuperview()
        
        // 創建新的對焦指示器
        let indicator = UIView(frame: CGRect(x: point.x - 50, y: point.y - 50, width: 100, height: 100))
        indicator.backgroundColor = .clear
        indicator.layer.borderColor = UIColor.yellow.cgColor
        indicator.layer.borderWidth = 2
        indicator.layer.cornerRadius = 50
        
        view.addSubview(indicator)
        focusIndicator = indicator
        
        // 動畫效果
        UIView.animate(withDuration: 0.3, animations: {
            indicator.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                indicator.transform = CGAffineTransform.identity
            } completion: { _ in
                UIView.animate(withDuration: 0.5, delay: 0.5) {
                    indicator.alpha = 0
                } completion: { _ in
                    indicator.removeFromSuperview()
                }
            }
        }
    }
    
    // MARK: - 光線檢測
    
    private func updateLightLevel(from pixelBuffer: CVPixelBuffer) {
        // 計算像素緩衝區的平均亮度
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        var totalBrightness: Double = 0
        var pixelCount = 0
        
        // 採樣每個第 10 個像素以提高性能
        for y in stride(from: 0, to: height, by: 10) {
            for x in stride(from: 0, to: width, by: 10) {
                let pixel = baseAddress.advanced(by: y * bytesPerRow + x * 4)
                let r = Double(pixel.load(as: UInt8.self))
                let g = Double(pixel.advanced(by: 1).load(as: UInt8.self))
                let b = Double(pixel.advanced(by: 2).load(as: UInt8.self))
                
                // 計算亮度（使用標準亮度公式）
                let brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
                totalBrightness += brightness
                pixelCount += 1
            }
        }
        
        let averageBrightness = totalBrightness / Double(pixelCount)
        
        DispatchQueue.main.async {
            if averageBrightness < 0.3 {
                self.lightLevelLabel.text = "光線不足"
                self.lightLevelLabel.textColor = .orange
                self.lightLevelLabel.isHidden = false
            } else if averageBrightness > 0.9 {
                self.lightLevelLabel.text = "光線過亮"
                self.lightLevelLabel.textColor = .yellow
                self.lightLevelLabel.isHidden = false
            } else {
                self.lightLevelLabel.isHidden = true
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // 更新光線水平（每 30 幀檢查一次）
        static var frameCount = 0
        frameCount += 1
        if frameCount % 30 == 0 {
            updateLightLevel(from: pixelBuffer)
        }
        
        // QR Code 掃描（每 10 幀掃描一次以提高性能）
        if frameCount % 10 == 0 {
            guard let qrCodeRequest = qrCodeRequest else { return }
            
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try imageRequestHandler.perform([qrCodeRequest])
            } catch {
                // 掃描失敗，繼續下一幀
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("處理照片失敗: \(error?.localizedDescription ?? "未知錯誤")")
            return
        }
        
        // 如果使用的是前置相機，需要鏡像翻轉
        var finalImage = image
        if currentDevice?.position == .front {
            if let cgImage = image.cgImage {
                finalImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
            }
        }
        
        // 調整圖片方向（確保正確顯示）
        if let cgImage = finalImage.cgImage {
            finalImage = UIImage(cgImage: cgImage, scale: finalImage.scale, orientation: .up)
        }
        
        delegate?.cameraViewController(self, didCaptureImage: finalImage)
    }
}

