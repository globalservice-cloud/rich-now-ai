//
//  SubscriptionStoreView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import StoreKit

struct SubscriptionStoreView: View {
    @StateObject private var storeKitManager = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: SubscriptionPlan?
    @State private var showPurchaseAlert = false
    @State private var purchaseSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 標題區域
                    headerSection
                    
                    // 當前訂閱狀態
                    currentSubscriptionSection
                    
                    // 訂閱方案卡片
                    subscriptionPlansSection
                    
                    // 功能比較表
                    featuresComparisonSection
                    
                    // 常見問題
                    faqSection
                    
                    // 條款和隱私
                    termsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle(LocalizationManager.shared.localizedString("subscription.store.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationManager.shared.localizedString("common.close")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("subscription.restore")) {
                        Task {
                            await storeKitManager.restorePurchases()
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await storeKitManager.loadProducts()
            }
        }
        .alert(LocalizationManager.shared.localizedString("subscription.purchase.title"), isPresented: $showPurchaseAlert) {
            Button(LocalizationManager.shared.localizedString("common.cancel"), role: .cancel) { }
            Button(LocalizationManager.shared.localizedString("subscription.purchase.confirm")) {
                if let plan = selectedPlan {
                    Task {
                        await purchasePlan(plan)
                    }
                }
            }
        } message: {
            if let plan = selectedPlan {
                Text(LocalizationManager.shared.localizedString("subscription.purchase.message").replacingOccurrences(of: "%@", with: plan.displayName))
            }
        }
        .alert(LocalizationManager.shared.localizedString("subscription.purchase.success"), isPresented: $purchaseSuccess) {
            Button(LocalizationManager.shared.localizedString("common.ok")) {
                dismiss()
            }
        } message: {
            Text(LocalizationManager.shared.localizedString("subscription.purchase.success_message"))
        }
    }
    
    // MARK: - 標題區域
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("💎")
                .font(.system(size: 60))
            
            Text(LocalizationManager.shared.localizedString("subscription.store.header_title"))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(LocalizationManager.shared.localizedString("subscription.store.header_subtitle"))
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - 當前訂閱狀態
    
    private var currentSubscriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizationManager.shared.localizedString("subscription.current_status"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: storeKitManager.currentSubscription.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: storeKitManager.currentSubscription.color))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(storeKitManager.currentSubscription.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(storeKitManager.currentSubscription.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if storeKitManager.subscriptionStatus == .active {
                    Text(LocalizationManager.shared.localizedString("subscription.active"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 訂閱方案卡片
    
    private var subscriptionPlansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("subscription.choose_plan"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            if storeKitManager.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(LocalizationManager.shared.localizedString("subscription.loading"))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(storeKitManager.products, id: \.plan) { product in
                        SubscriptionPlanCard(
                            product: product,
                            isSelected: selectedPlan == product.plan,
                            onTap: {
                                selectedPlan = product.plan
                                showPurchaseAlert = true
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - 功能比較表
    
    private var featuresComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("subscription.features_comparison"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            FeaturesComparisonTable()
        }
    }
    
    // MARK: - 常見問題
    
    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("subscription.faq.title"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                FAQItem(
                    question: LocalizationManager.shared.localizedString("subscription.faq.q1"),
                    answer: LocalizationManager.shared.localizedString("subscription.faq.a1")
                )
                
                FAQItem(
                    question: LocalizationManager.shared.localizedString("subscription.faq.q2"),
                    answer: LocalizationManager.shared.localizedString("subscription.faq.a2")
                )
                
                FAQItem(
                    question: LocalizationManager.shared.localizedString("subscription.faq.q3"),
                    answer: LocalizationManager.shared.localizedString("subscription.faq.a3")
                )
            }
        }
    }
    
    // MARK: - 條款和隱私
    
    private var termsSection: some View {
        VStack(spacing: 12) {
            Text(LocalizationManager.shared.localizedString("subscription.terms_notice"))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                Button(LocalizationManager.shared.localizedString("subscription.terms")) {
                    // 打開條款頁面
                }
                .font(.system(size: 12))
                .foregroundColor(.blue)
                
                Button(LocalizationManager.shared.localizedString("subscription.privacy")) {
                    // 打開隱私政策頁面
                }
                .font(.system(size: 12))
                .foregroundColor(.blue)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - 購買處理
    
    private func purchasePlan(_ plan: SubscriptionPlan) async {
        guard let product = storeKitManager.products.first(where: { $0.plan == plan }) else { return }
        
        let success = await storeKitManager.purchase(product)
        if success {
            purchaseSuccess = true
        }
    }
}

// MARK: - 訂閱方案卡片

struct SubscriptionPlanCard: View {
    let product: SubscriptionProduct
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // 標題和價格
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(product.plan.displayName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            
                            if product.isPopular {
                                Text(LocalizationManager.shared.localizedString("subscription.popular"))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.orange)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(product.plan.description)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(product.product.displayPrice)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: product.plan.color))
                        
                        if let discount = product.discount {
                            Text(discount)
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // 功能列表
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(product.plan.features, id: \.self) { feature in
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
                            .stroke(
                                isSelected ? (Color(hex: product.plan.color) ?? Color(.systemGray4)) : Color(.systemGray4),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 功能比較表

struct FeaturesComparisonTable: View {
    private let features = [
        (LocalizationManager.shared.localizedString("subscription.feature.ai_chat"), "ai_chat"),
        (LocalizationManager.shared.localizedString("subscription.feature.voice_input"), "voice_input"),
        (LocalizationManager.shared.localizedString("subscription.feature.image_analysis"), "image_analysis"),
        (LocalizationManager.shared.localizedString("subscription.feature.advanced_reports"), "advanced_reports"),
        (LocalizationManager.shared.localizedString("subscription.feature.custom_themes"), "custom_themes"),
        (LocalizationManager.shared.localizedString("subscription.feature.priority_support"), "priority_support")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題行
            HStack {
                Text(LocalizationManager.shared.localizedString("subscription.feature"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                    Text(plan.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            
            // 功能行
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                HStack {
                    Text(feature.0)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                        Image(systemName: planHasFeature(plan, feature.1) ? "checkmark" : "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(planHasFeature(plan, feature.1) ? .green : .red)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(index % 2 == 0 ? Color(.systemBackground) : Color(.systemGray6))
            }
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private func planHasFeature(_ plan: SubscriptionPlan, _ feature: String) -> Bool {
        let limits = plan.limits
        
        switch feature {
        case "ai_chat":
            return limits.aiChatMessages > 0
        case "voice_input":
            return limits.voiceMinutes > 0
        case "image_analysis":
            return limits.imageAnalysis > 0
        case "advanced_reports":
            return limits.advancedReports
        case "custom_themes":
            return limits.customThemes
        case "priority_support":
            return limits.prioritySupport
        default:
            return false
        }
    }
}

// MARK: - FAQ 項目

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(question)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(answer)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    SubscriptionStoreView()
}
