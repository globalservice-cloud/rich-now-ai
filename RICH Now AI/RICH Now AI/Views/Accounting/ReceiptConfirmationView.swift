//
//  ReceiptConfirmationView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import SwiftUI
import SwiftData

// 收據確認視圖（可編輯）
struct ReceiptConfirmationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State var editableData: EditableReceiptData
    let originalData: ExtractedReceiptData
    let onConfirm: (ExtractedReceiptData) -> Void
    let onCancel: () -> Void
    
    @State private var isSaving = false
    @State private var showSuccessMessage = false
    
    init(data: ExtractedReceiptData, onConfirm: @escaping (ExtractedReceiptData) -> Void, onCancel: @escaping () -> Void) {
        self.originalData = data
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        
        // 初始化可編輯數據
        self._editableData = State(initialValue: EditableReceiptData(
            merchant: data.merchant,
            amount: data.amount,
            currency: data.currency,
            date: data.date,
            category: data.category,
            paymentMethod: data.paymentMethod,
            tax: data.tax,
            total: data.total,
            notes: data.notes,
            invoiceNumber: data.invoiceNumber ?? "",
            sellerTaxId: data.sellerTaxId ?? "",
            items: data.items
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 標題和信心度
                    VStack(spacing: 12) {
                        Text("確認收據資訊")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // 信心度和資料來源指示器
                        VStack(spacing: 8) {
                            HStack {
                                Text("AI 判讀信心度")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                HStack(spacing: 4) {
                                    Text("\(Int(originalData.confidence * 100))%")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(originalData.confidence > 0.8 ? .green : originalData.confidence > 0.6 ? .orange : .red)
                                    
                                    Circle()
                                        .fill(originalData.confidence > 0.8 ? .green : originalData.confidence > 0.6 ? .orange : .red)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            
                            // 資料來源標示
                            HStack {
                                Text("資料來源")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: dataSourceIcon(for: originalData.dataSource))
                                        .font(.caption2)
                                        .foregroundColor(dataSourceColor(for: originalData.dataSource))
                                    Text(dataSourceText(for: originalData.dataSource))
                                        .font(.caption)
                                        .foregroundColor(dataSourceColor(for: originalData.dataSource))
                                }
                            }
                            
                            // 驗證狀態
                            if originalData.verificationStatus == .verified {
                                HStack {
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.shield.fill")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                        Text("已驗證")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // 可編輯欄位
                    VStack(spacing: 16) {
                        // 商家名稱
                        EditableField(
                            title: "商家名稱",
                            value: $editableData.merchant,
                            placeholder: "輸入商家名稱"
                        )
                        
                        // 金額
                        VStack(alignment: .leading, spacing: 8) {
                            Text("金額")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(editableData.currency)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                TextField("0.00", value: $editableData.amount, format: .number)
                                    .font(.system(size: 18, weight: .semibold))
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // 日期
                        VStack(alignment: .leading, spacing: 8) {
                            Text("日期")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            TextField("選擇日期", text: $editableData.date)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    DatePicker("", selection: Binding(
                                        get: {
                                            // 嘗試解析日期字串
                                            let formatter = DateFormatter()
                                            formatter.dateFormat = "yyyy-MM-dd"
                                            return formatter.date(from: editableData.date) ?? Date()
                                        },
                                        set: { newDate in
                                            let formatter = DateFormatter()
                                            formatter.dateFormat = "yyyy-MM-dd"
                                            editableData.date = formatter.string(from: newDate)
                                        }
                                    ), displayedComponents: .date)
                                        .labelsHidden()
                                        .opacity(0.011) // 透明但可點擊
                                )
                        }
                        
                        // 分類
                        VStack(alignment: .leading, spacing: 8) {
                            Text("分類")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Picker("分類", selection: $editableData.category) {
                                ForEach(transactionCategories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // 付款方式
                        EditableField(
                            title: "付款方式",
                            value: $editableData.paymentMethod,
                            placeholder: "輸入付款方式"
                        )
                        
                        // 稅額
                        VStack(alignment: .leading, spacing: 8) {
                            Text("稅額")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(editableData.currency)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                TextField("0.00", value: $editableData.tax, format: .number)
                                    .font(.system(size: 16))
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // 總額
                        VStack(alignment: .leading, spacing: 8) {
                            Text("總額")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(editableData.currency)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                TextField("0.00", value: $editableData.total, format: .number)
                                    .font(.system(size: 16, weight: .semibold))
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // 發票號碼（如果有）
                        if !editableData.invoiceNumber.isEmpty {
                            EditableField(
                                title: "發票號碼",
                                value: Binding(
                                    get: { editableData.invoiceNumber },
                                    set: { editableData.invoiceNumber = $0 }
                                ),
                                placeholder: "輸入發票號碼"
                            )
                        }
                        
                        // 店家統編（如果有）
                        if !editableData.sellerTaxId.isEmpty {
                            EditableField(
                                title: "店家統編",
                                value: Binding(
                                    get: { editableData.sellerTaxId },
                                    set: { editableData.sellerTaxId = $0 }
                                ),
                                placeholder: "輸入統編"
                            )
                        }
                        
                        // 商品明細
                        if !editableData.items.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("商品明細")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                ForEach(editableData.items.indices, id: \.self) { index in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            TextField("商品名稱", text: Binding(
                                                get: { editableData.items[index].name },
                                                set: { newValue in
                                                    editableData.items[index] = ReceiptItem(name: newValue, price: editableData.items[index].price, quantity: editableData.items[index].quantity)
                                                }
                                            ))
                                            HStack {
                                                Text("數量: \(editableData.items[index].quantity)")
                                                Spacer()
                                                Text("單價: \(editableData.items[index].price, specifier: "%.2f")")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        }
                                        
                                        Button(action: {
                                            editableData.items.remove(at: index)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    editableData.items.append(ReceiptItem(name: "", price: 0, quantity: 1))
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("新增商品")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        // 備註
                        VStack(alignment: .leading, spacing: 8) {
                            Text("備註")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $editableData.notes)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 操作按鈕
                    HStack(spacing: 12) {
                        Button("取消") {
                            onCancel()
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        Button(action: confirmAndSave) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("確認並儲存")
                                }
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.12, green: 0.23, blue: 0.54), Color(red: 0.19, green: 0.18, blue: 0.51)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .disabled(isSaving)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("確認收據")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        confirmAndSave()
                    }
                }
            }
            .alert("儲存成功", isPresented: $showSuccessMessage) {
                Button("確定") {
                    dismiss()
                }
            } message: {
                Text("收據已成功儲存")
            }
        }
    }
    
    private func confirmAndSave() {
        isSaving = true
        
        // 轉換回 ExtractedReceiptData 格式
        let confirmedData = ExtractedReceiptData(
            merchant: editableData.merchant,
            amount: editableData.amount,
            currency: editableData.currency,
            date: editableData.date,
            items: editableData.items, // 使用編輯後的項目
            tax: editableData.tax,
            total: editableData.total,
            paymentMethod: editableData.paymentMethod,
            category: editableData.category,
            confidence: originalData.confidence, // 保留原始信心度
            notes: editableData.notes,
            extractedAt: originalData.extractedAt,
            invoiceNumber: editableData.invoiceNumber.isEmpty ? nil : editableData.invoiceNumber,
            randomCode: originalData.randomCode,
            sellerTaxId: editableData.sellerTaxId.isEmpty ? nil : editableData.sellerTaxId,
            invoiceDate: originalData.invoiceDate,
            dataSource: originalData.dataSource,
            verificationStatus: originalData.verificationStatus
        )
        
        // 延遲一下以顯示保存動畫
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onConfirm(confirmedData)
            isSaving = false
            showSuccessMessage = true
        }
    }
    
    private func dataSourceIcon(for source: DataSource) -> String {
        switch source {
        case .qrCode:
            return "qrcode"
        case .ocr:
            return "text.viewfinder"
        case .hybrid:
            return "square.stack.3d.up"
        case .taxBureau:
            return "building.2"
        }
    }
    
    private func dataSourceColor(for source: DataSource) -> Color {
        switch source {
        case .qrCode:
            return .blue
        case .ocr:
            return .orange
        case .hybrid:
            return .purple
        case .taxBureau:
            return .green
        }
    }
    
    private func dataSourceText(for source: DataSource) -> String {
        switch source {
        case .qrCode:
            return "QR Code"
        case .ocr:
            return "OCR 辨識"
        case .hybrid:
            return "混合模式"
        case .taxBureau:
            return "國稅局 API"
        }
    }
    
    private var transactionCategories: [String] {
        ["餐飲", "交通", "居住", "娛樂", "教育", "醫療", "購物", "其他"]
    }
}

// 可編輯的收據數據
struct EditableReceiptData {
    var merchant: String
    var amount: Double
    var currency: String
    var date: String
    var category: String
    var paymentMethod: String
    var tax: Double
    var total: Double
    var notes: String
    var invoiceNumber: String = ""
    var sellerTaxId: String = ""
    var items: [ReceiptItem] = []
}

// 可編輯欄位視圖
struct EditableField: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $value)
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

