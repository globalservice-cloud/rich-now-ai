//
//  ImageCacheManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import Foundation
import UIKit
import os.log

class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSString, UIImage>()
    private let logger = Logger(subsystem: "com.richnowai", category: "ImageCacheManager")
    
    // 記憶體限制
    private let maxMemoryLimit: Int = 50 * 1024 * 1024 // 50MB
    private let maxCountLimit: Int = 100
    
    // 磁碟快取
    private let diskCacheURL: URL
    private let fileManager = FileManager.default
    
    private init() {
        // 設定記憶體快取限制
        cache.totalCostLimit = maxMemoryLimit
        cache.countLimit = maxCountLimit
        
        // 設定磁碟快取目錄
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cachesDirectory.appendingPathComponent("ImageCache")
        
        // 創建磁碟快取目錄
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        // 設定記憶體警告觀察者
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 圖片快取操作
    
    func setImage(_ image: UIImage, forKey key: String) {
        let nsKey = NSString(string: key)
        let cost = calculateImageCost(image)
        
        // 儲存到記憶體快取
        cache.setObject(image, forKey: nsKey, cost: cost)
        
        // 異步儲存到磁碟快取
        Task {
            await saveImageToDisk(image, forKey: key)
        }
    }
    
    func getImage(forKey key: String) -> UIImage? {
        let nsKey = NSString(string: key)
        
        // 先從記憶體快取獲取
        if let image = cache.object(forKey: nsKey) {
            return image
        }
        
        // 從磁碟快取獲取
        if let image = loadImageFromDisk(forKey: key) {
            // 重新載入到記憶體快取
            let cost = calculateImageCost(image)
            cache.setObject(image, forKey: nsKey, cost: cost)
            return image
        }
        
        return nil
    }
    
    func removeImage(forKey key: String) {
        let nsKey = NSString(string: key)
        cache.removeObject(forKey: nsKey)
        
        // 從磁碟快取移除
        Task {
            await removeImageFromDisk(forKey: key)
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
        
        // 清理磁碟快取
        Task {
            await clearDiskCache()
        }
    }
    
    // MARK: - 磁碟快取操作
    
    private func saveImageToDisk(_ image: UIImage, forKey key: String) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileURL = diskCacheURL.appendingPathComponent(key)
        
        do {
            try data.write(to: fileURL)
        } catch {
            logger.error("Failed to save image to disk: \(error.localizedDescription)")
        }
    }
    
    private func loadImageFromDisk(forKey key: String) -> UIImage? {
        let fileURL = diskCacheURL.appendingPathComponent(key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        
        return UIImage(data: data)
    }
    
    private func removeImageFromDisk(forKey key: String) async {
        let fileURL = diskCacheURL.appendingPathComponent(key)
        
        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            logger.error("Failed to remove image from disk: \(error.localizedDescription)")
        }
    }
    
    private func clearDiskCache() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil)
            
            for file in files {
                try fileManager.removeItem(at: file)
            }
        } catch {
            logger.error("Failed to clear disk cache: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 記憶體管理
    
    private func calculateImageCost(_ image: UIImage) -> Int {
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        return width * height * 4 // 4 bytes per pixel (RGBA)
    }
    
    @objc private func handleMemoryWarning() {
        logger.warning("Memory warning received, clearing image cache")
        cache.removeAllObjects()
    }
    
    // MARK: - 快取統計
    
    func getCacheStats() -> CacheStats {
        let memoryCount = cache.countLimit
        let memoryCost = cache.totalCostLimit
        let currentCount = cache.countLimit - cache.countLimit
        let currentCost = cache.totalCostLimit - cache.totalCostLimit
        
        return CacheStats(
            memoryCountLimit: memoryCount,
            memoryCostLimit: memoryCost,
            currentMemoryCount: currentCount,
            currentMemoryCost: currentCost,
            diskCacheSize: getDiskCacheSize()
        )
    }
    
    private func getDiskCacheSize() -> Int64 {
        do {
            let files = try fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey])
            
            var totalSize: Int64 = 0
            for file in files {
                let attributes = try fileManager.attributesOfItem(atPath: file.path)
                if let size = attributes[.size] as? Int64 {
                    totalSize += size
                }
            }
            
            return totalSize
        } catch {
            return 0
        }
    }
}

// MARK: - 支援類型

struct CacheStats {
    let memoryCountLimit: Int
    let memoryCostLimit: Int
    let currentMemoryCount: Int
    let currentMemoryCost: Int
    let diskCacheSize: Int64
    
    var memoryUsagePercentage: Double {
        return Double(currentMemoryCost) / Double(memoryCostLimit)
    }
    
    var diskCacheSizeMB: Double {
        return Double(diskCacheSize) / (1024 * 1024)
    }
}
