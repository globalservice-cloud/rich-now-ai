//
//  FinancialHealthDimensionGuideView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import SwiftUI
import SwiftData

// 財務健康維度引導視圖
struct FinancialHealthDimensionGuideView: View {
    let dimension: FinancialHealthDimension
    let onComplete: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var transactions: [Transaction]
    @StateObject private var healthManager = FinancialHealthManager.shared
    
    @State private var currentStep = 0
    @State private var userInputs: [String: Any] = [:]
    @State private var showSuccessMessage = false
    @State private var showIncomeStabilityGoal = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景漸層
                LinearGradient(
                    colors: [
                        dimensionColor(dimension).opacity(0.1),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 進度指示器
                    ProgressIndicator(currentStep: currentStep, totalSteps: guideSteps.count)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // 步驟內容
                    TabView(selection: $currentStep) {
                        ForEach(0..<guideSteps.count, id: \.self) { index in
                            GuideStepView(
                                step: guideSteps[index],
                                dimension: dimension,
                                userInputs: $userInputs,
                                onNext: {
                                    if currentStep < guideSteps.count - 1 {
                                        withAnimation {
                                            currentStep += 1
                                        }
                                    } else {
                                        completeGuide()
                                    }
                                },
                                onSkip: {
                                    if currentStep < guideSteps.count - 1 {
                                        withAnimation {
                                            currentStep += 1
                                        }
                                    } else {
                                        completeGuide()
                                    }
                                },
                                onShowIncomeStability: {
                                    // 確保在主線程更新狀態以觸發 sheet 顯示
                                    DispatchQueue.main.async {
                                        showIncomeStabilityGoal = true
                                    }
                                }
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle(dimensionDisplayName(dimension))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("common.close")) {
                        onComplete()
                    }
                }
            }
            .alert(
                LocalizationManager.shared.localizedString("guide.complete.title"),
                isPresented: $showSuccessMessage
            ) {
                Button(LocalizationManager.shared.localizedString("common.ok")) {
                    onComplete()
                }
            } message: {
                Text(LocalizationManager.shared.localizedString("guide.complete.message"))
            }
            .sheet(isPresented: $showIncomeStabilityGoal) {
                IncomeStabilityGoalView()
            }
        }
    }
    
    private var guideSteps: [GuideStep] {
        switch dimension {
        case .income:
            return [
                GuideStep(
                    title: "記錄您的收入來源",
                    description: "讓我們先了解您的收入結構",
                    type: .incomeEntry,
                    icon: "dollarsign.circle.fill"
                ),
                GuideStep(
                    title: "設定收入目標",
                    description: "為未來設定成長目標",
                    type: .goalSetting,
                    icon: "target"
                )
            ]
        case .expenses:
            return [
                GuideStep(
                    title: "追蹤您的支出",
                    description: "開始記錄日常開支",
                    type: .expenseEntry,
                    icon: "chart.line.downtrend.xyaxis"
                ),
                GuideStep(
                    title: "設定預算限制",
                    description: "為不同類別設定預算",
                    type: .budgetSetting,
                    icon: "chart.pie.fill"
                )
            ]
        case .savings:
            return [
                GuideStep(
                    title: "建立儲蓄目標",
                    description: "設定您的儲蓄目標金額",
                    type: .savingsGoal,
                    icon: "banknote"
                ),
                GuideStep(
                    title: "設定自動儲蓄",
                    description: "建立自動轉帳計劃",
                    type: .autoSave,
                    icon: "arrow.clockwise.circle.fill"
                )
            ]
        case .debt:
            return [
                GuideStep(
                    title: "記錄您的債務",
                    description: "完整記錄所有債務資訊",
                    type: .debtEntry,
                    icon: "creditcard"
                ),
                GuideStep(
                    title: "制定還債計劃",
                    description: "建立還款策略",
                    type: .debtPlan,
                    icon: "calendar"
                )
            ]
        case .investment:
            return [
                GuideStep(
                    title: "開始投資",
                    description: "記錄您的投資項目",
                    type: .investmentEntry,
                    icon: "chart.line.uptrend.xyaxis"
                ),
                GuideStep(
                    title: "設定投資目標",
                    description: "規劃您的投資策略",
                    type: .investmentGoal,
                    icon: "gift.fill"
                )
            ]
        case .protection:
            return [
                GuideStep(
                    title: "檢視保險保障",
                    description: "記錄您的保險資訊",
                    type: .insuranceEntry,
                    icon: "shield.fill"
                ),
                GuideStep(
                    title: "完善風險保護",
                    description: "確保有足夠的保障",
                    type: .protectionReview,
                    icon: "checkmark.shield.fill"
                )
            ]
        }
    }
    
