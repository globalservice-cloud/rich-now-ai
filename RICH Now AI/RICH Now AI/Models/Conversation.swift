//
//  Conversation.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData

// 訊息類型
enum MessageType: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

// 訊息內容類型
enum MessageContentType: String, Codable {
    case text = "text"
    case voice = "voice"
    case image = "image"
    case transaction = "transaction"
    case report = "report"
    case goal = "goal"
}

// 單一訊息
struct Message: Codable {
    let id: String
    let type: MessageType
    let contentType: MessageContentType
    let content: String
    let timestamp: Date
    let metadata: [String: String]? // 額外資訊，如語音檔案路徑、圖片路徑等
    
    init(type: MessageType, contentType: MessageContentType, content: String, metadata: [String: String]? = nil) {
        self.id = UUID().uuidString
        self.type = type
        self.contentType = contentType
        self.content = content
        self.timestamp = Date()
        self.metadata = metadata
    }
}

@Model
final class Conversation {
    // 對話基本資訊
    var title: String
    var createdAt: Date
    var lastMessageAt: Date
    var isActive: Bool
    
    // 對話內容 (JSON 格式存儲)
    var messages: Data // [Message] 的 JSON 格式
    
    // 對話上下文
    var context: String? // 當前討論的主題
    var vglaType: String? // 使用者的 VGLA 類型，用於客製化回應
    
    // 關聯
    @Relationship(deleteRule: .nullify, inverse: \User.conversations) var user: User?
    
    init(title: String, vglaType: String? = nil) {
        self.title = title
        self.createdAt = Date()
        self.lastMessageAt = Date()
        self.isActive = true
        self.messages = Data()
        self.vglaType = vglaType
    }
    
    // 添加訊息
    func addMessage(_ message: Message) {
        var messageList = getMessages()
        messageList.append(message)
        
        do {
            self.messages = try JSONEncoder().encode(messageList)
            self.lastMessageAt = message.timestamp
        } catch {
            print("Failed to encode messages: \(error)")
        }
    }
    
    // 獲取訊息列表
    func getMessages() -> [Message] {
        do {
            return try JSONDecoder().decode([Message].self, from: messages)
        } catch {
            print("Failed to decode messages: \(error)")
            return []
        }
    }
    
    // 獲取最後 N 條訊息（用於 AI 上下文）
    func getLastMessages(count: Int = 10) -> [Message] {
        let allMessages = getMessages()
        return Array(allMessages.suffix(count))
    }
    
    // 更新對話標題
    func updateTitle(_ newTitle: String) {
        self.title = newTitle
    }
    
    // 結束對話
    func endConversation() {
        self.isActive = false
    }
    
    // 重新開始對話
    func restartConversation() {
        self.isActive = true
        self.lastMessageAt = Date()
    }
    
    // 清空對話歷史
    func clearHistory() {
        self.messages = Data()
        self.lastMessageAt = Date()
    }
    
    // 獲取對話摘要（用於 AI 上下文）
    func getConversationSummary() -> String {
        let messageList = getMessages()
        let recentMessages = Array(messageList.suffix(5))
        
        return recentMessages.map { message in
            "\(message.type.rawValue): \(message.content)"
        }.joined(separator: "\n")
    }
}
