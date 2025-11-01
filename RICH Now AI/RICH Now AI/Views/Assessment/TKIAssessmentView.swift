//
//  TKIAssessmentView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct TKIAssessmentView: View {
    @StateObject private var testManager = TKITestManager()
    @Environment(\.dismiss) private var dismiss
    
    let onComplete: (TKIResult) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景漸層
                LinearGradient(
                    colors: [Color(hex: "#1E3A8A") ?? Color.blue, Color(hex: "#312E81") ?? Color.purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 標題區域
                    VStack(spacing: 16) {
                        Text("🧠")
                            .font(.system(size: 60))
                        
                        VStack(spacing: 8) {
                            Text("tki.title".localized)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("tki.subtitle".localized)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 20)
                    
                    // 進度條
                    VStack(spacing: 12) {
                        HStack {
                            Text("tki.question_progress".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            Text("\(Int(testManager.progress * 100))%")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        ProgressView(value: testManager.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "#F59E0B") ?? Color.orange))
                            .scaleEffect(y: 2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    
                    // 問題區域
                    if let question = testManager.currentQuestion {
                        VStack(spacing: 24) {
                            // 問題卡片
                            VStack(spacing: 20) {
                                Text("tki.question_\(question.questionNumber)_title".localized)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                
                                // 選項 A - 增大觸控區域
                                Button(action: {
                                    testManager.selectAnswer(question.modeA)
                                }) {
                                    OptionCard(
                                        title: "tki.option_a".localized,
                                        content: question.localizedOptionA,
                                        isSelected: testManager.getAnswer(for: question.id) == question.modeA
                                    )
                                    .frame(minHeight: 60) // 最小觸控高度
                                    .contentShape(Rectangle()) // 確保整個區域都可點擊
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // 選項 B - 增大觸控區域
                                Button(action: {
                                    testManager.selectAnswer(question.modeB)
                                }) {
                                    OptionCard(
                                        title: "tki.option_b".localized,
                                        content: question.localizedOptionB,
                                        isSelected: testManager.getAnswer(for: question.id) == question.modeB
                                    )
                                    .frame(minHeight: 60) // 最小觸控高度
                                    .contentShape(Rectangle()) // 確保整個區域都可點擊
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 40)
                            
                            Spacer()
                            
                            // 導航按鈕
                            HStack(spacing: 16) {
                                if testManager.canGoPrevious {
                                    Button(action: {
                                        testManager.previousQuestion()
                                    }) {
                                        HStack {
                                            Image(systemName: "chevron.left")
                                            Text("tki.previous".localized)
                                        }
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .frame(minHeight: 44) // 最小觸控高度 44pt
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(25)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contentShape(Rectangle())
                                }
                                
                                Spacer()
                                
                                if testManager.canGoNext {
                                    Button(action: {
                                        testManager.nextQuestion()
                                    }) {
                                        HStack {
                                            Text("tki.next".localized)
                                            Image(systemName: "chevron.right")
                                        }
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(hex: "#1E3A8A") ?? Color.blue)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .frame(minHeight: 44) // 最小觸控高度 44pt
                                        .background(.white)
                                        .cornerRadius(25)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contentShape(Rectangle())
                                } else {
                                    Button(action: {
                                        testManager.completeAssessment()
                                        if let result = testManager.result {
                                            onComplete(result)
                                        }
                                    }) {
                                        HStack {
                                            Text("tki.complete".localized)
                                            Image(systemName: "checkmark")
                                        }
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(hex: "#1E3A8A") ?? Color.blue)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(.white)
                                        .cornerRadius(25)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(
                // 關閉按鈕
                VStack {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                }
            )
        }
        .onChange(of: testManager.isCompleted) {
            if testManager.isCompleted, let result = testManager.result {
                onComplete(result)
            }
        }
    }
}

struct OptionCard: View {
    let title: String
    let content: String
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? Color(hex: "#1E3A8A") ?? Color.blue : .white.opacity(0.8))
            
            Text(content)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? Color(hex: "#1E3A8A") ?? Color.blue : .white)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(isSelected ? .white : Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isSelected ? .clear : Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    TKIAssessmentView { result in
        print("TKI Assessment completed: \(result)")
    }
}
