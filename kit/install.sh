#!/bin/bash
# Install the VR-headset display fix for every user (now and future) and the GDM login screen.
# Usage:  sudo ./install.sh            install / update
#         sudo ./install.sh --remove   uninstall
set -e
[ "$(id -u)" = 0 ] || { echo "Run with sudo: sudo $0 $*"; exit 1; }
cd "$(dirname "$0")"

BIN=/usr/local/bin/vr-display-fix.py
DESK=/etc/xdg/autostart/vr-display-fix.desktop
GREETER_DESK=/usr/share/gdm/greeter/autostart/vr-display-fix.desktop
UNIT=/etc/systemd/user/vr-display-fix-greeter.service
DROPIN=/etc/systemd/user/gnome-session@gnome-login.target.d/vr-display-fix.conf

# Older one-machine ASUS fix (fix6.sh / fix7.sh); it would run twice next to this one
rm -f /usr/local/bin/asus-vga-only.sh /etc/xdg/autostart/asus-vga-only.desktop \
      /usr/share/gdm/greeter/autostart/asus-vga-only.desktop \
      /etc/systemd/user/asus-vga-only-greeter.service \
      /etc/systemd/user/gnome-session@gnome-login.target.d/asus-vga-only.conf

if [ "$1" = --remove ]; then
    rm -f "$BIN" "$DESK" "$GREETER_DESK" "$UNIT" "$DROPIN"
    echo "Removed. Log out to go back to the GNOME default layout."
    exit 0
fi

[ -x /usr/bin/python3 ] && /usr/bin/python3 -c 'import gi' || {
    echo "Need the system python3 with gi:  sudo apt install python3-gi"; exit 1; }
install -m 755 vr-display-fix.py "$BIN"

# 1) Every user's desktop session, including accounts created later
cat > "$DESK" <<EOF
[Desktop Entry]
Type=Application
Name=VR headset display fix
Exec=$BIN
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF
chmod 644 "$DESK"

# 2a) Login screen on GNOME 46 and later (Ubuntu 24.10+): the greeter ignores autostart files,
#     so hook a user service into its systemd target
mkdir -p "$(dirname "$DROPIN")"
cat > "$UNIT" <<EOF
[Unit]
Description=Keep the GDM login screen off VR headsets
After=org.gnome.Shell@gdm.service
Requires=org.gnome.Shell@gdm.service

[Service]
Type=oneshot
Environment=DELAY=3
ExecStart=$BIN
EOF
printf '[Unit]\nWants=vr-display-fix-greeter.service\n' > "$DROPIN"
chmod 644 "$UNIT" "$DROPIN"

# 2b) Login screen on older GDM (Ubuntu 22.04 / 24.04) reads this autostart dir
if [ -d /usr/share/gdm/greeter/autostart ]; then
    ln -sf "$DESK" "$GREETER_DESK"
fi

# A user's own ~/.config/autostart entry with the same name would override the system one
for h in /home/*; do rm -f "$h/.config/autostart/vr-display-fix.desktop"; done

echo "Installed:"
ls -l "$BIN" "$DESK" "$UNIT" "$DROPIN" $( [ -L "$GREETER_DESK" ] && echo "$GREETER_DESK" )
echo
echo "Next: log out. The login screen and every account should now use the real monitor."
echo "Check in a desktop terminal:  $BIN --dry-run"
