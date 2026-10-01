#!/usr/bin/python3
# Keep the GNOME desktop (and the GDM login screen) off a VR headset.
#
# mutter treats an HTC VIVE (or other VR headset) as a normal monitor and can
# put the whole desktop on it, so the real monitor shows only a wallpaper or
# "No Signal". This script turns every VR headset off and mirrors all other
# monitors at one shared resolution. It does nothing when no headset is plugged in.
#
# Run it inside a graphical session (autostart / GDM greeter service).
# Uses /usr/bin/python3 on purpose: conda/venv pythons have no "gi" module.
# Test without changing anything:  /usr/local/bin/vr-display-fix.py --dry-run

import os
import sys
import time

import gi
gi.require_version('Gio', '2.0')
from gi.repository import Gio, GLib

# EDID vendor codes of VR headsets: HTC VIVE, Valve Index, Oculus/Meta, Pimax
VR_VENDORS = {'HVR', 'VLV', 'OVR', 'PVR'}
# Resolution tried first when every screen supports it (known good with HDMI->VGA adapters)
SAFE_SIZE = (1920, 1080)

BUS_NAME = 'org.gnome.Mutter.DisplayConfig'
OBJ_PATH = '/org/gnome/Mutter/DisplayConfig'


def log(msg):
    print('vr-display-fix: ' + msg, flush=True)


def is_vr(monitor):
    (connector, vendor, product, serial), _modes, props = monitor
    name = str(props.get('display-name', ''))
    return vendor in VR_VENDORS or 'VIVE' in product.upper() or 'VIVE' in name.upper()


def pick_mode(modes, size):
    """Mode id with this size whose refresh rate is closest to 60 Hz."""
    matches = [m for m in modes if (m[1], m[2]) == size]
    return min(matches, key=lambda m: abs(m[3] - 60.0))[0] if matches else None


def plan(state):
    """Return (logical_monitors, description) for ApplyMonitorsConfig, or None."""
    _serial, monitors, _logical, _props = state
    vr = [m for m in monitors if is_vr(m)]
    screens = sorted((m for m in monitors if not is_vr(m)), key=lambda m: m[0][0])
    if not vr:
        log('no VR headset connected, leaving the layout alone')
        return None
    if not screens:
        log('only a VR headset is connected, nothing to do')
        return None

    sizes = [{(m[1], m[2]) for m in mon[1]} for mon in screens]
    common = set.intersection(*sizes)
    preferred = {(m[1], m[2]) for mon in screens for m in mon[1]
                 if m[6].get('is-preferred', False)}
    if len(preferred) == 1 and preferred <= common:
        size = preferred.pop()
    elif SAFE_SIZE in common:
        size = SAFE_SIZE
    elif common:
        size = max(common, key=lambda s: s[0] * s[1])
    else:
        # No shared resolution: mirror only the screens that can match the first one
        first = screens[0]
        pref = [m for m in first[1] if m[6].get('is-preferred', False)] or first[1]
        size = (pref[0][1], pref[0][2])
        screens = [s for s in screens if pick_mode(s[1], size)]

    outputs = [(s[0][0], pick_mode(s[1], size), {}) for s in screens]
    logical = [(0, 0, 1.0, 0, True, outputs)]
    desc = 'mirror %s at %dx%d, off: %s' % (
        ', '.join(o[0] for o in outputs), size[0], size[1],
        ', '.join('%s (%s)' % (m[0][0], m[0][2]) for m in vr))
    return logical, desc


def main():
    dry_run = '--dry-run' in sys.argv
    time.sleep(0 if dry_run else float(os.environ.get('DELAY', '3')))
    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)

    # mutter may still be starting (especially on the login screen)
    for _ in range(30):
        try:
            state = bus.call_sync(BUS_NAME, OBJ_PATH, BUS_NAME, 'GetCurrentState',
                                  None, None, Gio.DBusCallFlags.NONE, -1, None).unpack()
            break
        except GLib.Error:
            time.sleep(1)
    else:
        log('mutter DisplayConfig not available, giving up')
        return 1

    if dry_run:
        for (connector, vendor, product, _s), _modes, _p in state[1]:
            log('found %s  vendor=%s  product=%s' % (connector, vendor, product))
    result = plan(state)
    if result is None:
        return 0
    logical, desc = result
    log(desc)
    if dry_run:
        return 0

    # method 1 = temporary: applied for this session only, no confirmation dialog
    args = GLib.Variant('(uua(iiduba(ssa{sv}))a{sv})', (state[0], 1, logical, {}))
    bus.call_sync(BUS_NAME, OBJ_PATH, BUS_NAME, 'ApplyMonitorsConfig',
                  args, None, Gio.DBusCallFlags.NONE, -1, None)
    return 0


if __name__ == '__main__':
    sys.exit(main())
