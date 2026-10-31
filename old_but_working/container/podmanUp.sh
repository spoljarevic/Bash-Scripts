#!/usr/bin/env bash
# -------------------------------------------------
# Start all Podman compose stacks for the home lab
# -------------------------------------------------

BASE="$HOME/homeLab"

# Start as normal user
COMPOSE_DIRS=(
    "jellyfin"
)

# Start as root
ROOT_DIRS=(
    "nginx-proxy-manager/"
    "semaphore"
)

echo "▶️ Starting rootless containers..."
for dir in "${COMPOSE_DIRS[@]}"; do
    echo "  → $dir (rootless)"
    pushd "$BASE/$dir" >/dev/null || exit 1
    podman compose up -d
    popd >/dev/null || exit 1
done

echo "▶️ Starting root containers..."
for dir in "${ROOT_DIRS[@]}"; do
    echo "  → $dir (root)"
    pushd "$BASE/$dir" >/dev/null || exit 1
    sudo podman compose up -d
    popd >/dev/null || exit 1
done

echo "✅ All stacks started."

