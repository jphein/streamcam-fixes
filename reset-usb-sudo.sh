#!/bin/bash
# Run this with sudo when fix-mic.sh can't reset the USB device
# Usage: sudo ./reset-usb-sudo.sh

echo "Resetting Logitech StreamCam USB device..."
usbreset "Logitech StreamCam" 2>/dev/null || {
    # Try by vendor:product ID if name doesn't work
    for dev in /sys/bus/usb/devices/*/product; do
        if grep -q "StreamCam" "$dev" 2>/dev/null; then
            devpath=$(dirname "$dev")
            echo "Found StreamCam at $devpath"
            echo "1" > "$devpath/authorized"
            echo "0" > "$devpath/authorized"
            echo "1" > "$devpath/authorized"
            echo "USB device reset via sysfs"
            break
        fi
    done
}

echo "Restarting PipeWire for user jp..."
sudo -u jp systemctl --user restart pipewire pipewire-pulse wireplumber

echo "Done! StreamCam should be reset."
