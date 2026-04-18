#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

HOME_DIR="${HOME:-/data/data/com.termux/files/home}"
APP_DIR="$HOME_DIR/sillytavern-terminal"
VERSIONS_DIR="$APP_DIR/versions"
CACHE_DIR="$APP_DIR/cache"
LOG_DIR="$APP_DIR/logs"
STATE_FILE="$APP_DIR/state.env"
SUPERVISOR_PID_FILE="$APP_DIR/sillytavern.pid"
CHILD_PID_FILE="$APP_DIR/sillytavern-child.pid"
ACTIVE_LINK="$APP_DIR/current"
REPO_URL="https://github.com/SillyTavern/SillyTavern.git"
TAGS_CACHE="$CACHE_DIR/tags.txt"
DEFAULT_PORT="8000"

mkdir -p "$APP_DIR" "$VERSIONS_DIR" "$CACHE_DIR" "$LOG_DIR"

if [ -f "$STATE_FILE" ]; then
  # shellcheck disable=SC1090
  . "$STATE_FILE"
fi

ACTIVE_VERSION="${ACTIVE_VERSION:-}"
SERVER_PORT="${SERVER_PORT:-$DEFAULT_PORT}"

save_state() {
  cat > "$STATE_FILE" <<EOF
ACTIVE_VERSION="$ACTIVE_VERSION"
SERVER_PORT="$SERVER_PORT"
EOF
}

base_setup() {
  pkg update -y
  pkg install -y git curl jq nodejs-lts
}

pause_wait() {
  printf '\nPress Enter to continue... '
  read -r _
}

header() {
  clear
  echo "========================================"
  echo "     SillyTavern Terminal Manager"
  echo "========================================"
  echo "QQ群号：1097394254"
  echo "Workspace: $APP_DIR"
  if [ -n "$ACTIVE_VERSION" ]; then
    echo "Active version: $ACTIVE_VERSION"
  else
    echo "Active version: none"
  fi
  echo "Port: $SERVER_PORT"
  echo "========================================"
}

ensure_current_link() {
  if [ -n "$ACTIVE_VERSION" ] && [ -d "$VERSIONS_DIR/$ACTIVE_VERSION" ]; then
    ln -sfn "$VERSIONS_DIR/$ACTIVE_VERSION" "$ACTIVE_LINK"
  fi
}

refresh_tags() {
  git ls-remote --tags --sort='-version:refname' "$REPO_URL" \
    | awk '{print $2}' \
    | sed 's#refs/tags/##' \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
    > "$TAGS_CACHE"
}

show_remote_versions() {
  echo "Latest official versions:"
  echo
  nl -w2 -s'. ' "$TAGS_CACHE" | head -n 50
  echo
  pause_wait
}

install_selected_version() {
  header
  echo "Fetching official versions..."
  refresh_tags
  echo
  nl -w2 -s'. ' "$TAGS_CACHE" | head -n 50
  echo
  printf 'Enter version number or exact tag: '
  read -r selection

  local chosen=""
  if echo "$selection" | grep -Eq '^[0-9]+$'; then
    chosen="$(sed -n "${selection}p" "$TAGS_CACHE" || true)"
  else
    chosen="$selection"
  fi

  if [ -z "$chosen" ]; then
    echo "Invalid selection."
    pause_wait
    return
  fi

  local target_dir="$VERSIONS_DIR/$chosen"
  if [ -d "$target_dir/.git" ]; then
    echo "Version $chosen is already installed."
  else
    echo "Installing version $chosen ..."
    git clone --branch "$chosen" --depth 1 "$REPO_URL" "$target_dir"
    (
      cd "$target_dir"
      npm install
    )
  fi

  ACTIVE_VERSION="$chosen"
  ensure_current_link
  save_state
  echo "Version $chosen is now active."
  pause_wait
}

install_latest_version() {
  header
  echo "Fetching latest version..."
  refresh_tags
  local latest
  latest="$(head -n 1 "$TAGS_CACHE")"

  if [ -z "$latest" ]; then
    echo "Could not determine latest version."
    pause_wait
    return
  fi

  local target_dir="$VERSIONS_DIR/$latest"
  if [ ! -d "$target_dir/.git" ]; then
    echo "Installing latest version $latest ..."
    git clone --branch "$latest" --depth 1 "$REPO_URL" "$target_dir"
    (
      cd "$target_dir"
      npm install
    )
  fi

  ACTIVE_VERSION="$latest"
  ensure_current_link
  save_state
  echo "Latest version $latest is now active."
  pause_wait
}

list_installed_versions() {
  header
  echo "Installed versions:"
  echo

  local versions
  versions="$(find "$VERSIONS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -Vr || true)"
  if [ -z "$versions" ]; then
    echo "No versions installed."
  else
    echo "$versions" | nl -w2 -s'. '
  fi

  echo
  pause_wait
}

