//
//  TextAccountingView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import SwiftData

struct TextAccountingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var transactionParser = TransactionParser()
    @State private var inputText = ""
    @State private var isProcessing = false
    @State private var parsedTransaction: ParsedTransaction?
    @State private var parsedTransactions: [ParsedTransaction] = []
    @State private var showConfirmation = false
    @State private var showMultipleConfirmation = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // 標題區域
                        VStack(spacing: 12) {
                            Text("💬")
                                .font(.system(size: 50))
                            
                            Text(LocalizationManager.shared.localizedString("text_accounting.title"))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(LocalizationManager.shared.localizedString("text_accounting.subtitle"))
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Text("💡 提示：可以一次輸入多筆交易，用「，」或「和」分隔，例如：「午餐 150 元，咖啡 80 元，公車 30 元」")
                                .font(.system(size: 13))
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.top, 4)
                        }
                        .padding(.top, 20)
                        
                        // 輸入區域
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(LocalizationManager.shared.localizedString("text_accounting.input_label"))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // 縮回鍵盤按鈕
                                if isTextFieldFocused {
                                    Button(action: {
                                        isTextFieldFocused = false
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "keyboard.chevron.compact.down")
                                                .font(.system(size: 14))
                                            Text("收起鍵盤")
                                                .font(.system(size: 14))
                                        }
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            
                            TextEditor(text: $inputText)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .focused($isTextFieldFocused)
                                .onChange(of: isTextFieldFocused) { _, focused in
                                    if focused {
                                        // 當鍵盤出現時，延遲一下後滾動到按鈕
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                proxy.scrollTo("analyzeButton", anchor: .bottom)
                                            }
                                        }
                                    }
                                }
                            
                            // 範例文字
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizationManager.shared.localizedString("text_accounting.examples_title"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• \(LocalizationManager.shared.localizedString("text_accounting.example1"))")
                                    Text("• \(LocalizationManager.shared.localizedString("text_accounting.example2"))")
                                    Text("• \(LocalizationManager.shared.localizedString("text_accounting.example3"))")
                                    Text("• \(LocalizationManager.shared.localizedString("text_accounting.example4"))")
                                }
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            }
                        }
                        
                        // 處理按鈕
                        Button(action: processTransaction) {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                
                                Text(isProcessing ? 
                                     LocalizationManager.shared.localizedString("text_accounting.processing") : 
                                     LocalizationManager.shared.localizedString("text_accounting.analyze"))
                                    .font(.system(size: 16, weight: .semibold))
                            }
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
                        }
                        .id("analyzeButton")
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                        .opacity(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                        
                        // 錯誤訊息
                        if let errorMessage = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // 成功訊息
                        if let successMessage = successMessage {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(successMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // 底部填充，確保按鈕在鍵盤上方可見
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .navigationTitle(LocalizationManager.shared.localizedString("text_accounting.navigation_title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(LocalizationManager.shared.localizedString("common.cancel")) {
                            dismiss()
                        }
                    }
                    
                    // 在 toolbar 中也添加縮回鍵盤按鈕（當鍵盤顯示時）
                    ToolbarItem(placement: .keyboard) {
                        HStack {
                            Spacer()
                            Button(action: {
                                isTextFieldFocused = false
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "keyboard.chevron.compact.down")
                                        .font(.system(size: 14))
                                    Text("完成")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showConfirmation) {
            if let parsedTransaction = parsedTransaction {
                TransactionConfirmationView(
                    parsedTransaction: parsedTransaction,
                    onConfirm: { confirmedTransaction in
                        saveTransaction(confirmedTransaction)
                    },
                    onCancel: {
                        showConfirmation = false
                        self.parsedTransaction = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showMultipleConfirmation) {
            MultipleTransactionsConfirmationView(
                transactions: parsedTransactions,
                onConfirm: { confirmedTransactions in
                    saveMultipleTransactions(confirmedTransactions)
                },
                onCancel: {
                    showMultipleConfirmation = false
                    self.parsedTransactions = []
                }
            )
        }
    }
    
    private func processTransaction() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isProcessing = true
        errorMessage = nil
        successMessage = nil
        parsedTransaction = nil
        parsedTransactions = []
        
        Task {
            do {
                // 嘗試解析多筆交易
                let parsed = try await transactionParser.parseMultipleTransactions(from: inputText)
                
                await MainActor.run {
                    self.isProcessing = false
                    
                    if parsed.count > 1 {
                        // 多筆交易
                        self.parsedTransactions = parsed
                        self.showMultipleConfirmation = true
                    } else if parsed.count == 1 {
                        // 單筆交易
                        self.parsedTransaction = parsed.first
                        self.showConfirmation = true
                    } else {
                        // 解析失敗
                        self.errorMessage = "無法解析交易記錄，請檢查輸入格式"
                    }
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func saveTransaction(_ transaction: ParsedTransaction) {
        // 轉換為 Transaction 模型
        let transactionType: TransactionType = transaction.type == .income ? .income : .expense
        let category = mapCategoryToTransactionCategory(transaction.category)
        
        let newTransaction = Transaction(
            amount: transaction.amount,
            type: transactionType,
            category: category,
            description: transaction.description,
            inputMethod: "text",
            originalText: inputText
        )
        
        // 設定 AI 分析結果
        newTransaction.isAutoCategorized = true
        newTransaction.aiConfidence = 0.9 // 假設高信心度
        newTransaction.aiSuggestion = transaction.category
        
        // 保存到資料庫
        modelContext.insert(newTransaction)
        
        do {
            try modelContext.save()
            
            // 顯示成功訊息
            successMessage = LocalizationManager.shared.localizedString("text_accounting.success")
            
            // 清空輸入
            inputText = ""
            parsedTransaction = nil
            showConfirmation = false
            
            // 2秒後關閉視圖
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        } catch {
            errorMessage = LocalizationManager.shared.localizedString("text_accounting.save_error")
        }
    }
    
    private func mapCategoryToTransactionCategory(_ category: String) -> TransactionCategory {
        switch category {
        case "餐飲":
            return .food
        case "交通":
            return .transport
        case "居住":
            return .housing
        case "娛樂":
            return .entertainment
        case "教育":
            return .education
        case "醫療":
            return .healthcare
        case "購物":
            return .shopping
        case "薪資":
            return .salary
        case "投資收益":
            return .investment_return
        case "禮物":
            return .other_expense
        default:
            return .other_expense
        }
    }
    
    private func saveMultipleTransactions(_ transactions: [ParsedTransaction]) {
        var savedCount = 0
        
        for transaction in transactions {
            let transactionType: TransactionType = transaction.type == .income ? .income : .expense
            let category = mapCategoryToTransactionCategory(transaction.category)
            
            let newTransaction = Transaction(
                amount: transaction.amount,
                type: transactionType,
                category: category,
                description: transaction.description,
                inputMethod: "text",
                originalText: inputText
            )
            
            newTransaction.isAutoCategorized = true
            newTransaction.aiConfidence = 0.9
            newTransaction.aiSuggestion = transaction.category
            
            modelContext.insert(newTransaction)
            savedCount += 1
        }
        
        do {
            try modelContext.save()
            
            // 顯示成功訊息
            successMessage = "成功記錄 \(savedCount) 筆交易！"
            
            // 清空輸入
            inputText = ""
            parsedTransactions = []
            showMultipleConfirmation = false
            
            // 2秒後關閉視圖
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        } catch {
            errorMessage = "保存失敗：\(error.localizedDescription)"
        }
    }
}

// 交易確認視圖
struct TransactionConfirmationView: View {
    let parsedTransaction: ParsedTransaction
    let onConfirm: (ParsedTransaction) -> Void
    let onCancel: () -> Void
    
    @State private var amount: Double
    @State private var category: String
    @State private var description: String
    @State private var selectedType: TransactionType
    
    init(parsedTransaction: ParsedTransaction, onConfirm: @escaping (ParsedTransaction) -> Void, onCancel: @escaping () -> Void) {
        self.parsedTransaction = parsedTransaction
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        
        self._amount = State(initialValue: parsedTransaction.amount)
        self._category = State(initialValue: parsedTransaction.category)
        self._description = State(initialValue: parsedTransaction.description)
        self._selectedType = State(initialValue: parsedTransaction.type)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 標題
                VStack(spacing: 8) {
                    Text("✅")
                        .font(.system(size: 40))
                    
                    Text(LocalizationManager.shared.localizedString("text_accounting.confirmation_title"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(LocalizationManager.shared.localizedString("text_accounting.confirmation_subtitle"))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // 交易詳情
                VStack(spacing: 16) {
                    // 金額
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationManager.shared.localizedString("text_accounting.amount"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("$")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(selectedType == .income ? .green : .red)
                            
                            TextField("0.00", value: $amount, format: .currency(code: "TWD"))
                                .font(.system(size: 20, weight: .bold))
                                .keyboardType(.decimalPad)
                                .foregroundColor(selectedType == .income ? .green : .red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // 類型選擇
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationManager.shared.localizedString("text_accounting.type"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Button(action: { selectedType = .income }) {
                                HStack {
                                    Image(systemName: "arrow.up.circle.fill")
                                    Text(LocalizationManager.shared.localizedString("transaction.income"))
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedType == .income ? .white : .green)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedType == .income ? Color.green : Color.green.opacity(0.1))
                                .cornerRadius(20)
                            }
                            
                            Button(action: { selectedType = .expense }) {
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text(LocalizationManager.shared.localizedString("transaction.expense"))
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedType == .expense ? .white : .red)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedType == .expense ? Color.red : Color.red.opacity(0.1))
                                .cornerRadius(20)
                            }
                        }
                    }
                    
                    // 分類
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationManager.shared.localizedString("text_accounting.category"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(category)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // 描述
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationManager.shared.localizedString("text_accounting.description"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextField(LocalizationManager.shared.localizedString("text_accounting.description_placeholder"), text: $description)
                            .font(.system(size: 16))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                // 按鈕
                HStack(spacing: 12) {
                    Button(LocalizationManager.shared.localizedString("common.cancel")) {
                        onCancel()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Button(LocalizationManager.shared.localizedString("common.confirm")) {
                        let updatedTransaction = ParsedTransaction(
                            amount: amount,
                            category: category,
                            description: description,
                            date: parsedTransaction.date,
                            type: selectedType
                        )
                        onConfirm(updatedTransaction)
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
                }
            }
            .padding(.horizontal, 20)
            .navigationTitle(LocalizationManager.shared.localizedString("text_accounting.confirm_transaction"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    TextAccountingView()
}
