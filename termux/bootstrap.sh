#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

APP_DIR="$HOME/sillytavern-terminal"

pkg update -y
pkg install -y curl

mkdir -p "$APP_DIR"
curl -fsSL https://raw.githubusercontent.com/luoyuewuyi/st-mobile-launcher/master/termux/install.sh -o "$APP_DIR/install.sh"
chmod +x "$APP_DIR/install.sh"

echo "Downloaded installer to $APP_DIR/install.sh"
echo "Running installer..."
exec "$APP_DIR/install.sh"
