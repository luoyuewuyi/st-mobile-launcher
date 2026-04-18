#!/data/data/com.termux/files/usr/bin/bash
set -eu

HOME_DIR="${HOME:-/data/data/com.termux/files/home}"
APP_DIR="$HOME_DIR/sillytavern-terminal"
BIN_DIR="$HOME_DIR/.local/bin"
MANAGER_URL="https://raw.githubusercontent.com/luoyuewuyi/st-mobile-launcher/master/termux/st-manager.sh"
MANAGER_FILE="$APP_DIR/st-manager.sh"
SHELL_RC="$HOME_DIR/.bashrc"
AUTO_MARKER_BEGIN="# >>> st-terminal autostart >>>"
AUTO_MARKER_END="# <<< st-terminal autostart <<<"

mkdir -p "$APP_DIR" "$BIN_DIR"

echo "== ST Terminal Manager: Install =="
echo

apt update
apt install -y git curl jq nodejs-lts which

echo "[1/3] Downloading manager..."
curl -fsSL "$MANAGER_URL" -o "$MANAGER_FILE"
chmod +x "$MANAGER_FILE"

echo "[2/3] Creating command entry..."
cat > "$BIN_DIR/st-terminal" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
exec "$MANAGER_FILE"
EOF
chmod +x "$BIN_DIR/st-terminal"

echo "[3/3] Enabling autostart..."
if [ -f "$SHELL_RC" ]; then
  if ! grep -Fq "$AUTO_MARKER_BEGIN" "$SHELL_RC"; then
    cat >> "$SHELL_RC" <<EOF

$AUTO_MARKER_BEGIN
if [ -n "\$PS1" ] && [ -z "\${ST_TERMINAL_RUNNING:-}" ]; then
  export ST_TERMINAL_RUNNING=1
  st-terminal
  unset ST_TERMINAL_RUNNING
fi
$AUTO_MARKER_END
EOF
  fi
else
  cat > "$SHELL_RC" <<EOF
$AUTO_MARKER_BEGIN
if [ -n "\$PS1" ] && [ -z "\${ST_TERMINAL_RUNNING:-}" ]; then
  export ST_TERMINAL_RUNNING=1
  st-terminal
  unset ST_TERMINAL_RUNNING
fi
$AUTO_MARKER_END
EOF
fi

echo
echo "Install complete."
echo "Termux will auto-open the manager menu next time."
echo "Starting manager now..."
sleep 1
exec "$MANAGER_FILE"
