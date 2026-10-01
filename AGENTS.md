# Instructions for AI agents

You are helping a student whose Ubuntu PC has a normal monitor and a VR headset (usually an HTC VIVE)
connected. GNOME's mutter treats the headset as a monitor and puts the desktop or the GDM login screen on it.
This repo fixes that. Reply to the student in the language they use (often Traditional Chinese).

## How the fix works

- `kit/vr-display-fix.py` runs in a graphical session. It finds the headset by EDID vendor (`VR_VENDORS`)
  or "VIVE" in the name, turns it off, and mirrors all other monitors through
  `org.gnome.Mutter.DisplayConfig.ApplyMonitorsConfig` (method 1, temporary, re-applied every login).
- `kit/install.sh` installs it system-wide:
  - `/etc/xdg/autostart`: every user, including accounts created later
  - `/etc/systemd/user/vr-display-fix-greeter.service`, plus a drop-in on `gnome-session@gnome-login.target`:
    GDM login screen on GNOME 46+
  - `/usr/share/gdm/greeter/autostart`: login screen on older GDM
- Details and history: `docs/GUIDE.md`.

## Rules

1. **You cannot run `sudo`.** It needs a password you can't type. Write the exact command and ask the student
   to run it in their own terminal, then ask them to paste the output.
2. **Diagnose before changing anything.** Run the steps below first.
3. **Do not retry approaches that already failed** (see `docs/GUIDE.md` section 5):
   - editing or copying `~/.config/monitors.xml`, or putting it in `/etc/xdg` or `/var/lib/gdm3`
   - copying config into each home directory, or creating a new user account as a fix
   - autologin as a workaround
   - GDM greeter autostart files on GNOME 46+ (the greeter ignores them; use the systemd unit)
4. **Always use `/usr/bin/python3`**, never a bare `python3`. Conda/venv Pythons don't have `gi`.
5. **Only change what is needed**, normally `VR_VENDORS` or `SAFE_SIZE` in `kit/vr-display-fix.py`.
   Re-run `sudo ./install.sh` after a change. Don't touch the GPU driver, kernel parameters or Xorg config
   unless the student asks and understands the risk.
6. Don't delete users, home directories or files outside this repo and the paths `install.sh` manages.

## Diagnosis steps

Run these yourself (no sudo needed) from a desktop session:

```bash
cat /etc/os-release | head -3; gnome-shell --version; echo $XDG_SESSION_TYPE
ls /usr/local/bin/vr-display-fix.py /etc/xdg/autostart/vr-display-fix.desktop 2>&1   # installed?
/usr/bin/python3 /usr/local/bin/vr-display-fix.py --dry-run || /usr/bin/python3 kit/vr-display-fix.py --dry-run
journalctl --user -b | grep vr-display-fix
for f in /sys/class/drm/card*-*/status; do echo "$f: $(cat $f)"; done
```

Ask the student to run this one (login screen logs):

```bash
sudo journalctl -b | grep -i vr-display-fix
```

Read the results this way:

| Result | Meaning / next step |
|---|---|
| Not installed | Have the student run `cd kit && sudo ./install.sh`, then log out and back in |
| `No module named 'gi'` | The student runs `sudo apt install python3-gi` |
| `no VR headset connected` but a headset is plugged in | Add the headset's `vendor=` (shown by dry-run) to `VR_VENDORS` |
| Wrong resolution or black screen on one output | Change `SAFE_SIZE`, or check the cable or adapter (VGA adapters often cause "No Signal") |
| Desktop works but the login screen doesn't | Check the greeter log; check that `gnome-session@gnome-login.target` exists on this GNOME version |
| `$XDG_SESSION_TYPE` is `x11` | The script still uses mutter's D-Bus API; if it fails, report it and don't improvise |
| Headset taken back after starting SteamVR | Expected: the script runs only at login. Run it again by hand |

## Verify

After any change: the student logs out, checks that the login screen is on the real monitor, logs in,
and checks for the panel and icons. Then run `--dry-run` again.

## Report back

If you changed the code and it worked, help the student open an issue (or a PR) with:
the distro or GNOME version, the `--dry-run` output, and the diff. Then other students' machines benefit too.
