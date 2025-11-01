//
//  ProfileSettingsView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct ProfileSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var userName: String = ""
    @State private var reportEmail: String = ""
    @State private var selectedLanguage: String = "en"
    @State private var showingLanguagePicker = false
    @State private var showingEmailValidation = false
    @State private var isEmailValid = true
    
    let languages = [
        ("en", "English", "🇺🇸"),
        ("zh-Hant", "繁體中文", "🇹🇼"),
        ("zh-Hans", "简体中文", "🇨🇳")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // 用戶名稱
                    VStack(alignment: .leading, spacing: 8) {
                        Text("您的稱呼")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("請輸入您的稱呼", text: $userName)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("這個稱呼會用於加百列與您的對話中")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("基本資訊")
                }
                
                Section {
                    // 報告電子郵件
                    VStack(alignment: .leading, spacing: 8) {
                        Text("報告電子郵件")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("請輸入電子郵件地址", text: $reportEmail)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .onChange(of: reportEmail) {
                                validateEmail()
                            }
                        
                        if !isEmailValid && !reportEmail.isEmpty {
                            Text("請輸入有效的電子郵件地址")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Text("財務報告將發送到此電子郵件地址")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("報告設定")
                }
                
                Section {
                    // 語言選擇
                    VStack(alignment: .leading, spacing: 8) {
                        Text("應用程式語言")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            showingLanguagePicker = true
                        }) {
                            HStack {
                                Text(getCurrentLanguageDisplay())
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        
                        Text("選擇您偏好的應用程式語言")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("語言設定")
                }
                
                Section {
                    // 預覽設定
                    VStack(alignment: .leading, spacing: 12) {
                        Text("預覽設定")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("稱呼：")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text(userName.isEmpty ? "未設定" : userName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                Text("電子郵件：")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text(reportEmail.isEmpty ? "未設定" : reportEmail)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                Text("語言：")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text(getCurrentLanguageDisplay())
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("設定預覽")
                }
            }
            .navigationTitle("個人資料設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        saveSettings()
                    }
                    .disabled(!isEmailValid && !reportEmail.isEmpty)
                }
            }
            .onAppear {
                loadCurrentSettings()
            }
            .sheet(isPresented: $showingLanguagePicker) {
                LanguagePickerView(
                    selectedLanguage: $selectedLanguage,
                    currentLanguage: localizationManager.currentLanguage.rawValue
                )
            }
            .onChange(of: localizationManager.currentLanguage) { _, newLanguage in
                // 當 LocalizationManager 的語言改變時，同步更新 selectedLanguage
                selectedLanguage = newLanguage.rawValue
            }
        }
    }
    
    // MARK: - 輔助方法
    
    private func loadCurrentSettings() {
        if let settings = settingsManager.currentSettings {
            userName = settings.userName
            reportEmail = settings.reportEmail
            // 優先使用 LocalizationManager 的當前語言，如果沒有則使用設定中的語言
            selectedLanguage = localizationManager.currentLanguage.rawValue
        } else {
            // 如果沒有設定，使用 LocalizationManager 的當前語言
            selectedLanguage = localizationManager.currentLanguage.rawValue
        }
    }
    
    private func saveSettings() {
        settingsManager.updateUserName(userName)
        settingsManager.updateReportEmail(reportEmail)
        settingsManager.updateLanguage(selectedLanguage)
        
        // 同步更新 LocalizationManager
        if let language = LocalizationManager.AppLanguage(rawValue: selectedLanguage) {
            localizationManager.changeLanguage(to: language)
        }
        
        dismiss()
    }
    
    private func validateEmail() {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        isEmailValid = emailPredicate.evaluate(with: reportEmail) || reportEmail.isEmpty
    }
    
    private func getCurrentLanguageDisplay() -> String {
        if let language = languages.first(where: { $0.0 == selectedLanguage }) {
            return "\(language.2) \(language.1)"
        }
        return "English 🇺🇸"
    }
}

// MARK: - 語言選擇器

struct LanguagePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLanguage: String
    let currentLanguage: String
    
    let languages = [
        ("en", "English", "🇺🇸"),
        ("zh-Hant", "繁體中文", "🇹🇼"),
        ("zh-Hans", "简体中文", "🇨🇳")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(languages, id: \.0) { language in
                    Button(action: {
                        selectedLanguage = language.0
                        // 立即應用語言變更（不等待保存）
                        if let appLanguage = LocalizationManager.AppLanguage(rawValue: language.0) {
                            LocalizationManager.shared.changeLanguage(to: appLanguage)
                        }
                        dismiss()
                    }) {
                        HStack {
                            Text(language.2)
                                .font(.title2)
                            
                            Text(language.1)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedLanguage == language.0 || (selectedLanguage != currentLanguage && language.0 == selectedLanguage) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("選擇語言")
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

// MARK: - 預覽

#Preview {
    ProfileSettingsView()
}
