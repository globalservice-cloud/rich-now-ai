//
//  Report.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData

// 報告類型
enum ReportType: String, Codable, CaseIterable {
    case monthly_summary = "monthly_summary"     // 月度財務總結
    case goal_progress = "goal_progress"         // 目標進度報告
    case budget_analysis = "budget_analysis"      // 預算分析報告
    case investment_performance = "investment_performance" // 投資績效報告
    case debt_analysis = "debt_analysis"        // 債務分析報告
    case financial_health = "financial_health"   // 財務健康報告
    case vgla_insights = "vgla_insights"         // VGLA 洞察報告
    case custom = "custom"                       // 自訂報告
}

// 報告狀態
enum ReportStatus: String, Codable {
    case generating = "generating"   // 生成中
    case completed = "completed"    // 已完成
    case failed = "failed"          // 生成失敗
}

// 報告內容結構
struct ReportContent: Codable {
    let title: String
    let summary: String
    let sections: [ReportSection]
    let charts: [ReportChart]
    let insights: [String]
    let recommendations: [String]
    let biblicalPrinciples: [String]
}

// 報告章節
struct ReportSection: Codable {
    let title: String
    let content: String
    let data: [String: String]? // 動態數據（簡化為字串）
}

// 報告圖表
struct ReportChart: Codable {
    let type: String // pie, bar, line, radar
    let title: String
    let data: [String: String] // 簡化為字串
}

@Model
final class Report {
    // 基本資訊
    var title: String
    var type: String // ReportType.rawValue
    var status: String // ReportStatus.rawValue
    
    // 時間範圍
    var startDate: Date
    var endDate: Date
    var generatedAt: Date
    
    // 報告內容
    var content: Data // ReportContent 的 JSON 格式
    var pdfData: Data? // PDF 格式的報告
    var htmlData: Data? // HTML 格式的報告
    
    // 生成設定
    var includeCharts: Bool
    var includeInsights: Bool
    var includeRecommendations: Bool
    var includeBiblicalPrinciples: Bool
    
    // 分享設定
    var isShareable: Bool
    var shareToken: String? // 分享令牌
    
    // 時間戳記
    var createdAt: Date
    var updatedAt: Date
    
    // 關聯
    @Relationship(deleteRule: .nullify, inverse: \User.reports) var user: User?
    
    init(title: String, type: ReportType, startDate: Date, endDate: Date) {
        self.title = title
        self.type = type.rawValue
        self.status = ReportStatus.generating.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.generatedAt = Date()
        self.content = Data()
        self.includeCharts = true
        self.includeInsights = true
        self.includeRecommendations = true
        self.includeBiblicalPrinciples = true
        self.isShareable = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // 更新報告內容
    @MainActor
    func updateContent(_ newContent: ReportContent) {
        do {
            self.content = try JSONEncoder().encode(newContent)
            self.status = ReportStatus.completed.rawValue
            self.updatedAt = Date()
        } catch {
            print("Failed to encode report content: \(error)")
        }
    }
    
    // 獲取報告內容
    @MainActor
    func getContent() -> ReportContent? {
        do {
            return try JSONDecoder().decode(ReportContent.self, from: content)
        } catch {
            print("Failed to decode report content: \(error)")
            return nil
        }
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
        self.updatedAt = Date()
    }
    
    // 生成 HTML
    func generateHTML() -> Data? {
        // 這裡會實作 HTML 生成邏輯
        return nil
    }
    
    // 更新 HTML 資料
    func updateHTMLData(_ htmlData: Data) {
        self.htmlData = htmlData
        self.updatedAt = Date()
    }
    
    // 標記為完成
    func markAsCompleted() {
        self.status = ReportStatus.completed.rawValue
        self.updatedAt = Date()
    }
    
    // 標記為失敗
    func markAsFailed() {
        self.status = ReportStatus.failed.rawValue
        self.updatedAt = Date()
    }
    
    // 啟用分享
    func enableSharing() {
        self.isShareable = true
        self.shareToken = UUID().uuidString
        self.updatedAt = Date()
    }
    
    // 停用分享
    func disableSharing() {
        self.isShareable = false
        self.shareToken = nil
        self.updatedAt = Date()
    }
    
    // 獲取報告類型枚舉
    func getReportType() -> ReportType? {
        return ReportType(rawValue: type)
    }
    
    // 獲取報告狀態枚舉
    func getReportStatus() -> ReportStatus? {
        return ReportStatus(rawValue: status)
    }
    
    // 檢查是否為生成中
    var isGenerating: Bool {
        return status == ReportStatus.generating.rawValue
    }
    
    // 檢查是否已完成
    var isCompleted: Bool {
        return status == ReportStatus.completed.rawValue
    }
    
    // 檢查是否生成失敗
    var isFailed: Bool {
        return status == ReportStatus.failed.rawValue
    }
    
    // 檢查是否有 PDF
    var hasPDF: Bool {
        return pdfData != nil && !pdfData!.isEmpty
    }
    
    // 檢查是否有 HTML
    var hasHTML: Bool {
        return htmlData != nil && !htmlData!.isEmpty
    }
    
    // 獲取報告大小（位元組）
    var reportSize: Int {
        var size = content.count
        if let pdfData = pdfData {
            size += pdfData.count
        }
        if let htmlData = htmlData {
            size += htmlData.count
        }
        return size
    }
}
