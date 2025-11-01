//
//  FamilyAccountView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import SwiftUI
import SwiftData

/// 家庭記帳主視圖
struct FamilyAccountView: View {
    @StateObject private var familyManager = FamilyAccountManager.shared
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var showingAddMember = false
    @State private var showingAddBudget = false
    @State private var showingAddTransaction = false
    @State private var showingFamilySettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if familyManager.currentFamilyGroup == nil {
                    // 未創建家庭群組
                    EmptyFamilyView(onCreateFamily: createFamilyGroup)
                } else {
                    // 已創建家庭群組
                    TabView(selection: $selectedTab) {
                        // 家庭總覽
                        FamilyOverviewTab()
                            .tabItem {
                                Label("總覽", systemImage: "house.fill")
                            }
                            .tag(0)
                        
                        // 成員管理
                        FamilyMembersTab()
                            .tabItem {
                                Label("成員", systemImage: "person.2.fill")
                            }
                            .tag(1)
                        
                        // 預算管理
                        FamilyBudgetTab()
                            .tabItem {
                                Label("預算", systemImage: "chart.pie.fill")
                            }
                            .tag(2)
                        
                        // 交易記錄
                        FamilyTransactionsTab()
                            .tabItem {
                                Label("交易", systemImage: "list.bullet.rectangle")
                            }
                            .tag(3)
                    }
                }
            }
            .navigationTitle(familyManager.currentFamilyGroup?.name ?? "家庭記帳")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFamilySettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddFamilyMemberView()
            }
            .sheet(isPresented: $showingAddBudget) {
                AddFamilyBudgetView()
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddFamilyTransactionView()
            }
            .sheet(isPresented: $showingFamilySettings) {
                FamilySettingsView()
            }
            .onAppear {
                familyManager.setModelContext(modelContext)
            }
        }
    }
    
    private func createFamilyGroup() {
        // 獲取當前用戶 ID（簡化實現）
        let ownerId = UUID() // 實際應該從 User 獲取
        _ = familyManager.createFamilyGroup(name: "我的家庭", ownerId: ownerId)
    }
}

// MARK: - 空狀態視圖

struct EmptyFamilyView: View {
    let onCreateFamily: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "house.and.flag.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("還沒有創建家庭群組")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("創建家庭群組後，可以管理家庭成員、設定預算並追蹤所有家庭財務交易")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: onCreateFamily) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("創建家庭群組")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.safeHex("#1E3A8A", default: .blue), Color.safeHex("#312E81", default: .purple)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - 家庭總覽標籤

struct FamilyOverviewTab: View {
    @StateObject private var familyManager = FamilyAccountManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 財務總覽卡片
                if let stats = familyManager.familyStats {
                    FamilyStatsCard(stats: stats)
                }
                
                // 預算警告
                let warnings = familyManager.checkBudgetWarnings()
                if !warnings.isEmpty {
                    BudgetWarningsCard(budgets: warnings)
                }
                
                // 快速操作
                FamilyQuickActionsCard()
            }
            .padding()
        }
    }
}

// MARK: - 家庭成員標籤

struct FamilyMembersTab: View {
    @StateObject private var familyManager = FamilyAccountManager.shared
    @State private var showingAddMember = false
    
    var body: some View {
        List {
            ForEach(familyManager.familyMembers, id: \.id) { member in
                FamilyMemberRow(member: member)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddMember = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddMember) {
            AddFamilyMemberView()
        }
    }
}

// MARK: - 家庭預算標籤

struct FamilyBudgetTab: View {
    @StateObject private var familyManager = FamilyAccountManager.shared
    @State private var showingAddBudget = false
    
    var body: some View {
        List {
            ForEach(familyManager.familyBudgets, id: \.id) { budget in
                FamilyBudgetRow(budget: budget)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddBudget = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddBudget) {
            AddFamilyBudgetView()
        }
    }
}

// MARK: - 家庭交易標籤

struct FamilyTransactionsTab: View {
    @StateObject private var familyManager = FamilyAccountManager.shared
    @State private var showingAddTransaction = false
    
