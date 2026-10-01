# VIVE 頭盔搶走桌面螢幕：解決指南

適用：Ubuntu 26.04（GNOME 50 / Wayland / GDM），電腦同時接一般螢幕和 HTC VIVE（Cosmos 等）VR 頭盔。
第一次處理日期：2026-09-23（螢幕經 HDMI→VGA 轉接的機器）。
最後更新：2026-10-01，用 GitHub 版 kit 重開機實測通過（見第 8 節）。

---

## 1. 症狀

- 登入畫面不在一般螢幕上，或螢幕只出現桌布、沒有圖示和面板
- 一般螢幕顯示「No Signal」，但電腦其實已經開機並登入
- 帳號 A 修好之後，新建的帳號 B 登入後又壞掉
- 登入後正常，登出回到登入畫面時又壞掉

## 2. 原因

GNOME 的顯示管理程式 mutter 把 VIVE 頭盔當成一般螢幕。它常常只用頭盔當顯示器，
一般螢幕就沒有畫面。畫面其實有輸出，只是輸出到頭盔裡。

更麻煩的是這個設定有三個地方要處理，每個地方都要各自修：

| 地方 | 誰在用 | 會讀 `~/.config/monitors.xml` 嗎 |
|---|---|---|
| 每個使用者的桌面 | 每個帳號（包括之後新建的） | 理論上會，但 mutter 看到頭盔時常常不理它 |
| GDM 登入畫面 | 系統帳號 `gdm-greeter`（動態 uid） | 另有一份，一樣不可靠 |
| 文字終端 (Ctrl+Alt+F3) | 核心 | 不會，這台固定只輸出到 Intel 顯示卡 |

## 3. 解法（每台機器做一次）

`kit/` 資料夾內兩個檔案：

- `vr-display-fix.py`：登入時自動執行。找出 VR 頭盔（EDID 廠商 `HVR`、`VLV`、`OVR`、`PVR`，或名稱含 VIVE）把它關掉，
  其他螢幕全部以同一解析度鏡像顯示。沒接頭盔時完全不動作。不需要寫死接頭名稱，每台機器都可以用。
- `install.sh`：安裝到系統，讓**所有帳號（包括之後建立的學生帳號）和登入畫面**都自動套用。

### 安裝步驟

1. 開一般終端機（不是在 Claude Code 裡，因為 `sudo` 要輸入密碼），下載並安裝：

   ```bash
   sudo apt install -y git python3-gi
   git clone https://github.com/cwstedctw/vive-display-fix.git
   cd vive-display-fix/kit
   sudo ./install.sh
   ```

   沒有網路時，把 `kit/` 資料夾用 USB 複製過去，在裡面執行 `sudo ./install.sh` 也可以
2. 重新開機（或登出）。登入畫面應該出現在一般螢幕上
3. 登入任一帳號，確認有桌面圖示和面板
4. （選擇性）在桌面的終端機執行下面指令，確認它看到的螢幕是對的：

   ```bash
   /usr/local/bin/vr-display-fix.py --dry-run
   ```

   正常輸出例如：
   `vr-display-fix: mirror DP-1, DP-4, HDMI-1 at 1920x1080, off: DP-2 (VIVE Cosmos)`

5. 更新到新版：`cd vive-display-fix && git pull && cd kit && sudo ./install.sh`

### 安裝了哪些東西

| 檔案 | 作用 |
|---|---|
| `/usr/local/bin/vr-display-fix.py` | 修正程式本身 |
| `/etc/xdg/autostart/vr-display-fix.desktop` | 每個帳號登入桌面時執行（新帳號也會自動有） |
| `/etc/systemd/user/vr-display-fix-greeter.service` | GDM 登入畫面執行（GNOME 46 以後） |
| `/etc/systemd/user/gnome-session@gnome-login.target.d/vr-display-fix.conf` | 讓登入畫面啟動上面那個 service |
| `/usr/share/gdm/greeter/autostart/vr-display-fix.desktop` | 舊版 GDM（Ubuntu 22.04/24.04）的登入畫面用 |

移除：`sudo ./install.sh --remove`，再登出。

## 4. 學生自己建立帳號

裝好之後不需要再為新帳號做任何事。`/etc/xdg/autostart` 對所有帳號生效，包括之後才建立的帳號。

