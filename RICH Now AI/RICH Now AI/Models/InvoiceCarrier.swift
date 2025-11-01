//
//  InvoiceCarrier.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import Foundation
import SwiftData
import SwiftUI

// 發票載具模型
@Model
final class InvoiceCarrier {
    @Attribute(.unique) var id: UUID = UUID()
    var carrierType: String          // 載具類型（手機條碼、自然人憑證等）
    var carrierNumber: String        // 載具號碼
    var carrierName: String          // 載具名稱/別名
    var isDefault: Bool              // 是否為預設載具
    var isActive: Bool               // 是否啟用
    var lastSyncDate: Date?          // 最後同步日期
    var createdAt: Date
    var updatedAt: Date
    
    // 關聯
    @Relationship(deleteRule: .nullify, inverse: \User.invoiceCarriers) var user: User?
    
    init(
        carrierType: CarrierType,
        carrierNumber: String,
        carrierName: String,
        isDefault: Bool = false
    ) {
        self.carrierType = carrierType.rawValue
        self.carrierNumber = carrierNumber
        self.carrierName = carrierName
        self.isDefault = isDefault
        self.isActive = true
        self.lastSyncDate = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var type: CarrierType {
        get { CarrierType(rawValue: carrierType) ?? .mobileBarcode }
        set { carrierType = newValue.rawValue }
    }
}

// 載具類型
enum CarrierType: String, Codable, CaseIterable {
    case mobileBarcode = "mobile_barcode"     // 手機條碼
    case naturalPerson = "natural_person"     // 自然人憑證
    case membership = "membership"            // 會員載具
    
    var displayName: String {
        switch self {
        case .mobileBarcode: return "手機條碼"
        case .naturalPerson: return "自然人憑證"
        case .membership: return "會員載具"
        }
    }
    
    var icon: String {
        switch self {
        case .mobileBarcode: return "qrcode"
        case .naturalPerson: return "person.badge.key"
        case .membership: return "person.circle.fill"
        }
    }
}

// 發票資訊
struct InvoiceInfo: Codable {
    let invoiceNumber: String        // 發票號碼
    let invoiceDate: Date            // 發票日期
    let sellerName: String           // 賣方名稱
    let sellerAddress: String?       // 賣方地址
    let sellerTaxId: String?         // 賣方統編
    let buyerName: String?           // 買方名稱
    let buyerTaxId: String?          // 買方統編
    let amount: Double               // 總金額
    let taxAmount: Double            // 稅額
    let items: [InvoiceItem]         // 發票明細
    let paymentMethod: String?       // 付款方式
    let carrierType: String?         // 載具類型
    let carrierNumber: String?       // 載具號碼
}

// 發票明細項目
struct InvoiceItem: Codable {
    let name: String                 // 商品名稱
    let quantity: Double             // 數量
    let unit: String?                // 單位
    let unitPrice: Double            // 單價
    let amount: Double               // 小計
    let taxRate: Double?             // 稅率
}

