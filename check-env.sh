#!/bin/bash
# ==============================================================================
# VR-Display-Fix 環境診斷工具 (check-env.sh)
# 供實驗室同學快速檢測電腦的 VR 頭盔 (VIVE) 與桌面螢幕環境狀態
# 無需 sudo，直接執行即可： ./check-env.sh
# ==============================================================================

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}${BOLD}====================================================================${NC}"
echo -e "${CYAN}${BOLD}       VR 頭盔搶螢幕問題 - 環境診斷工具 (check-env.sh)               ${NC}"
echo -e "${CYAN}${BOLD}====================================================================${NC}"
echo

# 1. 系統資訊檢查
echo -e "${BLUE}${BOLD}[1/6] 檢測作業系統與桌面環境${NC}"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo -e "  - 作業系統: ${GREEN}${PRETTY_NAME}${NC}"
else
    echo -e "  - 作業系統: ${YELLOW}未知${NC}"
fi

GNOME_VER=$(gnome-shell --version 2>/dev/null || echo "未安裝或不在圖形終端中")
echo -e "  - GNOME 版本: ${GREEN}${GNOME_VER}${NC}"

SESSION_TYPE=${XDG_SESSION_TYPE:-"未知 (可能非桌面 session)"}
echo -e "  - 視窗協定 (Session): ${GREEN}${SESSION_TYPE}${NC}"
echo

# 2. 檢測顯示連接埠
echo -e "${BLUE}${BOLD}[2/6] 檢測實體視訊輸出埠 (DRM Connectors)${NC}"
CONNECTED_PORTS=0
for status_file in /sys/class/drm/card*-*/status; do
    if [ -f "$status_file" ]; then
        STATUS=$(cat "$status_file")
        PORT_NAME=$(basename "$(dirname "$status_file")" | sed 's/card[0-9]*-//')
        if [ "$STATUS" = "connected" ]; then
            CONNECTED_PORTS=$((CONNECTED_PORTS + 1))
            echo -e "  - ${GREEN}[已連接]${NC} ${BOLD}${PORT_NAME}${NC}"
        fi
    fi
done

if [ "$CONNECTED_PORTS" -eq 0 ]; then
    echo -e "  - ${YELLOW}警告: 未偵測到已連線的顯示輸出！${NC}"
elif [ "$CONNECTED_PORTS" -eq 1 ]; then
    echo -e "  - 提示: 目前僅偵測到 1 個連線螢幕（若頭盔已插上但沒列出，請檢查連接線或電源轉接盒）。"
else
    echo -e "  - 提示: 偵測到 ${CONNECTED_PORTS} 個輸出設備（通常是 1 台一般螢幕 + 1 個 VR 頭盔）。"
fi
echo

# 3. 檢測 Python 模組
echo -e "${BLUE}${BOLD}[3/6] 檢測 Python3 與 GObject 依賴套件 (python3-gi)${NC}"
if [ -x /usr/bin/python3 ]; then
    if /usr/bin/python3 -c "import gi; gi.require_version('Gio', '2.0')" 2>/dev/null; then
        echo -e "  - python3-gi: ${GREEN}[正常] 系統 Python3 包含 Gio 與 gi 模組${NC}"
    else
        echo -e "  - python3-gi: ${RED}[缺少] 找不到 gi 模組！${NC}"
        echo -e "    請先執行: ${YELLOW}sudo apt install -y python3-gi${NC}"
    fi
else
    echo -e "  - /usr/bin/python3: ${RED}[未找到]${NC}"
fi
echo

# 4. 檢測 vr-display-fix 安裝狀態
echo -e "${BLUE}${BOLD}[4/6] 檢測 vr-display-fix 安裝狀態${NC}"
INSTALLED=true
if [ -f /usr/local/bin/vr-display-fix.py ]; then
    echo -e "  - 核心腳本: ${GREEN}[已安裝]${NC} /usr/local/bin/vr-display-fix.py"
else
    echo -e "  - 核心腳本: ${RED}[未安裝]${NC} /usr/local/bin/vr-display-fix.py"
    INSTALLED=false
fi

if [ -f /etc/xdg/autostart/vr-display-fix.desktop ]; then
    echo -e "  - 使用者自啟: ${GREEN}[已安裝]${NC} /etc/xdg/autostart/vr-display-fix.desktop"
