#!/bin/bash
# Script to create user 'unoq' and disable autologin for 'csie'
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)."
    echo "Usage: sudo $0"
    exit 1
fi

echo "=== 1. Creating user 'unoq' ==="
NEW_USER=false
if id "unoq" &>/dev/null; then
    echo "User 'unoq' already exists. Updating groups..."
    usermod -aG sudo,adm,plugdev unoq
else
    useradd -m -s /bin/bash -G sudo,adm,plugdev unoq
    echo "User 'unoq' created successfully."
    NEW_USER=true
fi

echo "=== 2. Setting password for 'unoq' ==="
# The password is not stored in this public repo: type the one your teacher gave you
if [ "$NEW_USER" = true ]; then
    until passwd unoq; do echo "Try again."; done
else
    echo "Kept the existing password. To change it: sudo passwd unoq"
fi

echo "=== 3. Disabling autologin for 'csie' ==="
for conf in /etc/gdm3/custom.conf /etc/gdm/custom.conf; do
    if [ -f "$conf" ]; then
        sed -i 's/^AutomaticLoginEnable[[:space:]]*=[[:space:]]*[Tt]rue/#AutomaticLoginEnable=True/' "$conf"
        sed -i 's/^AutomaticLogin[[:space:]]*=[[:space:]]*csie/#AutomaticLogin=csie/' "$conf"
        echo "Autologin disabled in $conf."
    fi
done

echo
echo "=== Verification ==="
echo "User unoq details:"
id unoq
if id -nG unoq | grep -qw sudo && sudo -l -U unoq | grep -q '(ALL'; then
    echo "OK: unoq has sudo rights (takes effect at unoq's next login)."
else
    echo "ERROR: unoq has no sudo rights. Check: sudo -l -U unoq"
    exit 1
fi
echo
echo "Autologin configuration in /etc/gdm3/custom.conf:"
grep -E "AutomaticLogin" /etc/gdm3/custom.conf 2>/dev/null || true

echo
echo "=========================================================="
echo "Setup complete!"
echo "To test, restart GDM or reboot the computer:"
echo "    sudo systemctl restart gdm"
echo "  or"
echo "    sudo reboot"
echo "=========================================================="
