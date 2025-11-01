//
//  SubscriptionManagementView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import StoreKit

struct SubscriptionManagementView: View {
    @StateObject private var storeKitManager = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showUpgradeAlert = false
    @State private var showCancelAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 當前訂閱狀態
                    currentSubscriptionCard
                    
                    // 使用統計
                    usageStatisticsSection
                    
                    // 功能限制提醒
                    if storeKitManager.currentSubscription != .pro {
                        upgradePromptSection
                    }
                    
                    // 管理選項
                    managementOptionsSection
                    
                    // 訂閱歷史
                    subscriptionHistorySection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle(LocalizationManager.shared.localizedString("subscription.management.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationManager.shared.localizedString("common.close")) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await storeKitManager.updateSubscriptionStatus()
            }
        }
        .alert(LocalizationManager.shared.localizedString("subscription.upgrade.title"), isPresented: $showUpgradeAlert) {
            Button(LocalizationManager.shared.localizedString("common.cancel"), role: .cancel) { }
            Button(LocalizationManager.shared.localizedString("subscription.upgrade.confirm")) {
                // 打開訂閱商店
            }
        } message: {
            Text(LocalizationManager.shared.localizedString("subscription.upgrade.message"))
        }
        .alert(LocalizationManager.shared.localizedString("subscription.cancel.title"), isPresented: $showCancelAlert) {
            Button(LocalizationManager.shared.localizedString("common.cancel"), role: .cancel) { }
            Button(LocalizationManager.shared.localizedString("subscription.cancel.confirm"), role: .destructive) {
                Task {
                    await storeKitManager.cancelSubscription()
                }
            }
        } message: {
            Text(LocalizationManager.shared.localizedString("subscription.cancel.message"))
        }
    }
    
    // MARK: - 當前訂閱卡片
    
    private var currentSubscriptionCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: storeKitManager.currentSubscription.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: storeKitManager.currentSubscription.color))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(storeKitManager.currentSubscription.displayName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(storeKitManager.currentSubscription.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(storeKitManager.currentSubscription.price)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: storeKitManager.currentSubscription.color))
                    
                    StatusBadge(status: storeKitManager.subscriptionStatus)
                }
            }
            
            // 功能列表
            VStack(alignment: .leading, spacing: 8) {
                ForEach(storeKitManager.currentSubscription.features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        
                        Text(feature)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: storeKitManager.currentSubscription.color) ?? .blue, lineWidth: 2)
                )
        )
    }
    
    // MARK: - 使用統計
    
    private var usageStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("subscription.usage.title"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                UsageStatRow(
                    title: LocalizationManager.shared.localizedString("subscription.feature.ai_chat"),
                    used: 45,
                    limit: storeKitManager.currentSubscription.limits.aiChatMessages,
                    icon: "brain.head.profile"
                )
                
                UsageStatRow(
                    title: LocalizationManager.shared.localizedString("subscription.feature.voice_input"),
                    used: 15,
                    limit: storeKitManager.currentSubscription.limits.voiceMinutes,
                    icon: "mic.fill"
                )
                
                UsageStatRow(
                    title: LocalizationManager.shared.localizedString("subscription.feature.image_analysis"),
                    used: 8,
                    limit: storeKitManager.currentSubscription.limits.imageAnalysis,
                    icon: "camera.fill"
                )
            }
        }
    }
    
    // MARK: - 升級提示
    
    private var upgradePromptSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizationManager.shared.localizedString("subscription.upgrade.title"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(LocalizationManager.shared.localizedString("subscription.upgrade.subtitle"))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(LocalizationManager.shared.localizedString("subscription.upgrade.button")) {
                    showUpgradeAlert = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange)
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 管理選項
    
    private var managementOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("subscription.management.options"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ManagementOptionRow(
                    title: LocalizationManager.shared.localizedString("subscription.management.restore"),
                    subtitle: LocalizationManager.shared.localizedString("subscription.management.restore_subtitle"),
                    icon: "arrow.clockwise",
                    action: {
                        Task {
                            await storeKitManager.restorePurchases()
                        }
                    }
                )
                
                ManagementOptionRow(
                    title: LocalizationManager.shared.localizedString("subscription.management.cancel"),
                    subtitle: LocalizationManager.shared.localizedString("subscription.management.cancel_subtitle"),
                    icon: "xmark.circle",
                    isDestructive: true,
                    action: {
                        showCancelAlert = true
                    }
                )
                
                ManagementOptionRow(
                    title: LocalizationManager.shared.localizedString("subscription.management.contact"),
                    subtitle: LocalizationManager.shared.localizedString("subscription.management.contact_subtitle"),
                    icon: "envelope",
                    action: {
                        // 打開客服郵件
                    }
                )
            }
        }
    }
    
    // MARK: - 訂閱歷史
    
    private var subscriptionHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("subscription.history.title"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                HistoryItemRow(
                    plan: .basic,
                    date: "2024-01-15",
                    status: .active,
                    amount: "$4.99"
                )
                
                HistoryItemRow(
                    plan: .free,
                    date: "2024-01-01",
                    status: .expired,
                    amount: "Free"
                )
            }
        }
    }
}

// MARK: - 狀態徽章

struct StatusBadge: View {
    let status: SubscriptionStatus
    
    var body: some View {
        Text(statusDisplayName)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .cornerRadius(8)
    }
    
    private var statusDisplayName: String {
        switch status {
        case .none:
            return LocalizationManager.shared.localizedString("subscription.status.none")
        case .active:
            return LocalizationManager.shared.localizedString("subscription.status.active")
        case .expired:
            return LocalizationManager.shared.localizedString("subscription.status.expired")
        case .cancelled:
            return LocalizationManager.shared.localizedString("subscription.status.cancelled")
        case .pending:
            return LocalizationManager.shared.localizedString("subscription.status.pending")
        case .gracePeriod:
            return LocalizationManager.shared.localizedString("subscription.status.grace_period")
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .active:
            return .green
        case .expired, .cancelled:
            return .red
        case .pending, .gracePeriod:
            return .orange
        case .none:
            return .gray
        }
    }
}

// MARK: - 使用統計行

struct UsageStatRow: View {
    let title: String
    let used: Int
    let limit: Int
    let icon: String
    
    private var usagePercentage: Double {
        guard limit > 0 else { return 0 }
        return Double(used) / Double(limit)
    }
    
    private var isUnlimited: Bool {
        return limit == -1
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                if isUnlimited {
                    Text(LocalizationManager.shared.localizedString("subscription.unlimited"))
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                } else {
                    HStack {
                        Text("\(used) / \(limit)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(usagePercentage * 100))%")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(usagePercentage > 0.8 ? .red : .secondary)
                    }
                    
                    ProgressView(value: usagePercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: usagePercentage > 0.8 ? .red : .blue))
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - 管理選項行

struct ManagementOptionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let isDestructive: Bool
    let action: () -> Void
    
    init(title: String, subtitle: String, icon: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isDestructive ? .red : .blue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isDestructive ? .red : .primary)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 歷史項目行

struct HistoryItemRow: View {
    let plan: SubscriptionPlan
    let date: String
    let status: SubscriptionStatus
    let amount: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(date)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(amount)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                StatusBadge(status: status)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    SubscriptionManagementView()
}
