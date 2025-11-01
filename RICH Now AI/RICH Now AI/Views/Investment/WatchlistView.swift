//
//  WatchlistView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import SwiftUI
import SwiftData

struct WatchlistView: View {
    @StateObject private var watchlistManager = WatchlistManager.shared
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddItem = false
    @State private var selectedType: WatchlistItemType = .stock
    
    var body: some View {
        NavigationBarContainer(
            title: "投資關注",
            showBackButton: true,
            showMenuButton: true
        ) {
            Group {
                if watchlistManager.watchlistItems.isEmpty {
                    EmptyWatchlistView(onAddItem: {
                        showingAddItem = true
                    })
                } else {
                    List {
                        ForEach(watchlistManager.watchlistItems, id: \.id) { item in
                            WatchlistItemRow(item: item)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        watchlistManager.removeFromWatchlist(item)
                                    } label: {
                                        Label("刪除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .refreshable {
                        await watchlistManager.updateAllPrices()
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddWatchlistItemView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                watchlistManager.setModelContext(modelContext)
                watchlistManager.setMarketDataService(MockMarketDataService())
                watchlistManager.loadWatchlist()
            }
        }
    }
}

// 關注項目行
struct WatchlistItemRow: View {
    let item: WatchlistItem
    
    var body: some View {
        HStack(spacing: 16) {
            // 類型圖標
            Image(systemName: item.watchlistType.icon)
                .font(.title2)
                .foregroundColor(item.watchlistType.color)
                .frame(width: 40)
            
            // 項目資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                HStack {
                    Text(item.symbol)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(item.market)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 價格資訊
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(item.currentPrice, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: item.isRising ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                        .foregroundColor(item.isRising ? .green : .red)
                    
                    Text("\(item.change >= 0 ? "+" : "")\(item.changePercentage, specifier: "%.2f")%")
                        .font(.caption)
                        .foregroundColor(item.isRising ? .green : .red)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// 空關注列表視圖
struct EmptyWatchlistView: View {
    let onAddItem: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("還沒有關注的投資項目")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("點擊下方按鈕添加想要追蹤的投資標的")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onAddItem) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("添加關注")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 添加關注項目視圖
struct AddWatchlistItemView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var watchlistManager = WatchlistManager.shared
    
    @State private var selectedType: WatchlistItemType = .stock
    @State private var symbol = ""
    @State private var name = ""
    @State private var market = "TWSE"
    @State private var currency = "TWD"
    @State private var priceAlert = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("投資類型")) {
                    Picker("類型", selection: $selectedType) {
                        ForEach(WatchlistItemType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                }
                
                Section(header: Text("基本資訊")) {
                    TextField("代碼", text: $symbol)
                        .placeholder(when: symbol.isEmpty) {
                            Text("例如：2330, TSM")
                        }
                    
                    TextField("名稱", text: $name)
                    
                    Picker("市場", selection: $market) {
                        Text("台灣證券交易所").tag("TWSE")
                        Text("紐約證券交易所").tag("NYSE")
                        Text("那斯達克").tag("NASDAQ")
                        Text("其他").tag("OTHER")
                    }
                    
                    Picker("幣別", selection: $currency) {
                        Text("新台幣").tag("TWD")
                        Text("美元").tag("USD")
                        Text("人民幣").tag("CNY")
                        Text("日圓").tag("JPY")
                    }
                }
                
                Section(header: Text("價格提醒（選填）")) {
                    TextField("提醒價格", text: $priceAlert)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Button("添加關注") {
                        addItem()
                    }
                    .disabled(symbol.isEmpty || name.isEmpty)
                }
            }
            .navigationTitle("添加關注")
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
    
    private func addItem() {
        // 輸入驗證
        guard !symbol.isEmpty else { return }
        guard !name.isEmpty else { return }
        
        // 清理輸入
        let cleanSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 驗證價格提醒
        var alertPrice: Double? = nil
        if !priceAlert.isEmpty {
            if let price = Double(priceAlert), price > 0 {
                alertPrice = price
            }
        }
        
        watchlistManager.addToWatchlist(
            symbol: cleanSymbol,
            name: cleanName,
            type: selectedType,
            market: market,
            currency: currency,
            priceAlert: alertPrice
        )
        
        dismiss()
    }
}

// View extension for placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    WatchlistView()
        .modelContainer(for: WatchlistItem.self)
}

