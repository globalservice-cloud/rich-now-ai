//
//  UserProfileManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import Foundation
import SwiftData
import Combine

@MainActor
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @Published var currentProfile: UserProfileData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCurrentProfile()
    }
    
    func loadCurrentProfile() {
        guard let modelContext = modelContext else { return }
        
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<UserProfileData>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let profiles = try modelContext.fetch(descriptor)
            
            if let profile = profiles.first {
                currentProfile = profile
            } else {
                // 創建新的用戶資料
                createNewProfile()
            }
        } catch {
            errorMessage = "Failed to load user profile: \(error.localizedDescription)"
            print("Error loading user profile: \(error)")
        }
        
        isLoading = false
    }
    
    func createNewProfile() {
        guard let modelContext = modelContext else { return }
        
        let newProfile = UserProfileData()
        modelContext.insert(newProfile)
        
        do {
            try modelContext.save()
            currentProfile = newProfile
        } catch {
            errorMessage = "Failed to create user profile: \(error.localizedDescription)"
            print("Error creating user profile: \(error)")
        }
    }
    
    func updateProfile(
        nickname: String? = nil,
        gender: String? = nil,
        email: String? = nil,
        conversationStyle: String? = nil,
        reportFrequency: String? = nil,
        selectedLanguage: String? = nil
    ) {
        guard let profile = currentProfile, let modelContext = modelContext else { return }
        
        profile.updateProfile(
            nickname: nickname,
            gender: gender,
            email: email,
            conversationStyle: conversationStyle,
            reportFrequency: reportFrequency,
            selectedLanguage: selectedLanguage
        )
        
        do {
            try modelContext.save()
            currentProfile = profile
        } catch {
            errorMessage = "Failed to update user profile: \(error.localizedDescription)"
            print("Error updating user profile: \(error)")
        }
    }
    
    func completeVGLA(result: VGLAResult) {
        guard let profile = currentProfile, let modelContext = modelContext else { return }
        
        // 更新 VGLA 完成狀態
        profile.completeVGLA()
        
        do {
            try modelContext.save()
            currentProfile = profile
        } catch {
            errorMessage = "Failed to save VGLA result: \(error.localizedDescription)"
            print("Error saving VGLA result: \(error)")
        }
    }
    
    func updateSubscription(tier: String) {
        guard let profile = currentProfile, let modelContext = modelContext else { return }
        
        profile.updateSubscription(tier: tier)
        
        do {
            try modelContext.save()
            currentProfile = profile
        } catch {
            errorMessage = "Failed to update subscription: \(error.localizedDescription)"
            print("Error updating subscription: \(error)")
        }
    }
    
    func canAccessVGLA() -> Bool {
        return currentProfile?.subscriptionTier != "free"
    }
    
    func getVGLAThemeCount() -> Int {
        switch currentProfile?.subscriptionTier {
        case "free":
            return 0
        case "basic":
            return 4
        case "pro":
            return 12
        case "enterprise", "byok":
            return 16
        default:
            return 0
        }
    }
    
    func getPersonalizedGreeting() -> String {
        guard let profile = currentProfile else {
            return LocalizationManager.shared.localizedString("gabriel.greeting").replacingOccurrences(of: "%@", with: "朋友")
        }
        
        let name = profile.nickname.isEmpty ? "朋友" : profile.nickname
        return LocalizationManager.shared.localizedString("gabriel.greeting").replacingOccurrences(of: "%@", with: name)
    }
    
    func getPersonalizedConversationStyle() -> String {
        guard let profile = currentProfile else {
            return LocalizationManager.shared.localizedString("onboarding.conversation_style_friendly")
        }
        
        return profile.conversationStyle ?? "friendly"
    }
    
    func shouldShowVGLA() -> Bool {
        guard let profile = currentProfile else { return false }
        return !profile.vglaCompleted && canAccessVGLA()
    }
    
    func getPersonalizedFinancialAdvice() -> String {
        guard currentProfile != nil else {
            return LocalizationManager.shared.localizedString("financial.advice.default")
        }
        
        // 根據用戶偏好提供個性化建議
        return LocalizationManager.shared.localizedString("financial.advice.default")
    }
    
    func getPersonalizedInvestmentAdvice() -> String {
        guard currentProfile != nil else {
            return LocalizationManager.shared.localizedString("investment.advice.default")
        }
        
        // 根據用戶偏好提供個性化投資建議
        return LocalizationManager.shared.localizedString("investment.advice.default")
    }
}
