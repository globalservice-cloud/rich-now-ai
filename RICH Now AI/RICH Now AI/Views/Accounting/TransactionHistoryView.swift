//
//  TransactionHistoryView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import SwiftData

struct TransactionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    
    @State private var selectedFilter: TransactionFilter = .all
    @State private var searchText = ""
    @State private var showFilterSheet = false
    @State private var selectedTransaction: Transaction?
    
    enum TransactionFilter: String, CaseIterable {
        case all = "all"
        case income = "income"
        case expense = "expense"
        case today = "today"
        case thisWeek = "thisWeek"
        case thisMonth = "thisMonth"
        
        var displayName: String {
            switch self {
            case .all:
                return LocalizationManager.shared.localizedString("transaction.filter.all")
            case .income:
                return LocalizationManager.shared.localizedString("transaction.filter.income")
            case .expense:
                return LocalizationManager.shared.localizedString("transaction.filter.expense")
            case .today:
                return LocalizationManager.shared.localizedString("transaction.filter.today")
            case .thisWeek:
                return LocalizationManager.shared.localizedString("transaction.filter.thisWeek")
            case .thisMonth:
                return LocalizationManager.shared.localizedString("transaction.filter.thisMonth")
            }
        }
    }
    
    var filteredTransactions: [Transaction] {
        var filtered = transactions
        
        // 搜尋過濾
        if !searchText.isEmpty {
            filtered = filtered.filter { transaction in
                transaction.transactionDescription.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.localizedCaseInsensitiveContains(searchText) ||
                (transaction.originalText?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // 類型過濾
        switch selectedFilter {
        case .all:
            break
        case .income:
            filtered = filtered.filter { $0.isIncome }
        case .expense:
            filtered = filtered.filter { $0.isExpense }
        case .today:
            let today = Calendar.current.startOfDay(for: Date())
            filtered = filtered.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        case .thisWeek:
            let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            filtered = filtered.filter { $0.date >= startOfWeek }
        case .thisMonth:
            let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
            filtered = filtered.filter { $0.date >= startOfMonth }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜尋和過濾欄
                VStack(spacing: 12) {
                    // 搜尋欄
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField(LocalizationManager.shared.localizedString("transaction.search_placeholder"), text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // 過濾按鈕
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TransactionFilter.allCases, id: \.self) { filter in
                                Button(action: { selectedFilter = filter }) {
                                    Text(filter.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedFilter == filter ? 
                                            Color.blue : Color(.systemGray6)
                                        )
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // 交易列表
                if filteredTransactions.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text(LocalizationManager.shared.localizedString("transaction.empty_title"))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text(LocalizationManager.shared.localizedString("transaction.empty_subtitle"))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                } else {
                    List {
                        ForEach(filteredTransactions) { transaction in
                            TransactionRowView(transaction: transaction)
                                .onTapGesture {
                                    selectedTransaction = transaction
                                }
                        }
                        .onDelete(perform: deleteTransactions)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(LocalizationManager.shared.localizedString("transaction.history_title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("transaction.filter")) {
                        showFilterSheet = true
                    }
                }
            }
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(transaction: transaction)
        }
        .sheet(isPresented: $showFilterSheet) {
            TransactionFilterView(selectedFilter: $selectedFilter)
        }
    }
    
    private func deleteTransactions(offsets: IndexSet) {
        for index in offsets {
            let transaction = filteredTransactions[index]
            modelContext.delete(transaction)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete transaction: \(error)")
        }
    }
}

// 交易行視圖
struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            // 圖示
            VStack {
                Image(systemName: transaction.isIncome ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(transaction.isIncome ? .green : .red)
            }
            .frame(width: 40, height: 40)
            .background(Color(.systemGray6))
            .cornerRadius(20)
            
            // 交易資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.transactionDescription)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack {
                    Text(transaction.category)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                    
                    if transaction.isAutoCategorized {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(transaction.date, style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            // 金額
            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.displayAmount, format: .currency(code: "TWD"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(transaction.isIncome ? .green : .red)
                
                if let originalText = transaction.originalText {
                    Text(originalText)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: 100, alignment: .trailing)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// 交易詳情視圖
struct TransactionDetailView: View {
    let transaction: Transaction
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 金額卡片
                    VStack(spacing: 12) {
                        Text(transaction.displayAmount, format: .currency(code: "TWD"))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(transaction.isIncome ? .green : .red)
                        
                        HStack {
                            Image(systemName: transaction.isIncome ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            Text(transaction.isIncome ? 
                                 LocalizationManager.shared.localizedString("transaction.income") : 
                                 LocalizationManager.shared.localizedString("transaction.expense"))
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(transaction.isIncome ? .green : .red)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // 交易詳情
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRowView(
                            title: LocalizationManager.shared.localizedString("transaction.description"),
                            value: transaction.transactionDescription
                        )
                        
                        DetailRowView(
                            title: LocalizationManager.shared.localizedString("transaction.category"),
                            value: transaction.category
                        )
                        
                        DetailRowView(
                            title: LocalizationManager.shared.localizedString("transaction.date"),
                            value: transaction.date.formatted(date: .abbreviated, time: .shortened)
                        )
                        
                        if let originalText = transaction.originalText {
                            DetailRowView(
                                title: LocalizationManager.shared.localizedString("transaction.original_text"),
                                value: originalText
                            )
                        }
                        
                        if let notes = transaction.notes {
                            DetailRowView(
                                title: LocalizationManager.shared.localizedString("transaction.notes"),
                                value: notes
                            )
                        }
                        
                        if !transaction.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizationManager.shared.localizedString("transaction.tags"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                    ForEach(transaction.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.system(size: 12))
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle(LocalizationManager.shared.localizedString("transaction.detail_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("common.done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 詳情行視圖
struct DetailRowView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.primary)
        }
    }
}

// 過濾視圖
struct TransactionFilterView: View {
    @Binding var selectedFilter: TransactionHistoryView.TransactionFilter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(TransactionHistoryView.TransactionFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                        dismiss()
                    }) {
                        HStack {
                            Text(filter.displayName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle(LocalizationManager.shared.localizedString("transaction.filter_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("common.done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TransactionHistoryView()
}
