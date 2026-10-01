#!/bin/bash
# Let Google Antigravity (Electron) use its sandbox on Ubuntu 24.04+.
# Ubuntu blocks unprivileged user namespaces (kernel.apparmor_restrict_unprivileged_userns=1)
# unless an AppArmor profile allows them, as /etc/apparmor.d/code does for VS Code.
# This adds the same kind of profile for Antigravity, for every user (new accounts too).
# Usage:  sudo ./fix-antigravity-sandbox.sh [path/to/antigravity]    (install Antigravity first)
set -e
[ "$(id -u)" = 0 ] || { echo "Run with sudo: sudo $0 $*"; exit 1; }

BIN="$1"
if [ -z "$BIN" ]; then
    for c in "$(readlink -f "$(command -v antigravity 2>/dev/null)" 2>/dev/null)" \
             /usr/share/antigravity/antigravity /opt/Antigravity/antigravity /opt/antigravity/antigravity; do
        [ -n "$c" ] && [ -x "$c" ] && [ -f "$c" ] && { BIN="$c"; break; }
    done
fi
case "$BIN" in /home/*)
    echo "Antigravity is in a home folder ($BIN): other users can't run it."
    echo "Install the system package (apt) instead, then run this again."; exit 1;;
esac
[ -n "$BIN" ] && [ -x "$BIN" ] || { echo "Antigravity not found. Install it first, or pass its path."; exit 1; }
echo "Antigravity binary: $BIN"

PROFILE=/etc/apparmor.d/antigravity
cat > "$PROFILE" <<EOF
# Allow Antigravity's Electron sandbox to create user namespaces (added by fix-antigravity-sandbox.sh)
abi <abi/4.0>,
include <tunables/global>

profile antigravity "$BIN" flags=(unconfined) {
  userns,

  include if exists <local/antigravity>
}
EOF
chmod 644 "$PROFILE"
apparmor_parser -r "$PROFILE"
echo "Loaded $PROFILE"
aa-status 2>/dev/null | grep -w antigravity || true

# Older Electron builds fall back to the setuid helper; it must be root-owned and mode 4755
SANDBOX="$(dirname "$BIN")/chrome-sandbox"
if [ -f "$SANDBOX" ]; then
    chown root:root "$SANDBOX"; chmod 4755 "$SANDBOX"
    ls -l "$SANDBOX"
fi
echo "Done. Start Antigravity normally (no --no-sandbox needed), as any user."
echo "Undo: sudo apparmor_parser -R $PROFILE && sudo rm $PROFILE"
