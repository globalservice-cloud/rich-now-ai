#!/bin/bash
# 強制下載 iCloud Drive 中的所有文件

echo "🔄 開始強制下載 iCloud Drive 文件..."

PROJECT_DIR="/Users/changyaotiem/Library/Mobile Documents/com~apple~CloudDocs/app開發/Rich Now AI/RICH Now AI"

echo "📂 項目目錄: $PROJECT_DIR"
echo ""

# 使用 osascript 來觸發 Finder 下載
echo "💡 方法 1: 使用 AppleScript 觸發 Finder 下載..."

# 計算需要下載的文件數量
echo "📊 檢查需要下載的文件..."

# 使用 find 查找所有文件並觸發下載
find "$PROJECT_DIR" -type f -name "*.swift" | while read file; do
    # 檢查文件是否已下載（使用 mdls）
    is_downloaded=$(mdls "$file" 2>/dev/null | grep "kMDItemIsDownloaded" | awk '{print $3}')
    
    if [ "$is_downloaded" != "1" ]; then
        echo "⏬ 需要下載: $file"
        # 觸發文件下載（通過讀取文件）
        head -1 "$file" > /dev/null 2>&1
    fi
done

echo ""
echo "✅ 下載請求已發送"
echo ""
echo "⚠️  重要提示："
echo "1. 請打開 Finder，導航到項目文件夾"
echo "2. 查看所有文件是否都有下載圖標（⏬）"
echo "3. 如果有，請等待 iCloud Drive 完成下載"
echo "4. 或者在 Finder 中右鍵選擇 '現在下載' 來強制下載所有文件"
echo ""
echo "💡 建議：如果問題持續存在，請將項目移到本地目錄開發"

