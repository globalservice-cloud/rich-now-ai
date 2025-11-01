//
//  APIKeySettingsView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import SwiftData

struct APIKeySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var keyManager = APIKeyManager.shared
    @State private var showingAddKey = false
    @State private var selectedKey: UserAPIKey?
    @State private var showingEditKey = false
    
    var body: some View {
        NavigationView {
            List {
                // 自備 Key 說明
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            
                            Text("自備 API Key 說明")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Text("使用您自己的 API Key 可以：")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• 不受應用程式配額限制")
                            Text("• 享受更快的響應速度")
                            Text("• 節省訂閱費用")
                            Text("• 獲得更好的服務品質")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("說明")
                }
                
                // 當前活躍 Key
                if let activeKey = keyManager.activeKey {
                    Section {
                        ActiveAPIKeyRow(apiKey: activeKey) {
                            selectedKey = activeKey
                            showingEditKey = true
                        }
                    } header: {
                        Text("當前活躍 Key")
                    }
                }
                
                // API Key 列表
                Section {
                    if keyManager.userAPIKeys.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("尚未添加 API Key")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("點擊下方按鈕添加您的第一個 API Key")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        ForEach(keyManager.userAPIKeys, id: \.id) { apiKey in
                            APIKeyRow(
                                apiKey: apiKey,
                                isActive: apiKey.id == keyManager.activeKey?.id
                            ) {
                                selectedKey = apiKey
                                showingEditKey = true
                            } onActivate: {
                                Task {
                                    await keyManager.activateAPIKey(apiKey)
                                }
                            } onDelete: {
                                Task {
                                    await keyManager.deleteAPIKey(apiKey)
                                }
                            }
                        }
                    }
                } header: {
                    Text("API Key 列表")
                }
                
                // 統計資訊
                if !keyManager.userAPIKeys.isEmpty {
                    Section {
                        APIKeyStatsView()
                    } header: {
                        Text("使用統計")
                    }
                }
            }
            .navigationTitle("API Key 設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加 Key") {
                        showingAddKey = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .onAppear {
                keyManager.setModelContext(modelContext)
            }
            .sheet(isPresented: $showingAddKey) {
                AddAPIKeyView()
            }
            .sheet(isPresented: $showingEditKey) {
                if let selectedKey = selectedKey {
                    EditAPIKeyView(apiKey: selectedKey)
                }
            }
        }
    }
}

// MARK: - 活躍 API Key 行

struct ActiveAPIKeyRow: View {
    let apiKey: UserAPIKey
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(apiKey.keyName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(apiKey.service) • 使用 \(apiKey.usageCount) 次")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - API Key 行

struct APIKeyRow: View {
    let apiKey: UserAPIKey
    let isActive: Bool
    let onEdit: () -> Void
    let onActivate: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isActive ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(apiKey.keyName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(apiKey.service) • 使用 \(apiKey.usageCount) 次")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let lastUsed = apiKey.lastUsedAt {
                    Text("最後使用：\(lastUsed, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if !isActive {
                Button("啟用") {
                    onActivate()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Menu {
                Button("編輯") {
                    onEdit()
                }
                
                if !isActive {
                    Button("啟用") {
                        onActivate()
                    }
                }
                
                Button("刪除", role: .destructive) {
                    showingDeleteAlert = true
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .alert("刪除 API Key", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("確定要刪除這個 API Key 嗎？此操作無法復原。")
        }
    }
}

// MARK: - API Key 統計視圖

struct APIKeyStatsView: View {
    @StateObject private var keyManager = APIKeyManager.shared
    
    var body: some View {
        let stats = keyManager.getAPIKeyStats()
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("總計統計")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "總 Key 數",
                    value: "\(stats["totalKeys"] as? Int ?? 0)",
                    icon: "key.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "活躍 Key",
                    value: "\(stats["activeKeys"] as? Int ?? 0)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "總使用次數",
                    value: "\(stats["totalUsage"] as? Int ?? 0)",
                    icon: "arrow.up.circle.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "總成本",
                    value: "$\(String(format: "%.2f", stats["totalCost"] as? Double ?? 0.0))",
                    icon: "dollarsign.circle.fill",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - 統計卡片

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - 添加 API Key 視圖

struct AddAPIKeyView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var keyManager = APIKeyManager.shared
    @State private var service: String = "openai"
    @State private var keyName: String = ""
    @State private var keyValue: String = ""
    @State private var isAdding = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let services = ["openai", "anthropic", "google"]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("服務", selection: $service) {
                        ForEach(services, id: \.self) { service in
                            Text(service.capitalized).tag(service)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("API 服務")
                }
                
                Section {
                    TextField("Key 名稱", text: $keyName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Key 名稱")
                } footer: {
                    Text("為這個 API Key 取一個容易識別的名稱")
                }
                
                Section {
                    TextField("API Key", text: $keyValue)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("API Key")
                } footer: {
                    Text("請輸入您的 \(service.capitalized) API Key")
                }
            }
            .navigationTitle("添加 API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        addAPIKey()
                    }
                    .disabled(isAdding || keyName.isEmpty || keyValue.isEmpty)
                }
            }
            .alert("結果", isPresented: $showingAlert) {
                Button("確定") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func addAPIKey() {
        isAdding = true
        
        Task {
            let success = await keyManager.addAPIKey(
                service: service,
                keyName: keyName,
                keyValue: keyValue
            )
            
            await MainActor.run {
                isAdding = false
                if success {
                    alertMessage = "API Key 添加成功！"
                    showingAlert = true
                    dismiss()
                } else {
                    alertMessage = keyManager.errorMessage ?? "添加失敗"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - 編輯 API Key 視圖

struct EditAPIKeyView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var keyManager = APIKeyManager.shared
    let apiKey: UserAPIKey
    
    @State private var keyName: String = ""
    @State private var keyValue: String = ""
    @State private var isEditing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Key 名稱", text: $keyName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Key 名稱")
                }
                
                Section {
                    TextField("API Key", text: $keyValue)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("API Key")
                } footer: {
                    Text("修改 API Key 將需要重新驗證")
                }
            }
            .navigationTitle("編輯 API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        updateAPIKey()
                    }
                    .disabled(isEditing)
                }
            }
            .onAppear {
                keyName = apiKey.keyName
                keyValue = apiKey.keyValue
            }
            .alert("結果", isPresented: $showingAlert) {
                Button("確定") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func updateAPIKey() {
        isEditing = true
        
        Task {
            let success = await keyManager.updateAPIKey(
                apiKey,
                newKeyName: keyName,
                newKeyValue: keyValue
            )
            
            await MainActor.run {
                isEditing = false
                if success {
                    alertMessage = "API Key 更新成功！"
                    showingAlert = true
                    dismiss()
                } else {
                    alertMessage = keyManager.errorMessage ?? "更新失敗"
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    APIKeySettingsView()
}