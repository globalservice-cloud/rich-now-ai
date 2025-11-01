//
//  FinancialGoalSettingView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import SwiftUI
import SwiftData
import os.log

struct FinancialGoalSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [FinancialGoal]
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedType: GoalType = .emergency_fund
    @State private var targetAmount = ""
    @State private var targetDate = Date().addingTimeInterval(365 * 24 * 60 * 60) // 一年後
    @State private var monthlyContribution = ""
    @State private var priority: GoalPriority = .medium
    @State private var errorMessage: String?
    
    private let logger = Logger(subsystem: "com.richnowai", category: "FinancialGoalSetting")
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本資訊")) {
                    TextField("目標名稱", text: $title)
                    TextField("目標描述", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("目標類型", selection: $selectedType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Text(typeDisplayName(type)).tag(type)
                        }
                    }
                    
                    Picker("優先級", selection: $priority) {
                        Text("低").tag(GoalPriority.low)
                        Text("中").tag(GoalPriority.medium)
                        Text("高").tag(GoalPriority.high)
                        Text("緊急").tag(GoalPriority.urgent)
                    }
                }
                
                Section(header: Text("金額與時間")) {
                    TextField("目標金額", text: $targetAmount)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("目標日期", selection: $targetDate, displayedComponents: .date)
                    
                    TextField("每月儲蓄金額", text: $monthlyContribution)
                        .keyboardType(.decimalPad)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button("儲存目標") {
                        saveGoal()
                    }
                    .disabled(!isValidInput)
                }
            }
            .navigationTitle("設定財務目標")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isValidInput: Bool {
        guard !title.isEmpty,
              !targetAmount.isEmpty,
              let amount = Double(targetAmount),
              amount > 0 else {
            return false
        }
        
        if !monthlyContribution.isEmpty {
            guard let contribution = Double(monthlyContribution),
                  contribution > 0 else {
                return false
            }
        }
        
        return true
    }
    
    private func saveGoal() {
        errorMessage = nil
        
        guard !title.isEmpty else {
            errorMessage = "請輸入目標名稱"
            return
        }
        
        guard !targetAmount.isEmpty,
              let amount = Double(targetAmount),
              amount > 0 else {
            errorMessage = "請輸入有效的目標金額"
            return
        }
        
        guard let contribution = !monthlyContribution.isEmpty ? Double(monthlyContribution) : amount / 12,
              contribution > 0 else {
            errorMessage = "請輸入有效的每月儲蓄金額"
            return
        }
        
        // 驗證日期
        guard targetDate > Date() else {
            errorMessage = "目標日期必須是未來的日期"
            return
        }
        
        let goal = FinancialGoal(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? "無描述" : description.trimmingCharacters(in: .whitespacesAndNewlines),
            type: selectedType,
            targetAmount: amount,
            targetDate: targetDate,
            monthlyContribution: contribution
        )
        goal.priority = priority.rawValue
        
        modelContext.insert(goal)
        
        do {
            try modelContext.save()
            logger.info("成功創建財務目標: \(title)")
            dismiss()
        } catch {
            let errorDesc = error.localizedDescription
            logger.error("保存財務目標失敗: \(errorDesc)")
            errorMessage = "保存失敗: \(errorDesc)"
        }
    }
    
    private func typeDisplayName(_ type: GoalType) -> String {
        switch type {
        case .emergency_fund: return "緊急預備金"
        case .debt_payoff: return "債務清償"
        case .home_purchase: return "購屋"
        case .car_purchase: return "購車"
        case .education: return "教育基金"
        case .retirement: return "退休規劃"
        case .investment: return "投資理財"
        case .travel: return "旅行基金"
        case .wedding: return "婚禮基金"
        case .business: return "創業基金"
        case .donation: return "奉獻目標"
        case .other: return "其他"
        }
    }
}

#Preview {
    FinancialGoalSettingView()
        .modelContainer(for: FinancialGoal.self)
}

