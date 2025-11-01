//
//  OnboardingConversationView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct OnboardingConversationView: View {
    @ObservedObject var state: OnboardingState
    @State private var inputText: String = ""
    @State private var showInput: Bool = false
    
    var body: some View {
        ZStack {
            // 背景
            Color(hex: "#F3F4F6")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 頂部狀態欄
                OnboardingProgressBar(currentStep: state.currentStep)
                    .padding(.top, 8)
                
                // 對話區域
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(state.messages) { message in
                                OnboardingMessageBubble(
                                    message: message,
                                    onQuickReply: handleQuickReply
                                )
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: state.messages.count) {
                        if let lastMessage = state.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // 輸入區域
                if showInput {
                    OnboardingInputArea(
                        inputText: $inputText,
                        currentStep: state.currentStep,
                        onSend: handleSend
                    )
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .onAppear {
            startConversation()
        }
    }
    
    private func startConversation() {
        // 根據當前步驟開始對話
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showInput = true
            askCurrentQuestion()
        }
    }
    
    private func askCurrentQuestion() {
        switch state.currentStep {
        case .getName:
            state.addGabrielMessage(
                "讓我們從認識開始吧！我可以怎麼稱呼你呢？😊",
                quickReplies: ["小明", "家豪", "雅婷", "自訂"]
            )
            
        case .getGender:
            state.addGabrielMessage(
                "\(state.userName)，為了給你最適合的建議，我想了解你的性別，方便告訴我嗎？"
            )
            
        case .getEmail:
            state.addGabrielMessage(
                "太好了！\(state.userName)，我想定期為你準備專屬的財務報告和成長建議。\n\n可以留下你的 Email 嗎？我保證只用來傳送對你有價值的內容 💝"
            )
            
        case .setReportFrequency:
            state.addGabrielMessage(
                "完美！那我多久寄一次財務報告給你呢？"
            )
            
        case .setConversationStyle:
            state.addGabrielMessage(
                "還有一件事，\(state.userName)，你希望我用什麼方式跟你對話呢？選擇最讓你舒服的方式 😊",
                quickReplies: ConversationStyle.allCases.map { $0.displayName }
            )
            
        default:
            break
        }
    }
    
    private func handleSend() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        state.addUserMessage(inputText)
        processUserInput(inputText)
        inputText = ""
    }
    
    private func handleQuickReply(_ reply: String) {
        state.addUserMessage(reply)
        processUserInput(reply)
    }
    
    private func processUserInput(_ input: String) {
        switch state.currentStep {
        case .getName:
            state.userName = input
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                state.addGabrielMessage(state.getPersonalizedResponse(for: input))
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    state.nextStep()
                    askCurrentQuestion()
                }
            }
            
        case .getGender:
            // 將字串轉換為 UserGender 枚舉
            if let gender = UserGender(rawValue: input.lowercased()) {
                state.userGender = gender
            } else {
                // 如果無法轉換，嘗試從顯示名稱轉換
                switch input.lowercased() {
                case "男性", "male", "男":
                    state.userGender = .male
                case "女性", "female", "女":
                    state.userGender = .female
                case "不透露", "prefer not to say", "不願透露":
                    state.userGender = .preferNotToSay
                default:
                    state.userGender = .preferNotToSay // 預設值
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                state.addGabrielMessage("謝謝你 \(state.userName)！我會記住的 ✨")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    state.nextStep()
                    askCurrentQuestion()
                }
            }
            
        case .getEmail:
            if input == "稍後再說" {
                state.userEmail = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    state.addGabrielMessage("沒問題！之後也可以隨時在設定中補充 😊")
                    moveToNextStep()
                }
            } else if isValidEmail(input) {
                state.userEmail = input
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    state.addGabrielMessage("太好了！我會好好珍惜你的信任 💝")
                    moveToNextStep()
                }
            } else {
                state.addGabrielMessage("這個 Email 格式好像不太對，可以再確認一次嗎？或選擇「稍後再說」")
            }
            
        case .setReportFrequency:
            // 處理報告頻率選擇
            break
            
        case .setConversationStyle:
            // 處理對話風格選擇
            if let style = ConversationStyle.allCases.first(where: { $0.displayName == input }) {
                state.conversationStyle = style
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    state.addGabrielMessage("太好了！我會用\(style.displayName)的方式跟你對話 ✨")
                    moveToNextStep()
                }
            } else {
                // 如果沒有找到匹配的風格，提供預設選項
                state.conversationStyle = .friendly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    state.addGabrielMessage("好的！我會用親切的方式跟你對話 ✨")
                    moveToNextStep()
                }
            }
            
        default:
            break
        }
    }
    
    private func moveToNextStep() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            state.nextStep()
            askCurrentQuestion()
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - 對話訊息

