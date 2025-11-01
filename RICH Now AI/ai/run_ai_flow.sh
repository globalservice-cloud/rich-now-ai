#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"

echo "== 1) 驗證 JSON 與規範 =="
bash "$ROOT_DIR/ai/scripts/validate_all.sh"

echo "== 2) 產生 STATUS.md =="
bash "$ROOT_DIR/ai/scripts/generate_status_md.sh"

echo "== 3) 檢查發佈關卡（可選） =="
if [ -f "$ROOT_DIR/ai/outputs/release-gates.json" ]; then
  bash "$ROOT_DIR/ai/scripts/release_check.sh"
else
  echo "（尚未提供 release-gates.json，略過）"
fi
echo "🎉 全流程完成。"
