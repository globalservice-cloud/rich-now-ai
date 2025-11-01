//
//  BackupSettingsView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct BackupSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var autoBackup: Bool = true
    @State private var backupFrequency: BackupFrequency = .weekly
    @State private var cloudSync: Bool = true
    @State private var showingBackupStatus = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("自動備份", isOn: $autoBackup)
                        .onChange(of: autoBackup) { _, _ in
                            updateBackupSettings()
                        }
                    
                    Text("自動備份您的財務數據到 iCloud")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("備份設定")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("備份頻率")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("備份頻率", selection: $backupFrequency) {
                            ForEach(BackupFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.displayName).tag(frequency)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: backupFrequency) { _, _ in
                            updateBackupSettings()
                        }
                        
                        Text("選擇備份數據的頻率")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("備份頻率")
                }
                
                Section {
                    Toggle("雲端同步", isOn: $cloudSync)
                        .onChange(of: cloudSync) { _, _ in
                            updateBackupSettings()
                        }
                    
                    Text("在多個設備間同步您的數據")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("同步設定")
                }
                
                Section {
                    Button("查看備份狀態") {
                        showingBackupStatus = true
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                } header: {
                    Text("備份管理")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("備份設定摘要")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("自動備份：\(autoBackup ? "已啟用" : "已停用")")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("備份頻率：\(backupFrequency.displayName)")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("雲端同步：\(cloudSync ? "已啟用" : "已停用")")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("設定摘要")
                }
            }
            .navigationTitle("備份與同步")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentSettings()
            }
            .sheet(isPresented: $showingBackupStatus) {
                BackupStatusView()
            }
        }
    }
    
    private func loadCurrentSettings() {
        if let settings = settingsManager.currentSettings {
            autoBackup = settings.autoBackup
            backupFrequency = BackupFrequency(rawValue: settings.backupFrequency) ?? .weekly
            cloudSync = settings.cloudSync
        }
    }
    
    private func updateBackupSettings() {
        settingsManager.updateBackupSettings(
            autoBackup: autoBackup,
            backupFrequency: backupFrequency,
            cloudSync: cloudSync
        )
    }
}

// MARK: - 備份狀態視圖

struct BackupStatusView: View {
    @Environment(\.dismiss) var dismiss
    @State private var lastBackupDate: Date = Date().addingTimeInterval(-86400)
    @State private var backupSize: String = "2.5 MB"
    @State private var isBackingUp: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("備份狀態")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                VStack(spacing: 16) {
                    // 最後備份時間
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("最後備份")
                                .font(.headline)
                            
                            Text(lastBackupDate, style: .relative)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 備份大小
                    HStack {
                        Image(systemName: "externaldrive.fill")
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading) {
                            Text("備份大小")
                                .font(.headline)
                            
                            Text(backupSize)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 備份狀態
                    HStack {
                        Image(systemName: isBackingUp ? "arrow.clockwise" : "checkmark.circle.fill")
                            .foregroundColor(isBackingUp ? .orange : .green)
                            .rotationEffect(.degrees(isBackingUp ? 360 : 0))
                            .animation(isBackingUp ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isBackingUp)
                        
                        VStack(alignment: .leading) {
                            Text("備份狀態")
                                .font(.headline)
                            
                            Text(isBackingUp ? "備份中..." : "備份完成")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Button("立即備份") {
                    performBackup()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isBackingUp)
                
                Spacer()
            }
            .padding()
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
    
    private func performBackup() {
        isBackingUp = true
        
        // 模擬備份過程
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isBackingUp = false
            lastBackupDate = Date()
        }
    }
}

#Preview {
    BackupSettingsView()
}
