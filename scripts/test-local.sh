#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 -m py_compile omarchy/bin/omarchy-extra-agent-usage
python3 -m unittest discover -s tests -p 'test_*.py' -v
node --check omarchy/bin/omarchy-copilot-usage
node --check vscode/copilot-quota-bridge/extension.js
jq empty config/raven.agents.shell-entry.json
jq empty omarchy/plugins/raven.agents/manifest.json
python3 - <<'PY'
from pathlib import Path

for path in (Path("README.md"), Path("omarchy/plugins/raven.agents/README.md")):
    text = path.read_text()
    if not any(ord(char) >= 0x1F300 for char in text):
        raise SystemExit(f"{path} must contain a meaningful emoji")
PY

echo "✅ local agent widget checks passed"
