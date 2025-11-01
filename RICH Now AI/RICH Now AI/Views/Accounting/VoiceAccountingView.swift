//
//  VoiceAccountingView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import AVFoundation

struct VoiceAccountingView: View {
    @StateObject private var recordingManager = VoiceRecordingManager.shared
    @StateObject private var voiceToTextService = VoiceToTextService.shared
    @StateObject private var transactionParser = TransactionParser()
    
    @State private var showingPermissionAlert = false
    @State private var showingTranscriptionResult = false
    @State private var showingTransactionPreview = false
    @State private var parsedTransaction: ParsedTransaction?
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 標題
                VStack(spacing: 8) {
                    Text(LocalizationManager.shared.localizedString("voice_accounting.title"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(LocalizationManager.shared.localizedString("voice_accounting.subtitle"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // 錄音界面
                VoiceRecordingInterface(
                    isRecording: recordingManager.isRecording,
                    duration: recordingManager.recordingDuration,
                    audioLevel: recordingManager.audioLevel,
                    isProcessing: isProcessing,
                    onStartRecording: startRecording,
                    onStopRecording: stopRecording,
                    onCancelRecording: cancelRecording
                )
                
                Spacer()
                
                // 轉錄結果
                if !voiceToTextService.transcriptionText.isEmpty {
                    TranscriptionResultView(
                        text: voiceToTextService.transcriptionText,
                        confidence: voiceToTextService.confidence,
                        onEdit: editTranscription,
                        onProcess: processTranscription
                    )
                }
                
                // 處理狀態
                if isProcessing {
                    ProcessingStatusView()
                }
                
                // 錯誤訊息
                if let error = recordingManager.recordingError ?? voiceToTextService.processingError {
                    ErrorMessageView(message: error)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationTitle(LocalizationManager.shared.localizedString("voice_accounting.nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .alert(LocalizationManager.shared.localizedString("voice_accounting.permission_alert.title"), isPresented: $showingPermissionAlert) {
                Button(LocalizationManager.shared.localizedString("common.settings")) {
                    openAppSettings()
                }
                Button(LocalizationManager.shared.localizedString("common.cancel"), role: .cancel) { }
            } message: {
                Text(LocalizationManager.shared.localizedString("voice_accounting.permission_alert.message"))
            }
            .sheet(isPresented: $showingTransactionPreview) {
                if let transaction = parsedTransaction {
                    TransactionPreviewView(transaction: transaction) { confirmedTransaction in
                        saveTransaction(confirmedTransaction)
                    }
                }
            }
        }
        .onAppear {
            checkPermissions()
        }
    }
    
    // MARK: - 錄音控制
    
    private func startRecording() {
        Task {
            do {
                try await recordingManager.startRecording()
            } catch VoiceRecordingError.permissionDenied {
                showingPermissionAlert = true
            } catch {
                // 其他錯誤已在 recordingManager 中處理
            }
        }
    }
    
    private func stopRecording() {
        guard let audioURL = recordingManager.stopRecording() else { return }
        
        isProcessing = true
        
        Task {
            do {
                let transcriptionText = try await voiceToTextService.transcribeAudio(from: audioURL)
                await MainActor.run {
                    voiceToTextService.transcriptionText = transcriptionText
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    voiceToTextService.processingError = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
    
    private func cancelRecording() {
        recordingManager.cancelRecording()
    }
    
    // MARK: - 文字處理
    
    private func editTranscription() {
        // 顯示文字編輯界面
        showingTranscriptionResult = true
    }
    
    private func processTranscription() {
        guard !voiceToTextService.transcriptionText.isEmpty else { return }
        
        isProcessing = true
        
        Task {
            do {
                let parsedTransaction = try await transactionParser.parseTransaction(
                    from: voiceToTextService.transcriptionText
                )
                
                await MainActor.run {
                    self.parsedTransaction = parsedTransaction
                    self.isProcessing = false
                    self.showingTransactionPreview = true
                }
            } catch {
                await MainActor.run {
                    voiceToTextService.processingError = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
    
    // MARK: - 交易保存
    
    private func saveTransaction(_ transaction: ParsedTransaction) {
        // 這裡應該保存到 SwiftData
        // 暫時只顯示成功訊息
        print("Transaction saved: \(transaction)")
    }
    
    // MARK: - 權限檢查
    
    private func checkPermissions() {
        if !recordingManager.hasPermission {
            showingPermissionAlert = true
        }
    }
    
    private func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - 錄音界面

struct VoiceRecordingInterface: View {
    let isRecording: Bool
    let duration: TimeInterval
    let audioLevel: Float
    let isProcessing: Bool
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onCancelRecording: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // 錄音按鈕
            ZStack {
                // 背景圓環
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 200, height: 200)
                
                // 音頻等級指示器
                if isRecording {
                    Circle()
                        .stroke(Color.blue, lineWidth: 8)
                        .frame(width: 200, height: 200)
                        .scaleEffect(1.0 + CGFloat(audioLevel) * 0.5)
                        .opacity(0.6)
                        .animation(.easeInOut(duration: 0.1), value: audioLevel)
                }
                
                // 錄音按鈕
                Button(action: isRecording ? onStopRecording : onStartRecording) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.blue)
                            .frame(width: 120, height: 120)
                            .scaleEffect(isRecording ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isRecording)
                        
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                }
                .disabled(isProcessing)
            }
            
            // 錄音狀態
            VStack(spacing: 8) {
                if isRecording {
                    Text(LocalizationManager.shared.localizedString("voice_accounting.recording"))
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(VoiceRecordingManager.shared.formatDuration(duration))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    // 取消按鈕
                    Button(action: onCancelRecording) {
                        Text(LocalizationManager.shared.localizedString("voice_accounting.cancel"))
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding(.top, 8)
                } else if isProcessing {
                    Text(LocalizationManager.shared.localizedString("voice_accounting.processing"))
                        .font(.headline)
                        .foregroundColor(.blue)
                } else {
                    Text(LocalizationManager.shared.localizedString("voice_accounting.tap_to_record"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - 轉錄結果視圖

struct TranscriptionResultView: View {
    let text: String
    let confidence: Float
    let onEdit: () -> Void
    let onProcess: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 信心度指示器
            HStack {
                Text(LocalizationManager.shared.localizedString("voice_accounting.confidence"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(confidence * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(confidence > 0.8 ? .green : confidence > 0.6 ? .orange : .red)
            }
            
            // 轉錄文字
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizationManager.shared.localizedString("voice_accounting.transcription"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            }
            
            // 操作按鈕
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    HStack {
                        Image(systemName: "pencil")
                        Text(LocalizationManager.shared.localizedString("voice_accounting.edit"))
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                
                Button(action: onProcess) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text(LocalizationManager.shared.localizedString("voice_accounting.process"))
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 處理狀態視圖

struct ProcessingStatusView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.blue, lineWidth: 4)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            }
            
            Text(LocalizationManager.shared.localizedString("voice_accounting.processing"))
                .font(.subheadline)
                .foregroundColor(.blue)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - 錯誤訊息視圖

struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
        )
    }
}

// MARK: - 交易預覽視圖

struct TransactionPreviewView: View {
    let transaction: ParsedTransaction
    let onSave: (ParsedTransaction) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(LocalizationManager.shared.localizedString("voice_accounting.transaction_preview"))
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 12) {
                    TransactionDetailRow(
                        title: LocalizationManager.shared.localizedString("transaction.amount"),
                        value: "$\(transaction.amount, default: "%.2f")"
                    )
                    
                    TransactionDetailRow(
                        title: LocalizationManager.shared.localizedString("transaction.category"),
                        value: transaction.category
                    )
                    
                    TransactionDetailRow(
                        title: LocalizationManager.shared.localizedString("transaction.description"),
                        value: transaction.description
                    )
                    
                    TransactionDetailRow(
                        title: LocalizationManager.shared.localizedString("transaction.date"),
                        value: DateFormatter.shortDate.string(from: transaction.date)
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                Spacer()
                
                Button(action: { onSave(transaction); dismiss() }) {
                    Text(LocalizationManager.shared.localizedString("voice_accounting.save_transaction"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                }
            }
            .padding()
            .navigationTitle(LocalizationManager.shared.localizedString("voice_accounting.preview"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .overlay(alignment: .topTrailing) {
                Button(LocalizationManager.shared.localizedString("common.cancel")) {
                    dismiss()
                }
                .padding()
            }
        }
    }
}

// MARK: - 交易詳情行

struct TransactionDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - 預覽

#Preview {
    VoiceAccountingView()
}
