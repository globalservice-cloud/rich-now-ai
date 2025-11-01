# Xcode 文件超時問題修復指南

## 問題說明
您遇到的文件讀取超時錯誤通常是由以下原因造成的：
1. **iCloud Drive 同步問題** - 文件存儲在 iCloud 中，可能尚未完全下載到本地
2. **Xcode 索引問題** - SourceKit 服務無法正確讀取文件
3. **緩存損壞** - Xcode 的構建緩存或索引緩存損壞

## 已執行的修復步驟

✅ 已清除 Xcode DerivedData
✅ 已清除 Xcode 系統緩存
✅ 已清除項目用戶數據（xcuserdata）

## 建議的解決方案

### 方案 1：確保 iCloud Drive 文件已下載（推薦先嘗試）

1. **打開 Finder**
2. **導航到項目文件夾**：
   ```
   ~/Library/Mobile Documents/com~apple~CloudDocs/app開發/Rich Now AI
   ```
3. **檢查文件圖標**：
   - ⏬ 如果有下載箭頭，表示文件還在 iCloud 中
   - ✅ 如果沒有箭頭，表示已下載到本地
4. **等待所有文件下載完成**：
   - 點擊 Finder 中的雲朵圖標查看下載進度
   - 或者右鍵選擇「現在下載」

### 方案 2：重置 Xcode 索引

1. **關閉 Xcode**
2. **執行以下命令**（我已經為您創建了腳本）：
   ```bash
   cd "/Users/changyaotiem/Library/Mobile Documents/com~apple~CloudDocs/app開發/Rich Now AI"
   ./.xcworkspace_fix.sh
   ```
3. **重新打開 Xcode**
4. **讓 Xcode 重新索引項目**（這可能需要幾分鐘）

### 方案 3：將項目移到本地目錄（最徹底的解決方案）

如果 iCloud Drive 持續造成問題，建議將項目移到本地：

1. **在本地創建項目目錄**：
   ```bash
   mkdir -p ~/Developer/RICH_Now_AI
   ```

2. **複製項目**：
   ```bash
   cp -R "/Users/changyaotiem/Library/Mobile Documents/com~apple~CloudDocs/app開發/Rich Now AI" ~/Developer/RICH_Now_AI/
   ```

3. **在 Xcode 中打開新位置的文件**

4. **（可選）將新位置添加到 Git** 並刪除 iCloud 中的舊項目

### 方案 4：重啟 SourceKit 服務

如果 Xcode 已打開：

1. 在 Xcode 中：**Product → Clean Build Folder** (⇧⌘K)
2. 退出 Xcode
3. 執行：
   ```bash
   killall -9 com.apple.dt.SourceKitService
   killall -9 com.apple.dt.SourceKitServiceXPCService
   ```
4. 重新打開 Xcode

## 預防措施

1. **避免在 iCloud Drive 中開發大型項目**
   - iCloud Drive 適合存儲，但不適合開發
   - 建議使用本地目錄（如 `~/Developer/`）

2. **定期清理 Xcode 緩存**
   - 可以運行提供的 `.xcworkspace_fix.sh` 腳本

3. **確保網絡連接穩定**
   - iCloud Drive 需要穩定的網絡連接

## 如果問題仍然存在

請檢查：
- [ ] 所有文件是否都已從 iCloud 下載到本地
- [ ] Xcode 是否有足夠的磁盤空間
- [ ] 項目路徑中是否有特殊字符導致問題
- [ ] 是否有多個 Xcode 實例在運行

如果以上方法都不行，建議將項目移到本地目錄開發。

