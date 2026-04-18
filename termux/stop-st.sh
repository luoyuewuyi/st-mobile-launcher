#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

HOME_DIR="/data/data/com.termux/files/home"
APP_DIR="$HOME_DIR/sillytavern-mobile"

exec "$APP_DIR/stop-st.sh"
