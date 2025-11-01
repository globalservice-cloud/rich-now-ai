//
//  QRCodeScanner.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import Foundation
import UIKit
import Vision
import Combine
import os.log

/// QR Code 掃描結果
struct QRCodeScanResult: Codable, Identifiable {
    let id: UUID
    let content: String
    let boundingBox: CGRect
    let confidence: Float
    let symbology: String
    
    init(content: String, boundingBox: CGRect, confidence: Float, symbology: String = "QR") {
        self.id = UUID()
        self.content = content
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.symbology = symbology
    }
}

/// QR Code 掃描器
@MainActor
class QRCodeScanner: ObservableObject {
    static let shared = QRCodeScanner()
    
    @Published var isScanning = false
    @Published var scanResults: [QRCodeScanResult] = []
    @Published var lastError: String?
    
    private let logger = Logger(subsystem: "com.richnowai", category: "QRCodeScanner")
    
    private init() {}
    
    // MARK: - 掃描 QR Code
    
    /// 從圖片掃描 QR Code
    func scanQRCodes(from image: UIImage) async throws -> [QRCodeScanResult] {
        isScanning = true
        lastError = nil
        scanResults = []
        
        defer {
            isScanning = false
        }
        
        guard let cgImage = image.cgImage else {
            throw QRCodeScanError.invalidImage
        }
        
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            if let error = error {
                Task { @MainActor in
                    self?.lastError = error.localizedDescription
                    self?.logger.error("QR Code 掃描失敗: \(error.localizedDescription)")
                }
            }
        }
        
        // 設定掃描類型為 QR Code
        request.symbologies = [.QR]
        
        // 設定準確度
        request.revision = VNDetectBarcodesRequestRevision2
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results else {
                logger.info("未掃描到 QR Code")
                return []
            }
            
            var results: [QRCodeScanResult] = []
            
            for observation in observations {
                guard let payload = observation.payloadStringValue else {
                    continue
                }
                
                // 轉換邊界框從 Vision 座標系統到 UIKit 座標系統
                let boundingBox = observation.boundingBox
                let imageSize = image.size
                
                // Vision 使用 0,0 在左下角，UIKit 使用 0,0 在左上角
                let convertedBox = CGRect(
                    x: boundingBox.origin.x * imageSize.width,
                    y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
                    width: boundingBox.width * imageSize.width,
                    height: boundingBox.height * imageSize.height
                )
                
                let result = QRCodeScanResult(
                    content: payload,
                    boundingBox: convertedBox,
                    confidence: observation.confidence,
                    symbology: observation.symbology.rawValue
                )
                
                results.append(result)
                logger.info("掃描到 QR Code: \(payload.prefix(50))... (信心度: \(observation.confidence))")
            }
            
            await MainActor.run {
                self.scanResults = results
            }
            
            return results
            
        } catch {
            logger.error("執行 QR Code 掃描請求失敗: \(error.localizedDescription)")
            throw QRCodeScanError.scanFailed(error.localizedDescription)
        }
    }
    
    /// 從圖片掃描所有條碼類型（包括 QR Code）
    func scanAllBarcodes(from image: UIImage) async throws -> [QRCodeScanResult] {
        guard let cgImage = image.cgImage else {
            throw QRCodeScanError.invalidImage
        }
        
        let request = VNDetectBarcodesRequest()
        
        // 支援所有條碼類型
        request.symbologies = [
            .QR, .Aztec, .Code128, .Code39, .Code93, 
            .EAN13, .EAN8, .PDF417, .UPCE, .DataMatrix
        ]
        
        request.revision = VNDetectBarcodesRequestRevision2
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        try handler.perform([request])
        
        guard let observations = request.results else {
            return []
        }
        
        var results: [QRCodeScanResult] = []
        
        for observation in observations {
            guard let payload = observation.payloadStringValue else {
                continue
            }
            
            let boundingBox = observation.boundingBox
            let imageSize = image.size
            
            let convertedBox = CGRect(
                x: boundingBox.origin.x * imageSize.width,
                y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
                width: boundingBox.width * imageSize.width,
                height: boundingBox.height * imageSize.height
            )
            
            let result = QRCodeScanResult(
                content: payload,
                boundingBox: convertedBox,
                confidence: observation.confidence,
                symbology: observation.symbology.rawValue
            )
            
            results.append(result)
        }
        
        return results
    }
    
    /// 快速掃描（只掃描 QR Code，返回第一個結果）
    func quickScanQRCode(from image: UIImage) async -> String? {
        do {
            let results = try await scanQRCodes(from: image)
            return results.first?.content
        } catch {
            logger.warning("快速掃描 QR Code 失敗: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - 錯誤定義

enum QRCodeScanError: LocalizedError {
    case invalidImage
    case scanFailed(String)
    case noQRCodeFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "無效的圖片格式"
        case .scanFailed(let reason):
            return "QR Code 掃描失敗: \(reason)"
        case .noQRCodeFound:
            return "未找到 QR Code"
        }
    }
}


