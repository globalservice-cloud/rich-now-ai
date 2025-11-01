#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

node - <<'NODE'
const fs=require('fs');
const root=process.env.ROOT_DIR || process.cwd();
function load(p){try{return JSON.parse(fs.readFileSync(p,'utf8'))}catch(e){return null}}
const out = `${root}/ai/outputs`;
const rfc=load(`${out}/rfc.json`);
const adr=load(`${out}/adr.json`);
const qa=load(`${out}/qa-report.json`);
const gates=load(`${out}/release-gates.json`);
const lines=[];
lines.push('# Weekly Status (Local)');
lines.push('*Generated:* '+new Date().toISOString());
if(rfc){lines.push('## RFC','- **Title**: '+(rfc.title||''),'- **Milestones**: '+JSON.stringify(rfc.milestones||[]));}
if(adr){lines.push('## ADR','- **Decision**: '+(adr.decision||''));}
if(qa){lines.push('## QA','- **Coverage**: '+qa.coverage+'%','- **Result**: '+qa.result);}
if(gates){lines.push('## Release Gates','- dataQuality: '+gates.dataQuality,'- tests: '+gates.tests,'- slo: '+gates.slo,'- signoff: '+gates.signoff,'- flagStrategy: '+gates.flagStrategy);}
fs.writeFileSync(`${root}/STATUS.md`,lines.join('\n'));
console.log('✅ 已產生 STATUS.md');
NODE
