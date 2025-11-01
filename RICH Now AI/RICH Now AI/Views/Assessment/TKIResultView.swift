//
//  TKIResultView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import Charts


private func localizedModeName(_ mode: TKIMode) -> String {
    LocalizationManager.shared.localizedString(mode.displayName)
}

struct TKIResultView: View {
    let result: TKIResult
    let onContinue: () -> Void
    
    @State private var showChart = false
    @State private var showRecommendations = false
    
    var body: some View {
        ZStack {
            // 背景漸層
            LinearGradient(
                colors: [Color.safeHex("#1E3A8A", default: .blue), Color.safeHex("#312E81", default: .purple)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // 標題區域
                    VStack(spacing: 16) {
                        Text("🎯")
                            .font(.system(size: 60))
                            .scaleEffect(showChart ? 1.0 : 0.8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showChart)
                        
                        VStack(spacing: 8) {
                            Text("tki.result.title".localized)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("tki.result.subtitle".localized)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .opacity(showChart ? 1.0 : 0.0)
                        .offset(y: showChart ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.3), value: showChart)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 20)
                    
                    // 主要模式卡片
                    VStack(spacing: 20) {
                        PrimaryModeCard(
                            primaryMode: result.primaryMode,
                            secondaryMode: result.secondaryMode,
                            scores: result.scores
                        )
                        .opacity(showChart ? 1.0 : 0.0)
                        .offset(y: showChart ? 0 : 30)
                        .animation(.easeOut(duration: 0.6).delay(0.5), value: showChart)
                        
                        // 雷達圖
                        TKIRadarChart(scores: result.scores)
                            .frame(height: 300)
                            .opacity(showChart ? 1.0 : 0.0)
                            .scaleEffect(showChart ? 1.0 : 0.8)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.7), value: showChart)
                    }
                    .padding(.horizontal, 20)
                    
                    // 財務決策風格
                    FinancialDecisionStyleCard(
                        style: LocalizationManager.shared.localizedString(result.financialDecisionStyleKeyValue),
                        primaryMode: result.primaryMode
                    )
                    .opacity(showRecommendations ? 1.0 : 0.0)
                    .offset(y: showRecommendations ? 0 : 30)
                    .animation(.easeOut(duration: 0.6).delay(0.9), value: showRecommendations)
                    .padding(.horizontal, 20)
                    
                    // 建議區域
                    TKIRecommendationsCard(recommendations: result.recommendationKeys)
                        .opacity(showRecommendations ? 1.0 : 0.0)
                        .offset(y: showRecommendations ? 0 : 30)
                        .animation(.easeOut(duration: 0.6).delay(1.1), value: showRecommendations)
                        .padding(.horizontal, 20)
                    
                    // 繼續按鈕
                    Button(action: onContinue) {
                        HStack {
                            Text("common.continue".localized)
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "#1E3A8A") ?? Color.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                    .opacity(showRecommendations ? 1.0 : 0.0)
                    .offset(y: showRecommendations ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(1.3), value: showRecommendations)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation {
            showChart = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showRecommendations = true
            }
        }
    }
}

struct PrimaryModeCard: View {
    let primaryMode: TKIMode
    let secondaryMode: TKIMode
    let scores: [TKIMode: Int]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("tki.result.primary_mode".localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HStack {
                    Text(localizedModeName(primaryMode))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "#F59E0B") ?? Color.orange)
                    
                    Spacer()
                    
                    Text("\(scores[primaryMode] ?? 0)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                if secondaryMode != primaryMode {
                    HStack {
                        Text("tki.result.secondary_mode".localized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text(localizedModeName(secondaryMode))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("\(scores[secondaryMode] ?? 0)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct TKIRadarChart: View {
    let scores: [TKIMode: Int]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("tki.result.score_distribution".localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Chart {
                ForEach(TKIMode.allCases, id: \.self) { mode in
                    BarMark(
                        x: .value("Mode", localizedModeName(mode)),
                        y: .value("Score", scores[mode] ?? 0)
                    )
                    .foregroundStyle(Color(hex: "#F59E0B") ?? Color.orange)
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let stringValue = value.as(String.self) {
                            Text(stringValue)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.8))
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct FinancialDecisionStyleCard: View {
    let style: String
    let primaryMode: TKIMode
    
    var body: some View {
        VStack(spacing: 16) {
            Text("tki.result.financial_style".localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(style)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// TKI 建議卡片
struct TKIRecommendationsCard: View {
    let recommendations: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("tki.result.recommendations".localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            ForEach(Array(recommendations.enumerated()), id: \.offset) { index, key in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1).")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#F59E0B") ?? Color.orange)
                    
                    Text(key.localized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    let sampleScores: [TKIMode: Int] = [
        .competing: 8,
        .collaborating: 12,
        .compromising: 6,
        .avoiding: 2,
        .accommodating: 2
    ]
    
    let sampleResult = TKIResult(scores: sampleScores)
    
    TKIResultView(result: sampleResult) {
        print("Continue from TKI result")
    }
}
