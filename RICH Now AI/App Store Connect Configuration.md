# App Store Connect 配置指南

## 概述

本指南將幫助你完成 RICH Now AI 應用程式在 App Store Connect 中的配置，包括訂閱產品設置、沙盒測試和發布準備。

## 步驟 1：登入 App Store Connect

1. 前往 [App Store Connect](https://appstoreconnect.apple.com)
2. 使用你的 Apple Developer 帳號登入
3. 選擇你的開發者團隊

## 步驟 2：創建應用程式

### 2.1 基本資訊
- **平台**：iOS
- **名稱**：RICH Now AI
- **主要語言**：English
- **Bundle ID**：com.richnowai.app
- **SKU**：rich-now-ai-2025

### 2.2 應用程式描述
**英文描述**：
```
RICH Now AI is a comprehensive financial management app powered by AI. Get personalized financial advice, track expenses with natural language, and achieve your financial goals with Gabriel, your AI financial guardian angel.

Key Features:
• AI-powered financial conversations
• Natural language expense tracking
• VGLA personality assessment
• Financial health dashboard
• Investment portfolio tracking
• Voice and photo accounting
• Multi-language support (EN/繁中/简体中文)
```

**繁體中文描述**：
```
RICH Now AI 是一款由 AI 驅動的綜合財務管理應用程式。透過加百列 AI 財務守護天使，獲得個人化財務建議，用自然語言追蹤支出，實現您的財務目標。

主要功能：
• AI 驅動的財務對話
• 自然語言記帳
• VGLA 個性測驗
• 財務健康儀表板
• 投資組合追蹤
• 語音和照片記帳
• 多語言支援（英文/繁中/简体中文）
```

**簡體中文描述**：
```
RICH Now AI 是一款由 AI 驱动的综合财务管理应用程序。通过加百列 AI 财务守护天使，获得个性化财务建议，用自然语言追踪支出，实现您的财务目标。

主要功能：
• AI 驱动的财务对话
• 自然语言记账
• VGLA 个性测验
• 财务健康仪表板
• 投资组合追踪
• 语音和照片记账
• 多语言支持（英文/繁中/简体中文）
```

## 步驟 3：配置訂閱產品

### 3.1 創建訂閱群組

1. 前往「功能」→「App 內購買項目」
2. 點擊「訂閱群組」→「+」
3. 創建訂閱群組：
   - **參考名稱**：RICH Now AI Subscriptions
   - **本地化**：
     - 英文：RICH Now AI Subscriptions
     - 繁體中文：RICH Now AI 訂閱方案
     - 簡體中文：RICH Now AI 订阅方案

### 3.2 基礎方案 (Basic Plan)

**產品設定**：
- **產品 ID**：`com.richnowai.basic.monthly`
- **參考名稱**：Basic Monthly
- **產品類型**：自動續訂訂閱
- **訂閱群組**：RICH Now AI Subscriptions
- **價格**：$4.99/月

**本地化設定**：
- **英文**：
  - 顯示名稱：Basic Plan
  - 描述：Essential financial management with AI assistance
- **繁體中文**：
  - 顯示名稱：基礎方案
  - 描述：基本財務管理與 AI 協助
- **簡體中文**：
  - 顯示名稱：基础方案
  - 描述：基本财务管理与 AI 协助

### 3.3 進階方案 (Premium Plan)

**產品設定**：
- **產品 ID**：`com.richnowai.premium.monthly`
- **參考名稱**：Premium Monthly
- **產品類型**：自動續訂訂閱
- **訂閱群組**：RICH Now AI Subscriptions
- **價格**：$9.99/月

**本地化設定**：
- **英文**：
  - 顯示名稱：Premium Plan
  - 描述：Advanced AI features and unlimited usage
- **繁體中文**：
  - 顯示名稱：進階方案
  - 描述：進階 AI 功能與無限制使用
- **簡體中文**：
  - 顯示名稱：进阶方案
  - 描述：进阶 AI 功能与无限制使用

### 3.4 專業方案 (Pro Plan)

**產品設定**：
- **產品 ID**：`com.richnowai.pro.monthly`
- **參考名稱**：Pro Monthly
- **產品類型**：自動續訂訂閱
- **訂閱群組**：RICH Now AI Subscriptions
- **價格**：$19.99/月

**本地化設定**：
- **英文**：
  - 顯示名稱：Pro Plan
  - 描述：Complete financial suite with priority support
- **繁體中文**：
  - 顯示名稱：專業方案
  - 描述：完整財務套件與優先客服支援
- **簡體中文**：
  - 顯示名称：专业方案
  - 描述：完整财务套件与优先客服支持

## 步驟 4：配置沙盒測試

### 4.1 創建沙盒測試帳號

1. 前往「用戶和訪問」→「沙盒測試員」
2. 點擊「+」創建新的測試帳號
3. 填寫測試員資訊：
   - **名字**：Test User
   - **姓氏**：Sandbox
   - **電子郵件**：test.sandbox@example.com
   - **密碼**：TestPassword123!
   - **國家/地區**：United States

### 4.2 配置測試環境

1. **在 iOS 設備上**：
   - 前往「設定」→「App Store」
   - 點擊「登入」→「登出」
   - 使用沙盒測試帳號登入

2. **在 Xcode 中**：
   - 前往「Product」→「Scheme」→「Edit Scheme」
   - 選擇「Run」→「Options」
   - 在「StoreKit Configuration」中選擇「Use StoreKit Configuration File」

### 4.3 測試訂閱功能

使用應用程式中的「訂閱測試」標籤頁測試：
1. 載入產品
2. 購買訂閱
3. 恢復購買
4. 取消訂閱
5. 檢查訂閱狀態

## 步驟 5：應用程式審核準備

### 5.1 隱私政策

創建隱私政策頁面，包含：
- 數據收集和使用
- AI 服務使用
- 訂閱管理
- 用戶權利

### 5.2 應用程式截圖

準備以下截圖：
- iPhone 6.7" (iPhone 15 Pro Max)
- iPhone 6.5" (iPhone 15 Plus)
- iPhone 5.5" (iPhone 8 Plus)
- iPad Pro 12.9" (第 6 代)
- iPad Pro 11" (第 4 代)

### 5.3 應用程式預覽

創建 30 秒的應用程式預覽影片，展示：
- 迎賓動畫
- VGLA 測驗
- AI 對話
- 記帳功能
- 財務儀表板

## 步驟 6：提交審核

### 6.1 版本資訊

- **版本號**：1.0.0
- **建置號**：1
- **發布類型**：手動發布

### 6.2 審核資訊

**審核備註**：
```
This app includes subscription functionality for testing. Please use the sandbox test account provided in the review notes.

Test Account:
Email: test.sandbox@example.com
Password: TestPassword123!

The app features:
1. AI-powered financial conversations
2. Natural language expense tracking
3. VGLA personality assessment
4. Financial health dashboard
5. Multi-language support (EN/繁中/简体中文)

All subscription products are configured and ready for testing.
```

### 6.3 提交檢查清單

- [ ] 應用程式通過所有測試
- [ ] 訂閱產品配置完成
- [ ] 沙盒測試成功
- [ ] 隱私政策已添加
- [ ] 截圖和預覽已上傳
- [ ] 審核備註已填寫
- [ ] 版本資訊正確

## 步驟 7：發布後監控

### 7.1 分析數據

監控以下指標：
- 下載量
- 訂閱轉換率
- 用戶留存率
- 收入數據

### 7.2 用戶反饋

- 監控 App Store 評論
- 回應用戶問題
- 收集功能建議

### 7.3 持續優化

- 根據數據調整訂閱價格
- 優化用戶體驗
- 添加新功能

## 常見問題

### Q: 如何測試訂閱功能？
A: 使用沙盒測試帳號在測試設備上登入，然後在應用程式中測試訂閱功能。

### Q: 訂閱產品無法載入怎麼辦？
A: 檢查產品 ID 是否正確，確保在 App Store Connect 中已創建產品。

### Q: 如何處理訂閱取消？
A: 用戶可以在 App Store 中管理訂閱，應用程式會自動同步狀態。

### Q: 如何處理退款？
A: 退款由 Apple 處理，應用程式會自動收到通知並更新訂閱狀態。

## 技術支援

如有技術問題，請參考：
- [StoreKit 2 文檔](https://developer.apple.com/documentation/storekit)
- [App Store Connect 文檔](https://developer.apple.com/app-store-connect/)
- [訂閱最佳實踐](https://developer.apple.com/app-store/subscriptions/)

---

**注意**：請確保在提交審核前完成所有配置，並在沙盒環境中充分測試所有功能。
