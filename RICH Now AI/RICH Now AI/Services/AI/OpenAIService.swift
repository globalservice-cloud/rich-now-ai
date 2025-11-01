//
//  OpenAIService.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import Combine
import SwiftUI
import AVFoundation

// OpenAI API 錯誤類型
enum OpenAIError: Error, LocalizedError {
    case invalidAPIKey
    case networkError
    case rateLimitExceeded
    case invalidResponse
    case encodingError
    case decodingError
    case networkOffline
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid OpenAI API Key"
        case .networkError:
            return "Network connection error"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .encodingError:
            return "Failed to encode request"
        case .decodingError:
            return "Failed to decode response"
        case .networkOffline:
            return "需要網路連線才能使用 AI 功能"
        }
    }
}

// OpenAI 訊息結構
struct OpenAIMessage: Codable {
    let role: String // "system", "user", "assistant"
    let content: String
}

// OpenAI 聊天請求
struct OpenAIChatRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let maxTokens: Int?
    let temperature: Double?
    let stream: Bool?
    let stop: [String]?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream, stop
        case maxTokens = "max_tokens"
    }
}

// OpenAI 聊天回應
struct OpenAIChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage?
}

struct OpenAIChoice: Codable {
    let index: Int
    let message: OpenAIMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

// Whisper 轉錄請求
struct WhisperTranscriptionRequest: Codable {
    let file: URL
    let model: String
    let language: String?
    let prompt: String?
    let responseFormat: String?
    let temperature: Double?
}

// Whisper 轉錄回應
struct WhisperTranscriptionResponse: Codable {
    let text: String
    let confidence: Float?
    let language: String?
}

struct OpenAIUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// OpenAI Streaming 回應
struct OpenAIStreamResponse: Codable {
    let choices: [OpenAIStreamChoice]
}

struct OpenAIStreamChoice: Codable {
    let delta: OpenAIStreamDelta?
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case delta
        case finishReason = "finish_reason"
    }
}

struct OpenAIStreamDelta: Codable {
    let content: String?
    let role: String?
}

// 語音轉文字請求
struct WhisperRequest: Codable {
    let model: String
    let file: String // Base64 encoded audio file
    let language: String?
    let prompt: String?
}

// 語音轉文字回應
struct WhisperResponse: Codable {
    let text: String
}

// 圖片分析請求
struct VisionRequest: Codable {
    let model: String
    let messages: [VisionMessage]
    let maxTokens: Int?
}

struct VisionMessage: Codable {
    let role: String
    let content: [VisionContent]
}

struct VisionContent: Codable {
    let type: String
    let text: String?
    let imageUrl: VisionImageUrl?
    
    enum CodingKeys: String, CodingKey {
        case type, text
        case imageUrl = "image_url"
    }
}

struct VisionImageUrl: Codable {
    let url: String
}

// 圖片分析回應
struct VisionResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [VisionChoice]
}

struct VisionChoice: Codable {
    let index: Int
    let message: OpenAIMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

// 交易解析結果
struct TransactionParseResult: Codable {
    let amount: Double?
    let category: String?
    let description: String?
    let date: String?
    let confidence: Double
    let suggestions: [String]
}

@MainActor
class OpenAIService: ObservableObject {
    static let shared = OpenAIService()
    
    // API 設定
    private let baseURL = "https://api.openai.com/v1"
    private let chatEndpoint = "/chat/completions"
    private let whisperEndpoint = "/audio/transcriptions"
    private let visionEndpoint = "/chat/completions"
    
    // API Key 管理
    private var apiKey: String? {
        return APIKeyManager.shared.getAPIKey(for: "openai")
    }
    private var isUsingOwnAPIKey: Bool {
        return APIKeyManager.shared.isUsingOwnAPIKey(for: "openai")
    }
    
    // 使用量追蹤
    @Published var monthlyUsage: Int = 0
    @Published var monthlyLimit: Int = 50 // 免費版限制
    @Published var isProUser: Bool = false
    @Published var subscriptionTier: SubscriptionTier = .free
    
    // API 成本追蹤
    @Published var monthlyAPICost: Double = 0.0
    @Published var costPerRequest: Double = 0.0
    
    private init() {
        // API Key 管理已移至 APIKeyManager
    }
    
    // MARK: - 語音轉文字 (Whisper API)
    
