//
//  VoiceRecordingManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import AVFoundation
import AVFAudio
import Combine

// 語音錄音管理器
@MainActor
class VoiceRecordingManager: NSObject, ObservableObject {
    static let shared = VoiceRecordingManager()
    
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0.0
    @Published var recordingError: String?
    @Published var hasPermission = false
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var audioLevelTimer: Timer?
    private var recordingURL: URL?
    
    private override init() {
        super.init()
        checkMicrophonePermission()
    }
    
    // MARK: - 權限管理
    
    func checkMicrophonePermission() {
        if #available(iOS 17, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                hasPermission = true
            case .denied, .undetermined:
                hasPermission = false
            @unknown default:
                hasPermission = false
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                hasPermission = true
            case .denied, .undetermined:
                hasPermission = false
            @unknown default:
                hasPermission = false
            }
        }
    }
    
    func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17, *) {
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    Task { @MainActor in
                        self.hasPermission = granted
                        continuation.resume(returning: granted)
                    }
                }
            }
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    Task { @MainActor in
                        self.hasPermission = granted
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    // MARK: - 錄音控制
    
    func startRecording() async throws {
        if !hasPermission {
            let granted = await requestMicrophonePermission()
            guard granted else {
                throw VoiceRecordingError.permissionDenied
            }
        }
        
        // 配置音頻會話
        try configureAudioSession()
        
        // 創建錄音文件URL
        let url = createRecordingURL()
        recordingURL = url
        
        // 配置錄音器
        let settings = getRecordingSettings()
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        
        // 開始錄音
        guard audioRecorder?.record() == true else {
            throw VoiceRecordingError.recordingFailed
        }
        
        isRecording = true
        recordingDuration = 0
        recordingError = nil
        
        // 開始計時器
        startRecordingTimer()
        startAudioLevelTimer()
    }
    
    func stopRecording() -> URL? {
        guard isRecording else { return nil }
        
        audioRecorder?.stop()
        isRecording = false
        
        // 停止計時器
        stopRecordingTimer()
        stopAudioLevelTimer()
        
        let url = recordingURL
        recordingURL = nil
        return url
    }
    
    func cancelRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        isRecording = false
        
        // 刪除錄音文件
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        recordingURL = nil
        
        // 停止計時器
        stopRecordingTimer()
        stopAudioLevelTimer()
    }
    
    // MARK: - 音頻會話配置
    
    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        try audioSession.setCategory(.record, mode: .default, options: [.allowBluetoothHFP])
        try audioSession.setActive(true)
    }
    
    private func getRecordingSettings() -> [String: Any] {
        return [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }
    
    private func createRecordingURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "voice_recording_\(Date().timeIntervalSince1970).m4a"
        return documentsPath.appendingPathComponent(fileName)
    }
    
    // MARK: - 計時器管理
    
    private func startRecordingTimer() {
        stopRecordingTimer()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.recordingDuration += 0.1
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func startAudioLevelTimer() {
        stopAudioLevelTimer()
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.updateAudioLevel()
            }
        }
    }
    
    private func stopAudioLevelTimer() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
    }
    
    private func updateAudioLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            audioLevel = 0.0
            return
        }
        
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        
        // 將分貝轉換為0-1範圍的音量
        let normalizedLevel = pow(10, averagePower / 20)
        audioLevel = max(0, min(1, normalizedLevel))
    }
    
    // MARK: - 格式化
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func getMaxRecordingDuration() -> TimeInterval {
        return 300.0 // 5分鐘最大錄音時間
    }
    
    func isMaxDurationReached() -> Bool {
        return recordingDuration >= getMaxRecordingDuration()
    }
}

// MARK: - AVAudioRecorderDelegate

extension VoiceRecordingManager: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                recordingError = "Recording failed to complete successfully"
            }
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            recordingError = error?.localizedDescription ?? "Unknown recording error"
        }
    }
}

// MARK: - 錯誤定義

enum VoiceRecordingError: LocalizedError {
    case permissionDenied
    case recordingFailed
    case audioSessionError
    case fileCreationError
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "麥克風權限被拒絕"
        case .recordingFailed:
            return "錄音失敗"
        case .audioSessionError:
            return "音頻會話錯誤"
        case .fileCreationError:
            return "檔案創建失敗"
        }
    }
}
