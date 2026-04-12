#!/usr/bin/env bash

status=$(protonvpn status 2>&1)

if echo "$status" | grep -qi "^Status: Connected$"; then
    echo "VPN is connected. Disconnecting..."
    protonvpn disconnect
else
    echo "VPN is disconnected. Connecting..."
    protonvpn connect
fi
