//
//  UIImage+Vision.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import UIKit
import CoreImage
import CoreGraphics

extension UIImage {
    
    // MARK: - 圖片大小調整
    
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func resized(to maxSize: CGFloat) -> UIImage {
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
        } else {
            newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
        }
        
        return resized(to: newSize)
    }
    
    // MARK: - OCR 優化
    
    func enhancedForOCR() -> UIImage {
        guard let cgImage = self.cgImage else { return self }
        
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        
        // 應用多個濾鏡來增強文字識別
        var outputImage = ciImage
        
        // 1. 調整對比度
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(outputImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(1.2, forKey: kCIInputContrastKey)
            contrastFilter.setValue(0.1, forKey: kCIInputBrightnessKey)
            contrastFilter.setValue(1.0, forKey: kCIInputSaturationKey)
            
            if let contrastOutput = contrastFilter.outputImage {
                outputImage = contrastOutput
            }
        }
        
        // 2. 銳化
        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(outputImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.5, forKey: kCIInputSharpnessKey)
            
            if let sharpenOutput = sharpenFilter.outputImage {
                outputImage = sharpenOutput
            }
        }
        
        // 3. 去噪
        if let noiseFilter = CIFilter(name: "CINoiseReduction") {
            noiseFilter.setValue(outputImage, forKey: kCIInputImageKey)
            noiseFilter.setValue(0.02, forKey: "inputNoiseLevel")
            noiseFilter.setValue(0.40, forKey: "inputSharpness")
            
            if let noiseOutput = noiseFilter.outputImage {
                outputImage = noiseOutput
            }
        }
        
        // 4. 邊緣增強
        if let edgeFilter = CIFilter(name: "CIEdges") {
            edgeFilter.setValue(outputImage, forKey: kCIInputImageKey)
            edgeFilter.setValue(1.0, forKey: kCIInputIntensityKey)
            
            if let edgeOutput = edgeFilter.outputImage {
                // 將邊緣檢測結果與原圖混合
                if let blendFilter = CIFilter(name: "CIOverlayBlendMode") {
                    blendFilter.setValue(outputImage, forKey: kCIInputImageKey)
                    blendFilter.setValue(edgeOutput, forKey: kCIInputBackgroundImageKey)
                    
                    if let blendOutput = blendFilter.outputImage {
                        outputImage = blendOutput
                    }
                }
            }
        }
        
        // 轉換回 UIImage
        guard let enhancedCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return self
        }
        
        return UIImage(cgImage: enhancedCGImage)
    }
    
    // MARK: - 圖片方向修正
    
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        guard let cgImage = self.cgImage else { return self }
        
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: cgImage.bitmapInfo.rawValue
        )
        
        context?.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        guard let newCGImage = context?.makeImage() else { return self }
        return UIImage(cgImage: newCGImage)
    }
    
    // MARK: - 圖片品質檢查
    
    func isSuitableForOCR() -> Bool {
        // 檢查圖片大小
        let minSize: CGFloat = 100
        if size.width < minSize || size.height < minSize {
            return false
        }
        
        // 檢查圖片是否太模糊（簡單的邊緣檢測）
        if let cgImage = self.cgImage {
            let context = CIContext()
            let ciImage = CIImage(cgImage: cgImage)
            
            if let edgeFilter = CIFilter(name: "CIEdges") {
                edgeFilter.setValue(ciImage, forKey: kCIInputImageKey)
                edgeFilter.setValue(1.0, forKey: kCIInputIntensityKey)
                
                if let edgeOutput = edgeFilter.outputImage,
                   let edgeCGImage = context.createCGImage(edgeOutput, from: edgeOutput.extent) {
                    
                    // 計算邊緣密度
                    let edgeDensity = calculateEdgeDensity(cgImage: edgeCGImage)
                    return edgeDensity > 0.01 // 邊緣密度閾值
                }
            }
        }
        
        return true
    }
    
    private func calculateEdgeDensity(cgImage: CGImage) -> Double {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let totalBytes = height * bytesPerRow
        
        var pixelData = [UInt8](repeating: 0, count: totalBytes)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var edgePixels = 0
        let threshold: UInt8 = 128
        
        for i in stride(from: 0, to: totalBytes, by: bytesPerPixel) {
            let red = pixelData[i]
            let green = pixelData[i + 1]
            let blue = pixelData[i + 2]
            
            if red > threshold || green > threshold || blue > threshold {
                edgePixels += 1
            }
        }
        
        return Double(edgePixels) / Double(width * height)
    }
    
    // MARK: - 圖片壓縮
    
    func compressedJPEG(quality: CGFloat = 0.8) -> Data? {
        return self.jpegData(compressionQuality: quality)
    }
    
    func compressedPNG() -> Data? {
        return self.pngData()
    }
    
    // MARK: - 圖片格式檢測
    
    func detectImageFormat() -> ImageFormat {
        guard let cgImage = self.cgImage else { return .unknown }
        
        let alphaInfo = cgImage.alphaInfo
        let hasAlpha = alphaInfo == .premultipliedLast ||
                      alphaInfo == .premultipliedFirst ||
                      alphaInfo == .last ||
                      alphaInfo == .first ||
                      alphaInfo == .noneSkipLast ||
                      alphaInfo == .noneSkipFirst
        
        return hasAlpha ? .png : .jpeg
    }
    
    // MARK: - 圖片資訊
    
    func getImageInfo() -> ImageInfo {
        return ImageInfo(
            size: size,
            scale: scale,
            orientation: imageOrientation,
            format: detectImageFormat(),
            isSuitableForOCR: isSuitableForOCR()
        )
    }
}

// MARK: - 支援結構

enum ImageFormat {
    case jpeg
    case png
    case unknown
}

struct ImageInfo {
    let size: CGSize
    let scale: CGFloat
    let orientation: UIImage.Orientation
    let format: ImageFormat
    let isSuitableForOCR: Bool
}
