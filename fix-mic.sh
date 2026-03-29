#!/bin/bash
# Smart mic fix - tests mic and resets USB only if needed
# Usage: fix-mic.sh [--no-reset]

NO_RESET=false
[[ "$1" == "--no-reset" ]] && NO_RESET=true

test_mic() {
    # Record 1 second and check if we got actual audio data
    local tmpfile=$(mktemp)
    timeout 1 pw-record --target "$(wpctl status | grep -A5 'Sources:' | grep StreamCam | grep -oP '^\s*\*?\s*\K\d+')" "$tmpfile" 2>/dev/null
    local size=$(stat -c%s "$tmpfile" 2>/dev/null || echo 0)
    rm -f "$tmpfile"
    # WAV header is 44 bytes, need more than that for actual audio
    [ "$size" -gt 100 ]
}

echo "Testing mic..."
if test_mic; then
    echo "Mic is working!"
    exit 0
fi

if $NO_RESET; then
    echo "Mic not responding! Run fix-mic.sh to reset."
    exit 1
fi

echo "Mic not responding. Resetting USB device..."
pkexec usbreset "Logitech StreamCam"
sleep 1

echo "Restarting PipeWire..."
systemctl --user restart pipewire pipewire-pulse wireplumber
sleep 2

echo "Testing mic again..."
if test_mic; then
    echo "Mic fixed!"
else
    echo "Mic still not working. Try unplugging and replugging the StreamCam."
    exit 1
fi
