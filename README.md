# Logitech StreamCam Linux Fixes

Fixes and workarounds for the **Logitech StreamCam** (046d:0893) on Ubuntu/GNOME with Wayland + PipeWire.

## The Problem

The StreamCam exposes both UVC video and UAC audio interfaces over USB 3.0. On Ubuntu with Wayland and PipeWire, the mic can stop working when PipeWire's camera portal interferes with audio routing — especially after adding a PipeWire screen capture source in OBS.

WirePlumber logs:
```
Failed to call Lookup: GDBus.Error:org.freedesktop.portal.Error.NotFound: No entry for camera
```

The mic's PipeWire node gets orphaned — it still exists, but no application can connect to it.

## Issues & Fixes

### 1. Mic stops working after adding PipeWire screen capture to OBS

**Problem**: StreamCam mic works in veadotube, but stops working in both veadotube AND OBS after adding a PipeWire screen capture source. The PipeWire portal's session management interferes with existing audio node connections.

**Fix**: Restart the PipeWire stack to clear stale node connections:
```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

The included `fix-mic.sh` script automates this — it tests the mic first, and only resets if needed.

### 2. USB reset permission denied

**Problem**: `usbreset "Logitech StreamCam"` fails with `Permission denied` as a normal user.

**Fix**: Use `pkexec usbreset` (polkit prompt), or reset via sysfs as root:
```bash
# Find the device
for dev in /sys/bus/usb/devices/*/product; do
    grep -q "StreamCam" "$dev" 2>/dev/null && echo "$(dirname $dev)"
done

# Toggle authorized flag to force re-enumeration
echo 0 > /sys/bus/usb/devices/<device>/authorized
echo 1 > /sys/bus/usb/devices/<device>/authorized
```

The included `reset-usb-sudo.sh` automates this.

### 3. OBS uses wrong /dev/video node

**Problem**: The StreamCam exposes two V4L2 nodes — `/dev/video0` (main capture) and `/dev/video1` (metadata). OBS can pick the wrong one, resulting in no video.

**Fix**: Always select `/dev/video0` in OBS. Check with:
```bash
v4l2-ctl --list-devices
```

## Scripts

| Script | Purpose |
|--------|---------|
| `fix-mic.sh` | Tests mic, resets USB + restarts PipeWire if broken |
| `reset-usb-sudo.sh` | Root-level USB reset via sysfs when `pkexec` isn't available |

### fix-mic.sh

```bash
# Test and fix mic automatically
./fix-mic.sh

# Just test without resetting
./fix-mic.sh --no-reset
```

### reset-usb-sudo.sh

```bash
# When fix-mic.sh can't reset via pkexec
sudo ./reset-usb-sudo.sh
```

## Quick Troubleshooting

```bash
# Test if mic works
timeout 1 pw-record --target "$(wpctl status | grep -A5 'Sources:' | \
    grep StreamCam | grep -oP '^\s*\*?\s*\K\d+')" /tmp/test.wav

# Restart PipeWire stack
systemctl --user restart pipewire pipewire-pulse wireplumber

# Reset USB device (needs elevated privs)
pkexec usbreset "Logitech StreamCam"

# Check camera and audio devices
v4l2-ctl --list-devices
wpctl status
```

## Environment

Tested on:
- Ubuntu 24.04 LTS (Wayland, GNOME, PipeWire)
- Kernel 6.8 and 6.17 (HWE)
- OBS Studio with PipeWire screen capture

## Related

This is part of a series of USB bug investigations on Linux. See the full write-up: [The USB Bug Quartet: Phantom I/O, Camera Crashes, and Kernel Accounting Lies](https://jphein.com/the-usb-bug-trilogy-phantom-i-o-camera-crashes-and-kernel-accounting-lies/)

## License

MIT
