#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCHEMA_DIR="$ROOT_DIR/ai/schemas"
OUT_DIR="$ROOT_DIR/ai/outputs"

bold() { printf "\033[1m%s\033[0m\n" "$*"; }
red()  { printf "\033[31m%s\033[0m\n" "$*"; }
green(){ printf "\033[32m%s\033[0m\n" "$*"; }

if ! command -v node >/dev/null 2>&1; then
  red "❌ 需要 Node.js。請先安裝（https://nodejs.org/ 或 brew install node）。"; exit 1; fi

if ! command -v ajv >/dev/null 2>&1; then
  bold "ℹ️ 沒找到 ajv-cli，嘗試安裝（需 npm）..."
  if command -v npm >/dev/null 2>&1; then npm i -g ajv-cli@5 >/dev/null 2>&1 || true; fi
fi
if ! command -v ajv >/dev/null 2>&1; then
  red "❌ 無法使用 ajv-cli。也可改用：npx ajv-cli@5 validate ..."; exit 1; fi

validate() {
  local name="$1"; local schema="$2"; local data="$3";
  if [ -f "$data" ]; then
    echo "🔎 驗證 $name → $data"
    if ajv validate -s "$schema" -d "$data" --errors=text; then
      green "✅ $name 通過"
    else
      red "❌ $name 失敗（修正 $data 後重試）"; exit 2
    fi
  else
    echo "⚠️ 未找到 $data，略過"
  fi
}

bold "== AI Flow 本地驗證啟動 =="
validate "RFC" "$SCHEMA_DIR/rfc.schema.json" "$OUT_DIR/rfc.json"
validate "ADR" "$SCHEMA_DIR/adr.schema.json" "$OUT_DIR/adr.json"
validate "Dev Output" "$SCHEMA_DIR/dev-output.schema.json" "$OUT_DIR/dev-output.json"
validate "QA Report" "$SCHEMA_DIR/qa-report.schema.json" "$OUT_DIR/qa-report.json"
validate "Release Gates" "$SCHEMA_DIR/release-gates.schema.json" "$OUT_DIR/release-gates.json"
green "🎉 可用檔案皆通過！"
