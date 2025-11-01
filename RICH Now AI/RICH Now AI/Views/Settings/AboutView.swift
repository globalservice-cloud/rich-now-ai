//
//  AboutView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingContactSupport = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    // 應用程式資訊
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("RICH Now AI")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("版本 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("您的智能財務管理助手")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } header: {
                    Text("應用程式資訊")
                }
                
                Section {
                    // 功能特色
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "brain.head.profile", title: "AI 財務顧問", description: "智能加百列提供個人化財務建議")
                        FeatureRow(icon: "chart.bar.fill", title: "財務健康評估", description: "六大維度全面評估您的財務狀況")
                        FeatureRow(icon: "creditcard.fill", title: "智能記帳", description: "自然語言記帳，語音和照片記帳")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "投資組合追蹤", description: "實時追蹤投資表現和資產配置")
                        FeatureRow(icon: "person.2.fill", title: "個性化面板", description: "基於 VGLA 測驗的專屬財務面板")
                    }
                } header: {
                    Text("功能特色")
                }
                
                Section {
                    // 法律文件
                    Button("隱私政策") {
                        showingPrivacyPolicy = true
                    }
                    .foregroundColor(.primary)
                    
                    Button("服務條款") {
                        showingTermsOfService = true
                    }
                    .foregroundColor(.primary)
                    
                    Button("聯絡支援") {
                        showingContactSupport = true
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("法律與支援")
                }
                
                Section {
                    // 開發資訊
                    VStack(alignment: .leading, spacing: 8) {
                        Text("開發團隊")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("RICH Now AI 開發團隊")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("© 2025 RICH Now AI. All rights reserved.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("開發資訊")
                }
            }
            .navigationTitle("關於")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingTermsOfService) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showingContactSupport) {
                ContactSupportView()
            }
        }
    }
}

// MARK: - 功能特色行

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 隱私政策視圖

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("隱私政策")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    Text("最後更新：2025年10月26日")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                    
                    Group {
                        Text("1. 資訊收集")
                            .font(.headline)
                            .padding(.top)
                        
                        Text("我們收集您提供的財務數據、使用模式和偏好設定，以提供個人化的財務管理服務。")
                            .font(.body)
                        
                        Text("2. 資訊使用")
                            .font(.headline)
                            .padding(.top)
                        
                        Text("您的數據僅用於改善應用程式功能、提供財務建議和生成個人化報告。")
                            .font(.body)
                        
                        Text("3. 資訊保護")
                            .font(.headline)
                            .padding(.top)
                        
                        Text("我們採用業界標準的加密技術保護您的數據，絕不會與第三方分享您的個人財務資訊。")
                            .font(.body)
                        
                        Text("4. 您的權利")
                            .font(.headline)
                            .padding(.top)
                        
                        Text("您可以隨時查看、修改或刪除您的數據，也可以選擇退出數據收集。")
                            .font(.body)
                    }
                }
                .padding()
            }
            .navigationTitle("隱私政策")
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

// MARK: - 服務條款視圖

struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("服務條款")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    Text("最後更新：2025年10月26日")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                    
                    Group {
                        Text("1. 服務描述")
                            .font(.headline)
                            .padding(.top)
                        
                        Text("RICH Now AI 提供智能財務管理服務，包括記帳、投資追蹤和財務建議。")
                            .font(.body)
                        
                        Text("2. 用戶責任")
                            .font(.headline)
                            .padding(.top)
                        
                        Text("用戶應提供準確的財務資訊，並對其財務決策負責。")
                            .font(.body)
                        
                        Text("3. 服務限制")
                            .font(.headline)
                            .padding(.top)
                        
                        Text("本應用程式僅提供財務管理工具，不構成投資建議。")
                            .font(.body)
                        
                        Text("4. 免責聲明")
                            .font(.headline)
                            .padding(.top)
                        
                        Text("我們不對用戶的財務決策或投資結果承擔責任。")
                            .font(.body)
                    }
                }
                .padding()
            }
            .navigationTitle("服務條款")
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

// MARK: - 聯絡支援視圖

struct ContactSupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var supportEmail = "support@richnowai.com"
    @State private var supportPhone = "+1-800-RICH-NOW"
    @State private var showingEmailComposer = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("聯絡支援")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                VStack(spacing: 16) {
                    // 電子郵件支援
                    Button(action: {
                        showingEmailComposer = true
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text("電子郵件支援")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(supportEmail)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    
                    // 電話支援
                    Button(action: {
                        // 撥打電話
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading) {
                                Text("電話支援")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(supportPhone)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    
                    // 常見問題
                    Button(action: {
                        // 開啟常見問題
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading) {
                                Text("常見問題")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("查看常見問題解答")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("聯絡支援")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEmailComposer) {
                // 這裡可以整合 MFMailComposeViewController
                Text("電子郵件撰寫器")
            }
        }
    }
}

#Preview {
    AboutView()
}
