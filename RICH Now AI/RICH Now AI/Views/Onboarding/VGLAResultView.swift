//
//  VGLAResultView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import SwiftUI

struct VGLAResultView: View {
    let result: VGLAResult
    let userName: String
    var onContinue: () -> Void
    
    @State private var currentSection = 0
    @State private var showGabriel = false
    @State private var showContent = false
    @State private var showOpenAIExplanation = false
    
    private let sections = ["結果", "優點", "挑戰", "他人眼中的你", "財務顧問"]
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [Color.safeHex("#1E3A8A", default: .blue), Color.safeHex("#312E81", default: .purple)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 頂部標題
                VStack(spacing: 16) {
                    Text("🎉")
                        .font(.system(size: 60))
                        .scaleEffect(showGabriel ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showGabriel)
                    
                    Text("VGLA 測驗結果")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.3), value: showContent)
                    
                    Text("\(userName)，讓我為你詳細解析")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.5), value: showContent)
                }
                .padding(.top, 40)
                .padding(.horizontal, 20)
                
                // 內容區域
                ScrollView {
                    LazyVStack(spacing: 20) {
                            // 主要和次要類型結果
                            VStack(spacing: 16) {
                                VGLAResultCard(
                                    title: "你的主要思考特性",
                                    subtitle: "\(result.primaryType) - \(getTypeDescription(result.primaryType))",
                                    icon: getTypeIcon(result.primaryType),
                                    color: getTypeColor(result.primaryType),
                                    content: result.strengths
                                )
                                
                                VGLAResultCard(
                                    title: "你的次要思考特性",
                                    subtitle: "\(result.secondaryType) - \(getTypeDescription(result.secondaryType))",
                                    icon: getTypeIcon(result.secondaryType),
                                    color: getTypeColor(result.secondaryType),
                                    content: getSecondaryTypeStrengths(result.secondaryType)
                                )
                                
                                // 組合型態說明
                                VGLAResultCard(
                                    title: "你的組合型態",
                                    subtitle: "\(result.combinationType) - \(getCombinationDescription(result.combinationType))",
                                    icon: "🔗",
                                    color: Color.safeHex("#8B5CF6", default: .purple),
                                    content: getCombinationStrengths(result.combinationType)
                                )
                            }
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(x: showContent ? 0 : -50)
                        .animation(.easeOut(duration: 0.8).delay(0.7), value: showContent)
                        
                        // 正向環境
                        VGLAEnvironmentCard(
                            title: "😊 正向環境",
                            subtitle: "(當您輕鬆開心時您的思考順序是)",
                            strengths: result.strengths,
                            weaknesses: result.weaknesses,
                            color: Color.safeHex("#10B981", default: .green)
                        )
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(x: showContent ? 0 : 50)
                        .animation(.easeOut(duration: 0.8).delay(0.9), value: showContent)
                        
                        // 緊張有壓力時
                        VGLAEnvironmentCard(
                            title: "😰 緊張有壓力時",
                            subtitle: "(當您緊張有壓力時您的思考順序)",
                            strengths: [
                                "在壓力下，你可能會特別注意 \(result.order.last ?? "A") 方面的挑戰",
                                "建議你轉換心情，專注發揮 \(result.primaryType) 的優點"
                            ],
                            weaknesses: result.challenges,
                            color: Color.safeHex("#F59E0B", default: .orange)
                        )
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(x: showContent ? 0 : -50)
                        .animation(.easeOut(duration: 0.8).delay(1.1), value: showContent)
                        
                        // 在別人眼中的您
                        VGLAEnvironmentCard(
                            title: "👥 在別人眼中的您",
                            subtitle: "",
                            strengths: result.positiveTraits,
                            weaknesses: result.howOthersSeeYou,
                            color: Color(hex: "#8B5CF6")!
                        )
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(x: showContent ? 0 : 50)
                        .animation(.easeOut(duration: 0.8).delay(1.3), value: showContent)
                        
                            // 財務顧問邀請
                            VGLAFinancialAdvisorCard(
                                result: result,
                                userName: userName,
                                onStartChat: {
                                    onContinue()
                                }
                            )
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 50)
                        .animation(.easeOut(duration: 0.8).delay(1.5), value: showContent)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
        .sheet(isPresented: $showOpenAIExplanation) {
            OpenAILoginExplanationView {
                showOpenAIExplanation = false
                onContinue()
            }
        }
    }
    
    private func startAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showGabriel = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showContent = true
            }
        }
    }
    
    private func getTypeDescription(_ type: String) -> String {
        switch type {
        case "V": return "願景型"
        case "G": return "感性型"
        case "L": return "邏輯型"
        case "A": return "行動型"
        default: return "未知類型"
        }
    }
    
    private func getTypeIcon(_ type: String) -> String {
        switch type {
        case "V": return "🌟"
        case "G": return "💝"
        case "L": return "🧠"
        case "A": return "⚡"
        default: return "🌟"
        }
    }
    
        private func getTypeColor(_ type: String) -> Color {
            switch type {
            case "V": return Color.safeHex("#F59E0B", default: .orange)
            case "G": return Color.safeHex("#EC4899", default: .pink)
            case "L": return Color.safeHex("#3B82F6", default: .blue)
            case "A": return Color.safeHex("#10B981", default: .green)
            default: return Color.safeHex("#F59E0B", default: .orange)
            }
        }
        
        private func getSecondaryTypeStrengths(_ type: String) -> [String] {
            switch type {
            case "V": return ["善於構想未來願景", "具有創新思維", "能夠激勵他人", "喜歡探索可能性"]
            case "G": return ["重視人際關係", "善於傾聽", "具有同理心", "注重團隊和諧"]
            case "L": return ["邏輯思維清晰", "善於分析問題", "注重細節", "喜歡系統化思考"]
            case "A": return ["行動力強", "善於執行", "喜歡挑戰", "能夠快速決策"]
            default: return []
            }
        }
        
        private func getCombinationDescription(_ combination: String) -> String {
            switch combination {
            case "VG": return "願景型 + 感性型"
            case "VL": return "願景型 + 邏輯型"
            case "VA": return "願景型 + 行動型"
            case "GL": return "感性型 + 邏輯型"
            case "GA": return "感性型 + 行動型"
            case "LA": return "邏輯型 + 行動型"
            default: return "綜合型"
            }
        }
        
        private func getCombinationStrengths(_ combination: String) -> [String] {
            switch combination {
            case "VG": return ["既有遠見又重視人際關係", "能夠激勵團隊達成共同目標", "善於平衡理想與現實"]
            case "VL": return ["既有願景又有邏輯分析能力", "能夠制定詳細的實施計劃", "善於將想法轉化為可行方案"]
            case "VA": return ["既有願景又有執行力", "能夠快速將想法付諸行動", "善於在變化中保持方向"]
            case "GL": return ["既重視人際關係又有邏輯思維", "能夠理性分析情感問題", "善於在團隊中發揮協調作用"]
            case "GA": return ["既重視人際關係又有行動力", "能夠快速建立信任關係", "善於在團隊中推動執行"]
            case "LA": return ["既有邏輯思維又有行動力", "能夠快速分析並執行", "善於在壓力下保持效率"]
            default: return ["綜合多種思考模式", "具有靈活的適應能力", "能夠在不同情境下發揮優勢"]
            }
        }
}