else
    echo -e "  - 使用者自啟: ${RED}[未安裝]${NC} /etc/xdg/autostart/vr-display-fix.desktop"
    INSTALLED=false
fi

if [ -f /etc/systemd/user/vr-display-fix-greeter.service ]; then
    echo -e "  - 登入畫面自啟: ${GREEN}[已安裝]${NC} /etc/systemd/user/vr-display-fix-greeter.service"
else
    echo -e "  - 登入畫面自啟: ${YELLOW}[未設定]${NC} (若為 GNOME 46+ 需要此項以修復登入畫面)"
fi
echo

# 5. Mutter DisplayConfig 模擬排程 (Dry-run)
echo -e "${BLUE}${BOLD}[5/6] 執行螢幕佈局識別模擬 (Dry-Run)${NC}"
SCRIPT_PATH=""
if [ -f /usr/local/bin/vr-display-fix.py ]; then
    SCRIPT_PATH="/usr/local/bin/vr-display-fix.py"
elif [ -f "$DIR/kit/vr-display-fix.py" ]; then
    SCRIPT_PATH="$DIR/kit/vr-display-fix.py"
fi

if [ -n "$SCRIPT_PATH" ]; then
    DRY_RUN_OUT=$(/usr/bin/python3 "$SCRIPT_PATH" --dry-run 2>&1 || true)
    echo "$DRY_RUN_OUT" | while IFS= read -r line; do
        if echo "$line" | grep -qi "mirror"; then
            echo -e "  ${GREEN}▶ $line${NC}"
        elif echo "$line" | grep -qi "found"; then
            echo -e "  - $line"
        elif echo "$line" | grep -qi "no VR headset"; then
            echo -e "  ${YELLOW}▶ $line${NC}"
        else
            echo -e "  $line"
        fi
    done
else
    echo -e "  ${RED}錯誤: 找不到 vr-display-fix.py 腳本${NC}"
fi
echo

# 6. GDM 自動登入設定檢查
echo -e "${BLUE}${BOLD}[6/6] 檢測 GDM 自動登入狀態 (/etc/gdm3/custom.conf)${NC}"
GDM_CONF="/etc/gdm3/custom.conf"
[ -f "$GDM_CONF" ] || GDM_CONF="/etc/gdm/custom.conf"

if [ -f "$GDM_CONF" ]; then
    AUTOLOGIN_ACTIVE=$(grep -E "^[[:space:]]*AutomaticLoginEnable[[:space:]]*=[[:space:]]*[Tt]rue" "$GDM_CONF" || true)
    AUTOLOGIN_USER=$(grep -E "^[[:space:]]*AutomaticLogin[[:space:]]*=" "$GDM_CONF" || true)
    if [ -n "$AUTOLOGIN_ACTIVE" ]; then
        echo -e "  - 自動登入狀態: ${RED}[啟用中]${NC} -> $AUTOLOGIN_USER"
        echo -e "    建議使用 setup-unoq.sh 關閉自動登入，避免開機直接跳過帳號選擇。"
    else
        echo -e "  - 自動登入狀態: ${GREEN}[已關閉 / 註解]${NC} 開機會正常停在 GDM 登入選單"
    fi
else
    echo -e "  - GDM 設定檔: 未找到"
fi
echo

# 總結建議
echo -e "${CYAN}${BOLD}====================================================================${NC}"
echo -e "${BOLD}                     診斷總結與操作建議                             ${NC}"
echo -e "${CYAN}${BOLD}====================================================================${NC}"

if [ "$INSTALLED" = true ]; then
    echo -e "${GREEN}✔ 此電腦已正確安裝 VR 顯示修復腳本！${NC}"
    echo -e "  - 若畫面突然又被搶走，可手動執行: ${BOLD}/usr/local/bin/vr-display-fix.py${NC}"
else
    echo -e "${YELLOW}✘ 此電腦尚未安裝修復腳本！若開機畫面跑到頭盔裡，請執行：${NC}"
    echo -e "    ${BOLD}cd \"$DIR/kit\" && sudo ./install.sh${NC}"
    echo -e "    安裝完成後登出或重開機即可。"
fi

echo -e "  - 若需要建立 unoq 學生專用帳號並關閉 csie 自動登入，請執行："
echo -e "    ${BOLD}sudo \"$DIR/setup-unoq.sh\"${NC}"
echo -e "${CYAN}====================================================================${NC}"