struct OnboardingMessageBubble: View {
    let message: OnboardingMessage
    let onQuickReply: (String) -> Void
    
    var body: some View {
        switch message.speaker {
        case .user:
            userBubble
        case .gabriel:
            gabrielBubble
        case .system:
            systemBubble
        }
    }
    
    private var userBubble: some View {
        HStack {
            Spacer()
            
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
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 280, alignment: .trailing)
        }
    }
    
    private var gabrielBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 8) {
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
                
                if let quickReplies = message.quickReplies, !quickReplies.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                        ForEach(quickReplies, id: \.self) { reply in
                            Button(action: { onQuickReply(reply) }) {
                                Text(reply)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.blue.opacity(0.1))
                                    )
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: 300, alignment: .leading)
    }
    
    private var systemBubble: some View {
        HStack {
            Spacer()
            Text(message.content)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

struct OnboardingInputArea: View {
    @Binding var inputText: String
    let currentStep: OnboardingStep
    let onSend: () -> Void
    
    private var placeholder: String {
        switch currentStep {
        case .getName:
            return "請輸入您的名字"
        case .getEmail:
            return "輸入 Email"
        case .getGender:
            return "輸入您的性別或選擇按鈕"
        case .setReportFrequency:
            return "想多久收到報告？"
        case .setConversationStyle:
            return "選擇偏好的對話風格"
        default:
            return "輸入訊息..."
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack(spacing: 12) {
                TextField(placeholder, text: $inputText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        triggerSend()
                    }
                
                Button(action: triggerSend) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func triggerSend() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSend()
    }
}


// MARK: - Selection Buttons

struct GenderSelectionButtons: View {
    let onSelect: (String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            SelectionButton(title: "男性", icon: "👨", action: { onSelect("男性") })
            SelectionButton(title: "女性", icon: "👩", action: { onSelect("女性") })
            SelectionButton(title: "不便透露", icon: "🙂", action: { onSelect("不便透露") })
        }
        .padding()
    }
}

struct ReportFrequencyButtons: View {
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(ReportFrequency.allCases, id: \.self) { frequency in
                Button(action: { onSelect(frequency.displayName) }) {
                    HStack {
                        Text(frequency.icon)
                        VStack(alignment: .leading) {
                            Text(frequency.displayName)
                                .font(.system(size: 16, weight: .semibold))
                            Text(frequency.description)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(hex: "#EFF6FF"))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
    }
}

struct ConversationStyleButtons: View {
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(ConversationStyle.allCases, id: \.self) { style in
                Button(action: { onSelect(style.displayName) }) {
                    HStack {
                        Text(style.icon)
                            .font(.system(size: 24))
                        VStack(alignment: .leading) {
                            Text(style.displayName)
                                .font(.system(size: 16, weight: .semibold))
                            Text(style.description)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(hex: "#EFF6FF"))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
    }
}

struct SelectionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 32))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#1F2937"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(hex: "#EFF6FF"))
            .cornerRadius(12)
        }
    }
}

// MARK: - Progress Bar

struct OnboardingProgressBar: View {
    let currentStep: OnboardingStep
    
    var progress: CGFloat {
        CGFloat(currentStep.rawValue) / CGFloat(OnboardingStep.allCases.count - 1)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(currentStep.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#6B7280"))
                Spacer()
                Text("\(currentStep.rawValue + 1) / \(OnboardingStep.allCases.count)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }
            .padding(.horizontal)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "#E5E7EB")!)
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#3B82F6")!, Color(hex: "#8B5CF6")!],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.spring(), value: progress)
                }
                .cornerRadius(2)
            }
            .frame(height: 4)
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.white)
    }
}

#Preview {
    OnboardingConversationView(state: OnboardingState())
}