    var body: some View {
        List {
            ForEach(familyManager.familyTransactions, id: \.id) { transaction in
                FamilyTransactionRow(transaction: transaction)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddTransaction = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddFamilyTransactionView()
        }
    }
}

// MARK: - 添加家庭成員視圖

struct AddFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var familyManager = FamilyAccountManager.shared
    
    @State private var name = ""
    @State private var role = ""
    @State private var age: Int?
    @State private var ageString = ""
    @State private var canManageBudget = false
    @State private var canViewAllTransactions = true
    @State private var monthlyAllowance: Double?
    @State private var allowanceString = ""
    @State private var errorMessage: String?
    
    let commonRoles = ["父親", "母親", "長子", "長女", "次子", "次女", "其他"]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("成員名稱", text: $name)
                    Picker("角色", selection: $role) {
                        ForEach(commonRoles, id: \.self) { role in
                            Text(role).tag(role)
                        }
                    }
                    
                    TextField("年齡（選填）", text: $ageString)
                        .keyboardType(.numberPad)
                        .onChange(of: ageString) { _, newValue in
                            age = Int(newValue)
                        }
                } header: {
                    Text("基本資訊")
                }
                
                Section {
                    Toggle("可管理預算", isOn: $canManageBudget)
                    Toggle("可查看所有交易", isOn: $canViewAllTransactions)
                    
                    TextField("每月零用錢（選填）", text: $allowanceString)
                        .keyboardType(.decimalPad)
                        .onChange(of: allowanceString) { _, newValue in
                            monthlyAllowance = Double(newValue)
                        }
                } header: {
                    Text("權限設定")
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button("添加成員") {
                        addMember()
                    }
                    .disabled(!isValidInput)
                }
            }
            .navigationTitle("添加家庭成員")
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
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addMember() {
        errorMessage = nil
        
        let success = familyManager.addFamilyMember(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role,
            age: age,
            canManageBudget: canManageBudget,
            canViewAllTransactions: canViewAllTransactions,
            monthlyAllowance: monthlyAllowance
        )
        
        if success {
            dismiss()
        } else {
            errorMessage = familyManager.errorMessage ?? "添加成員失敗"
        }
    }
}

// MARK: - 添加家庭預算視圖

struct AddFamilyBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var familyManager = FamilyAccountManager.shared
    
    @State private var name = ""
    @State private var category = ""
    @State private var budgetedAmountString = ""
    @State private var selectedPeriod = "monthly"
    @State private var warningThreshold: Double = 0.8
    @State private var errorMessage: String?
    
    let categories = ["餐飲", "交通", "居住", "水電瓦斯", "醫療", "教育", "娛樂", "購物", "保險", "其他"]
    let periods = [("每月", "monthly"), ("每週", "weekly"), ("每年", "yearly")]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("預算名稱", text: $name)
                    Picker("分類", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    TextField("預算金額", text: $budgetedAmountString)
                        .keyboardType(.decimalPad)
                    
                    Picker("預算週期", selection: $selectedPeriod) {
                        ForEach(periods, id: \.1) { period in
                            Text(period.0).tag(period.1)
                        }
                    }
                } header: {
                    Text("預算資訊")
                }
                
                Section {
                    HStack {
                        Text("警告閾值")
                        Spacer()
                        Text("\(Int(warningThreshold * 100))%")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $warningThreshold, in: 0.5...1.0, step: 0.05)
                } header: {
                    Text("警告設定")
                } footer: {
                    Text("當支出達到預算的 \(Int(warningThreshold * 100))% 時將發出警告")
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button("創建預算") {
                        createBudget()
                    }
                    .disabled(!isValidInput)
                }
            }
            .navigationTitle("添加家庭預算")
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
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !category.isEmpty &&
        !budgetedAmountString.isEmpty &&
        Double(budgetedAmountString) != nil
    }
    
    private func createBudget() {
        errorMessage = nil
        
        guard let budgetedAmount = Double(budgetedAmountString), budgetedAmount > 0 else {
            errorMessage = "請輸入有效的預算金額"
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        var startDate: Date
        var endDate: Date
        
        switch selectedPeriod {
        case "monthly":
            let interval = calendar.dateInterval(of: .month, for: now)!
            startDate = interval.start
            endDate = interval.end
        case "weekly":
            let interval = calendar.dateInterval(of: .weekOfYear, for: now)!
            startDate = interval.start
            endDate = interval.end
        case "yearly":
            let interval = calendar.dateInterval(of: .year, for: now)!
            startDate = interval.start
            endDate = interval.end
        default:
            startDate = now
            endDate = calendar.date(byAdding: .month, value: 1, to: now)!
        }
        
        let budget = familyManager.createFamilyBudget(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            budgetedAmount: budgetedAmount,
            period: selectedPeriod,
            startDate: startDate,
            endDate: endDate,
            warningThreshold: warningThreshold
        )
        
        if budget != nil {
            dismiss()
        } else {
            errorMessage = familyManager.errorMessage ?? "創建預算失敗"
        }
    }
}