- 建議**關掉自動登入**，讓學生從登入畫面選自己的帳號：
  `/etc/gdm3/custom.conf` 中設 `AutomaticLoginEnable=False`
- 建立帳號：`sudo adduser 學號`，或 設定 → 系統 → 使用者 → 新增使用者
- 若要讓學生不用管理員就能自己建帳號，需要另外給 sudo 權限或建帳號的程式，這不在這份指南範圍內

## 5. 走過的彎路（不要再試）

這些都試過，**沒有用或不夠**：

| 做法 | 為什麼不行 |
|---|---|
| 在「設定 → 顯示器」調好，存成 `~/.config/monitors.xml` | 只對這個帳號有效，而且重開機後 mutter 看到頭盔又不理它 |
| 複製 `monitors.xml` 到 `/etc/xdg/`、`/var/lib/gdm3/seat0/config/` | 同上；而且檔案綁定螢幕序號，換一台機器就對不上 |
| 複製設定檔到每個使用者家目錄 | 新帳號沒有；要一直補 |
| 設定自動登入某個帳號 | 只是繞過登入畫面，其他帳號還是壞的 |
| 把 autostart 放在 `/usr/share/gdm/greeter/autostart` | GNOME 50 的登入畫面不讀這個資料夾，要用 systemd user service（install.sh 已處理） |
| 只開 VGA 轉接的那一個輸出 | 有些 HDMI→VGA 轉接器在單獨輸出時黑畫面；鏡像到所有輸出才穩定 |
| 使用者自己的 `~/.config/autostart/` 裡放同名檔案 | 會蓋掉系統版本，install.sh 會刪掉 |

## 6. 仍然有問題時

1. **先確認硬體**：換一條線或直接接 HDMI/DP。VGA 轉接器很常是「No Signal」的原因。
2. **看程式有沒有執行**：
   ```bash
   journalctl --user -b | grep vr-display-fix          # 桌面
   sudo journalctl -b | grep -i vr-display-fix          # 登入畫面
   ```
3. **`No module named 'gi'`**：程式固定用 `/usr/bin/python3`，不要改成 `python3`。
   有裝 Anaconda 的帳號，`python3` 會指到 conda，沒有 `gi`。缺套件就執行 `sudo apt install python3-gi`。
4. **頭盔沒被認出**（dry-run 顯示 `no VR headset connected`）：dry-run 會先列出每個接頭的
   `vendor=`，把頭盔的廠商代碼加進 `vr-display-fix.py` 的 `VR_VENDORS`，再執行一次 `sudo ./install.sh`。
5. **鏡像的解析度不對**：改 `vr-display-fix.py` 裡的 `SAFE_SIZE`。
6. **暫時救急**（看不到畫面時）：Ctrl+Alt+F3 登入文字模式（這台只會出現在 Intel 輸出上），
   `sudo ./install.sh --remove`，或拔掉 VIVE 再 `sudo systemctl restart gdm`。

## 7. 關於 VR 使用

程式只在桌面（GNOME）裡關掉頭盔，沒有停用顯示卡接頭。SteamVR 在 Wayland 上能不能照常直接輸出到頭盔，**這次沒有測試**。
如果 VR 程式抓不到頭盔，先 `sudo ./install.sh --remove` 比較看看。

## 8. 測試紀錄

| 日期 | 機器 | 結果 |
|---|---|---|
| 2026-09-23 | 第一台（ASUS VG255，VGA 經 HDMI→VGA 轉接，VIVE Cosmos） | 舊版單機修正（`asus-vga-only.sh`）可用 |
| 2026-10-01 | 同一台，改裝 GitHub 版 kit，**重新開機**、關閉自動登入 | 通過，見下方 |

2026-10-01 重開機後確認的項目：

- 舊版 `asus-vga-only` 檔案已被 `install.sh` 移除，不會重複執行
- 登入畫面：開機約 40 秒後 `vr-display-fix-greeter.service` 執行，畫面出現在一般螢幕
- 登入桌面後 autostart 再執行一次，有圖示和面板
- 兩次都輸出 `mirror DP-1, DP-4, HDMI-1 at 1920x1080, off: DP-2 (VIVE Cosmos)`，
  `/sys/class/drm` 顯示 DP-2（VIVE）為 disabled

尚未測試：其他學生機（不同顯示卡或螢幕）、新建帳號第一次登入、SteamVR。
在新機器測試後，請把結果加到上表（開 issue 或 PR）。
