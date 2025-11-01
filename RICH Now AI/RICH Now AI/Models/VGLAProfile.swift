//
//  VGLAProfile.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData

// VGLA 組合型態
enum VGLACombinationType: String, Codable {
    // Vision 為主
    case VA = "VA" // 願景 + 行動
    case VG = "VG" // 願景 + 感性
    case VL = "VL" // 願景 + 邏輯
    case VV = "VV" // 純願景型
    
    // Action 為主
    case AV = "AV" // 行動 + 願景
    case AG = "AG" // 行動 + 感性
    case AL = "AL" // 行動 + 邏輯
    case AA = "AA" // 純行動型
    
    // Gracious 為主
    case GV = "GV" // 感性 + 願景
    case GA = "GA" // 感性 + 行動
    case GL = "GL" // 感性 + 邏輯
    case GG = "GG" // 純感性型
    
    // Logic 為主
    case LV = "LV" // 邏輯 + 願景
    case LA = "LA" // 邏輯 + 行動
    case LG = "LG" // 邏輯 + 感性
    case LL = "LL" // 純邏輯型
    
    var displayName: String {
        switch self {
        case .VA: return "願景實踐者"
        case .VG: return "願景關懷者"
        case .VL: return "願景分析師"
        case .VV: return "純粹夢想家"
        case .AV: return "行動願景家"
        case .AG: return "行動關懷者"
        case .AL: return "行動分析師"
        case .AA: return "純粹實踐者"
        case .GV: return "關懷夢想家"
        case .GA: return "關懷實踐者"
        case .GL: return "理性關懷者"
        case .GG: return "純粹關懷者"
        case .LV: return "系統願景家"
        case .LA: return "理性實踐者"
        case .LG: return "理性關懷者"
        case .LL: return "純粹分析師"
        }
    }
    
    var description: String {
        switch self {
        case .VA: return "你喜歡有美好的夢想，並且直接看到成果。你既有遠見，又能付諸行動。"
        case .VG: return "你喜歡有美好的願景，並且可以幫助人。你用感性的思考方式實現有意義的夢想。"
        case .VL: return "你喜歡有系統的願景規劃，用邏輯分析來實現長期目標。"
        case .VV: return "你是純粹的夢想家，專注於願景和長期意義。"
        case .AV: return "你快速行動並追求長期影響，能夠立即執行有願景的計劃。"
        case .AG: return "你用行動表達關愛，立即實踐並關懷他人。"
        case .AL: return "你理性分析後快速執行，兼具邏輯思維和執行力。"
        case .AA: return "你是純粹的實踐者，專注於立即行動和看見結果。"
        case .GV: return "你用愛心實現美好願景，關懷他人並追求有意義的未來。"
        case .GA: return "你用行動表達關愛，立即實踐對他人的關心。"
        case .GL: return "你理性規劃後為家人著想，用邏輯思維照顧所愛的人。"
        case .GG: return "你是純粹的關懷者，專注於關係和情感連結。"
        case .LV: return "你系統化地追求長期目標，用邏輯架構實現願景。"
        case .LA: return "你分析後立即執行，兼具理性思維和行動力。"
        case .LG: return "你理性規劃後為家人著想，用系統化的方式照顧他人。"
        case .LL: return "你是純粹的分析師，專注於邏輯和系統化思考。"
        }
    }
    
