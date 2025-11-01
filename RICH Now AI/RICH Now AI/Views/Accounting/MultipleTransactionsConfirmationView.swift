//
//  MultipleTransactionsConfirmationView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import SwiftUI

// 多筆交易確認視圖
struct MultipleTransactionsConfirmationView: View {
    let transactions: [ParsedTransaction]
    let onConfirm: ([ParsedTransaction]) -> Void
    let onCancel: () -> Void
    
    @State private var editableTransactions: [EditableTransaction]
    @State private var isSaving = false
    
    init(transactions: [ParsedTransaction], onConfirm: @escaping ([ParsedTransaction]) -> Void, onCancel: @escaping () -> Void) {
        self.transactions = transactions
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        
        // 初始化可編輯的交易列表
        self._editableTransactions = State(initialValue: transactions.map { transaction in
            EditableTransaction(
                amount: transaction.amount,
                category: transaction.category,
                description: transaction.description,
                type: transaction.type,
                date: transaction.date
            )
        })
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 標題區域
                VStack(spacing: 8) {
                    Text("📝")
                        .font(.system(size: 40))
                    
                    Text("確認多筆交易")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("共 \(transactions.count) 筆交易，請檢查並確認")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // 交易列表
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(editableTransactions.enumerated()), id: \.offset) { index, transaction in
                            TransactionEditCard(
                                transaction: $editableTransactions[index],
                                index: index + 1
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                
                // 底部按鈕
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
                    
                    Button(action: {
                        confirmAllTransactions()
                    }) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                    Image(systemName: "checkmark.circle.fill")
                                Text("確認全部 (\(transactions.count) 筆)")
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
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, 12)
                .background(Color(.systemBackground))
            }
            .navigationTitle("確認交易")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func confirmAllTransactions() {
        isSaving = true
        
        // 轉換回 ParsedTransaction 格式
        let confirmedTransactions = editableTransactions.map { editable in
            ParsedTransaction(
                amount: editable.amount,
                category: editable.category,
                description: editable.description,
                date: editable.date,
                type: editable.type
            )
        }
        
        // 延遲一下以顯示保存動畫
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onConfirm(confirmedTransactions)
            isSaving = false
        }
    }
}

// 可編輯的交易結構
struct EditableTransaction {
    var amount: Double
    var category: String
    var description: String
    var type: TransactionType
    var date: Date
}

// 交易編輯卡片
struct TransactionEditCard: View {
    @Binding var transaction: EditableTransaction
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 交易編號
            HStack {
                Text("交易 \(index)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(transaction.type == .income ? "收入" : "支出")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(transaction.type == .income ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((transaction.type == .income ? Color.green : Color.red).opacity(0.1))
                    .cornerRadius(8)
            }
            
            // 金額
            HStack {
                Text("💰")
                    .font(.system(size: 20))
                Text("$\(String(format: "%.2f", transaction.amount))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(transaction.type == .income ? .green : .red)
            }
            
            // 類別
            HStack {
                Text("📂")
                    .font(.system(size: 16))
                Text(transaction.category)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }
            
            // 描述
            if !transaction.description.isEmpty {
                HStack(alignment: .top) {
                    Text("📝")
                        .font(.system(size: 16))
                    Text(transaction.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    MultipleTransactionsConfirmationView(
        transactions: [
            ParsedTransaction(amount: 150, category: "餐飲", description: "午餐", date: Date(), type: .expense),
            ParsedTransaction(amount: 80, category: "餐飲", description: "咖啡", date: Date(), type: .expense),
            ParsedTransaction(amount: 30, category: "交通", description: "公車", date: Date(), type: .expense)
        ],
        onConfirm: { _ in },
        onCancel: { }
    )
}

