//
//  ContinueOnboardingView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import SwiftUI

/// 繼續迎賓流程的提示視圖
struct ContinueOnboardingView: View {
    @StateObject private var progressManager = OnboardingProgressManager.shared
    @StateObject private var userStateManager = UserStateManager.shared
    @Binding var isPresented: Bool
    var onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 圖標
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            // 標題
            Text("有未完成的迎賓流程")
                .font(.title2)
                .fontWeight(.bold)
            
            // 描述
            VStack(spacing: 12) {
                if let progress = progressManager.savedOnboardingState {
                    let completeness = progressManager.checkProfileCompleteness()
                    
                    Text("您上次的進度已保存，可以繼續完成迎賓流程。")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // 進度資訊
                    VStack(spacing: 8) {
                        HStack {
                            Text("完成度：")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(completeness.completionPercentage))%")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        
                        if progress.vglaIsComplete {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("VGLA 測驗已完成")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        } else if !progress.vglaAnswers.isEmpty {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.orange)
                                Text("VGLA 測驗進度：第 \(progress.vglaCurrentQuestion)/60 題")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
            }
            
            // 按鈕
            VStack(spacing: 12) {
                Button(action: {
                    onContinue()
                    isPresented = false
                }) {
                    Text("繼續迎賓流程")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.safeHex("#1E3A8A", default: .blue), Color.safeHex("#312E81", default: .purple)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                
                Button(action: {
                    // 清除進度，繼續使用應用程式
                    progressManager.clearProgress()
                    isPresented = false
                }) {
                    Text("稍後再說")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

#Preview {
    ContinueOnboardingView(isPresented: .constant(true)) {
        print("繼續迎賓流程")
    }
    .padding()
    .background(Color.gray.opacity(0.3))
}