switch_installed_version() {
  header
  local versions
  versions="$(find "$VERSIONS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -Vr || true)"

  if [ -z "$versions" ]; then
    echo "No versions installed."
    pause_wait
    return
  fi

  echo "$versions" | nl -w2 -s'. '
  echo
  printf 'Choose installed version number: '
  read -r selection

  local chosen
  chosen="$(echo "$versions" | sed -n "${selection}p" || true)"
  if [ -z "$chosen" ]; then
    echo "Invalid selection."
    pause_wait
    return
  fi

  ACTIVE_VERSION="$chosen"
  ensure_current_link
  save_state
  echo "Switched to $chosen"
  pause_wait
}

start_server() {
  header

  if [ -z "$ACTIVE_VERSION" ] || [ ! -d "$VERSIONS_DIR/$ACTIVE_VERSION" ]; then
    echo "No active version selected."
    pause_wait
    return
  fi

  if [ -f "$SUPERVISOR_PID_FILE" ]; then
    local old_pid
    old_pid="$(cat "$SUPERVISOR_PID_FILE" 2>/dev/null || true)"
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
      echo "SillyTavern keepalive is already running on PID $old_pid"
      echo "Open: http://127.0.0.1:$SERVER_PORT"
      pause_wait
      return
    fi
  fi

  ensure_current_link
  local log_file="$LOG_DIR/sillytavern-$ACTIVE_VERSION.log"

  if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock || true
  fi

  (
    cd "$ACTIVE_LINK"
    nohup bash -c '
      while true; do
        node server.js --port "'"$SERVER_PORT"'" >> "'"$log_file"'" 2>&1 &
        child=$!
        echo "$child" > "'"$CHILD_PID_FILE"'"
        wait "$child"
        echo "[keepalive] server exited, restarting in 2 seconds..." >> "'"$log_file"'"
        sleep 2
      done
    ' >/dev/null 2>&1 &
    echo $! > "$SUPERVISOR_PID_FILE"
  )

  echo "Started SillyTavern $ACTIVE_VERSION"
  echo "Keepalive: enabled"
  echo "Open: http://127.0.0.1:$SERVER_PORT"
  echo "Log: $log_file"
  pause_wait
}

stop_server() {
  header

  if [ ! -f "$SUPERVISOR_PID_FILE" ]; then
    echo "Server is not running."
    pause_wait
    return
  fi

  local supervisor_pid
  supervisor_pid="$(cat "$SUPERVISOR_PID_FILE" 2>/dev/null || true)"
  local child_pid
  child_pid="$(cat "$CHILD_PID_FILE" 2>/dev/null || true)"

  if [ -n "$supervisor_pid" ] && kill -0 "$supervisor_pid" 2>/dev/null; then
    kill "$supervisor_pid" 2>/dev/null || true
    echo "Stopped keepalive PID $supervisor_pid"
  else
    echo "Keepalive process already stopped."
  fi

  if [ -n "$child_pid" ] && kill -0 "$child_pid" 2>/dev/null; then
    kill "$child_pid" 2>/dev/null || true
    echo "Stopped server PID $child_pid"
  fi

  if command -v termux-wake-unlock >/dev/null 2>&1; then
    termux-wake-unlock || true
  fi

  rm -f "$SUPERVISOR_PID_FILE" "$CHILD_PID_FILE"
  pause_wait
}

refresh_active_dependencies() {
  header

  if [ -z "$ACTIVE_VERSION" ] || [ ! -d "$VERSIONS_DIR/$ACTIVE_VERSION" ]; then
    echo "No active version selected."
    pause_wait
    return
  fi

  echo "Running npm install for $ACTIVE_VERSION ..."
  (
    cd "$VERSIONS_DIR/$ACTIVE_VERSION"
    npm install
  )
  echo "Done."
  pause_wait
}

show_latest_log() {
  header
  local latest_log
  latest_log="$(find "$LOG_DIR" -type f -name '*.log' | sort | tail -n 1 || true)"

  if [ -z "$latest_log" ]; then
    echo "No logs found."
    pause_wait
    return
  fi

  tail -n 40 "$latest_log"
  pause_wait
}

change_port() {
  header
  printf 'Enter port (current %s): ' "$SERVER_PORT"
  read -r new_port

  if ! echo "$new_port" | grep -Eq '^[0-9]+$'; then
    echo "Invalid port."
    pause_wait
    return
  fi

  SERVER_PORT="$new_port"
  save_state
  echo "Port changed to $SERVER_PORT"
  pause_wait
}

main_menu() {
  while true; do
    header
    cat <<'EOF'
1. First-time setup
2. Show official versions
3. Install a specific version
4. Install latest official version
5. List installed versions
6. Switch active version
7. Start SillyTavern
8. Stop SillyTavern
9. Refresh active version dependencies
10. Show latest log
11. Change server port
0. Exit
EOF
    echo
    printf 'Choose: '
    read -r choice

    case "$choice" in
      1) header; echo "Installing base dependencies..."; base_setup; echo "Done."; pause_wait ;;
      2) header; refresh_tags; show_remote_versions ;;
      3) install_selected_version ;;
      4) install_latest_version ;;
      5) list_installed_versions ;;
      6) switch_installed_version ;;
      7) start_server ;;
      8) stop_server ;;
      9) refresh_active_dependencies ;;
      10) show_latest_log ;;
      11) change_port ;;
      0) exit 0 ;;
      *) echo "Invalid choice."; pause_wait ;;
    esac
  done
}

main_menu