    var communicationStyle: String {
        switch self {
        case .VA: return "從大願景切入，提供立即可行的步驟，強調夢想如何快速實現。"
        case .VG: return "強調如何幫助他人，實現有意義的夢想，用愛心溝通。"
        case .VL: return "用數據支持願景，提供邏輯架構，系統化地說明長期計劃。"
        case .VV: return "完全專注於願景和意義，用故事和比喻說明。"
        case .AV: return "提供立即行動步驟，並說明長期影響，快速且有願景。"
        case .AG: return "立即行動並表達關懷，用實際行動幫助他人。"
        case .AL: return "提供理性分析和具體步驟，快速且邏輯清晰。"
        case .AA: return "完全專注於執行和結果，提供最快速的行動方案。"
        case .GV: return "用愛心描繪美好未來，強調關係和長期意義。"
        case .GA: return "用行動表達關愛，立即幫助並關懷他人。"
        case .GL: return "理性規劃並關懷家人，用邏輯方式照顧所愛的人。"
        case .GG: return "完全專注於關係和情感，用溫暖的方式溝通。"
        case .LV: return "用系統化方式追求願景，提供清晰的邏輯架構。"
        case .LA: return "理性分析後立即執行，提供數據支持的行動方案。"
        case .LG: return "理性規劃後為他人著想，用系統化的方式關懷家人。"
        case .LL: return "完全專注於分析和系統，提供詳細的邏輯說明。"
        }
    }
    
    var financialApproach: String {
        switch self {
        case .VA: return "設定大膽的財務目標，並立即開始執行。適合創業和快速投資。"
        case .VG: return "為家人設定長期財務目標，用愛心規劃未來。適合家庭理財和奉獻規劃。"
        case .VL: return "系統化地規劃長期財富，用數據支持投資決策。適合長期投資和退休規劃。"
        case .VV: return "專注於財務自由的願景，追求有意義的財富。適合價值投資。"
        case .AV: return "快速行動並追求長期回報，適合主動投資和創業。"
        case .AG: return "立即行動並幫助他人，適合慈善事業和社會企業。"
        case .AL: return "理性分析後快速投資，適合量化投資和技術分析。"
        case .AA: return "專注於快速變現，適合短期交易和兼職收入。"
        case .GV: return "用愛心實現財務願景，適合家庭理財和傳承規劃。"
        case .GA: return "用行動照顧家人，適合穩健理財和保險規劃。"
        case .GL: return "理性規劃家庭財務，適合預算管理和儲蓄計劃。"
        case .GG: return "完全為家人著想，適合保守理財和風險控制。"
        case .LV: return "系統化追求財務目標，適合資產配置和長期規劃。"
        case .LA: return "理性分析後立即執行，適合程式交易和技術投資。"
        case .LG: return "理性規劃家庭財務，適合系統化預算和長期儲蓄。"
        case .LL: return "完全理性投資，適合量化分析和數據驅動決策。"
        }
    }
}

// VGLA 歷史記錄
@Model
final class VGLAHistoryRecord {
    var testDate: Date
    var primaryType: String
    var secondaryType: String
    var combinationType: String // VGLACombinationType.rawValue
    var scoreData: Data // VGLAScore 的 JSON 格式
    var notes: String? // 備註
    
    // 關聯
    @Relationship(deleteRule: .nullify) var user: User?
    
    init(primaryType: String, secondaryType: String, combinationType: String, scoreData: Data) {
        self.testDate = Date()
        self.primaryType = primaryType
        self.secondaryType = secondaryType
        self.combinationType = combinationType
        self.scoreData = scoreData
    }
    
    // 獲取分數
    @MainActor
    func getScore() -> VGLAScore? {
        return try? JSONDecoder().decode(VGLAScore.self, from: scoreData)
    }
    
    // 獲取組合型態
    func getCombinationType() -> VGLACombinationType? {
        return VGLACombinationType(rawValue: combinationType)
    }
}

// VGLA 完整檔案
@Model
final class VGLAProfile {
    // 當前型態
    var currentPrimaryType: String
    var currentSecondaryType: String
    var currentCombinationType: String
    var lastTestDate: Date
    
    // 下次測驗提醒
    var nextTestDate: Date // 3 個月後
    var shouldRetakeTest: Bool
    
    // 型態變化追蹤
    var hasTypeChanged: Bool
    var previousCombinationType: String?
    var typeChangeDate: Date?
    
    // 關聯
    @Relationship(deleteRule: .cascade) var historyRecords: [VGLAHistoryRecord] = []
    @Relationship(deleteRule: .nullify) var user: User?
    
