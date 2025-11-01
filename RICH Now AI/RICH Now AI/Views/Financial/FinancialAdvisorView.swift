//
//  FinancialAdvisorView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import SwiftUI
import Combine
import AVFoundation

struct FinancialAdvisorView: View {
    let vglaResult: VGLAResult
    let userName: String
    
    @StateObject private var conversationManager = FinancialConversationManager()
    @State private var isRecording = false
    @State private var showMicrophonePermission = false
    @State private var currentPhase: ConversationPhase = .introduction
    
    enum ConversationPhase {
        case introduction
        case listening
        case analyzing
        case questioning
        case summarizing
    }
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [Color(hex: "#1E3A8A")!, Color(hex: "#312E81")!],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 頂部標題
                VStack(spacing: 12) {
                    Text("💬")
                        .font(.system(size: 40))
                    
                    Text("財務富足之旅")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("基於你的 \(vglaResult.primaryType) 特質")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                // 對話區域
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(conversationManager.messages) { message in
                                FinancialMessageBubble(
                                    message: message,
                                    vglaResult: vglaResult
                                )
                                .id(message.id)
                            }
                            
                            if isRecording {
                                RecordingIndicator()
                                    .id("recording")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: conversationManager.messages.count) {
                        if let lastMessage = conversationManager.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // 底部控制區域
                VStack(spacing: 16) {
                    // 當前階段指示器
                    PhaseIndicator(currentPhase: currentPhase)
                    
                    // 麥克風按鈕
                    MicrophoneButton(
                        isRecording: isRecording,
                        onStartRecording: startRecording,
                        onStopRecording: stopRecording
                    )
                    .disabled(!conversationManager.canRecord)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            startConversation()
        }
        .alert("需要麥克風權限", isPresented: $showMicrophonePermission) {
            Button("設定") {
                openAppSettings()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("請允許使用麥克風來進行語音對話")
        }
    }
    
    private func startConversation() {
        let personalizedGreeting = getPersonalizedGreeting()
        conversationManager.addGabrielMessage(personalizedGreeting)
    }
    
    private func getPersonalizedGreeting() -> String {
        switch vglaResult.primaryType {
        case "V":
            return "\(userName)，我看到你是一個願景型的人。讓我們一起探索你的財務夢想和長期目標。請告訴我，你希望透過理財實現什麼樣的願景？"
        case "G":
            return "\(userName)，我感受到你重視人際關係和情感連結。在財務規劃上，我們可以考慮如何讓理財也能照顧到家人和重要的人。請分享你的想法。"
        case "L":
            return "\(userName)，你是一個邏輯思考者。讓我們用系統化的方式來分析你的財務狀況和目標。請告訴我你目前的財務情況和具體目標。"
        case "A":
            return "\(userName)，你是行動派！讓我們直接開始制定具體的財務行動計劃。請告訴我你希望立即開始的財務目標是什麼？"
        default:
            return "\(userName)，讓我們根據你的特質來制定最適合的財務規劃策略。請告訴我你的財務目標和想法。"
        }
    }
    
    private func startRecording() {
        conversationManager.requestMicrophonePermission { granted in
            if granted {
                isRecording = true
                currentPhase = .listening
                conversationManager.startRecording()
            } else {
                showMicrophonePermission = true
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        currentPhase = .analyzing
        conversationManager.stopRecording { transcription in
            if let transcription = transcription {
                processUserInput(transcription)
            }
        }
    }
    
    private func processUserInput(_ input: String) {
        conversationManager.addUserMessage(input)
        
        // 根據 VGLA 結果調整回應方式
        let response = generatePersonalizedResponse(input)
        conversationManager.addGabrielMessage(response)
        
        currentPhase = .questioning
    }
    
    private func generatePersonalizedResponse(_ input: String) -> String {
        // 這裡會根據 VGLA 結果和用戶輸入生成個性化回應
        // 實際實現時會調用 AI 服務
        return "我聽到了你的想法。讓我進一步了解..."
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - 對話管理器

class FinancialConversationManager: ObservableObject {
    @Published var messages: [FinancialMessage] = []
    @Published var canRecord: Bool = false
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession = AVAudioSession.sharedInstance()
    
    func addGabrielMessage(_ content: String) {
        let message = FinancialMessage(
            id: UUID(),
            content: content,
            isFromUser: false,
            timestamp: Date()
        )
        messages.append(message)
    }
    
    func addUserMessage(_ content: String) {
        let message = FinancialMessage(
            id: UUID(),
            content: content,
            isFromUser: true,
            timestamp: Date()
        )
        messages.append(message)
    }
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.canRecord = granted
                    completion(granted)
                }
            }
        } else {
            recordingSession.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.canRecord = granted
                    completion(granted)
                }
            }
        }
    }
    
    func startRecording() {
        // 實現錄音邏輯
    }
    
    func stopRecording(completion: @escaping (String?) -> Void) {
        // 實現停止錄音和語音轉文字邏輯
        completion("這是語音轉換的文字")
    }
}

// MARK: - 訊息模型

struct FinancialMessage: Identifiable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

// MARK: - 視圖組件

struct FinancialMessageBubble: View {
    let message: FinancialMessage
    let vglaResult: VGLAResult
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                userBubble
            } else {
                gabrielBubble
                Spacer()
            }
        }
    }
    
    private var userBubble: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(message.content)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.blue)
                )
            
            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: 280, alignment: .trailing)
    }
    
    private var gabrielBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            // 加百列頭像
            GabrielAvatarView(
                gender: .male, // 可以根據設定調整
                size: 32,
                showFullBody: false
            )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(message.content)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.systemGray6))
                    )
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: 300, alignment: .leading)
    }
}

struct RecordingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
                
                Text("正在聆聽...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red, lineWidth: 1)
                    )
            )
            
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct PhaseIndicator: View {
    let currentPhase: FinancialAdvisorView.ConversationPhase
    
    private var phaseText: String {
        switch currentPhase {
        case .introduction:
            return "準備開始對話"
        case .listening:
            return "正在聆聽你的想法"
        case .analyzing:
            return "分析你的需求"
        case .questioning:
            return "深入提問中"
        case .summarizing:
            return "整理重點"
        }
    }
    
    var body: some View {
        Text(phaseText)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
    }
}

struct MicrophoneButton: View {
    let isRecording: Bool
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    
    var body: some View {
        Button(action: isRecording ? onStopRecording : onStartRecording) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.white)
                    .frame(width: 80, height: 80)
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isRecording)
                
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32))
                    .foregroundColor(isRecording ? .white : Color(hex: "#1E3A8A"))
            }
        }
        .disabled(!isRecording && !canRecord)
    }
    
    private var canRecord: Bool {
        // 這裡會檢查錄音權限
        return true
    }
}

#Preview {
    FinancialAdvisorView(
        vglaResult: VGLAResult(responses: []),
        userName: "小明"
    )
}
