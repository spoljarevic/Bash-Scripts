#!/usr/bin/env bash
# Run every script with stub versions of the external tools it calls and
# check that it calls the right commands for the given input. The stubs
# record their arguments in $CALLS. Meant for a throwaway CI container: the
# scripts use real paths below /home/ls and /usr/share/backgrounds.
set -uo pipefail

REPO=$(cd "$(dirname "$0")/../.." && pwd)
STUBS=$(mktemp -d)
CALLS=$STUBS/calls.log
export CALLS
failed=0

for tool in proton-drive protonvpn podman sudo figlet chafa fastfetch linux-wallpaperengine; do
  cat > "$STUBS/$tool" <<'EOF'
#!/usr/bin/env bash
echo "$(basename "$0") $*" >> "$CALLS"
case "$(basename "$0")" in
  protonvpn) [ "${1:-}" = status ] && echo "$PROTONVPN_STATUS" ;;
  sudo) exec "$@" ;;
  chafa) echo "sixel-data" ;;
esac
exit 0
EOF
  chmod +x "$STUBS/$tool"
done
export PATH=$STUBS:$PATH

run() {
  : > "$CALLS"
  local input=$2; shift 2
  printf '%b' "$input" | bash "$@" > "$STUBS/out.log" 2>&1
}

expect_call() {
  if grep -qxF -- "$2" "$CALLS"; then
    echo "  ok: $2"
  else
    echo "  FAIL ($1): expected call: $2"
    echo "  calls were:"; sed 's/^/    /' "$CALLS"
    failed=1
  fi
}

expect_no_call() {
  if grep -q -- "^$2" "$CALLS"; then
    echo "  FAIL ($1): unexpected call to $2"; failed=1
  else
    echo "  ok: no $2"
  fi
}

echo "######## vpn/protonvpnToggle.sh"
PROTONVPN_STATUS="Status: Connected" run toggle "" "$REPO/vpn/protonvpnToggle.sh"
expect_call toggle "protonvpn disconnect"
PROTONVPN_STATUS="Status: Disconnected" run toggle "" "$REPO/vpn/protonvpnToggle.sh"
expect_call toggle "protonvpn connect"

echo "######## filesync/protondrive/obsidian"
mkdir -p /home/ls/obsidian && touch /home/ls/obsidian/note.md
run obsidian "y\nn\n" "$REPO/filesync/protondrive/obsidian"
expect_call obsidian "proton-drive filesystem download -c replace /my-files/00_spoljarevic/obsidian /home/ls/"
expect_no_call obsidian "proton-drive filesystem upload"
run obsidian "n\ny\n" "$REPO/filesync/protondrive/obsidian"
expect_call obsidian "proton-drive filesystem upload -c merge /home/ls/obsidian/note.md /my-files/00_spoljarevic/obsidian/"
expect_no_call obsidian "proton-drive filesystem download"

echo "######## old_but_working/container/podmanUp.sh"
mkdir -p "$HOME/homeLab/jellyfin" "$HOME/homeLab/nginx-proxy-manager" "$HOME/homeLab/semaphore"
run podmanUp "" "$REPO/old_but_working/container/podmanUp.sh"
if [ "$(grep -c '^podman compose up -d$' "$CALLS")" = 3 ]; then
  echo "  ok: 3 x podman compose up -d"
else
  echo "  FAIL (podmanUp): expected 3 compose starts"; cat "$CALLS"; failed=1
fi
expect_call podmanUp "sudo podman compose up -d"
rm -rf "$HOME/homeLab/semaphore"
if run podmanUp "" "$REPO/old_but_working/container/podmanUp.sh"; then
  echo "  FAIL (podmanUp): a missing stack directory must stop the script"; failed=1
else
  echo "  ok: stops when a stack directory is missing"
fi

echo "######## old_but_working/converter/ascii-generator"
run ascii "Hello World\n" "$REPO/old_but_working/converter/ascii-generator"
expect_call ascii "figlet -c -t -f ansishadow Hello World"

echo "######## old_but_working/converter/sixel-converter"
assets=$HOME/.config/fastfetch/assets
mkdir -p "$assets" && touch "$assets/logo.png"
run sixel "logo\npng\n40\n" "$REPO/old_but_working/converter/sixel-converter"
expect_call sixel "chafa -s 40x40 $assets/logo.png"
expect_call sixel "fastfetch --raw $assets/logo.sixel --logo-width 20 --logo-height 20 --logo-padding-top 2"
if [ "$(cat "$assets/logo.sixel")" = sixel-data ]; then
  echo "  ok: sixel file written"
else
  echo "  FAIL (sixel): no sixel file"; failed=1
fi

echo "######## old_but_working/extractor/osImageExtractor.sh"
mkdir -p /usr/share/backgrounds && touch /usr/share/backgrounds/a.png /usr/share/backgrounds/b.jpg
run extractor "" "$REPO/old_but_working/extractor/osImageExtractor.sh"
if [ -e "$HOME/Pictures/wallpaper/os/a.png" ] && [ -e "$HOME/Pictures/wallpaper/os/b.jpg" ]; then
  echo "  ok: wallpapers copied"
else
  echo "  FAIL (extractor): wallpapers not copied"; cat "$STUBS/out.log"; failed=1
fi

echo "######## old_but_working/autostart/wallpaper-engine"
run wallpaper "" "$REPO/old_but_working/autostart/wallpaper-engine"
sleep 1
expect_call wallpaper "linux-wallpaperengine --silent --screen-root DP-2 3324167761"
expect_call wallpaper "linux-wallpaperengine --silent --screen-root DVI-D-1 2779991246"

echo "######## steam/launchScripts/worms.sh"
STEAM_RUNTIME=/steam-runtime run worms "" "$REPO/steam/launchScripts/worms.sh" env
preload=$(sed -n 's/^LD_PRELOAD=//p' "$HOME/worms-stdout.log")
case "$preload" in
  *"/usr/lib/libwavpack.so.1 /steam-runtime/amd64/lib/x86_64-linux-gnu/libdbus-1.so.3"*) echo "  ok: LD_PRELOAD set for the game" ;;
  *) echo "  FAIL (worms): LD_PRELOAD was '$preload'"; failed=1 ;;
esac

echo
if [ "$failed" = 0 ]; then echo "######## all scripts work"; else echo "######## some scripts FAILED"; fi
exit "$failed"