    private func completeGuide() {
        // 保存用戶輸入的數據
        saveUserInputs()
        
        // 刷新健康評分
        Task {
            await healthManager.refreshHealthScore()
        }
        
        showSuccessMessage = true
    }
    
    private func saveUserInputs() {
        guard let user = users.first else { return }
        
        // 根據不同維度保存相應數據
        switch dimension {
        case .income:
            // 收入已在 IncomeEntryViewWrapper 中保存
            break
        case .expenses:
            // 這些可以通過TransactionEntryView處理
            break
        case .savings:
            // 創建儲蓄目標
            if let amount = userInputs["goalAmount"] as? Double {
                let targetDate = userInputs["deadline"] as? Date ?? Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
                // 計算建議的月度儲蓄金額
                let months = Calendar.current.dateComponents([.month], from: Date(), to: targetDate).month ?? 12
                let monthlyContribution = months > 0 ? amount / Double(months) : amount / 12
                
                let goal = FinancialGoal(
                    title: "儲蓄目標",
                    description: "維度引導創建的儲蓄目標",
                    type: .emergency_fund,
                    targetAmount: amount,
                    targetDate: targetDate,
                    monthlyContribution: monthlyContribution
                )
                goal.updatePriority(.high)
                goal.user = user
                modelContext.insert(goal)
            }
        case .debt:
            // 這裡可以記錄債務資訊到UserProfile或特殊欄位
            break
        case .investment:
            // 可以引導用戶到投資頁面
            break
        case .protection:
            // 記錄保險資訊
            break
        }
        
        try? modelContext.save()
    }
}

// 引導步驟
struct GuideStep {
    let title: String
    let description: String
    let type: GuideStepType
    let icon: String
}

enum GuideStepType {
    case incomeEntry
    case goalSetting
    case expenseEntry
    case budgetSetting
    case savingsGoal
    case autoSave
    case debtEntry
    case debtPlan
    case investmentEntry
    case investmentGoal
    case insuranceEntry
    case protectionReview
}

// 步驟視圖
struct GuideStepView: View {
    let step: GuideStep
    let dimension: FinancialHealthDimension
    @Binding var userInputs: [String: Any]
    let onNext: () -> Void
    let onSkip: () -> Void
    let onShowIncomeStability: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 圖示
            Image(systemName: step.icon)
                .font(.system(size: 80))
                .foregroundColor(dimensionColor(dimension))
            