    func transcribeAudio(url: URL, language: String? = nil, prompt: String? = nil) async throws -> String {
        guard let key = apiKey else {
            throw OpenAIError.invalidAPIKey
        }
        
        // 檢查是否可以發送請求
        guard APIKeyManager.shared.canMakeRequest(for: "openai") else {
            throw OpenAIError.rateLimitExceeded
        }
        
        let request = WhisperTranscriptionRequest(
            file: url,
            model: "whisper-1",
            language: language,
            prompt: prompt,
            responseFormat: "json",
            temperature: 0.0
        )
        
        let response: WhisperTranscriptionResponse = try await makeRequest(
            endpoint: whisperEndpoint,
            request: request,
            apiKey: key
        )
        
        // 追蹤 API 使用量
        let estimatedTokens = estimateTokensForAudio(url: url)
        APIKeyManager.shared.trackAPIUsage(for: "openai", tokens: estimatedTokens, cost: calculateWhisperCost(duration: getAudioDuration(url: url)))
        
        return response.text
    }
    
    private func estimateTokensForAudio(url: URL) -> Int {
        // Whisper API 的 token 估算
        let duration = getAudioDuration(url: url)
        return Int(duration * 0.75) // 大約每秒0.75個token
    }
    
    private func calculateWhisperCost(duration: TimeInterval) -> Double {
        // Whisper API 定價：$0.006 per minute
        return duration / 60.0 * 0.006
    }
    
    private func getAudioDuration(url: URL) -> TimeInterval {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let frameCount = audioFile.length
            let sampleRate = audioFile.fileFormat.sampleRate
            return Double(frameCount) / sampleRate
        } catch {
            return 0.0
        }
    }

    // MARK: - 聊天對話

    func chat(messages: [OpenAIMessage], apiKey: String? = nil) async throws -> String {
        try checkNetworkAvailability()
        
        guard let key = apiKey ?? self.apiKey else {
            throw OpenAIError.invalidAPIKey
        }
        
        // 檢查是否可以發送請求
        guard APIKeyManager.shared.canMakeRequest(for: "openai") else {
            throw OpenAIError.rateLimitExceeded
        }
        
        let request = OpenAIChatRequest(
            model: "gpt-4o",
            messages: messages,
            maxTokens: 2000,
            temperature: 0.7,
            stream: false,
            stop: nil
        )
        
        let response: OpenAIChatResponse = try await makeRequest(
            endpoint: chatEndpoint,
            request: request,
            apiKey: key
        )
        
        guard let choice = response.choices.first else {
            throw OpenAIError.invalidResponse
        }
        
        // 追蹤 API 使用量
        if let usage = response.usage {
            APIKeyManager.shared.trackAPIUsage(for: "openai", tokens: usage.totalTokens, cost: calculateCost(tokens: usage.totalTokens))
        }
        
        return choice.message.content
    }
    
