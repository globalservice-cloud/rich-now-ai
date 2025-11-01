//
//  ImageCompressionManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import Foundation
import UIKit
import CoreImage
import Combine
import os.log

@MainActor
class ImageCompressionManager: ObservableObject {
    static let shared = ImageCompressionManager()
    
    @Published var isCompressing = false
    @Published var compressionProgress: Double = 0.0
    @Published var compressionStats: CompressionStats = CompressionStats(
        totalImages: 0,
        compressedImages: 0,
        totalSizeSaved: 0,
        compressionRatio: 0
    )
    
    private let logger = Logger(subsystem: "com.richnowai", category: "ImageCompressionManager")
    
    // 壓縮設定
    private let maxImageSize: CGSize = CGSize(width: 2048, height: 2048)
    private let compressionQuality: CGFloat = 0.8
    private let maxMemoryUsage: Int = 100 * 1024 * 1024 // 100MB
    
    private init() {}
    
    // MARK: - 圖片壓縮
    
    func compressImage(_ image: UIImage, targetSize: CGSize? = nil) -> UIImage? {
        let targetSize = targetSize ?? maxImageSize
        
        // 計算壓縮比例
        let scale = min(targetSize.width / image.size.width, targetSize.height / image.size.height)
        
        // 如果圖片已經足夠小，直接返回
        if scale >= 1.0 {
            return image
        }
        
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        
        // 使用 UIGraphicsImageRenderer 進行高品質壓縮
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let compressedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return compressedImage
    }
    
    func compressImagesInMemory() async {
        isCompressing = true
        compressionProgress = 0.0
        
        // 獲取所有記憶體中的圖片
        let images = await getAllImagesInMemory()
        let totalImages = images.count
        
        var compressedCount = 0
        var totalSizeSaved: Int64 = 0
        
        for (index, image) in images.enumerated() {
            if let compressedImage = compressImage(image) {
                // 計算壓縮後的大小
                let originalSize = getImageSize(image)
                let compressedSize = getImageSize(compressedImage)
                let sizeSaved = originalSize - compressedSize
                
                totalSizeSaved += sizeSaved
                compressedCount += 1
            }
            
            // 更新進度
            compressionProgress = Double(index + 1) / Double(totalImages)
            
            // 避免阻塞主線程
            await Task.yield()
        }
        
        // 更新統計信息
        compressionStats = CompressionStats(
            totalImages: totalImages,
            compressedImages: compressedCount,
            totalSizeSaved: totalSizeSaved,
            compressionRatio: totalImages > 0 ? Double(compressedCount) / Double(totalImages) : 0
        )
        
        logger.info("Compressed \(compressedCount)/\(totalImages) images, saved \(totalSizeSaved) bytes")
        
        isCompressing = false
    }
    
    // MARK: - 智能壓縮
    
    func smartCompressImage(_ image: UIImage, for purpose: ImagePurpose) -> UIImage? {
        let targetSize = getTargetSize(for: purpose)
        let quality = getCompressionQuality(for: purpose)
        
        return compressImageWithQuality(image, targetSize: targetSize, quality: quality)
    }
    
    private func compressImageWithQuality(_ image: UIImage, targetSize: CGSize, quality: CGFloat) -> UIImage? {
        // 調整大小
        let resizedImage = resizeImage(image, to: targetSize)
        
        // 壓縮品質
        guard let imageData = resizedImage.jpegData(compressionQuality: quality) else {
            return resizedImage
        }
        
        return UIImage(data: imageData)
    }
    
    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let scale = min(targetSize.width / image.size.width, targetSize.height / image.size.height)
        
        if scale >= 1.0 {
            return image
        }
        
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    // MARK: - 壓縮設定
    
    private func getTargetSize(for purpose: ImagePurpose) -> CGSize {
        switch purpose {
        case .thumbnail:
            return CGSize(width: 200, height: 200)
        case .preview:
            return CGSize(width: 800, height: 600)
        case .fullSize:
            return CGSize(width: 2048, height: 2048)
        case .ocr:
            return CGSize(width: 1024, height: 1024)
        }
    }
    
    private func getCompressionQuality(for purpose: ImagePurpose) -> CGFloat {
        switch purpose {
        case .thumbnail:
            return 0.6
        case .preview:
            return 0.8
        case .fullSize:
            return 0.9
        case .ocr:
            return 0.95
        }
    }
    
    // MARK: - 記憶體管理
    
    private func getAllImagesInMemory() async -> [UIImage] {
        // 這裡應該從實際的圖片快取中獲取圖片
        // 目前返回空數組作為示例
        return []
    }
    
    private func getImageSize(_ image: UIImage) -> Int64 {
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            return 0
        }
        return Int64(data.count)
    }
    
    // MARK: - 壓縮統計
    
    func getCompressionReport() -> CompressionReport {
        return CompressionReport(
            stats: compressionStats,
            isCompressing: isCompressing,
            compressionProgress: compressionProgress
        )
    }
    
    // MARK: - 批量壓縮
    
    func batchCompressImages(_ images: [UIImage], purpose: ImagePurpose) async -> [UIImage] {
        var compressedImages: [UIImage] = []
        
        for image in images {
            if let compressed = smartCompressImage(image, for: purpose) {
                compressedImages.append(compressed)
            } else {
                compressedImages.append(image)
            }
        }
        
        return compressedImages
    }
}

// MARK: - 支援類型

enum ImagePurpose {
    case thumbnail
    case preview
    case fullSize
    case ocr
}

struct CompressionStats {
    let totalImages: Int
    let compressedImages: Int
    let totalSizeSaved: Int64
    let compressionRatio: Double
    
    var averageSizeSaved: Int64 {
        return compressedImages > 0 ? totalSizeSaved / Int64(compressedImages) : 0
    }
    
    var sizeSavedMB: Double {
        return Double(totalSizeSaved) / (1024 * 1024)
    }
}

struct CompressionReport {
    let stats: CompressionStats
    let isCompressing: Bool
    let compressionProgress: Double
    
    var efficiency: Double {
        return stats.compressionRatio
    }
    
    var spaceSaved: String {
        return String(format: "%.1f MB", stats.sizeSavedMB)
    }
}
