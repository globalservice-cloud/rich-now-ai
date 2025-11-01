//
//  CloudKitConfiguration.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import CloudKit

struct CloudKitConfiguration {
    
    // MARK: - Container Configuration
    
    static let containerIdentifier = "iCloud.com.richnowai.app"
    static let container = CKContainer(identifier: containerIdentifier)
    
    // MARK: - Record Types
    
    struct RecordTypes {
        static let userProfile = "UserProfile"
        static let vglaAssessment = "VGLAAssessment"
        static let tkiAssessment = "TKIAssessment"
        static let conversation = "Conversation"
        static let transaction = "Transaction"
        static let financialGoal = "FinancialGoal"
        static let budget = "Budget"
        static let report = "Report"
        static let investment = "Investment"
        static let investmentTransaction = "InvestmentTransaction"
        static let investmentPortfolio = "InvestmentPortfolio"
        static let subscriptionTier = "SubscriptionTier"
        static let themePanel = "ThemePanel"
        static let gabriel = "Gabriel"
    }
    
    // MARK: - Field Names
    
    struct FieldNames {
        // User Profile
        static let userId = "userId"
        static let name = "name"
        static let email = "email"
        static let age = "age"
        static let occupation = "occupation"
        static let familyStatus = "familyStatus"
        static let createdAt = "createdAt"
        static let lastLoginAt = "lastLoginAt"
        static let financialHealthScore = "financialHealthScore"
        static let subscriptionType = "subscriptionType"
        
        // VGLA Assessment
        static let vglaCompleted = "vglaCompleted"
        static let vglaPrimaryType = "vglaPrimaryType"
        static let vglaSecondaryType = "vglaSecondaryType"
        static let vglaCombinationType = "vglaCombinationType"
        static let vglaScore = "vglaScore"
        
        // TKI Assessment
        static let tkiCompleted = "tkiCompleted"
        static let tkiPrimaryMode = "tkiPrimaryMode"
        static let tkiSecondaryMode = "tkiSecondaryMode"
        static let tkiScores = "tkiScores"
        static let tkiCompletedAt = "tkiCompletedAt"
        
        // Transaction
        static let amount = "amount"
        static let category = "category"
        static let transactionDescription = "transactionDescription"
        static let date = "date"
        static let type = "type"
        static let isRecurring = "isRecurring"
        static let tags = "tags"
        
        // Financial Goal
        static let title = "title"
        static let goalDescription = "goalDescription"
        static let targetAmount = "targetAmount"
        static let currentAmount = "currentAmount"
        static let targetDate = "targetDate"
        static let priority = "priority"
        static let isCompleted = "isCompleted"
    }
    
    // MARK: - Sync Configuration
    
    struct SyncConfiguration {
        static let batchSize = 100
        static let maxRetryAttempts = 3
        static let syncInterval: TimeInterval = 300 // 5 minutes
        static let conflictResolutionStrategy = ConflictResolutionStrategy.timestampBased
    }
    
    enum ConflictResolutionStrategy {
        case timestampBased
        case localWins
        case remoteWins
        case merge
    }
    
    // MARK: - Privacy Settings
    
    struct PrivacySettings {
        static let userDiscoverability = true
        static let shareUserData = false
        static let encryptSensitiveData = true
    }
    
    // MARK: - Data Retention
    
    struct DataRetention {
        static let conversationRetentionDays = 365
        static let transactionRetentionDays = 2555 // 7 years
        static let assessmentRetentionDays = 3650 // 10 years
        static let backupRetentionDays = 30
    }
    
    // MARK: - Sync Status
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
        case conflict
        case offline
    }
    
    // MARK: - Error Handling
    
    struct ErrorCodes {
        static let networkError = "NETWORK_ERROR"
        static let authenticationError = "AUTH_ERROR"
        static let quotaExceeded = "QUOTA_EXCEEDED"
        static let conflictError = "CONFLICT_ERROR"
        static let unknownError = "UNKNOWN_ERROR"
    }
    
    // MARK: - Performance Optimization
    
    struct PerformanceSettings {
        static let enableBatching = true
        static let enableCaching = true
        static let cacheExpirationTime: TimeInterval = 3600 // 1 hour
        static let maxCacheSize = 50 * 1024 * 1024 // 50 MB
    }
}
