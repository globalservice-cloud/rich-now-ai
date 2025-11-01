//
//  LoadingStateManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import Foundation
import SwiftUI
import Combine
import os.log

/// 載入狀態管理器 - 統一管理應用程式的載入狀態和用戶反饋
@MainActor
class LoadingStateManager: ObservableObject {
    static let shared = LoadingStateManager()
    
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String = ""
    @Published var loadingProgress: Double = 0.0
    @Published var currentLoadingTask: LoadingTask?
    @Published var queuedTasks: [LoadingTask] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.richnowai", category: "LoadingStateManager")
    
    private init() {}
    
    // MARK: - 載入任務管理
    
    func startLoading(task: LoadingTask) {
        if isLoading {
            // 如果已有載入任務，將新任務加入佇列
            queuedTasks.append(task)
            logger.debug("載入任務已加入佇列: \(task.id)")
        } else {
            // 立即開始載入
            executeLoadingTask(task)
        }
    }
    
    func stopLoading(taskId: UUID? = nil) {
        if let taskId = taskId {
            // 停止特定任務
            if currentLoadingTask?.id == taskId {
                finishCurrentTask()
            } else {
                queuedTasks.removeAll { $0.id == taskId }
            }
        } else {
            // 停止當前任務
            finishCurrentTask()
        }
    }
    
    func updateProgress(_ progress: Double, message: String? = nil) {
        guard isLoading else { return }
        loadingProgress = min(1.0, max(0.0, progress))
        if let message = message {
            loadingMessage = message
        }
    }
    
    private func executeLoadingTask(_ task: LoadingTask) {
        // 創建可變的任務副本
        var mutableTask = task
        mutableTask.onProgress = { [weak self] progress, message in
            Task { @MainActor in
                self?.updateProgress(progress, message: message)
            }
        }
        
        currentLoadingTask = mutableTask
        isLoading = true
        loadingMessage = task.message
        loadingProgress = 0.0
        
        logger.info("開始載入任務: \(task.id), 訊息: \(task.message)")
        
        Task { @MainActor in
            do {
                try await mutableTask.execution()
                
                finishCurrentTask()
                processNextTask()
            } catch {
                handleTaskError(error, task: mutableTask)
            }
        }
    }
    
    private func finishCurrentTask() {
        isLoading = false
        loadingProgress = 0.0
        currentLoadingTask = nil
        loadingMessage = ""
    }
    
    private func processNextTask() {
        guard !queuedTasks.isEmpty else { return }
        let nextTask = queuedTasks.removeFirst()
        executeLoadingTask(nextTask)
    }
    
    private func handleTaskError(_ error: Error, task: LoadingTask) {
        logger.error("載入任務失敗: \(task.id), 錯誤: \(error.localizedDescription)")
        finishCurrentTask()
        
        // 執行錯誤處理
        task.onError?(error)
        
        // 繼續處理下一個任務
        processNextTask()
    }
    
    // MARK: - 便捷方法
    
    func showLoading(message: String = "載入中...") {
        let task = LoadingTask(
            id: UUID(),
            message: message,
            execution: { try? await Task.sleep(nanoseconds: 100_000_000) }
        )
        startLoading(task: task)
    }
    
    func hideLoading() {
        stopLoading()
    }
}

// MARK: - 載入任務

struct LoadingTask {
    let id: UUID
    let message: String
    let execution: () async throws -> Void
    var onProgress: ((Double, String?) -> Void)?
    var onError: ((Error) -> Void)?
}

// MARK: - 載入視圖修飾器

extension View {
    func loadingOverlay(isLoading: Bool, message: String = "載入中...", progress: Double? = nil) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    LoadingOverlayView(message: message, progress: progress)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: isLoading)
                }
            }
        )
    }
}

struct LoadingOverlayView: View {
    let message: String
    let progress: Double?
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // 載入卡片
            VStack(spacing: 20) {
                // 載入指示器
                if let progress = progress {
                    ProgressView(value: progress)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .frame(width: 60, height: 60)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .frame(width: 60, height: 60)
                }
                
                // 載入訊息
                if !message.isEmpty {
                    Text(message)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(uiColor: .systemGray6))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
        }
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - 錯誤處理管理器

@MainActor
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var errorHistory: [AppError] = []
    
    private let logger = Logger(subsystem: "com.richnowai", category: "ErrorHandler")
    
    private init() {}
    
    func handleError(_ error: Error, context: String? = nil) {
        let appError = AppError(
            id: UUID(),
            error: error,
            context: context,
            timestamp: Date()
        )
        
        currentError = appError
        errorHistory.append(appError)
        
        logger.error("錯誤發生: \(context ?? "未知"), \(error.localizedDescription)")
        
        // 限制錯誤歷史記錄數量
        if errorHistory.count > 100 {
            errorHistory.removeFirst()
        }
    }
    
    func clearError() {
        currentError = nil
    }
}

struct AppError: Identifiable, Equatable {
    let id: UUID
    let error: NSError
    let context: String?
    let timestamp: Date
    
    init(id: UUID, error: Error, context: String?, timestamp: Date) {
        self.id = id
        // 將 Error 轉換為 NSError 以便比較
        self.error = error as NSError
        self.context = context
        self.timestamp = timestamp
    }
    
    var message: String {
        error.localizedDescription
    }
    
    var title: String {
        context ?? "發生錯誤"
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 錯誤視圖

struct ErrorAlertView: View {
    @ObservedObject var errorHandler = ErrorHandler.shared
    @State private var showAlert = false
    
    var body: some View {
        EmptyView()
            .alert(errorHandler.currentError?.title ?? "錯誤", isPresented: $showAlert) {
                Button("確定") {
                    errorHandler.clearError()
                }
            } message: {
                Text(errorHandler.currentError?.message ?? "")
            }
            .onChange(of: errorHandler.currentError) { oldError, newError in
                showAlert = newError != nil
            }
    }
}

// MARK: - 用戶反饋管理器

@MainActor
class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()
    
    @Published var showSuccess: Bool = false
    @Published var successMessage: String = ""
    @Published var showInfo: Bool = false
    @Published var infoMessage: String = ""
    
    private var successTimer: Timer?
    private var infoTimer: Timer?
    
    private init() {}
    
    func showSuccess(message: String, duration: Double = 2.0) {
        successMessage = message
        showSuccess = true
        
        successTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.showSuccess = false
            }
        }
        successTimer = timer
    }
    
    func showInfo(message: String, duration: Double = 3.0) {
        infoMessage = message
        showInfo = true
        
        infoTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.showInfo = false
            }
        }
        infoTimer = timer
    }
}

// MARK: - 反饋視圖

struct FeedbackToastView: View {
    @ObservedObject var feedbackManager = FeedbackManager.shared
    
    var body: some View {
        VStack {
            if feedbackManager.showSuccess {
                SuccessToast(message: feedbackManager.successMessage)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            if feedbackManager.showInfo {
                InfoToast(message: feedbackManager.infoMessage)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Spacer()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: feedbackManager.showSuccess)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: feedbackManager.showInfo)
    }
}

struct SuccessToast: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
            
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .padding(.top, 50)
    }
}

struct InfoToast: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.title2)
            
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .padding(.top, 50)
    }
}

