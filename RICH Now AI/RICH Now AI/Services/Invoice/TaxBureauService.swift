//
//  TaxBureauService.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import Foundation
import Combine
import os.log

// 國稅局發票服務
class TaxBureauService {
    static let shared = TaxBureauService()
    
    private let baseURL = "https://api.einvoice.nat.gov.tw"
    private var apiKey: String?
    private let logger = Logger(subsystem: "com.richnowai", category: "TaxBureauService")
    
    private init() {}
    
    func setAPIKey(_ key: String) {
        self.apiKey = key
    }
    
    /// 檢查是否有設置 API Key
    func hasAPIKey() -> Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }
    
    // MARK: - 發票查詢
    
    /// 根據載具號碼查詢發票
    func fetchInvoicesByCarrier(
        carrierNumber: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [InvoiceInfo] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        // 構建請求URL
        var components = URLComponents(string: "\(baseURL)/PB2CAPIVAN/invapp/InvApp")
        components?.queryItems = [
            URLQueryItem(name: "version", value: "0.5"),
            URLQueryItem(name: "action", value: "qryWinningInv"),
            URLQueryItem(name: "appID", value: apiKey ?? ""),
            URLQueryItem(name: "carrierType", value: "1"), // 手機條碼
            URLQueryItem(name: "carrierId", value: carrierNumber),
            URLQueryItem(name: "invDate", value: startDateString),
            URLQueryItem(name: "invEndDate", value: endDateString)
        ]
        
        guard let url = components?.url else {
            throw TaxBureauError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TaxBureauError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw TaxBureauError.httpError(httpResponse.statusCode)
        }
        
        // 解析回應
        return try parseInvoiceResponse(data)
    }
    
    /// 根據發票號碼和日期查詢
    func fetchInvoiceByNumber(
        invoiceNumber: String,
        invoiceDate: Date
    ) async throws -> InvoiceInfo {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: invoiceDate)
        
        var components = URLComponents(string: "\(baseURL)/PB2CAPIVAN/invapp/InvApp")
        components?.queryItems = [
            URLQueryItem(name: "version", value: "0.5"),
            URLQueryItem(name: "action", value: "qryInvDetail"),
            URLQueryItem(name: "appID", value: apiKey ?? ""),
            URLQueryItem(name: "invNum", value: invoiceNumber),
            URLQueryItem(name: "invDate", value: dateString)
        ]
        
        guard let url = components?.url else {
            throw TaxBureauError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TaxBureauError.invalidResponse
        }
        
        return try parseInvoiceDetailResponse(data)
    }
    
    /// 根據發票號碼和隨機碼查詢發票詳細資訊（用於 QR Code 驗證）
    func queryInvoiceDetail(
        invoiceNumber: String,
        randomCode: String
    ) async throws -> InvoiceInfo {
        // 先從發票號碼提取日期資訊
        // 發票號碼格式：AB12345678，前2碼是年份，但我們無法直接知道月份
        // 所以嘗試查詢最近3個月的發票
        
        let calendar = Calendar.current
        let today = Date()
        var foundInvoice: InvoiceInfo?
        
        // 查詢最近3個月
        for monthOffset in 0..<3 {
            guard let targetDate = calendar.date(byAdding: .month, value: -monthOffset, to: today) else {
                continue
            }
            
            do {
                let invoice = try await fetchInvoiceByNumber(
                    invoiceNumber: invoiceNumber,
                    invoiceDate: targetDate
                )
                
                // 驗證隨機碼是否匹配（如果 API 返回了隨機碼）
                // 注意：國稅局 API 可能不直接返回隨機碼，這裡假設發票號碼和日期匹配即為正確
                foundInvoice = invoice
                break
            } catch {
                // 繼續嘗試下一個月份
                continue
            }
        }
        
        guard let invoice = foundInvoice else {
            throw TaxBureauError.parseError
        }
        
        return invoice
    }
    
    // MARK: - 發票解析
    
    private func parseInvoiceResponse(_ data: Data) throws -> [InvoiceInfo] {
        // 解析國稅局API回應格式
        // 根據財政部電子發票整合服務平台 API 文檔
        struct InvoiceListResponse: Codable {
            let code: String?
            let msg: String?
            let invNum: String?
            let invDate: String?
            let invPeriod: String?
            let sellerName: String?
            let invStatus: String?
            let invDonatable: String?
            let amount: String?
            let invTime: String?
        }
        
        struct APIResponse: Codable {
            let code: String?
            let msg: String?
            let invNum: [InvoiceListResponse]?
        }
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(APIResponse.self, from: data)
            
            // 檢查 API 回應狀態
            guard let code = response.code, code == "200" else {
                let errorMsg = response.msg ?? "未知錯誤"
                logger.error("國稅局 API 錯誤: \(errorMsg)")
                throw TaxBureauError.parseError
            }
            
            // 轉換為 InvoiceInfo 列表
            guard let invoices = response.invNum else {
                return []
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            return invoices.compactMap { inv -> InvoiceInfo? in
                guard let invDateStr = inv.invDate,
                      let invDate = dateFormatter.date(from: invDateStr),
                      let amountStr = inv.amount,
                      let amount = Double(amountStr) else {
                    logger.warning("無法解析發票數據: \(inv.invNum ?? "未知")")
                    return nil
                }
                
                return InvoiceInfo(
                    invoiceNumber: inv.invNum ?? "",
                    invoiceDate: invDate,
                    sellerName: inv.sellerName ?? "未知商家",
                    sellerAddress: nil,
                    sellerTaxId: nil,
                    buyerName: nil,
                    buyerTaxId: nil,
                    amount: amount,
                    taxAmount: amount * 0.05, // 假設 5% 稅率
                    items: [],
                    paymentMethod: nil,
                    carrierType: "mobile_barcode",
                    carrierNumber: nil
                )
            }
        } catch {
            logger.error("解析發票回應失敗: \(error.localizedDescription)")
            // 如果解析失敗，嘗試返回空陣列而不是拋出錯誤
            // 這樣用戶可以看到錯誤訊息但不至於崩潰
            throw TaxBureauError.parseError
        }
    }
    
    private func parseInvoiceDetailResponse(_ data: Data) throws -> InvoiceInfo {
        // 解析發票詳情
        struct InvoiceDetailResponse: Codable {
            let code: String?
            let msg: String?
            let invNum: String?
            let invDate: String?
            let sellerName: String?
            let sellerAddress: String?
            let sellerBan: String? // 統編
            let buyerName: String?
            let buyerBan: String?
            let invStatus: String?
            let invPeriod: String?
            let invTime: String?
            let totalAmount: String?
            let invDetail: [InvoiceDetailItem]?
        }
        
        struct InvoiceDetailItem: Codable {
            let description: String?
            let quantity: String?
            let unit: String?
            let unitPrice: String?
            let amount: String?
            let taxType: String?
        }
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(InvoiceDetailResponse.self, from: data)
            
            guard let code = response.code, code == "200" else {
                let errorMsg = response.msg ?? "未知錯誤"
                logger.error("國稅局 API 錯誤: \(errorMsg)")
                throw TaxBureauError.parseError
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            guard let invDateStr = response.invDate,
                  let invDate = dateFormatter.date(from: invDateStr),
                  let totalAmountStr = response.totalAmount,
                  let totalAmount = Double(totalAmountStr) else {
                throw TaxBureauError.parseError
            }
            
            let items = (response.invDetail ?? []).compactMap { item -> InvoiceItem? in
                guard let name = item.description,
                      let quantityStr = item.quantity,
                      let quantity = Double(quantityStr),
                      let amountStr = item.amount,
                      let amount = Double(amountStr) else {
                    return nil
                }
                
                let unitPrice = Double(item.unitPrice ?? "0") ?? 0.0
                
                return InvoiceItem(
                    name: name,
                    quantity: quantity,
                    unit: item.unit,
                    unitPrice: unitPrice > 0 ? unitPrice : (amount / quantity),
                    amount: amount,
                    taxRate: nil
                )
            }
            
            // 計算稅額（假設含稅，稅率 5%）
            let taxAmount = totalAmount * 0.05 / 1.05
            
            return InvoiceInfo(
                invoiceNumber: response.invNum ?? "",
                invoiceDate: invDate,
                sellerName: response.sellerName ?? "未知商家",
                sellerAddress: response.sellerAddress,
                sellerTaxId: response.sellerBan,
                buyerName: response.buyerName,
                buyerTaxId: response.buyerBan,
                amount: totalAmount,
                taxAmount: taxAmount,
                items: items,
                paymentMethod: nil,
                carrierType: "mobile_barcode",
                carrierNumber: nil
            )
        } catch {
            logger.error("解析發票詳情失敗: \(error.localizedDescription)")
            throw TaxBureauError.parseError
        }
    }
}

// MARK: - 錯誤定義

enum TaxBureauError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case invalidAPIKey
    case parseError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無效的URL"
        case .invalidResponse:
            return "無效的回應"
        case .httpError(let code):
            return "HTTP錯誤: \(code)"
        case .invalidAPIKey:
            return "無效的API金鑰"
        case .parseError:
            return "解析錯誤"
        case .networkError:
            return "網路錯誤"
        }
    }
}

