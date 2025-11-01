//
//  UserProfileView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import SwiftUI

struct UserProfileView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var progressManager = OnboardingProgressManager.shared
    @State private var isEditing = false
    @State private var editedNickname = ""
    @State private var editedGender: String = "prefer_not_to_say"
    @State private var editedEmail = ""
    @State private var editedConversationStyle: String = "friendly"
    @State private var editedReportFrequency: String = "monthly"
    @State private var showGenderPicker = false
    @State private var showConversationStylePicker = false
    @State private var showReportFrequencyPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                LinearGradient(
                    colors: [Color.safeHex("#F3F4F6", default: Color(.systemGray6)), Color.safeHex("#E5E7EB", default: Color(.systemGray5))],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 完成度提示（如果有未完成的迎賓流程）
                        if progressManager.hasIncompleteOnboarding {
                            let completeness = progressManager.checkProfileCompleteness()
                            if !completeness.isComplete {
                                ProfileCompletenessCard(completeness: completeness)
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                            }
                        }
                        
                        // 頭像區域
                        VStack(spacing: 16) {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.safeHex("#1E3A8A", default: .blue), Color.safeHex("#312E81", default: .purple)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(profileManager.currentProfile?.nickname.prefix(1).uppercased() ?? "U")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            
                            Text(profileManager.currentProfile?.nickname ?? LocalizationManager.shared.localizedString("profile.nickname"))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 20)
                        
                        // 資料卡片
                        VStack(spacing: 16) {
                            ProfileInfoCard(
                                title: LocalizationManager.shared.localizedString("profile.nickname"),
                                value: isEditing ? editedNickname : (profileManager.currentProfile?.nickname ?? ""),
                                isEditing: isEditing,
                                onEdit: { newValue in
                                    editedNickname = newValue
                                }
                            )
                            
                            ProfileInfoCard(
                                title: LocalizationManager.shared.localizedString("profile.gender"),
                                value: isEditing ? editedGender : (profileManager.currentProfile?.gender ?? ""),
                                isEditing: isEditing,
                                onEdit: { _ in
                                    showGenderPicker = true
                                }
                            )
                            
                            ProfileInfoCard(
                                title: LocalizationManager.shared.localizedString("profile.email"),
                                value: isEditing ? editedEmail : (profileManager.currentProfile?.email ?? ""),
                                isEditing: isEditing,
                                onEdit: { newValue in
                                    editedEmail = newValue
                                }
                            )
                            
                            ProfileInfoCard(
                                title: LocalizationManager.shared.localizedString("profile.conversation_style"),
                                value: isEditing ? editedConversationStyle : (profileManager.currentProfile?.conversationStyle ?? ""),
                                isEditing: isEditing,
                                onEdit: { _ in
                                    showConversationStylePicker = true
                                }
                            )
                            
                            ProfileInfoCard(
                                title: LocalizationManager.shared.localizedString("profile.report_frequency"),
                                value: isEditing ? editedReportFrequency : (profileManager.currentProfile?.reportFrequency ?? ""),
                                isEditing: isEditing,
                                onEdit: { _ in
                                    showReportFrequencyPicker = true
                                }
                            )
                            
                            ProfileInfoCard(
                                title: LocalizationManager.shared.localizedString("profile.subscription_tier"),
                                value: profileManager.currentProfile?.subscriptionTier ?? "",
                                isEditing: false,
                                onEdit: { _ in }
                            )
                            
                            ProfileInfoCard(
                                title: LocalizationManager.shared.localizedString("profile.vgla_completed"),
                                value: (profileManager.currentProfile?.vglaCompleted ?? false) ? "✅" : "❌",
                                isEditing: false,
                                onEdit: { _ in }
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // 底部按鈕
                VStack {
                    Spacer()
                    
                    HStack(spacing: 16) {
                        if isEditing {
                            Button(action: cancelEditing) {
                                Text(LocalizationManager.shared.localizedString("profile.cancel"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                            
                            Button(action: saveChanges) {
                                Text(LocalizationManager.shared.localizedString("profile.save_changes"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(hex: "#1E3A8A"))
                                    .cornerRadius(10)
                            }
                        } else {
                            Button(action: startEditing) {
                                Text(LocalizationManager.shared.localizedString("profile.edit_profile"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(hex: "#1E3A8A"))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(LocalizationManager.shared.localizedString("profile.title"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadCurrentValues()
        }
        .sheet(isPresented: $showGenderPicker) {
            GenderPickerView(selectedGender: $editedGender)
        }
        .sheet(isPresented: $showConversationStylePicker) {
            ConversationStylePickerView(selectedStyle: $editedConversationStyle)
        }
        .sheet(isPresented: $showReportFrequencyPicker) {
            ReportFrequencyPickerView(selectedFrequency: $editedReportFrequency)
        }
    }
    
    private func loadCurrentValues() {
        guard let profile = profileManager.currentProfile else { return }
        
        editedNickname = profile.nickname
        editedGender = profile.gender ?? "prefer_not_to_say"
        editedEmail = profile.email ?? ""
        editedConversationStyle = profile.conversationStyle ?? "friendly"
        editedReportFrequency = profile.reportFrequency ?? "monthly"
    }
    
    private func startEditing() {
        loadCurrentValues()
        isEditing = true
    }
    
    private func cancelEditing() {
        isEditing = false
        loadCurrentValues()
    }
    
    private func saveChanges() {
        profileManager.updateProfile(
            nickname: editedNickname,
            gender: editedGender,
            email: editedEmail.isEmpty ? nil : editedEmail,
            conversationStyle: editedConversationStyle,
            reportFrequency: editedReportFrequency
        )
        
        // 同步保存到 UserStateManager
        let profile = UserProfile(
            name: editedNickname,
            email: editedEmail.isEmpty ? nil : editedEmail,
            gender: editedGender == "prefer_not_to_say" ? nil : editedGender,
            gabrielGender: nil, // 在加百列設定中管理
            reportFrequency: editedReportFrequency,
            conversationStyle: editedConversationStyle
        )
        UserStateManager.shared.saveUserProfile(profile)
        
        // 更新進度管理器（如果還有未完成的迎賓流程）
        if progressManager.hasIncompleteOnboarding {
            progressManager.updateSavedProgress(
                userName: editedNickname,
                userEmail: editedEmail.isEmpty ? nil : editedEmail,
                userGender: editedGender == "prefer_not_to_say" ? nil : editedGender,
                reportFrequency: editedReportFrequency,
                conversationStyle: editedConversationStyle
            )
        }
        
        isEditing = false
    }
}

struct ProfileInfoCard: View {
    let title: String
    let value: String
    let isEditing: Bool
    let onEdit: (String) -> Void
    
    @State private var editingValue = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            if isEditing && (title == LocalizationManager.shared.localizedString("profile.nickname") || title == LocalizationManager.shared.localizedString("profile.email")) {
                TextField(value.isEmpty ? title : "", text: $editingValue)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .onAppear {
                        editingValue = value
                    }
                    .onChange(of: editingValue) { _, newValue in
                        onEdit(newValue)
                    }
            } else {
                Button(action: {
                    if isEditing {
                        onEdit("")
                    }
                }) {
                    HStack {
                        Text(value.isEmpty ? title : value)
                            .font(.system(size: 16))
                            .foregroundColor(value.isEmpty ? .secondary : .primary)
                        
                        if isEditing {
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct GenderPickerView: View {
    @Binding var selectedGender: String
    @Environment(\.presentationMode) var presentationMode
    
    private let genders = ["male", "female", "prefer_not_to_say"]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(genders, id: \.self) { gender in
                    Button(action: {
                        selectedGender = gender
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(getGenderDisplayName(gender))
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedGender == gender {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.safeHex("#1E3A8A", default: .blue))
                            }
                        }
                    }
                }
            }
            .navigationTitle(LocalizationManager.shared.localizedString("profile.gender"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("common.close")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func getGenderDisplayName(_ gender: String) -> String {
        switch gender {
        case "male":
            return LocalizationManager.shared.localizedString("gender.male")
        case "female":
            return LocalizationManager.shared.localizedString("gender.female")
        case "prefer_not_to_say":
            return LocalizationManager.shared.localizedString("gender.prefer_not_to_say")
        default:
            return gender
        }
    }
}

struct ConversationStylePickerView: View {
    @Binding var selectedStyle: String
    @Environment(\.presentationMode) var presentationMode
    
    private let styles = ["formal", "friendly", "casual", "professional"]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(styles, id: \.self) { style in
                    Button(action: {
                        selectedStyle = style
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(getStyleDisplayName(style))
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedStyle == style {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.safeHex("#1E3A8A", default: .blue))
                            }
                        }
                    }
                }
            }
            .navigationTitle(LocalizationManager.shared.localizedString("profile.conversation_style"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("common.close")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func getStyleDisplayName(_ style: String) -> String {
        switch style {
        case "formal":
            return LocalizationManager.shared.localizedString("onboarding.conversation_style_formal")
        case "friendly":
            return LocalizationManager.shared.localizedString("onboarding.conversation_style_friendly")
        case "casual":
            return LocalizationManager.shared.localizedString("onboarding.conversation_style_casual")
        case "professional":
            return LocalizationManager.shared.localizedString("onboarding.conversation_style_professional")
        default:
            return style
        }
    }
}

struct ReportFrequencyPickerView: View {
    @Binding var selectedFrequency: String
    @Environment(\.presentationMode) var presentationMode
    
    private let frequencies = ["daily", "weekly", "biweekly", "monthly", "quarterly", "yearly", "never"]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(frequencies, id: \.self) { frequency in
                    Button(action: {
                        selectedFrequency = frequency
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(getFrequencyDisplayName(frequency))
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedFrequency == frequency {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.safeHex("#1E3A8A", default: .blue))
                            }
                        }
                    }
                }
            }
            .navigationTitle(LocalizationManager.shared.localizedString("profile.report_frequency"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("common.close")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func getFrequencyDisplayName(_ frequency: String) -> String {
        switch frequency {
        case "daily":
            return LocalizationManager.shared.localizedString("report_frequency.daily")
        case "weekly":
            return LocalizationManager.shared.localizedString("report_frequency.weekly")
        case "biweekly":
            return LocalizationManager.shared.localizedString("report_frequency.biweekly")
        case "monthly":
            return LocalizationManager.shared.localizedString("report_frequency.monthly")
        case "quarterly":
            return LocalizationManager.shared.localizedString("report_frequency.quarterly")
        case "yearly":
            return LocalizationManager.shared.localizedString("report_frequency.yearly")
        case "never":
            return LocalizationManager.shared.localizedString("report_frequency.never")
        default:
            return frequency
        }
    }
}

#Preview {
    UserProfileView()
}
