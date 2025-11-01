//
//  SettingsView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Binding var showAdvancedAssessment: Bool
    @State private var showingMainSettings = false
    @State private var showMainMenu = false
    @State private var showVGLAAssessment = false
    
    var body: some View {
        NavigationBarContainer(
            title: LocalizationManager.shared.localizedString("settings.title"),
            showBackButton: true,
            showMenuButton: true,
            onBack: {
                // 返回主頁的邏輯
            },
            onMenu: {
                showMainMenu = true
            }
        ) {
            List {
                // 主要設定入口
                Section {
                    Button(action: {
                        showingMainSettings = true
                    }) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text("完整設定")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("個人資料、外觀、加百列、通知等")
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
                } header: {
                    Text("主要設定")
                }
                
                // 測驗設定
                Section {
                    // VGLA 測驗
                    Button(action: {
                        // 這裡可以導航到VGLA測驗
                    }) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("VGLA 測驗")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("財務決策思考模式測驗")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    // TKI 測驗
                    Button(action: {
                        showAdvancedAssessment = true
                    }) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.orange)
                                .font(.title2)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("TKI 測驗")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("衝突處理風格測驗")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("測驗設定")
                }
                
                // 快速設定
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("快速設定")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("點擊上方「完整設定」以訪問所有設定選項，包括：")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            QuickSettingRow(icon: "person.fill", title: "個人資料", description: "稱呼、語言、電子郵件")
                            QuickSettingRow(icon: "paintbrush.fill", title: "外觀設定", description: "設計風格、顏色、字體")
                            QuickSettingRow(icon: "person.circle.fill", title: "加百列設定", description: "性別、服裝、個性")
                            QuickSettingRow(icon: "bell.fill", title: "通知設定", description: "提醒、報告、警報")
                            QuickSettingRow(icon: "lock.fill", title: "隱私與安全", description: "數據保護、認證")
                            QuickSettingRow(icon: "icloud.fill", title: "備份與同步", description: "自動備份、雲端同步")
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("設定說明")
                }
            }
            .sheet(isPresented: $showingMainSettings) {
                SettingsMainView()
            }
            .sheet(isPresented: $showMainMenu) {
                MainMenuView(isPresented: $showMainMenu)
            }
            .sheet(isPresented: $showVGLAAssessment) {
                VGLAAssessmentView { result in
                    showVGLAAssessment = false
                }
            }
        }
    }
}

// MARK: - 快速設定行

struct QuickSettingRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SettingsView(showAdvancedAssessment: .constant(false))
}
