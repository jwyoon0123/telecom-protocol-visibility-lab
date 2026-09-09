#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
. "$REPO/tools/load-env.sh"
HOME_IP="${HOME_IP:-10.10.10.54}"

MODE="${1:-status}"

UPF_CFG="/etc/open5gs/upf.yaml"
SGWU_CFG="/etc/open5gs/sgwu.yaml"

UPF_BIN="/usr/local/bin/open5gs-upfd"
SGWU_BIN="/usr/local/bin/open5gs-sgwud"

UPF_LOG="/var/log/open5gs/upf.log"
SGWU_LOG="/var/log/open5gs/sgwu.log"


show_status()
{
    echo "=========================================="
    echo " CORE MODE STATUS"
    echo "=========================================="

    echo
    echo "[PROCESS]"
    pgrep -af 'open5gs-(upfd|sgwud)' || true

    echo
    echo "[UDP/2152]"
    ss -lunp | grep ':2152' || true

    echo
    echo "[UPF CONFIG]"
    grep -nA10 -B3 'gtpu:' "$UPF_CFG" 2>/dev/null || true

    echo
}


patch_upf()
{
    local address="$1"
    local backup
    backup="${UPF_CFG}.pre-mode-switch-$(date +%Y%m%d-%H%M%S)"
    cp -a "$UPF_CFG" "$backup"
    echo "[BACKUP] $backup"

    python3 - "$UPF_CFG" "$address" <<'PY'
from pathlib import Path
import sys
import yaml

cfg = Path(sys.argv[1])
addr = sys.argv[2]

d = yaml.safe_load(cfg.read_text())

servers = d["upf"]["gtpu"]["server"]

if not servers:
    raise SystemExit("UPF GTP-U server config 없음")

servers[0]["address"] = addr

cfg.write_text(
    yaml.safe_dump(
        d,
        sort_keys=False,
        allow_unicode=True
    )
)

print(f"[OK] UPF GTP-U -> {addr}:2152")
PY
}


stop_upf()
{
    pkill -TERM -x open5gs-upfd 2>/dev/null || true
    sleep 2
}


start_upf()
{
    nohup "$UPF_BIN" \
        -c "$UPF_CFG" \
        >"$UPF_LOG" 2>&1 &

    sleep 3

    pgrep -af open5gs-upfd >/dev/null || {
        echo "[FATAL] UPF start failed"
        tail -50 "$UPF_LOG" || true
        exit 1
    }
}


stop_sgwu()
{
    pkill -TERM -x open5gs-sgwud 2>/dev/null || true
    sleep 2
}


start_sgwu()
{
    if pgrep -x open5gs-sgwud >/dev/null; then
        echo "[OK] SGW-U already running"
        return
    fi

    nohup "$SGWU_BIN" \
        -c "$SGWU_CFG" \
        >"$SGWU_LOG" 2>&1 &

    sleep 3

    pgrep -af open5gs-sgwud >/dev/null || {
        echo "[FATAL] SGW-U start failed"
        tail -50 "$SGWU_LOG" || true
        exit 1
    }
}


case "$MODE" in

    5g|5G)
        echo "=========================================="
        echo " SWITCH CORE -> 5G"
        echo "=========================================="

        #
        # LTE SGW-U가 .54:2152를 사용하지 못하도록 먼저 중지
        #
        echo
        echo "[1] STOP LTE SGW-U"
        stop_sgwu

        #
        # 기존 UPF 종료
        #
        echo
        echo "[2] STOP UPF"
        stop_upf

        #
        # UPF를 Home external GTP-U endpoint로 전환
        #
        echo
        echo "[3] UPF -> ${HOME_IP}:2152"
        patch_upf "$HOME_IP"

        #
        # UPF 시작
        #
        echo
        echo "[4] START UPF"
        start_upf

        echo
        echo "[5] VERIFY"

        ss -lunp | grep ':2152' || true

        if ss -lunp | grep -F "${HOME_IP}:2152" | grep -q 'open5gs-upfd'
        then
            echo
            echo "=========================================="
            echo " CORE MODE = 5G"
            echo " UPF = ${HOME_IP}:2152"
            echo " SGW-U = STOP"
            echo "=========================================="
        else
            echo "[FATAL] 5G UPF external UDP/2152 verification failed"
            exit 1
        fi
        ;;


    4g|4G|lte|LTE)
        echo "=========================================="
        echo " SWITCH CORE -> 4G/LTE"
        echo "=========================================="

        #
        # 먼저 UPF를 종료해서 Home external UDP/2152를 해제
        #
        echo
        echo "[1] STOP UPF"
        stop_upf

        #
        # 5G UPF는 loopback으로 이동
        #
        echo
        echo "[2] UPF -> 127.0.0.7"
        patch_upf "127.0.0.7"

        #
        # UPF 재시작
        #
        echo
        echo "[3] START UPF ON LOOPBACK"
        start_upf

        #
        # LTE SGW-U 시작
        #
        echo
        echo "[4] START LTE SGW-U"
        stop_sgwu
        start_sgwu

        echo
        echo "[5] VERIFY"

        ss -lunp | grep ':2152' || true

        if ss -lunp | grep -F "${HOME_IP}:2152" | grep -q 'open5gs-sgwud'
        then
            echo
            echo "=========================================="
            echo " CORE MODE = 4G/LTE"
            echo " SGW-U = ${HOME_IP}:2152"
            echo " UPF   = 127.0.0.7"
            echo "=========================================="
        else
            echo "[FATAL] LTE SGW-U external UDP/2152 verification failed"
            exit 1
        fi
        ;;


    status)
        show_status
        ;;


    *)
        echo "Usage:"
        echo "  $0 5g"
        echo "  $0 4g"
        echo "  $0 status"
        exit 1
        ;;
esac
