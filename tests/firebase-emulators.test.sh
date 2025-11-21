#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f firebase.json ]]; then
  echo "firebase.jsonが見つかりません"
  exit 1
fi

python3 - <<'PY'
import json
import sys
from pathlib import Path

path = Path("firebase.json")
data = json.loads(path.read_text())

emulators = data.get("emulators")
if not isinstance(emulators, dict):
    print("emulatorsセクションがありません")
    sys.exit(1)

expected_ports = {
    "auth": 9099,
    "firestore": 8080,
    "storage": 9199,
    "pubsub": 8085,
    "ui": 4000,
}

for name, port in expected_ports.items():
    cfg = emulators.get(name)
    if not isinstance(cfg, dict):
        print(f"{name}エミュレーター設定がありません")
        sys.exit(1)
    if cfg.get("port") != port:
        print(f"{name}エミュレーターのポートが不一致: expected {port}, got {cfg.get('port')}")
        sys.exit(1)

print("emulator config OK")
PY
