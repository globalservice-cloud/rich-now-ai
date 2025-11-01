//
//  VGLAReport.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData

// VGLA 報告章節
struct VGLAReportChapter: Codable {
    let title: String
    let content: String
    let insights: [String]
    let biblicalReferences: [String]
}

// 完整 VGLA 報告
struct VGLAReportData: Codable {
    let user: String
    let date: String
    let primaryType: String
    let secondaryType: String
    let tertiaryType: String
    let blindSpotType: String
    let score: VGLAScore
    let chapters: [VGLAReportChapter]
    let summary: String
    let growthRecommendations: [String]
    let collaborationSuggestions: [String]
    let financialAdvice: String
}

@Model
final class VGLAReport {
    // 報告基本資訊
    var title: String
    var generatedAt: Date
    var reportData: Data // JSON 格式的完整報告
    var pdfData: Data? // PDF 格式的報告
    
    // 關聯
    @Relationship(deleteRule: .nullify) var assessment: VGLAAssessment?
    @Relationship(deleteRule: .nullify) var user: User?
    
    @MainActor
    init(title: String, reportData: VGLAReportData) {
        self.title = title
        self.generatedAt = Date()
        self.reportData = (try? JSONEncoder().encode(reportData)) ?? Data()
    }
    
    // 獲取報告資料
    @MainActor
    func getReportData() -> VGLAReportData? {
        return try? JSONDecoder().decode(VGLAReportData.self, from: reportData)
    }
    
    // 生成 PDF
    func generatePDF() -> Data? {
        // 這裡會實作 PDF 生成邏輯
        // 使用 PDFKit 或第三方庫
        return nil
    }
    
    // 更新 PDF 資料
    func updatePDFData(_ pdfData: Data) {
        self.pdfData = pdfData
    }
}
