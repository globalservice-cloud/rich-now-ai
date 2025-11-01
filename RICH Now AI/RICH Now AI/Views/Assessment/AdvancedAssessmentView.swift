//
//  AdvancedAssessmentView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import SwiftData
import Combine

struct AdvancedAssessmentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showTKIAssessment = false
    @State private var showTKIResult = false
    @State private var showVGLAAssessment = false
    @State private var tkiResult: TKIResult?
    @State private var vglaAssessments: [VGLAAssessment] = []
    
    let onComplete: (TKIResult?) -> Void
    
    private var hasCompletedVGLA: Bool {
        !vglaAssessments.isEmpty && vglaAssessments.contains { $0.isCompleted }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景漸層
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.23, blue: 0.54),
                        Color(red: 0.19, green: 0.18, blue: 0.51)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // 標題區域
                        VStack(spacing: 16) {
                            Text("🔬")
                                .font(.system(size: 60))
                            
                            VStack(spacing: 8) {
                                Text(LocalizationManager.shared.localizedString("advanced.title"))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text(LocalizationManager.shared.localizedString("advanced.subtitle"))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 40)
                        .padding(.horizontal, 20)
                        
                        // 測驗卡片
                        VStack(spacing: 20) {
                            // VGLA 測驗卡片
                            VGLAAssessmentCard(
                                isCompleted: hasCompletedVGLA,
                                onStart: {
                                    showVGLAAssessment = true
                                }
                            )
                            
                            // TKI 測驗卡片
                            TKIAssessmentCard(
                                isCompleted: tkiResult != nil,
                                onStart: {
                                    showTKIAssessment = true
                                }
                            )
                            
                            // 未來可擴展其他測驗
                            FutureAssessmentCard()
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(
                // 關閉按鈕
                VStack {
                    HStack {
                        Button(action: {
                            onComplete(tkiResult)
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44) // 增大觸控區域到44x44
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Circle()) // 確保整個圓形區域都可點擊
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                }
            )
        }
        .sheet(isPresented: $showTKIAssessment) {
            TKIAssessmentView { result in
                tkiResult = result
                showTKIAssessment = false
                showTKIResult = true
            }
        }
        .sheet(isPresented: $showTKIResult) {
            if let result = tkiResult {
                TKIResultView(result: result) {
                    showTKIResult = false
                    onComplete(result)
                }
            }
        }
        .sheet(isPresented: $showVGLAAssessment) {
            VGLAAssessmentView { result in
                showVGLAAssessment = false
                // 重新載入VGLA測驗狀態
                loadVGLAAssessments()
            }
        }
        .onAppear {
            loadVGLAAssessments()
        }
    }
    
    private func loadVGLAAssessments() {
        let descriptor = FetchDescriptor<VGLAAssessment>()
        if let assessments = try? modelContext.fetch(descriptor) {
            vglaAssessments = assessments
        }
    }
}

// VGLA 測驗卡片
struct VGLAAssessmentCard: View {
    let isCompleted: Bool
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 卡片標題
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("VGLA 測驗")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("財務決策思考模式測驗")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))
                }
            }
            
            // 卡片內容
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("測驗時間")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("約 15-20 分鐘")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("測驗題數")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("60 題")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                // VGLA 四個維度預覽
                VStack(alignment: .leading, spacing: 8) {
                    Text("測驗維度")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 8) {
                        Text("V - Vision")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        
                        Text("G - Goal")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        
                        Text("L - Logic")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        
                        Text("A - Action")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            
            // 按鈕 - 增大觸控區域
            Button(action: onStart) {
                HStack {
                    if isCompleted {
                        Image(systemName: "arrow.clockwise")
                        Text("重新測驗")
                    } else {
                        Image(systemName: "play.fill")
                        Text("開始測驗")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.12, green: 0.23, blue: 0.54))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44) // 最小觸控高度 44pt
                .padding(.vertical, 12)
                .background(.white)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle()) // 確保整個區域都可點擊
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 1.0, opacity: 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(white: 1.0, opacity: 0.3), lineWidth: 1)
                )
        )
    }
}

struct TKIAssessmentCard: View {
    let isCompleted: Bool
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 卡片標題
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationManager.shared.localizedString("advanced.tki_card"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(LocalizationManager.shared.localizedString("advanced.tki_description"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))
                }
            }
            
            // 卡片內容
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizationManager.shared.localizedString("advanced.tki_duration"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(LocalizationManager.shared.localizedString("advanced.tki_duration"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(LocalizationManager.shared.localizedString("advanced.tki_questions"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("30 題")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                // 五種模式預覽
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationManager.shared.localizedString("advanced.tki_modes"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 8) {
                        ForEach(TKIMode.allCases, id: \.self) { mode in
                            Text(LocalizationManager.shared.localizedString(mode.displayName))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // 按鈕 - 增大觸控區域
            Button(action: onStart) {
                HStack {
                    if isCompleted {
                        Image(systemName: "arrow.clockwise")
                        Text(LocalizationManager.shared.localizedString("advanced.tki_retake"))
                    } else {
                        Image(systemName: "play.fill")
                        Text(LocalizationManager.shared.localizedString("advanced.tki_start"))
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.12, green: 0.23, blue: 0.54))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44) // 最小觸控高度 44pt
                .padding(.vertical, 12)
                .background(.white)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle()) // 確保整個區域都可點擊
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 1.0, opacity: 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(white: 1.0, opacity: 0.3), lineWidth: 1)
                )
        )
    }
}

struct FutureAssessmentCard: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationManager.shared.localizedString("advanced.future_assessments"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(LocalizationManager.shared.localizedString("advanced.future_description"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "clock")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizationManager.shared.localizedString("advanced.coming_soon"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                HStack(spacing: 12) {
                    Text(LocalizationManager.shared.localizedString("advanced.mbti"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                    
                    Text(LocalizationManager.shared.localizedString("advanced.big5"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                    
                    Text(LocalizationManager.shared.localizedString("advanced.disc"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 1.0, opacity: 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(white: 1.0, opacity: 0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    AdvancedAssessmentView { result in
        if let result = result {
            print("Advanced assessment completed: \(result)")
        } else {
            print("Advanced assessment completed with no result")
        }
    }
    .modelContainer(for: [User.self, VGLAAssessment.self], inMemory: true)
}
