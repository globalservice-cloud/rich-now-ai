//
//  InvoiceCarrierManagementView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import SwiftUI
import SwiftData

struct InvoiceCarrierManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var carrierManager = InvoiceCarrierManager.shared
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var showingAddCarrier = false
    @State private var showingSyncOptions = false
    
    var body: some View {
        NavigationView {
            List {
                if carrierManager.carriers.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("還沒有設定發票載具")
                                .font(.headline)
                            
                            Text("添加載具後可自動同步發票並更新消費紀錄")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("添加載具") {
                                showingAddCarrier = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                } else {
                    Section(header: Text("我的載具")) {
                        ForEach(carrierManager.carriers, id: \.id) { carrier in
                            CarrierRow(
                                carrier: carrier,
                                isDefault: carrierManager.defaultCarrier?.id == carrier.id
                            ) {
                                carrierManager.setDefaultCarrier(carrier)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    carrierManager.removeCarrier(carrier)
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    
                    Section {
                        if let defaultCarrier = carrierManager.defaultCarrier {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Button(action: {
                                    Task {
                                        await carrierManager.syncInvoicesFromTaxBureau(carrier: defaultCarrier)
                                    }
                                }) {
                                    Text("同步發票")
                                }
                                .disabled(carrierManager.isSyncing)
                                
                                if carrierManager.isSyncing {
                                    Spacer()
                                    ProgressView()
                                }
                            }
                            
                            Button(action: {
                                showingSyncOptions = true
                            }) {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("設定自動同步")
                                }
                            }
                        }
                    } header: {
                        Text("發票同步")
                    }
                    
                    if let lastSync = carrierManager.lastSyncDate {
                        Section {
                            HStack {
                                Text("最後同步時間")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(lastSync, style: .relative)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("發票載具管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCarrier = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCarrier) {
                AddCarrierView()
            }
            .sheet(isPresented: $showingSyncOptions) {
                SyncOptionsView()
            }
            .onAppear {
                carrierManager.setModelContext(modelContext, user: users.first)
                carrierManager.loadCarriers()
            }
            .onChange(of: users.count) { _, _ in
                carrierManager.setModelContext(modelContext, user: users.first)
            }
        }
    }
}

// 載具行
struct CarrierRow: View {
    let carrier: InvoiceCarrier
    let isDefault: Bool
    let onSetDefault: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: carrier.type.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(carrier.carrierName)
                        .font(.headline)
                    
                    if isDefault {
                        Text("預設")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                
                Text(carrier.carrierNumber)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(carrier.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isDefault {
                Button("設為預設") {
                    onSetDefault()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// 添加載具視圖
struct AddCarrierView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var carrierManager = InvoiceCarrierManager.shared
    
    @State private var selectedType: CarrierType = .mobileBarcode
    @State private var number = ""
    @State private var name = ""
    @State private var isDefault = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("載具類型", selection: $selectedType) {
                        ForEach(CarrierType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                } header: {
                    Text("載具類型")
                }
                
                Section {
                    TextField("載具號碼", text: $number)
                    
                    TextField("載具名稱/別名", text: $name, prompt: Text("例如：我的手機條碼"))
                    
                    Toggle("設為預設載具", isOn: $isDefault)
                } header: {
                    Text("載具資訊")
                } footer: {
                    if selectedType == .mobileBarcode {
                        Text("手機條碼格式：/XXXX-XXXX\n載具號碼將用於從國稅局自動同步發票")
                    } else {
                        Text("載具號碼將用於從國稅局自動同步發票")
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button("添加") {
                        addCarrier()
                    }
                    .disabled(!isValidInput)
                }
            }
            .navigationTitle("添加載具")
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
        let cleanNumber = number.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanNumber.isEmpty,
              !cleanName.isEmpty else {
            return false
        }
        
        // 驗證載具號碼格式
        if selectedType == .mobileBarcode {
            // 手機條碼格式：/XXXX-XXXX (8碼數字)
            let pattern = #"^/\d{4}-\d{4}$"#
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: cleanNumber.utf16.count)
            if regex?.firstMatch(in: cleanNumber, range: range) == nil {
                return false
            }
        }
        
        return true
    }
    
    private func addCarrier() {
        errorMessage = nil
        
        let cleanNumber = number.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanNumber.isEmpty else {
            errorMessage = "請輸入載具號碼"
            return
        }
        
        guard !cleanName.isEmpty else {
            errorMessage = "請輸入載具名稱"
            return
        }
        
        // 驗證載具號碼格式
        if selectedType == .mobileBarcode {
            let pattern = #"^/\d{4}-\d{4}$"#
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: cleanNumber.utf16.count)
            if regex?.firstMatch(in: cleanNumber, range: range) == nil {
                errorMessage = "手機條碼格式錯誤，應為 /XXXX-XXXX（例如：/1234-5678）"
                return
            }
        }
        
        // 添加載具並保存
        let success = carrierManager.addCarrier(
            type: selectedType,
            number: cleanNumber,
            name: cleanName,
            isDefault: isDefault
        )
        
        if success {
            // 成功保存，關閉視圖
            dismiss()
        } else {
            // 顯示錯誤訊息
            errorMessage = carrierManager.errorMessage ?? "添加載具失敗"
        }
    }
}

// 同步選項視圖
struct SyncOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var carrierManager = InvoiceCarrierManager.shared
    @State private var autoSyncEnabled = false
    @State private var syncInterval: TimeInterval = 3600 // 1小時
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("啟用自動同步", isOn: $autoSyncEnabled)
                    
                    if autoSyncEnabled {
                        Picker("同步間隔", selection: $syncInterval) {
                            Text("每小時").tag(TimeInterval(3600))
                            Text("每6小時").tag(TimeInterval(21600))
                            Text("每天").tag(TimeInterval(86400))
                        }
                    }
                } header: {
                    Text("自動同步")
                } footer: {
                    Text("自動同步將在背景從國稅局下載發票並自動創建交易紀錄")
                }
            }
            .navigationTitle("同步設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        if autoSyncEnabled {
                            carrierManager.enableAutoSync(interval: syncInterval)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    InvoiceCarrierManagementView()
        .modelContainer(for: InvoiceCarrier.self)
}

