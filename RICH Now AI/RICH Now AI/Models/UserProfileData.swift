//
//  UserProfileData.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import Foundation
import SwiftData

@Model
class UserProfileData {
    var id: UUID
    var nickname: String
    var gender: String?
    var email: String?
    var conversationStyle: String?
    var reportFrequency: String?
    var selectedLanguage: String
    var vglaCompleted: Bool
    var subscriptionTier: String
    var createdAt: Date
    var updatedAt: Date
    
    init(
        nickname: String = "",
        gender: String? = nil,
        email: String? = nil,
        conversationStyle: String? = nil,
        reportFrequency: String? = nil,
        selectedLanguage: String = "en",
        vglaCompleted: Bool = false,
        subscriptionTier: String = "free"
    ) {
        self.id = UUID()
        self.nickname = nickname
        self.gender = gender
        self.email = email
        self.conversationStyle = conversationStyle
        self.reportFrequency = reportFrequency
        self.selectedLanguage = selectedLanguage
        self.vglaCompleted = vglaCompleted
        self.subscriptionTier = subscriptionTier
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateProfile(
        nickname: String? = nil,
        gender: String? = nil,
        email: String? = nil,
        conversationStyle: String? = nil,
        reportFrequency: String? = nil,
        selectedLanguage: String? = nil
    ) {
        if let nickname = nickname {
            self.nickname = nickname
        }
        if let gender = gender {
            self.gender = gender
        }
        if let email = email {
            self.email = email
        }
        if let conversationStyle = conversationStyle {
            self.conversationStyle = conversationStyle
        }
        if let reportFrequency = reportFrequency {
            self.reportFrequency = reportFrequency
        }
        if let selectedLanguage = selectedLanguage {
            self.selectedLanguage = selectedLanguage
        }
        self.updatedAt = Date()
    }
    
    func completeVGLA() {
        self.vglaCompleted = true
        self.updatedAt = Date()
    }
    
    func updateSubscription(tier: String) {
        self.subscriptionTier = tier
        self.updatedAt = Date()
    }
}