            // 標題和描述
            VStack(spacing: 12) {
                Text(step.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // 輸入內容區域
            GuideInputView(
                stepType: step.type,
                dimension: dimension,
                userInputs: $userInputs,
                onShowIncomeStability: onShowIncomeStability
            )
            .padding(.horizontal, 20)
            
            Spacer()
            
            // 操作按鈕
            VStack(spacing: 12) {
                Button(action: onNext) {
                    Text(LocalizationManager.shared.localizedString("common.next"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(dimensionColor(dimension))
                        )
                }
                
                Button(action: onSkip) {
                    Text(LocalizationManager.shared.localizedString("common.skip"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// 收入輸入視圖包裝器（用於保存數據）
private struct IncomeEntryViewWrapper: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    let dimension: FinancialHealthDimension
    @Binding var amount: Double
    let onComplete: () -> Void
    @StateObject private var healthManager = FinancialHealthManager.shared
    
    var body: some View {
        IncomeEntryView(amount: $amount) {
            // 當用戶點擊確認時，先保存收入數據
            saveIncomeData(amount)
            // 稍微延遲確保數據已保存並刷新評分，然後觸發完成回調
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete()
            }
        }
    }
    
    private func saveIncomeData(_ incomeAmount: Double) {
        guard let user = users.first, incomeAmount > 0 else { return }
        
        // 創建收入交易記錄
        let incomeTransaction = Transaction(
            amount: incomeAmount,
            type: .income,
            category: .salary,
            description: "月收入",
            date: Date()
        )
        incomeTransaction.user = user
        incomeTransaction.inputMethod = "manual"
        incomeTransaction.isAutoCategorized = true
        
        modelContext.insert(incomeTransaction)
        
        do {
            try modelContext.save()
            print("✅ 收入數據已保存: \(incomeAmount)")
            
            // 刷新健康評分
            Task {
                await healthManager.refreshHealthScore()
            }
        } catch {
            print("❌ 保存收入數據失敗: \(error.localizedDescription)")
        }
    }
}

// 引導輸入視圖
struct GuideInputView: View {
    let stepType: GuideStepType
    let dimension: FinancialHealthDimension
    @Binding var userInputs: [String: Any]
    let onShowIncomeStability: () -> Void
    
    var body: some View {
        Group {
            switch stepType {
            case .incomeEntry:
                IncomeEntryViewWrapper(
                    dimension: dimension,
                    amount: Binding(
                        get: { userInputs["amount"] as? Double ?? 0 },
                        set: { userInputs["amount"] = $0 }
                    ),
                    onComplete: {
                        // 輸入完成後顯示目標差距
                        onShowIncomeStability()
                    }
                )
            case .expenseEntry:
                AmountInputView(
                    title: "月支出",
                    amount: Binding(
                        get: { userInputs["amount"] as? Double ?? 0 },
                        set: { userInputs["amount"] = $0 }
                    )
                )
            case .goalSetting, .savingsGoal:
                GoalInputView(
                    title: "目標金額",
                    amount: Binding(
                        get: { userInputs["goalAmount"] as? Double ?? 0 },
                        set: { userInputs["goalAmount"] = $0 }
                    ),
                    deadline: Binding(
                        get: { userInputs["deadline"] as? Date ?? Date() },
                        set: { userInputs["deadline"] = $0 }
                    )
                )
            case .budgetSetting:
                BudgetInputView(
                    amount: Binding(
                        get: { userInputs["budgetAmount"] as? Double ?? 0 },
                        set: { userInputs["budgetAmount"] = $0 }
                    )
                )
            case .debtEntry:
                DebtInputView(
                    amount: Binding(
                        get: { userInputs["debtAmount"] as? Double ?? 0 },
                        set: { userInputs["debtAmount"] = $0 }
                    ),
                    interestRate: Binding(
                        get: { userInputs["interestRate"] as? Double ?? 0 },
                        set: { userInputs["interestRate"] = $0 }
                    )
                )
            default:
                InfoView(
                    message: LocalizationManager.shared.localizedString("guide.step.info"),
                    icon: "info.circle.fill"
                )
            }
        }
    }
}

// 金額輸入視圖
struct AmountInputView: View {
    let title: String
    @Binding var amount: Double
    @State private var amountText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            TextField("請輸入金額", text: $amountText)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: amountText) { _, newValue in
                    amount = Double(newValue) ?? 0
                }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// 目標輸入視圖
struct GoalInputView: View {
    let title: String
    @Binding var amount: Double
    @Binding var deadline: Date
    @State private var amountText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                
                TextField("目標金額", text: $amountText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: amountText) { _, newValue in
                        amount = Double(newValue) ?? 0
                    }
            }
            
            DatePicker(
                "達成日期",
                selection: $deadline,
                displayedComponents: .date
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// 預算輸入視圖
struct BudgetInputView: View {
    @Binding var amount: Double
    @State private var amountText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每月預算")
                .font(.headline)
            
            TextField("預算金額", text: $amountText)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: amountText) { _, newValue in
                    amount = Double(newValue) ?? 0
                }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// 債務輸入視圖
struct DebtInputView: View {
    @Binding var amount: Double
    @Binding var interestRate: Double
    @State private var amountText = ""
    @State private var rateText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("債務金額")
                    .font(.headline)
                
                TextField("總債務", text: $amountText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: amountText) { _, newValue in
                        amount = Double(newValue) ?? 0
                    }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("年利率 (%)")
                    .font(.headline)
                
                TextField("利率", text: $rateText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: rateText) { _, newValue in
                        interestRate = Double(newValue) ?? 0
                    }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// 資訊視圖
struct InfoView: View {
    let message: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// 進度指示器
struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                    
                    if index < totalSteps - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            
            Text("步驟 \(currentStep + 1) / \(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// 擴展使 FinancialHealthDimension 支持 Identifiable
extension FinancialHealthDimension: Identifiable {
    public var id: String { rawValue }
}

// 輔助函數
private func dimensionDisplayName(_ dimension: FinancialHealthDimension) -> String {
    LocalizationManager.shared.localizedString("financial_health.dimension.\(dimension.rawValue)")
}

private func dimensionColor(_ dimension: FinancialHealthDimension) -> Color {
    switch dimension {
    case .income: return .green
    case .expenses: return .orange
    case .savings: return .blue
    case .debt: return .red
    case .investment: return .purple
    case .protection: return .yellow
    }
}