// MARK: - 添加家庭交易視圖

struct AddFamilyTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var familyManager = FamilyAccountManager.shared
    
    @State private var amountString = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategory: TransactionCategory = .food
    @State private var description = ""
    @State private var selectedMemberId: UUID?
    @State private var date = Date()
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("金額", text: $amountString)
                        .keyboardType(.decimalPad)
                    
                    Picker("類型", selection: $selectedType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(typeDisplayName(type)).tag(type)
                        }
                    }
                    
                    Picker("分類", selection: $selectedCategory) {
                        ForEach(TransactionCategory.allCases, id: \.self) { category in
                            Text(categoryDisplayName(category)).tag(category)
                        }
                    }
                    
                    TextField("描述", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("成員", selection: $selectedMemberId) {
                        Text("不指定").tag(nil as UUID?)
                        ForEach(familyManager.familyMembers, id: \.id) { member in
                            Text(member.name).tag(member.id as UUID?)
                        }
                    }
                    
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                } header: {
                    Text("交易資訊")
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button("添加交易") {
                        addTransaction()
                    }
                    .disabled(!isValidInput)
                }
            }
            .navigationTitle("添加交易")
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
        !amountString.isEmpty &&
        Double(amountString) != nil &&
        Double(amountString)! > 0 &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addTransaction() {
        errorMessage = nil
        
        guard let amount = Double(amountString), amount > 0 else {
            errorMessage = "請輸入有效的金額"
            return
        }
        
        let transaction = familyManager.addFamilyTransaction(
            amount: amount,
            type: selectedType,
            category: selectedCategory,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            memberId: selectedMemberId,
            date: date
        )
        
        if transaction != nil {
            dismiss()
        } else {
            errorMessage = familyManager.errorMessage ?? "添加交易失敗"
        }
    }
    
    private func typeDisplayName(_ type: TransactionType) -> String {
        switch type {
        case .income: return "收入"
        case .expense: return "支出"
        case .transfer: return "轉帳"
        case .investment: return "投資"
        case .loan: return "貸款"
        case .insurance: return "保險"
        case .donation: return "奉獻"
        }
    }
    
    private func categoryDisplayName(_ category: TransactionCategory) -> String {
        switch category {
        case .food: return "餐飲"
        case .transport: return "交通"
        case .housing: return "居住"
        case .utilities: return "水電瓦斯"
        case .healthcare: return "醫療"
        case .education: return "教育"
        case .entertainment: return "娛樂"
        case .shopping: return "購物"
        case .insurance: return "保險"
        case .loan_payment: return "貸款還款"
        case .investment: return "投資"
        case .donation: return "奉獻"
        case .other_expense: return "其他支出"
        case .salary: return "薪資"
        case .bonus: return "獎金"
        case .investment_return: return "投資收益"
        case .business: return "營業收入"
        case .other_income: return "其他收入"
        }
    }
}

// MARK: - 支援視圖組件

struct FamilyStatsCard: View {
    let stats: FamilyAccountingStats
    
