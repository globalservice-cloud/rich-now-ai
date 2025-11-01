//
//  IncomeEntryView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import SwiftUI

// 收入輸入視圖（完成後顯示目標差距）
struct IncomeEntryView: View {
    @Binding var amount: Double
    let onComplete: () -> Void
    
    @State private var amountText = ""
    @State private var showResult = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("月收入")
                .font(.headline)
            
            TextField("請輸入金額", text: $amountText)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: amountText) { _, newValue in
                    amount = Double(newValue) ?? 0
                }
            
            if !amountText.isEmpty && amount > 0 {
                Button(action: {
                    showResult = true
                    // 延遲一下再觸發完成，讓用戶看到結果
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onComplete()
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("確認並查看分析")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                }
            }
            
            if showResult {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("已記錄：NT$ \(String(format: "%.0f", amount))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

