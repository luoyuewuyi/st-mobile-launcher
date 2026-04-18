#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

HOME_DIR="/data/data/com.termux/files/home"
APP_DIR="$HOME_DIR/sillytavern-mobile"
REPO_DIR="$APP_DIR/SillyTavern"
LOG_DIR="$APP_DIR/logs"
PROPS_DIR="$HOME_DIR/.termux"
PROPS_FILE="$PROPS_DIR/termux.properties"

mkdir -p "$APP_DIR" "$LOG_DIR" "$PROPS_DIR"

echo "[1/6] Updating package lists..."
pkg update -y

echo "[2/6] Installing dependencies..."
pkg install -y git nodejs-lts

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "[3/6] Cloning SillyTavern..."
  git clone --depth 1 https://github.com/SillyTavern/SillyTavern.git "$REPO_DIR"
else
  echo "[3/6] SillyTavern already exists, skipping clone."
fi

echo "[4/6] Installing npm dependencies..."
cd "$REPO_DIR"
npm install

if [ -f "$PROPS_FILE" ]; then
  if ! grep -q '^allow-external-apps=true$' "$PROPS_FILE"; then
    printf '\nallow-external-apps=true\n' >> "$PROPS_FILE"
  fi
else
  printf 'allow-external-apps=true\n' > "$PROPS_FILE"
fi

cat > "$APP_DIR/start-st.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

HOME_DIR="/data/data/com.termux/files/home"
APP_DIR="$HOME_DIR/sillytavern-mobile"
REPO_DIR="$APP_DIR/SillyTavern"
LOG_DIR="$APP_DIR/logs"
PID_FILE="$APP_DIR/sillytavern.pid"
LOG_FILE="$LOG_DIR/sillytavern.log"

mkdir -p "$LOG_DIR"

if [ -f "$PID_FILE" ]; then
  OLD_PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [ -n "${OLD_PID:-}" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    echo "SillyTavern is already running on PID $OLD_PID"
    exit 0
  fi
fi

cd "$REPO_DIR"
nohup node server.js > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"
echo "Started SillyTavern. Log: $LOG_FILE"
EOF

cat > "$APP_DIR/stop-st.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

HOME_DIR="/data/data/com.termux/files/home"
APP_DIR="$HOME_DIR/sillytavern-mobile"
PID_FILE="$APP_DIR/sillytavern.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "No PID file found."
  exit 0
fi

PID="$(cat "$PID_FILE" 2>/dev/null || true)"
if [ -n "${PID:-}" ] && kill -0 "$PID" 2>/dev/null; then
  kill "$PID"
  echo "Stopped SillyTavern PID $PID"
else
  echo "Process already stopped."
fi

rm -f "$PID_FILE"
EOF

cat > "$APP_DIR/update-st.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

HOME_DIR="/data/data/com.termux/files/home"
APP_DIR="$HOME_DIR/sillytavern-mobile"
REPO_DIR="$APP_DIR/SillyTavern"

cd "$REPO_DIR"
git pull --ff-only
npm install
echo "SillyTavern updated."
EOF

chmod +x "$APP_DIR/start-st.sh" "$APP_DIR/stop-st.sh" "$APP_DIR/update-st.sh"

echo "[5/6] Generated launcher scripts in $APP_DIR"
echo "[6/6] Done."
echo
echo "Important:"
echo "- Restart Termux once so allow-external-apps takes effect."
echo "- Then install the Android launcher app."
echo "- First app launch still requires granting RUN_COMMAND permission to the launcher."
echo
echo "Quick commands:"
echo "- Start:  bash ~/sillytavern-mobile/start-st.sh"
echo "- Stop:   bash ~/sillytavern-mobile/stop-st.sh"
echo "- Update: bash ~/sillytavern-mobile/update-st.sh"
