//
//  UserStateManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import Foundation
import SwiftUI
import Combine

class UserStateManager: ObservableObject {
    static let shared = UserStateManager()
    
    @Published var isOnboardingCompleted: Bool = false
    @Published var hasCompletedVGLA: Bool = false
    @Published var vglaResult: VGLAResult?
    @Published var userProfile: UserProfile?
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadUserState()
    }
    
    // MARK: - 載入用戶狀態
    private func loadUserState() {
        isOnboardingCompleted = userDefaults.bool(forKey: "isOnboardingCompleted")
        hasCompletedVGLA = userDefaults.bool(forKey: "hasCompletedVGLA")
        
        // 載入 VGLA 結果
        if let vglaData = userDefaults.data(forKey: "vglaResult"),
           let result = try? JSONDecoder().decode(VGLAResult.self, from: vglaData) {
            vglaResult = result
        }
        
        // 載入用戶資料
        if let profileData = userDefaults.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            userProfile = profile
        }
    }
    
    // MARK: - 保存用戶狀態
    func saveOnboardingCompleted() {
        isOnboardingCompleted = true
        userDefaults.set(true, forKey: "isOnboardingCompleted")
    }
    
    func saveVGLAResult(_ result: VGLAResult) {
        vglaResult = result
        hasCompletedVGLA = true
        
        if let data = try? JSONEncoder().encode(result) {
            userDefaults.set(data, forKey: "vglaResult")
        }
        userDefaults.set(true, forKey: "hasCompletedVGLA")
    }
    
    func saveUserProfile(_ profile: UserProfile) {
        userProfile = profile
        
        if let data = try? JSONEncoder().encode(profile) {
            userDefaults.set(data, forKey: "userProfile")
        }
    }
    
    // MARK: - 重置用戶狀態
    func resetUserState() {
        isOnboardingCompleted = false
        hasCompletedVGLA = false
        vglaResult = nil
        userProfile = nil
        
        userDefaults.removeObject(forKey: "isOnboardingCompleted")
        userDefaults.removeObject(forKey: "hasCompletedVGLA")
        userDefaults.removeObject(forKey: "vglaResult")
        userDefaults.removeObject(forKey: "userProfile")
    }
    
    // MARK: - 檢查是否需要重新測驗
    func shouldShowVGLA() -> Bool {
        return !hasCompletedVGLA
    }
    
    // MARK: - 獲取用戶顯示名稱
    func getUserDisplayName() -> String {
        return userProfile?.name ?? "用戶"
    }
}

// MARK: - 用戶資料模型
struct UserProfile: Codable {
    let name: String
    let email: String?
    let gender: String?
    let gabrielGender: String?
    let reportFrequency: String?
    let conversationStyle: String?
    let createdAt: Date
    
    init(name: String, email: String? = nil, gender: String? = nil, gabrielGender: String? = nil, reportFrequency: String? = nil, conversationStyle: String? = nil) {
        self.name = name
        self.email = email
        self.gender = gender
        self.gabrielGender = gabrielGender
        self.reportFrequency = reportFrequency
        self.conversationStyle = conversationStyle
        self.createdAt = Date()
    }
}
