#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

HOME_DIR="${HOME:-/data/data/com.termux/files/home}"
APP_DIR="$HOME_DIR/sillytavern-terminal"
BIN_DIR="$HOME_DIR/.local/bin"
MANAGER_FILE="$APP_DIR/st-manager.sh"

mkdir -p "$APP_DIR" "$BIN_DIR"

pkg update -y
pkg install -y git curl jq nodejs-lts

curl -fsSL https://raw.githubusercontent.com/luoyuewuyi/st-mobile-launcher/master/termux/st-manager.sh -o "$MANAGER_FILE"
chmod +x "$MANAGER_FILE"

cat > "$BIN_DIR/st-terminal" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
exec "$MANAGER_FILE"
EOF

chmod +x "$BIN_DIR/st-terminal"

echo
echo "Install complete."
echo "Run with:"
echo "  st-terminal"
echo
echo "If command not found, restart Termux once."
