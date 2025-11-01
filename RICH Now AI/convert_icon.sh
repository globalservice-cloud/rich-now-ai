#!/bin/bash

# 圖片轉換腳本
# 使用方法：./convert_icon.sh your-image.png

if [ $# -eq 0 ]; then
    echo "使用方法: ./convert_icon.sh your-image.png"
    exit 1
fi

INPUT_IMAGE="$1"
OUTPUT_DIR="RICH Now AI/RICH Now AI/Assets.xcassets/AppIcon.appiconset"

# 檢查 ImageMagick 是否安裝
if ! command -v convert &> /dev/null; then
    echo "請先安裝 ImageMagick: brew install imagemagick"
    exit 1
fi

# 創建輸出目錄
mkdir -p "$OUTPUT_DIR"

# 轉換不同尺寸
echo "正在轉換圖片..."

convert "$INPUT_IMAGE" -resize 1024x1024 "$OUTPUT_DIR/icon-1024.png"
convert "$INPUT_IMAGE" -resize 180x180 "$OUTPUT_DIR/icon-180.png"
convert "$INPUT_IMAGE" -resize 120x120 "$OUTPUT_DIR/icon-120.png"
convert "$INPUT_IMAGE" -resize 87x87 "$OUTPUT_DIR/icon-87.png"
convert "$INPUT_IMAGE" -resize 58x58 "$OUTPUT_DIR/icon-58.png"
convert "$INPUT_IMAGE" -resize 167x167 "$OUTPUT_DIR/icon-167.png"
convert "$INPUT_IMAGE" -resize 152x152 "$OUTPUT_DIR/icon-152.png"
convert "$INPUT_IMAGE" -resize 76x76 "$OUTPUT_DIR/icon-76.png"
convert "$INPUT_IMAGE" -resize 40x40 "$OUTPUT_DIR/icon-40.png"
convert "$INPUT_IMAGE" -resize 29x29 "$OUTPUT_DIR/icon-29.png"

echo "轉換完成！所有 icon 文件已保存到 $OUTPUT_DIR"
echo "現在您可以在 Xcode 中看到新的 App Icon 了！"
