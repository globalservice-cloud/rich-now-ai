//
//  PDFDocumentProcessor.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/01/XX.
//

import Foundation
import UIKit
import PDFKit
import Vision
import Combine
import os.log

// PDF 文件處理器
@MainActor
class PDFDocumentProcessor: ObservableObject {
    static let shared = PDFDocumentProcessor()
    
    @Published var isProcessing = false
    @Published var extractedData: ExtractedReceiptData?
    @Published var processingError: String?
    @Published var isSupported = true
    
    private let photoAccountingManager = PhotoAccountingManager.shared
    private let logger = Logger(subsystem: "com.richnowai", category: "PDFDocumentProcessor")
    
    private init() {
        checkPDFSupport()
    }
    
    // MARK: - 支援檢查
    
    private func checkPDFSupport() {
        isSupported = PDFKit.PDFDocument.self != nil
    }
    
    // MARK: - PDF 處理
    
    /// 處理 PDF 文件，提取發票/收據資訊
    func processPDFDocument(_ pdfData: Data) async throws -> ExtractedReceiptData {
        isProcessing = true
        processingError = nil
        extractedData = nil
        
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            throw PDFProcessingError.invalidPDF
        }
        
        // 獲取第一頁（通常發票在第一頁）
        guard let firstPage = pdfDocument.page(at: 0) else {
            throw PDFProcessingError.noPages
        }
        
        // 將 PDF 頁面轉換為 UIImage
        let pageImage = await convertPDFPageToImage(firstPage)
        
        // 使用 PhotoAccountingManager 處理圖片
        do {
            let receiptData = try await photoAccountingManager.processReceiptImage(
                pageImage,
                source: .unknown
            )
            
            self.extractedData = receiptData
            self.isProcessing = false
            return receiptData
            
        } catch {
            self.isProcessing = false
            self.processingError = error.localizedDescription
            throw error
        }
    }
    
    /// 處理多頁 PDF，返回所有頁面的處理結果
    func processMultiPagePDF(_ pdfData: Data) async throws -> [ExtractedReceiptData] {
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            throw PDFProcessingError.invalidPDF
        }
        
        var results: [ExtractedReceiptData] = []
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            let pageImage = await convertPDFPageToImage(page)
            
            do {
                let receiptData = try await photoAccountingManager.processReceiptImage(
                    pageImage,
                    source: .unknown
                )
                results.append(receiptData)
            } catch {
                logger.warning("處理 PDF 第 \(pageIndex + 1) 頁失敗: \(error.localizedDescription)")
                // 繼續處理下一頁
            }
        }
        
        guard !results.isEmpty else {
            throw PDFProcessingError.processingFailed
        }
        
        return results
    }
    
    // MARK: - PDF 頁面轉圖片
    
    /// 將 PDF 頁面轉換為 UIImage
    private func convertPDFPageToImage(_ page: PDFPage) async -> UIImage {
        let pageRect = page.bounds(for: .mediaBox)
        
        // 設置高解析度渲染
        let scale: CGFloat = 2.0
        let size = CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            context.cgContext.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: context.cgContext)
        }
    }
    
    /// 檢查 PDF 是否包含發票（通過檢查關鍵字）
    func isInvoicePDF(_ pdfData: Data) async -> Bool {
        guard let pdfDocument = PDFDocument(data: pdfData),
              let firstPage = pdfDocument.page(at: 0) else {
            return false
        }
        
        // 提取文字內容
        guard let pageContent = firstPage.string else {
            return false
        }
        
        // 檢查是否包含發票關鍵字
        let invoiceKeywords = [
            "發票", "統一發票", "電子發票", "收據", "receipt", "invoice",
            "金額", "總計", "合計", "amount", "total", "sum",
            "店家", "商家", "merchant", "store", "shop"
        ]
        
        let lowercasedContent = pageContent.lowercased()
        return invoiceKeywords.contains { lowercasedContent.contains($0.lowercased()) }
    }
}

// MARK: - 錯誤定義

enum PDFProcessingError: LocalizedError {
    case invalidPDF
    case noPages
    case processingFailed
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidPDF:
            return "無效的 PDF 文件"
        case .noPages:
            return "PDF 文件沒有頁面"
        case .processingFailed:
            return "PDF 處理失敗"
        case .unsupportedFormat:
            return "不支援的 PDF 格式"
        }
    }
}

