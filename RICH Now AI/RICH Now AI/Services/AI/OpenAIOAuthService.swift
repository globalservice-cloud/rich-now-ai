//
//  OpenAIOAuthService.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import Foundation
import SwiftUI
import WebKit
import Combine

// MARK: - OAuth 配置
struct OpenAIOAuthConfig {
    static let clientId = "your-openai-client-id" // 需要從 OpenAI 獲取
    static let redirectURI = "richnowai://oauth/callback"
    static let scope = "openid profile email"
    static let authURL = "https://auth0.openai.com/authorize"
    static let tokenURL = "https://auth0.openai.com/oauth/token"
}

// MARK: - OAuth Token 模型
struct OpenAIOAuthToken: Codable {
    let accessToken: String
    let refreshToken: String?
    let tokenType: String
    let expiresIn: Int
    let scope: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case scope
    }
}

// MARK: - OAuth 用戶信息
struct OpenAIUserInfo: Codable {
    let sub: String
    let email: String
    let name: String?
    let picture: String?
}

// MARK: - OAuth 服務
@MainActor
class OpenAIOAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userInfo: OpenAIUserInfo?
    
    var authToken: OpenAIOAuthToken?
    
    // 生成 OAuth 授權 URL
    func getAuthorizationURL() -> URL? {
        var components = URLComponents(string: OpenAIOAuthConfig.authURL)
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: OpenAIOAuthConfig.clientId),
            URLQueryItem(name: "redirect_uri", value: OpenAIOAuthConfig.redirectURI),
            URLQueryItem(name: "scope", value: OpenAIOAuthConfig.scope),
            URLQueryItem(name: "state", value: generateRandomState())
        ]
        return components?.url
    }
    
    // 處理 OAuth 回調
    func handleCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            errorMessage = "無效的回調 URL"
            return
        }
        
        // 檢查是否有錯誤
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            errorMessage = "授權錯誤: \(error)"
            return
        }
        
        // 獲取授權碼
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            errorMessage = "未找到授權碼"
            return
        }
        
        // 交換 token
        exchangeCodeForToken(code: code)
    }
    
    // 交換授權碼獲取 token
    private func exchangeCodeForToken(code: String) {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: OpenAIOAuthConfig.tokenURL) else {
            errorMessage = "無效的 token URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "grant_type": "authorization_code",
            "client_id": OpenAIOAuthConfig.clientId,
            "code": code,
            "redirect_uri": OpenAIOAuthConfig.redirectURI
        ]
        
        request.httpBody = bodyParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "網路錯誤: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "未收到回應數據"
                    return
                }
                
                do {
                    let token = try JSONDecoder().decode(OpenAIOAuthToken.self, from: data)
                    self?.authToken = token
                    self?.isAuthenticated = true
                    self?.saveToken(token)
                    self?.fetchUserInfo()
                } catch {
                    self?.errorMessage = "解析 token 失敗: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    // 獲取用戶信息
    private func fetchUserInfo() {
        guard let token = authToken else { return }
        
        guard let url = URL(string: "https://auth0.openai.com/userinfo") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "獲取用戶信息失敗: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else { return }
                
                do {
                    let userInfo = try JSONDecoder().decode(OpenAIUserInfo.self, from: data)
                    self?.userInfo = userInfo
                } catch {
                    self?.errorMessage = "解析用戶信息失敗: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    // 保存 token 到 Keychain
    private func saveToken(_ token: OpenAIOAuthToken) {
        // 這裡可以將 token 保存到 Keychain 或其他安全存儲
        UserDefaults.standard.set(token.accessToken, forKey: "openai_access_token")
        UserDefaults.standard.set(token.refreshToken, forKey: "openai_refresh_token")
    }
    
    // 從 Keychain 載入 token
    func loadSavedToken() {
        if let accessToken = UserDefaults.standard.string(forKey: "openai_access_token"),
           !accessToken.isEmpty {
            isAuthenticated = true
            // 可以驗證 token 是否仍然有效
        }
    }
    
    // 登出
    func logout() {
        isAuthenticated = false
        authToken = nil
        userInfo = nil
        UserDefaults.standard.removeObject(forKey: "openai_access_token")
        UserDefaults.standard.removeObject(forKey: "openai_refresh_token")
    }
    
    // 生成隨機 state 參數
    private func generateRandomState() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map { _ in letters.randomElement()! })
    }
    
    // 獲取當前 access token
    func getAccessToken() -> String? {
        return authToken?.accessToken ?? UserDefaults.standard.string(forKey: "openai_access_token")
    }
}
