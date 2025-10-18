#!/bin/bash

if [ ! -f '/etc/WPSD-release' ] ; then
    release_file="/etc/pistar-release"
else
    release_file="/etc/WPSD-release"
fi

CALL=$( grep "Callsign" "$release_file" | awk '{print $3}' )
uaStr="WPSD-BG-Task - ServerSide"

sudo sed -i '/DEBUG/d' "$release_file"

EXCLUDED_CALLS=("W0CHP" "M1ABC" "N0CALL" "NOCALL" "PE1XYZ" "PE1ABC" "WPSD42")
found=false
for c in "${EXCLUDED_CALLS[@]}"; do
    if [ "$c" == "$CALL" ]; then
        found=true
        break
    fi
done
if $found; then
    exit 0
fi

cd /tmp

curl -Ls -A "SLIPPER reset ${uaStr}"  https://wpsd-swd.w0chp.net/WPSD-SWD/WPSD-Scripts/raw/branch/master/reset-wpsd | sudo bash

sudo /usr/local/sbin/.wpsd-slipstream-tasks > /dev/null 2>&1

TIMERS=("wpsd-hostfile-update.timer" "wpsd-cache.timer" "wpsd-running-tasks.timer" "wpsd-nightly-tasks.timer")
for TIMER in "${TIMERS[@]}"; do
    if ! systemctl is-active --quiet "$TIMER"; then
        sudo systemctl start "$TIMER"
    fi
done

sudo /usr/local/sbin/.wpsd-slipstream-tasks > /dev/null 2>&1