    init(primaryType: String, secondaryType: String, combinationType: String) {
        self.currentPrimaryType = primaryType
        self.currentSecondaryType = secondaryType
        self.currentCombinationType = combinationType
        self.lastTestDate = Date()
        self.nextTestDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        self.shouldRetakeTest = false
        self.hasTypeChanged = false
    }
    
    // 更新型態
    func updateType(primaryType: String, secondaryType: String, combinationType: String, scoreData: Data) {
        // 檢查是否改變
        if self.currentCombinationType != combinationType {
            self.hasTypeChanged = true
            self.previousCombinationType = self.currentCombinationType
            self.typeChangeDate = Date()
        }
        
        // 更新當前型態
        self.currentPrimaryType = primaryType
        self.currentSecondaryType = secondaryType
        self.currentCombinationType = combinationType
        self.lastTestDate = Date()
        self.nextTestDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        self.shouldRetakeTest = false
        
        // 添加歷史記錄
        let record = VGLAHistoryRecord(
            primaryType: primaryType,
            secondaryType: secondaryType,
            combinationType: combinationType,
            scoreData: scoreData
        )
        record.user = user
        historyRecords.append(record)
    }
    
    // 檢查是否需要重測
    func checkRetakeNeeded() {
        if Date() >= nextTestDate {
            self.shouldRetakeTest = true
        }
    }
    
    // 獲取當前組合型態
    func getCurrentCombinationType() -> VGLACombinationType? {
        return VGLACombinationType(rawValue: currentCombinationType)
    }
    
    // 獲取型態變化趨勢
    func getTypeChangeTrend() -> [String] {
        return historyRecords
            .sorted { $0.testDate < $1.testDate }
            .map { $0.combinationType }
    }
    
    // 獲取最常見的型態
    func getMostCommonType() -> String {
        let types = historyRecords.map { $0.combinationType }
        var counts: [String: Int] = [:]
        
        for type in types {
            counts[type, default: 0] += 1
        }
        
        return counts.max(by: { $0.value < $1.value })?.key ?? currentCombinationType
    }
    
    // 獲取型態穩定度（0-1）
    func getTypeStability() -> Double {
        guard historyRecords.count > 1 else { return 1.0 }
        
        let types = historyRecords.map { $0.combinationType }
        let uniqueTypes = Set(types)
        
        // 型態種類越少，穩定度越高
        return 1.0 - (Double(uniqueTypes.count - 1) / Double(types.count))
    }
}

// VGLA 組合分析器
extension VGLAScore {
    // 獲取組合型態
    func getCombinationType() -> VGLACombinationType {
        guard orderTotal.count >= 2 else {
            // 如果只有一個主要型態
            let primary = orderTotal.first ?? "V"
            return VGLACombinationType(rawValue: "\(primary)\(primary)") ?? .VV
        }
        
        let primary = orderTotal[0]
        let secondary = orderTotal[1]
        
        // 檢查分數差距
        let primaryScore = total[primary] ?? 0
        let secondaryScore = total[secondary] ?? 0
        let scoreDifference = abs(primaryScore - secondaryScore)
        
        // 如果分數差距很小（< 3 分），使用組合型態
        // 否則使用純型態
        if scoreDifference < 3 {
            return VGLACombinationType(rawValue: "\(primary)\(secondary)") ?? .VV
        } else {
            return VGLACombinationType(rawValue: "\(primary)\(primary)") ?? .VV
        }
    }
    
    // 獲取前兩個優先思考模式的分數差距
    func getTopTwoScoreDifference() -> Int {
        guard orderTotal.count >= 2 else { return 0 }
        
        let primary = orderTotal[0]
        let secondary = orderTotal[1]
        
        let primaryScore = total[primary] ?? 0
        let secondaryScore = total[secondary] ?? 0
        
        return abs(primaryScore - secondaryScore)
    }
}