    func chatStream(messages: [OpenAIMessage], apiKey: String? = nil) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    try checkNetworkAvailability()
                } catch {
                    continuation.finish(throwing: error)
                    return
                }
                
                guard let key = apiKey ?? self.apiKey else {
                    continuation.finish(throwing: OpenAIError.invalidAPIKey)
                    return
                }

                let request = OpenAIChatRequest(
                    model: "gpt-4o",
                    messages: messages,
                    maxTokens: 2000,
                    temperature: 0.7,
                    stream: true,
                    stop: nil
                )

                do {
                    try await makeStreamingRequest(
                        endpoint: chatEndpoint,
                        request: request,
                        apiKey: key,
                        continuation: continuation
                    )
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func makeStreamingRequest<T: Codable>(
        endpoint: String,
        request: T,
        apiKey: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        guard let url = URL(string: baseURL + endpoint) else {
            throw OpenAIError.networkError
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw OpenAIError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenAIError.networkError
        }
        
        // 處理 Server-Sent Events (SSE) 格式的 streaming 回應
        let responseString = String(data: data, encoding: .utf8) ?? ""
        let lines = responseString.components(separatedBy: .newlines)
        
        for line in lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                if jsonString == "[DONE]" {
                    continuation.finish()
                    return
                }
                
                do {
                    let streamData = jsonString.data(using: .utf8)!
                    let streamResponse = try JSONDecoder().decode(OpenAIStreamResponse.self, from: streamData)
                    
                    if let choice = streamResponse.choices.first,
                       let delta = choice.delta,
                       let content = delta.content {
                        continuation.yield(content)
                    }
                } catch {
                    // 忽略解析錯誤，繼續處理下一行
                    continue
                }
            }
        }
        
        continuation.finish()
    }
    
    // MARK: - 語音轉文字
    
    func transcribeAudio(audioData: Data, apiKey: String? = nil) async throws -> String {
        guard let key = apiKey ?? self.apiKey else {
            throw OpenAIError.invalidAPIKey
        }
        
        // 將音訊資料轉換為 Base64
        let base64Audio = audioData.base64EncodedString()
        
        let request = WhisperRequest(
            model: "whisper-1",
            file: base64Audio,
            language: "zh-TW",
            prompt: "這是一個財務記帳的語音輸入，請轉錄為文字"
        )
        
        let response: WhisperResponse = try await makeRequest(
            endpoint: whisperEndpoint,
            request: request,
            apiKey: key
        )
        
        return response.text
    }
    
    // MARK: - 圖片分析
    
    func analyzeReceipt(imageData: Data, apiKey: String? = nil) async throws -> TransactionParseResult {
        guard let key = apiKey ?? self.apiKey else {
            throw OpenAIError.invalidAPIKey
        }
        
        // 將圖片轉換為 Base64
        let base64Image = imageData.base64EncodedString()
        
        let message = VisionMessage(
            role: "user",
            content: [
                VisionContent(
                    type: "text",
                    text: "請分析這張發票或收據，提取以下資訊：金額、商家名稱、日期、商品項目。請以 JSON 格式回應。",
                    imageUrl: nil
                ),
                VisionContent(
                    type: "image_url",
                    text: nil,
                    imageUrl: VisionImageUrl(url: "data:image/jpeg;base64,\(base64Image)")
                )
            ]
        )
        
        let request = VisionRequest(
            model: "gpt-4o",
            messages: [message],
            maxTokens: 1000
        )
        
        let response: VisionResponse = try await makeRequest(
            endpoint: visionEndpoint,
            request: request,
            apiKey: key
        )
        
        guard let choice = response.choices.first else {
            throw OpenAIError.invalidResponse
        }
        
        // 解析回應為交易資訊
        return try parseTransactionFromResponse(choice.message.content)
    }
    
    // MARK: - 交易解析
    
    func parseTransactionFromText(_ text: String, apiKey: String? = nil) async throws -> TransactionParseResult {
        guard let key = apiKey ?? self.apiKey else {
            throw OpenAIError.invalidAPIKey
        }
        
        let systemMessage = OpenAIMessage(
            role: "system",
            content: "你是一個財務記帳助手。請從使用者的自然語言輸入中提取交易資訊，包括金額、分類、描述、日期。請以 JSON 格式回應，包含 confidence 信心度（0-1）和 suggestions 建議。"
        )
        
        let userMessage = OpenAIMessage(
            role: "user",
            content: "請解析以下交易資訊：\(text)"
        )
        
        let response = try await chat(messages: [systemMessage, userMessage], apiKey: key)
        return try parseTransactionFromResponse(response)
    }
    
    // MARK: - 私有方法
    
    private func getEffectiveAPIKey() -> String? {
        // 檢查是否有用戶自備的 API Key
        if let userKey = APIKeyManager.shared.useAPIKey(for: "openai") {
            return userKey
        }
        
        // 使用應用程式預設的 API Key
        return apiKey
    }
    
    private func checkNetworkAvailability() throws {
        guard NetworkMonitor.shared.isConnected else {
            throw OpenAIError.networkOffline
        }
    }
    
    private func makeRequest<T: Codable, R: Codable>(
        endpoint: String,
        request: T,
        apiKey: String
    ) async throws -> R {
        guard let url = URL(string: baseURL + endpoint) else {
            throw OpenAIError.networkError
        }
        
        // 優先使用用戶自備的 API Key
        let effectiveAPIKey = getEffectiveAPIKey() ?? apiKey
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(effectiveAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw OpenAIError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.networkError
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw OpenAIError.invalidAPIKey
        case 429:
            throw OpenAIError.rateLimitExceeded
        default:
            throw OpenAIError.networkError
        }
        
        do {
            return try JSONDecoder().decode(R.self, from: data)
        } catch {
            throw OpenAIError.decodingError
        }
    }
    
    private func parseTransactionFromResponse(_ response: String) throws -> TransactionParseResult {
        // 嘗試解析 JSON 回應
        if let data = response.data(using: .utf8),
           let result = try? JSONDecoder().decode(TransactionParseResult.self, from: data) {
            return result
        }
        
        // 如果無法解析 JSON，返回基本結果
        return TransactionParseResult(
            amount: nil,
            category: nil,
            description: response,
            date: nil,
            confidence: 0.5,
            suggestions: []
        )
    }
    
    // MARK: - 成本計算
    
    private func calculateCost(tokens: Int) -> Double {
        // GPT-4o 定價：$0.005 per 1K tokens (input), $0.015 per 1K tokens (output)
        // 這裡使用平均價格
        let costPerToken = 0.00001 // $0.00001 per token
        return Double(tokens) * costPerToken
    }
    
    // MARK: - 使用量管理
    
    func checkUsageLimit() -> Bool {
        return APIKeyManager.shared.canMakeRequest(for: "openai")
    }
    
    func incrementUsage() {
        // 使用量追蹤已移至 APIKeyManager
    }
    
    func resetMonthlyUsage() {
        APIUsageTracker.shared.resetMonthlyUsage()
    }
}
