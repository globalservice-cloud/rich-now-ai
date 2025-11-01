# 將項目移到本地目錄 - 解決方案

## 為什麼要移到本地？

您在 iCloud Drive 中開發遇到了文件讀取超時問題，這是因為：

1. **iCloud Drive 同步延遲** - 文件可能還在雲端
2. **SourceKit 服務超時** - Xcode 無法等待 iCloud 下載
3. **性能問題** - iCloud Drive 不適合頻繁讀寫的開發工作

## 立即解決方案（推薦）

### 步驟 1：創建本地開發目錄

```bash
mkdir -p ~/Developer/RICH_Now_AI
```

### 步驟 2：複製項目到本地

```bash
cp -R "/Users/changyaotiem/Library/Mobile Documents/com~apple~CloudDocs/app開發/Rich Now AI" ~/Developer/RICH_Now_AI/
```

### 步驟 3：在 Xcode 中打開新項目

1. 打開 Xcode
2. **File → Open**
3. 選擇 `~/Developer/RICH_Now_AI/Rich Now AI/RICH Now AI/RICH Now AI.xcodeproj`
4. 等待 Xcode 完成索引（通常更快）

### 步驟 4：驗證項目正常工作

- 嘗試編譯項目
- 檢查是否還有超時錯誤

## 遷移後的建議

### 備份策略

1. **使用 Git** (推薦)
   ```bash
   cd ~/Developer/RICH_Now_AI/Rich\ Now\ AI
   git init
   git add .
   git commit -m "Initial commit"
   ```

2. **定期備份到 iCloud**
   - 可以設置一個定時任務，定期將項目備份到 iCloud
   - 但不要在 iCloud 中直接開發

### 避免將 iCloud 用作開發目錄

- ✅ **適合 iCloud 的**：文檔、圖片、備份
- ❌ **不適合 iCloud 的**：開發項目、編譯輸出、臨時文件

## 如果仍想保留在 iCloud 中

如果必須在 iCloud 中工作，請：

1. **確保所有文件已下載到本地**
   - 在 Finder 中檢查，確保沒有下載圖標（⏬）
   - 如果有，右鍵選擇「現在下載」

2. **設置 iCloud Drive 為「優化儲存空間」的例外**
   - 系統設置 → Apple ID → iCloud → iCloud Drive → 選項
   - 將項目文件夾設為「下載並保留原件」

3. **重啟 SourceKit 服務**
   ```bash
   killall -9 com.apple.dt.SourceKitService
   killall -9 com.apple.dt.SourceKitServiceXPCService
   ```

## 預期結果

遷移到本地目錄後，您應該會看到：

- ✅ 文件讀取立即響應（無超時）
- ✅ Xcode 索引更快
- ✅ 編譯和構建更快
- ✅ 更好的開發體驗

立即行動：執行上面的複製命令，然後在 Xcode 中打開本地版本！