// MARK: - 結果卡片

struct VGLAResultCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let content: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(icon)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(content, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(color)
                            .font(.system(size: 16, weight: .bold))
                        
                        Text(item)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color, lineWidth: 1)
                )
        )
    }
}

struct VGLAEnvironmentCard: View {
    let title: String
    let subtitle: String
    let strengths: [String]
    let weaknesses: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // 您的優勢
            VStack(alignment: .leading, spacing: 8) {
                Text("您的優勢：")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.safeHex("#10B981", default: .green))
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(strengths, id: \.self) { strength in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(Color.safeHex("#10B981", default: .green))
                                .font(.system(size: 14, weight: .bold))
                            
                            Text(strength)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            
            // 您要特別注意的時候
            VStack(alignment: .leading, spacing: 8) {
                Text("您要特別注意的時候：")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.safeHex("#F59E0B", default: .orange))
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(weaknesses, id: \.self) { weakness in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(Color.safeHex("#F59E0B", default: .orange))
                                .font(.system(size: 14, weight: .bold))
                            
                            Text(weakness)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color, lineWidth: 1)
                )
        )
    }
}

struct VGLAFinancialAdvisorCard: View {
    let result: VGLAResult
    let userName: String
    let onStartChat: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🤖")
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("選擇 AI 功能方案")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("基於你的個性特質")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("\(userName)，現在讓我們開始財務目標的深度對話。")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("我會根據你的 \(result.primaryType) 特質，用最適合的方式與你交流。")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("請選擇你想要的 AI 功能使用方式，讓我們開始你的財務富足之旅。")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Button(action: onStartChat) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("選擇 AI 功能方案")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color.safeHex("#1E3A8A", default: .blue))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.white)
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.safeHex("#8B5CF6", default: .purple).opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.safeHex("#8B5CF6", default: .purple), lineWidth: 1)
                )
        )
    }
}

#Preview {
    VGLAResultView(
        result: VGLAResult(responses: []),
        userName: "小明"
    ) {
        // 繼續動作
    }
}