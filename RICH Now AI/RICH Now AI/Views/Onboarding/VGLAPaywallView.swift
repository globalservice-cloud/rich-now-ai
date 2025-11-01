//
//  VGLAPaywallView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import SwiftUI

struct VGLAPaywallView: View {
    let onPurchase: () -> Void
    let onSkip: () -> Void
    @State private var showPurchaseOptions = false
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [Color(hex: "#1E3A8A")!, Color(hex: "#312E81")!],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // 圖標
                VStack(spacing: 20) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: true)
                    
                    Text("VGLA 性格測驗")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                
                // 功能介紹
                VStack(spacing: 20) {
                    VGLAPaywallFeatureRow(
                        icon: "chart.bar.fill",
                        title: LocalizationManager.shared.localizedString("vgla.paywall.personalized_analysis"),
                        description: LocalizationManager.shared.localizedString("vgla.paywall.personalized_analysis_desc")
                    )
                    
                    VGLAPaywallFeatureRow(
                        icon: "target",
                        title: LocalizationManager.shared.localizedString("vgla.paywall.investment_advice"),
                        description: LocalizationManager.shared.localizedString("vgla.paywall.investment_advice_desc")
                    )
                    
                    VGLAPaywallFeatureRow(
                        icon: "message.fill",
                        title: LocalizationManager.shared.localizedString("vgla.paywall.ai_style"),
                        description: LocalizationManager.shared.localizedString("vgla.paywall.ai_style_desc")
                    )
                    
                    VGLAPaywallFeatureRow(
                        icon: "paintbrush.fill",
                        title: LocalizationManager.shared.localizedString("vgla.paywall.themes"),
                        description: LocalizationManager.shared.localizedString("vgla.paywall.themes_desc")
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 按鈕區域
                VStack(spacing: 16) {
                    Button(action: {
                        showPurchaseOptions = true
                    }) {
                        HStack {
                            Text(LocalizationManager.shared.localizedString("vgla.paywall.start_assessment"))
                                .font(.system(size: 18, weight: .semibold))
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(Color(hex: "#1E3A8A"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .cornerRadius(15)
                    }
                    
                    Button(action: onSkip) {
                        Text(LocalizationManager.shared.localizedString("vgla.paywall.skip_for_now"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showPurchaseOptions) {
            VGLAPurchaseView(
                onPurchase: onPurchase,
                onCancel: { showPurchaseOptions = false }
            )
        }
    }
}

struct VGLAPaywallFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "#F59E0B"))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
    }
}

struct VGLAPurchaseView: View {
    let onPurchase: () -> Void
    let onCancel: () -> Void
    @State private var selectedPlan = 0
    
    private let plans = [
        ("Basic", "$2.99", "month", "vgla.purchase.basic_desc"),
        ("Pro", "$9.99", "month", "vgla.purchase.pro_desc"),
        ("Enterprise", "$19.99", "month", "vgla.purchase.enterprise_desc")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 標題
                VStack(spacing: 12) {
                    Text(LocalizationManager.shared.localizedString("vgla.purchase.title"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(LocalizationManager.shared.localizedString("vgla.purchase.subtitle"))
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // 方案選擇
                VStack(spacing: 12) {
                    ForEach(0..<plans.count, id: \.self) { index in
                        PlanCard(
                            title: plans[index].0,
                            price: plans[index].1,
                            period: plans[index].2,
                            description: LocalizationManager.shared.localizedString(plans[index].3),
                            isSelected: selectedPlan == index
                        ) {
                            selectedPlan = index
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 購買按鈕
                VStack(spacing: 12) {
                    Button(action: onPurchase) {
                        Text(LocalizationManager.shared.localizedString("vgla.purchase.buy_now"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#1E3A8A"))
                            .cornerRadius(15)
                    }
                    
                    Button(action: onCancel) {
                        Text(LocalizationManager.shared.localizedString("vgla.purchase.cancel"))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationTitle(LocalizationManager.shared.localizedString("vgla.purchase.navigation_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("common.close")) {
                        onCancel()
                    }
                }
            }
        }
    }
}

struct PlanCard: View {
    let title: String
    let price: String
    let period: String
    let description: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        HStack(alignment: .bottom, spacing: 2) {
                            Text(price)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(hex: "#1E3A8A"))
                            
                            Text("/" + period)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color(hex: "#1E3A8A") : .secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "#1E3A8A")!.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color(hex: "#1E3A8A")! : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VGLAPaywallView(
        onPurchase: { print("Purchase tapped") },
        onSkip: { print("Skip tapped") }
    )
}
