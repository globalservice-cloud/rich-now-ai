# OpenAI OAuth 設置指南

## 概述
本應用程式支援使用 OpenAI 帳號直接登入，無需手動輸入 API Key。這需要設置 OAuth 2.0 授權流程。

## 設置步驟

### 1. 在 OpenAI 註冊 OAuth 應用程式

1. 前往 [OpenAI Platform](https://platform.openai.com/)
2. 登入你的 OpenAI 帳號
3. 前往 Settings > OAuth Applications
4. 點擊 "Create New Application"
5. 填寫應用程式資訊：
   - **Application Name**: RICH Now AI
   - **Description**: AI-powered financial advisor app
   - **Redirect URI**: `richnowai://oauth/callback`
   - **Scopes**: `openid profile email`

### 2. 獲取 Client ID

1. 創建應用程式後，複製 **Client ID**
2. 在 `OpenAIOAuthService.swift` 中更新：
   ```swift
   static let clientId = "your-actual-client-id-here"
   ```

### 3. 配置 URL Scheme

在 Xcode 項目中：

1. 選擇項目根目錄
2. 選擇 Target "RICH Now AI"
3. 前往 "Info" 標籤
4. 展開 "URL Types"
5. 添加新的 URL Type：
   - **Identifier**: `com.richnowai.oauth`
   - **URL Schemes**: `richnowai`
   - **Role**: `Editor`

### 4. 測試 OAuth 流程

1. 運行應用程式
2. 在引導流程中選擇 "使用 OpenAI 帳號登入"
3. 應該會打開 WebView 顯示 OpenAI 登入頁面
4. 登入成功後會自動返回應用程式

## 安全注意事項

1. **Client ID 保護**: 雖然 Client ID 可以公開，但建議不要將其提交到公開的版本控制系統
2. **Token 存儲**: Access Token 會安全地存儲在 Keychain 中
3. **HTTPS**: 所有 OAuth 通信都通過 HTTPS 進行
4. **State 參數**: 使用隨機 state 參數防止 CSRF 攻擊

## 故障排除

### 常見問題

1. **"無法生成授權 URL"**
   - 檢查 Client ID 是否正確設置
   - 確認 URL Scheme 已正確配置

2. **"授權錯誤"**
   - 檢查 Redirect URI 是否與 OpenAI 設置一致
   - 確認應用程式狀態為 "Active"

3. **"Token 交換失敗"**
   - 檢查網路連接
   - 確認 Client ID 和 Redirect URI 正確

### 調試模式

在開發過程中，可以在 `OpenAIOAuthService.swift` 中添加更多日誌：

```swift
print("Authorization URL: \(authURL)")
print("Callback URL: \(url)")
print("Token response: \(String(data: data, encoding: .utf8) ?? "nil")")
```

## 生產環境設置

1. 使用生產環境的 Client ID
2. 確保 Redirect URI 與實際應用程式包名一致
3. 在 App Store Connect 中配置正確的 URL Scheme
4. 測試完整的 OAuth 流程

## 備用方案

如果 OAuth 設置遇到問題，用戶仍然可以使用手動輸入 API Key 的方式：

1. 在登入頁面選擇 "手動輸入 API Key"
2. 輸入從 OpenAI Platform 獲取的 API Key
3. 應用程式會正常運行

## 支援

如果遇到問題，請檢查：
1. OpenAI 應用程式設置
2. URL Scheme 配置
3. 網路連接
4. 應用程式日誌
