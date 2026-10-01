# VR 頭盔搶螢幕修復與環境檢測指南 (學生操作手冊)

這份手冊放在隨身碟 `VR-Display-Fix` 目錄中（內容和 GitHub repo https://github.com/cwstedctw/vive-display-fix 相同），專門供實驗室同學解決 **「電腦接上 HTC VIVE / VR 頭盔後，一般螢幕黑屏、顯示 No Signal，或桌面圖示被移到頭盔內部」** 的問題。

---

## 為什麼會發生這個問題？

Ubuntu 的 GNOME 桌面環境（Mutter 視窗管理員）會把顯卡上接的所有輸出孔（HDMI / DisplayPort）都當成一般電腦螢幕。
當 HTC VIVE 頭盔插在顯卡上時，GNOME 經常把它誤判為「主要螢幕」，導致：
- 開機後的 GDM 登入畫面只出現在頭盔裡，螢幕呈現黑屏或 No Signal。
- 登入進入桌面後，主要螢幕只看得到桌布，活動面板和桌面圖示全都在頭盔裡。
- **單純建立新帳號無法解決**，因為新帳號登入時一樣會被 GNOME 重新分配到頭盔。

本工具能自動辨識 HTC VIVE 等常見 VR 頭盔，將頭盔輸出關閉，並將桌面完整鏡像/導向實體螢幕。

---

## 隨身碟檔案清單

隨身碟路徑：`/run/media/<你的使用者名稱>/Toshiba/VR-Display-Fix/`

| 檔案/資料夾 | 說明 |
|---|---|
| **`check-env.sh`** | **一鍵環境診斷工具**（無需 sudo，直接執行可檢查螢幕、頭盔連線狀態與安裝進度） |
| **`setup-unoq.sh`** | **帳號設定工具**（自動建立 `unoq` 帳號、執行時輸入密碼，具備 sudo 權限，並關閉 `csie` 自動登入） |
| **`kit/install.sh`** | **系統級修復安裝檔**（需要 sudo，會修復 GDM 登入畫面與所有現存及未來帳號） |
| **`kit/vr-display-fix.py`** | 核心偵測與 Mutter D-Bus 螢幕排程程式 |
| **`AGENTS.md`** | 供 AI 輔助排查的診斷指引 |

---

## 兩個設定，順序不能換

| 順序 | 做什麼 | 指令 | 一定要做嗎 |
|---|---|---|---|
| **第一個** | **修好 GUI 登入畫面**：登入畫面和所有帳號的桌面都回到一般螢幕 | `cd kit && sudo ./install.sh` | 必要 |
| **第二個** | **新增使用者**：建立學生帳號 `unoq`，並關掉 `csie` 自動登入 | `sudo ./setup-unoq.sh` | 選用 |

先做第一個。第一個修好之後，第二個新增的帳號（包括以後再建的任何帳號）登入時會自動套用修正，不用再另外處理。
只做第二個沒有用：新帳號登入時畫面一樣會被頭盔搶走。

---

## 如何在另一台電腦上使用？

### 步驟 1：取得工具並進入終端機

**沒有隨身碟時**，直接從 GitHub 下載，然後跳到步驟 2：

```bash
sudo apt install -y git python3-gi
git clone https://github.com/cwstedctw/vive-display-fix.git
cd vive-display-fix
```

**用隨身碟時**：
開啟終端機（快捷鍵 `Ctrl + Alt + T`），切換到隨身碟目錄：

```bash
cd /run/media/$USER/Toshiba/VR-Display-Fix
# 或者如果隨身碟自動掛載在 /media/：
# cd /media/$USER/Toshiba/VR-Display-Fix
```

---

### 步驟 2：執行環境診斷（無需 sudo）

```bash
./check-env.sh
```

- 檢查輸出中的 `[2/6]` 是否有偵測到 2 個輸出埠（例如 `DP-2` 與 `HDMI-2`）。
- 檢查 `[5/6]` 是否能成功識別 `mirror ... off: DP-2 (VIVE Cosmos)`。
- 若 `[3/6]` 顯示缺少 `python3-gi`，請先安裝依賴：
  ```bash
  sudo apt update && sudo apt install -y python3-gi
  ```

---

### 步驟 3：【第一個設定】修好 GUI 登入畫面（需 sudo）

直接執行隨身碟內的安裝腳本：

```bash
cd kit
sudo ./install.sh
cd ..
```

安裝腳本會自動將修復程式註冊到：
1. `/etc/xdg/autostart/`：使所有帳號（包括新建帳號）登入時自動修復螢幕。
2. `/etc/systemd/user/vr-display-fix-greeter.service`：使 Ubuntu 24.10 / 26.04+ GDM 登入畫面自動顯示在實體螢幕上。

---

### 步驟 4：【第二個設定，選用】新增使用者 `unoq` 並關閉舊帳號自動登入

若該電腦需要設定為學生專用帳號 `unoq`：

```bash
sudo ./setup-unoq.sh
```

- 帳號名稱：`unoq`
- 密碼：執行時會要求輸入兩次，請用老師提供的密碼（這個 repo 是公開的，所以不寫在這裡）
- 具備 `sudo`、`adm` 管理者群組。
- 自動將 `/etc/gdm3/custom.conf` 中的自動登入註解關閉。

---

### 步驟 5：登出或重新開機測試

```bash
sudo reboot
# 或
sudo systemctl restart gdm
```

重開機後：
1. 實體螢幕上應正常顯示 GDM 登入畫面。
2. 選擇帳號登入後，面板與圖示皆應正常顯示在螢幕上。

---

## 常見問題與應變措施

### Q1：開機後實體螢幕完全看不到桌面（黑屏 / 畫面已被頭盔搶走），無法開終端機？
1. 按鍵盤快捷鍵 `Ctrl + Alt + F3`（若沒反應可嘗試 `F2` ~ `F6`）切換到純文字終端機（TTY）。
2. 輸入使用者名稱與密碼登入。
3. 執行安裝：
   ```bash
   cd /run/media/$USER/Toshiba/VR-Display-Fix/kit
   sudo ./install.sh
   sudo systemctl restart gdm
   ```
4. 即可恢復圖形介面。

### Q2：登入後打開 SteamVR，螢幕畫面又跑掉了？
修復腳本預設是在「登入時」執行一次。如果啟動 VR 軟體後頭盔又搶走畫面，只需在一般終端機再次手動執行：
```bash
/usr/local/bin/vr-display-fix.py
```
或直接登出後重新登入即可。

### Q3：如何完全移除本工具？
若未來不需要此修復，在隨身碟目錄執行：
```bash
cd kit
sudo ./install.sh --remove
```
