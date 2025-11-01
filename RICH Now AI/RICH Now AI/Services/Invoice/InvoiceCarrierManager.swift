//
//  InvoiceCarrierManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import Foundation
import SwiftData
import Combine
import os.log

// 發票載具管理器
@MainActor
class InvoiceCarrierManager: ObservableObject {
    static let shared = InvoiceCarrierManager()
    
    @Published var carriers: [InvoiceCarrier] = []
    @Published var defaultCarrier: InvoiceCarrier?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    
    private var modelContext: ModelContext?
    private var currentUser: User?
    private let taxBureauService = TaxBureauService.shared
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.richnowai", category: "InvoiceCarrierManager")
    
    private init() {}
    
    func setModelContext(_ context: ModelContext, user: User? = nil) {
        self.modelContext = context
        
        // 如果沒有傳入用戶，嘗試從 ModelContext 獲取第一個用戶
        if let user = user {
            self.currentUser = user
        } else {
            Task { @MainActor in
                await loadCurrentUser()
            }
        }
        
        loadCarriers()
    }
    
    private func loadCurrentUser() async {
        guard let modelContext = modelContext else { return }
        
        do {
            var descriptor = FetchDescriptor<User>()
            descriptor.fetchLimit = 1
            let users = try modelContext.fetch(descriptor)
            self.currentUser = users.first
        } catch {
            logger.error("獲取當前用戶失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 載具管理
    
    func loadCarriers() {
        guard let modelContext = modelContext else {
            errorMessage = "ModelContext not initialized"
            return
        }
        
        do {
            var descriptor = FetchDescriptor<InvoiceCarrier>()
            descriptor.sortBy = [SortDescriptor(\InvoiceCarrier.createdAt)]
            let fetchedCarriers = try modelContext.fetch(descriptor)
            
            // 手動排序：預設載具在前，然後按創建日期
            let sortedCarriers = fetchedCarriers.sorted { first, second in
                if first.isDefault != second.isDefault {
                    return first.isDefault
                }
                return first.createdAt > second.createdAt
            }
            
            self.carriers = sortedCarriers
            self.defaultCarrier = sortedCarriers.first { $0.isDefault } ?? sortedCarriers.first
        } catch {
            self.errorMessage = "Failed to load carriers: \(error.localizedDescription)"
        }
    }
    
    func addCarrier(
        type: CarrierType,
        number: String,
        name: String,
        isDefault: Bool = false
    ) -> Bool {
        guard let modelContext = modelContext else {
            errorMessage = "ModelContext 未初始化"
            logger.error("ModelContext 未初始化，無法添加載具")
            return false
        }
        
        // 檢查是否已存在
        let existing = carriers.first { $0.carrierNumber == number && $0.carrierType == type.rawValue }
        if existing != nil {
            errorMessage = "此載具已存在"
            logger.warning("嘗試添加重複的載具: \(number)")
            return false
        }
        
        // 如果設為預設，取消其他預設
        if isDefault {
            for carrier in carriers where carrier.isDefault {
                carrier.isDefault = false
                carrier.updatedAt = Date()
            }
        }
        
        // 如果沒有當前用戶，嘗試加載
        if currentUser == nil {
            Task { @MainActor in
                await loadCurrentUser()
            }
            // 再次檢查
            if currentUser == nil {
                do {
                    var descriptor = FetchDescriptor<User>()
                    descriptor.fetchLimit = 1
                    let users = try modelContext.fetch(descriptor)
                    currentUser = users.first
                } catch {
                    logger.error("獲取當前用戶失敗: \(error.localizedDescription)")
                }
            }
        }
        
        let carrier = InvoiceCarrier(
            carrierType: type,
            carrierNumber: number,
            carrierName: name,
            isDefault: isDefault
        )
        
        // 關聯到當前用戶
        if let user = currentUser {
            carrier.user = user
        }
        
        modelContext.insert(carrier)
        
        do {
            try modelContext.save()
            
            // 重新加載載具列表以確保數據一致性
            loadCarriers()
            
            logger.info("成功添加載具: \(name) (\(number))")
            errorMessage = nil
            return true
        } catch {
            let errorDesc = error.localizedDescription
            errorMessage = "保存載具失敗: \(errorDesc)"
            logger.error("保存載具失敗: \(errorDesc)")
            logger.error("詳細錯誤: \(error)")
            return false
        }
    }
    
    func setDefaultCarrier(_ carrier: InvoiceCarrier) {
        guard let modelContext = modelContext else { return }
        
        // 取消其他預設
        for c in carriers where c.isDefault && c.id != carrier.id {
            c.isDefault = false
        }
        
        carrier.isDefault = true
        defaultCarrier = carrier
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to set default carrier: \(error.localizedDescription)"
        }
    }
    
    func removeCarrier(_ carrier: InvoiceCarrier) {
        guard let modelContext = modelContext else { return }
        
        modelContext.delete(carrier)
        
        do {
            try modelContext.save()
            carriers.removeAll { $0.id == carrier.id }
            if defaultCarrier?.id == carrier.id {
                defaultCarrier = carriers.first
            }
        } catch {
            errorMessage = "Failed to remove carrier: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 發票同步
    
    func syncInvoicesFromTaxBureau(
        carrier: InvoiceCarrier? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async {
        let targetCarrier = carrier ?? defaultCarrier
        guard let carrier = targetCarrier else {
            errorMessage = "請先設定發票載具"
            return
        }
        
        let start = startDate ?? Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let end = endDate ?? Date()
        
        isSyncing = true
        errorMessage = nil
        
        do {
            logger.info("開始同步發票: 載具=\(carrier.carrierName), 期間=\(start)...\(end)")
            
            let invoices = try await taxBureauService.fetchInvoicesByCarrier(
                carrierNumber: carrier.carrierNumber,
                startDate: start,
                endDate: end
            )
            
            logger.info("成功獲取 \(invoices.count) 張發票")
            
            // 將發票轉換為交易記錄
            await createTransactionsFromInvoices(invoices)
            
            // 更新載具最後同步時間
            carrier.lastSyncDate = Date()
            carrier.updatedAt = Date()
            
            if let modelContext = modelContext {
                try modelContext.save()
            }
            
            lastSyncDate = Date()
            isSyncing = false
            
            logger.info("發票同步完成")
            
        } catch {
            let errorDesc = error.localizedDescription
            logger.error("同步發票失敗: \(errorDesc)")
            errorMessage = "同步發票失敗: \(errorDesc)"
            isSyncing = false
        }
    }
    
    private func createTransactionsFromInvoices(_ invoices: [InvoiceInfo]) async {
        guard let modelContext = modelContext else {
            logger.error("ModelContext 未初始化，無法創建交易記錄")
            return
        }
        
        var successCount = 0
        var duplicateCount = 0
        
        // 檢查現有交易，避免重複創建
        let existingInvoiceNumbers = await getExistingInvoiceNumbers(context: modelContext)
        
        for invoice in invoices {
            // 檢查是否已存在相同的發票
            if existingInvoiceNumbers.contains(invoice.invoiceNumber) {
                duplicateCount += 1
                logger.debug("跳過重複發票: \(invoice.invoiceNumber)")
                continue
            }
            
            // 創建交易記錄
            let transaction = Transaction(
                amount: invoice.amount,
                type: .expense,
                category: determineCategory(from: invoice),
                description: invoice.sellerName,
                date: invoice.invoiceDate
            )
            
            // 添加發票資訊
            transaction.notes = buildTransactionNotes(from: invoice)
            transaction.invoiceNumber = invoice.invoiceNumber
            transaction.invoiceDate = invoice.invoiceDate
            transaction.merchantName = invoice.sellerName
            transaction.taxAmount = invoice.taxAmount
            transaction.inputMethod = "invoice_sync"
            transaction.isAutoCategorized = true
            
            modelContext.insert(transaction)
            successCount += 1
        }
        
        do {
            try modelContext.save()
            logger.info("成功創建 \(successCount) 筆交易記錄，跳過 \(duplicateCount) 筆重複發票")
        } catch {
            let errorDesc = error.localizedDescription
            logger.error("保存交易記錄失敗: \(errorDesc)")
            errorMessage = "創建交易記錄失敗: \(errorDesc)"
        }
    }
    
    // 輔助方法：獲取現有發票號碼
    private func getExistingInvoiceNumbers(context: ModelContext) async -> Set<String> {
        do {
            var descriptor = FetchDescriptor<Transaction>()
            descriptor.predicate = #Predicate<Transaction> { $0.invoiceNumber != nil }
            let transactions = try context.fetch(descriptor)
            return Set(transactions.compactMap { $0.invoiceNumber })
        } catch {
            logger.warning("獲取現有發票號碼失敗: \(error.localizedDescription)")
            return []
        }
    }
    
    // 輔助方法：根據發票資訊判斷分類
    private func determineCategory(from invoice: InvoiceInfo) -> TransactionCategory {
        let sellerName = invoice.sellerName.lowercased()
        
        // 簡單的分類判斷邏輯
        if sellerName.contains("7-11") || sellerName.contains("全家") || sellerName.contains("ok") {
            return .food
        } else if sellerName.contains("中油") || sellerName.contains("台塑") || sellerName.contains("加油站") {
            return .transport
        } else if sellerName.contains("醫院") || sellerName.contains("診所") || sellerName.contains("藥局") {
            return .healthcare
        } else if sellerName.contains("學校") || sellerName.contains("教育") {
            return .education
        } else {
            return .shopping
        }
    }
    
    // 輔助方法：構建交易備註
    private func buildTransactionNotes(from invoice: InvoiceInfo) -> String {
        var notes = "發票號碼: \(invoice.invoiceNumber)"
        
        if !invoice.items.isEmpty {
            let itemsText = invoice.items.prefix(5).map { item in
                "\(item.name) x\(Int(item.quantity))"
            }.joined(separator: ", ")
            notes += "\n商品: \(itemsText)"
            if invoice.items.count > 5 {
                notes += " 等 \(invoice.items.count) 項"
            }
        }
        
        if invoice.taxAmount > 0 {
            notes += "\n稅額: \(String(format: "%.2f", invoice.taxAmount))"
        }
        
        return notes
    }
    
    // MARK: - 自動同步設定
    
    func enableAutoSync(interval: TimeInterval = 3600) {
        // 每小時自動同步一次
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.syncInvoicesFromTaxBureau()
                }
            }
            .store(in: &cancellables)
    }
}

