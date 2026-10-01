# VIVE 頭盔搶走桌面螢幕：修正工具

> **實驗室學生機請看 [STUDENT_GUIDE.md](STUDENT_GUIDE.md)**（含環境檢測 `check-env.sh`、建立 `unoq` 帳號 `setup-unoq.sh`、修 Antigravity 沙箱錯誤 `fix-antigravity-sandbox.sh`）。
> 這份 README 是一般說明，適用各種電腦和情況。

適用：Ubuntu（GNOME / Wayland / GDM），電腦同時接一般螢幕和 HTC VIVE 等 VR 頭盔。

## 你是不是遇到這個問題？

- 登入畫面不在一般螢幕上
- 登入後螢幕只有桌布，沒有圖示和面板
- 一般螢幕顯示「No Signal」，但電腦其實已經開機
- 換一個帳號、新建帳號也一樣壞

已在一台 Ubuntu 26.04 + VIVE Cosmos 的電腦重開機實測通過（2026-10-01）。

原因是 GNOME 把 VR 頭盔當成一般螢幕，把桌面輸出到頭盔裡。**新增帳號沒有用**，要安裝這個工具，每台電腦裝一次就好，之後所有帳號（包括新建的）和登入畫面都會自動修好。

## 安裝（需要 sudo 密碼）

### 情況 A：看得到桌面

開終端機：

```bash
sudo apt install -y git python3-gi
git clone https://github.com/cwstedctw/vive-display-fix.git
cd vive-display-fix/kit
sudo ./install.sh
```

然後**重新開機**（或登出），登入畫面應該出現在一般螢幕上。

已經裝過舊版，要更新：`cd vive-display-fix && git pull && cd kit && sudo ./install.sh`

### 情況 B：看不到桌面（畫面在頭盔裡）

1. 按 `Ctrl+Alt+F3`（沒反應就試 F2～F6），用文字模式登入
   - 文字模式不一定出現在你現在看的螢幕上；試著把螢幕線換到主機板（內顯）的接頭，或先拔掉 VIVE
2. 執行上面「情況 A」的同一串指令
3. 執行 `sudo systemctl restart gdm`，回到圖形登入畫面

## 確認有沒有成功

登入後在終端機執行：

```bash
/usr/local/bin/vr-display-fix.py --dry-run
```

正常會看到類似：

```
vr-display-fix: mirror DP-1, DP-4, HDMI-1 at 1920x1080, off: DP-2 (VIVE Cosmos)
```

## 注意

- 接兩台以上一般螢幕時，所有螢幕會**顯示同一個畫面**（鏡像），不是延伸桌面
- 登入**之後**才開 VIVE 或 SteamVR，畫面可能又被搶走：執行 `/usr/local/bin/vr-display-fix.py`，或登出再登入
- SteamVR 裝了這個工具後還能不能正常使用頭盔，**尚未測試**。若抓不到頭盔，先 `sudo ./install.sh --remove` 比較看看

## 移除

```bash
cd vive-display-fix/kit
sudo ./install.sh --remove
```

## 還是不行？用 AI agent 幫忙

在 repo 資料夾開 AI coding agent（Claude Code、Codex 等），跟它說：

> 照 AGENTS.md 幫我診斷這台電腦的 VIVE 螢幕問題

agent 會照 `AGENTS.md` 的步驟檢查。需要 sudo 的指令它會寫給你，**由你自己在終端機執行**。

修好了而且有改程式，請開 issue 回報你改了什麼，讓其他同學也能用。

實驗室學生機的步驟：[STUDENT_GUIDE.md](STUDENT_GUIDE.md)（快速版：[使用說明.txt](使用說明.txt)）

詳細原理和試過但失敗的方法：[docs/GUIDE.md](docs/GUIDE.md)
