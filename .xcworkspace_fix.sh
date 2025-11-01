#!/bin/bash
# Xcode 文件超時問題修復腳本

echo "🔧 開始修復 Xcode 文件超時問題..."

# 1. 清除 DerivedData
echo "📦 清除 DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/RICH_Now_AI-*

# 2. 清除 Xcode 緩存
echo "🗑️  清除 Xcode 緩存..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*

# 3. 清除項目的用戶數據
echo "🧹 清除項目用戶數據..."
rm -rf "RICH Now AI/RICH Now AI.xcodeproj/xcuserdata"
rm -rf "RICH Now AI/RICH Now AI.xcodeproj/project.xcworkspace/xcuserdata"

# 4. 重建索引文件
echo "🔍 重建項目索引..."
cd "RICH Now AI"
find . -name ".DS_Store" -delete
find . -name "*.xcworkspace" -exec rm -rf {} \;

echo "✅ 修復完成！"
echo ""
echo "下一步操作："
echo "1. 關閉 Xcode"
echo "2. 等待 iCloud Drive 完成同步（檢查 Finder 中文件是否都已下載）"
echo "3. 重新打開 Xcode"
echo "4. 如果問題仍然存在，考慮將項目移到本地目錄（不在 iCloud 中）"

