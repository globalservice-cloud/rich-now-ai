//
//  Transaction.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData

// 交易類型
enum TransactionType: String, Codable, CaseIterable {
    case income = "income"           // 收入
    case expense = "expense"         // 支出
    case transfer = "transfer"       // 轉帳
    case investment = "investment"   // 投資
    case loan = "loan"              // 貸款
    case insurance = "insurance"     // 保險
    case donation = "donation"      // 奉獻
}

// 交易分類
enum TransactionCategory: String, Codable, CaseIterable {
    // 收入分類
    case salary = "salary"           // 薪資
    case bonus = "bonus"            // 獎金
    case investment_return = "investment_return" // 投資收益
    case business = "business"       // 營業收入
    case other_income = "other_income" // 其他收入
    
    // 支出分類
    case food = "food"              // 餐飲
    case transport = "transport"     // 交通
    case housing = "housing"        // 居住
    case utilities = "utilities"    // 水電瓦斯
    case healthcare = "healthcare"   // 醫療
    case education = "education"     // 教育
    case entertainment = "entertainment" // 娛樂
    case shopping = "shopping"      // 購物
    case insurance = "insurance"    // 保險
    case loan_payment = "loan_payment" // 貸款還款
    case investment = "investment"  // 投資
    case donation = "donation"     // 奉獻
    case other_expense = "other_expense" // 其他支出
}

// 交易狀態
enum TransactionStatus: String, Codable {
    case pending = "pending"        // 待確認
    case confirmed = "confirmed"     // 已確認
    case cancelled = "cancelled"    // 已取消
}

@Model
final class Transaction {
    // 唯一識別碼
    @Attribute(.unique) var id: UUID = UUID()
    
    // 基本資訊
    var amount: Double
    var type: String // TransactionType.rawValue
    var category: String // TransactionCategory.rawValue
    var transactionDescription: String
    var date: Date
    var status: String // TransactionStatus.rawValue
    
    // 輸入方式
    var inputMethod: String // "text", "voice", "image", "manual"
    var originalText: String? // 原始輸入文字
    var voiceFilePath: String? // 語音檔案路徑
    var imageFilePath: String? // 圖片檔案路徑
    
    // AI 分析結果
    var aiConfidence: Double? // AI 分析信心度 0-1
    var aiSuggestion: String? // AI 建議的分類
    var isAutoCategorized: Bool // 是否為 AI 自動分類
    
    // 帳戶資訊
    var fromAccount: String? // 來源帳戶
    var toAccount: String? // 目標帳戶
    
    // 標籤與備註
    var tags: [String] // 標籤
    var notes: String? // 備註
    
    // 發票資訊（台灣）
    var invoiceNumber: String? // 發票號碼
    var invoiceDate: Date? // 發票日期
    var merchantName: String? // 商家名稱
    var taxAmount: Double? // 稅額
    
    // 時間戳記
    var createdAt: Date
    var updatedAt: Date
    
    // 關聯
    @Relationship(deleteRule: .nullify, inverse: \User.transactions) var user: User?
    @Relationship(deleteRule: .nullify, inverse: \FamilyGroup.transactions) var familyGroup: FamilyGroup?
    
    init(amount: Double, type: TransactionType, category: TransactionCategory, description: String, date: Date = Date()) {
        self.amount = amount
        self.type = type.rawValue
        self.category = category.rawValue
        self.transactionDescription = description
        self.date = date
        self.status = TransactionStatus.confirmed.rawValue
        self.inputMethod = "manual"
        self.isAutoCategorized = false
        self.tags = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // 便利初始化方法
    convenience init(amount: Double, type: TransactionType, category: TransactionCategory, description: String, inputMethod: String, originalText: String?) {
        self.init(amount: amount, type: type, category: category, description: description)
        self.inputMethod = inputMethod
        self.originalText = originalText
    }
    
    // 更新交易資訊
    func update(amount: Double? = nil, category: TransactionCategory? = nil, description: String? = nil, notes: String? = nil) {
        if let amount = amount {
            self.amount = amount
        }
        if let category = category {
            self.category = category.rawValue
        }
        if let description = description {
            self.transactionDescription = description
        }
        if let notes = notes {
            self.notes = notes
        }
        self.updatedAt = Date()
    }
    
    // 添加標籤
    func addTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
        }
    }
    
    // 移除標籤
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    // 確認交易
    func confirm() {
        self.status = TransactionStatus.confirmed.rawValue
        self.updatedAt = Date()
    }
    
    // 取消交易
    func cancel() {
        self.status = TransactionStatus.cancelled.rawValue
        self.updatedAt = Date()
    }
    
    // 獲取交易類型枚舉
    func getTransactionType() -> TransactionType? {
        return TransactionType(rawValue: type)
    }
    
    // 獲取交易分類枚舉
    func getTransactionCategory() -> TransactionCategory? {
        return TransactionCategory(rawValue: category)
    }
    
    // 獲取交易狀態枚舉
    func getTransactionStatus() -> TransactionStatus? {
        return TransactionStatus(rawValue: status)
    }
    
    // 檢查是否為收入
    var isIncome: Bool {
        return getTransactionType() == .income
    }
    
    // 檢查是否為支出
    var isExpense: Bool {
        return getTransactionType() == .expense
    }
    
    // 獲取顯示金額（支出為負數）
    var displayAmount: Double {
        switch getTransactionType() {
        case .income, .investment:
            return amount
        case .expense, .loan, .insurance:
            return -amount
        case .transfer, .donation:
            return amount // 轉帳和奉獻保持原值
        case .none:
            return amount
        }
    }
}
