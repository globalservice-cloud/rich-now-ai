#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if ! command -v node >/dev/null 2>&1; then
  echo "❌ 需要 Node.js"; exit 1; fi

node - <<'NODE'
const fs=require('fs');
const root=process.env.ROOT_DIR || process.cwd();
const file=`${root}/ai/outputs/release-gates.json`;
if(!fs.existsSync(file)){ console.error('❌ 找不到 release-gates.json'); process.exit(1);}
const j=JSON.parse(fs.readFileSync(file,'utf8'));
const ok=j.dataQuality && j.tests && j.slo && j.signoff;
if(!ok){ console.error('❌ Release gates 未全部通過：', j); process.exit(2);}
console.log('✅ Release gates 通過：', j);
NODE