    var body: some View {
        VStack(spacing: 16) {
            Text("本月財務總覽")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                FamilyStatItem(title: "總收入", amount: stats.totalIncome, color: .green)
                FamilyStatItem(title: "總支出", amount: stats.totalExpenses, color: .red)
                FamilyStatItem(title: "淨收入", amount: stats.netIncome, color: stats.netIncome >= 0 ? .blue : .orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct FamilyStatItem: View {
    let title: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(formatAmount(amount))
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TWD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "NT$ \(Int(amount))"
    }
}

struct BudgetWarningsCard: View {
    let budgets: [FamilyBudget]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("預算警告")
                    .font(.headline)
            }
            
            ForEach(budgets.prefix(3), id: \.id) { budget in
                BudgetWarningRow(budget: budget)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct BudgetWarningRow: View {
    let budget: FamilyBudget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(budget.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(budget.usageRate * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
            
            ProgressView(value: budget.usageRate, total: 1.0)
                .tint(budget.usageRate >= 1.0 ? .red : .orange)
        }
    }
}

struct FamilyQuickActionsCard: View {
    @State private var showingAddMember = false
    @State private var showingAddBudget = false
    @State private var showingAddTransaction = false
    @State private var showingReports = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("快速操作")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                FamilyQuickActionButton(title: "添加成員", icon: "person.badge.plus", color: .blue) {
                    showingAddMember = true
                }
                FamilyQuickActionButton(title: "創建預算", icon: "plus.circle", color: .green) {
                    showingAddBudget = true
                }
                FamilyQuickActionButton(title: "記錄交易", icon: "plus.square", color: .orange) {
                    showingAddTransaction = true
                }
                FamilyQuickActionButton(title: "查看報表", icon: "chart.bar.fill", color: .purple) {
                    showingReports = true
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .sheet(isPresented: $showingAddMember) {
            AddFamilyMemberView()
        }
        .sheet(isPresented: $showingAddBudget) {
            AddFamilyBudgetView()
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddFamilyTransactionView()
        }
        .sheet(isPresented: $showingReports) {
            // TODO: 添加報表視圖
        }
    }
}

struct FamilyQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(uiColor: .systemGray6))
            .cornerRadius(12)
        }
    }
}

struct FamilyMemberRow: View {
    let member: FamilyMember
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(member.name.prefix(1))
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.headline)
                Text(member.role)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if member.monthlyAllowance != nil {
                Text("零用錢：NT$ \(Int(member.monthlyAllowance!))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct FamilyBudgetRow: View {
    let budget: FamilyBudget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(budget.name)
                    .font(.headline)
                Spacer()
                Text(formatAmount(budget.spentAmount) + " / " + formatAmount(budget.budgetedAmount))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: budget.usageRate, total: 1.0)
                .tint(budget.isOverWarningThreshold ? .red : .blue)
            
            HStack {
                Text("剩餘：\(formatAmount(budget.remainingAmount))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("使用率：\(Int(budget.usageRate * 100))%")
                    .font(.caption)
                    .foregroundColor(budget.isOverWarningThreshold ? .red : .secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        return "NT$ \(Int(amount))"
    }
}

struct FamilyTransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.transactionDescription)
                    .font(.headline)
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formatAmount(transaction.displayAmount))
                .font(.headline)
                .foregroundColor(transaction.isIncome ? .green : .red)
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let sign = amount >= 0 ? "+" : ""
        return "\(sign)NT$ \(Int(abs(amount)))"
    }
}

struct FamilySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var familyManager = FamilyAccountManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    if let group = familyManager.currentFamilyGroup {
                        Text("家庭名稱：\(group.name)")
                        Text("創建時間：\(group.createdAt, style: .date)")
                    }
                } header: {
                    Text("家庭資訊")
                }
                
                Section {
                    Button(role: .destructive) {
                        // 刪除家庭群組（需要確認）
                    } label: {
                        Text("解散家庭群組")
                    }
                }
            }
            .navigationTitle("家庭設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FamilyAccountView()
}

