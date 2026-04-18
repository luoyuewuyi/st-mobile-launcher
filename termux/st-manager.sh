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

pause_wait() {
  printf '\n按回车继续：'
  read -r _
}

header() {
  clear
  echo "================================"
  echo "     酒馆终端管理器"
  echo "================================"
  echo "QQ群号：1097394254"
  if [ -n "$ACTIVE_VERSION" ]; then
    echo "当前版本：$ACTIVE_VERSION"
  else
    echo "当前版本：未选择"
  fi
  echo "端口：$SERVER_PORT"
  echo "================================"
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

choose_version() {
  header
  echo "正在获取版本列表..."
  refresh_tags
  echo
  nl -w2 -s'. ' "$TAGS_CACHE" | head -n 50
  echo
  printf '输入序号或版本号：'
  read -r selection

  local chosen=""
  if echo "$selection" | grep -Eq '^[0-9]+$'; then
    chosen="$(sed -n "${selection}p" "$TAGS_CACHE" || true)"
  else
    chosen="$selection"
  fi

  if [ -z "$chosen" ]; then
    echo "输入无效。"
    pause_wait
    return
  fi

  local target_dir="$VERSIONS_DIR/$chosen"
  if [ ! -d "$target_dir/.git" ]; then
    echo "正在安装版本 $chosen ..."
    git clone --branch "$chosen" --depth 1 "$REPO_URL" "$target_dir"
    (
      cd "$target_dir"
      npm install
    )
  fi

  ACTIVE_VERSION="$chosen"
  ensure_current_link
  save_state
  echo "当前版本已切换到：$chosen"
  pause_wait
}

update_tavern() {
  header
  refresh_tags
  local latest
  latest="$(head -n 1 "$TAGS_CACHE")"

  if [ -z "$latest" ]; then
    echo "获取最新版本失败。"
    pause_wait
    return
  fi

  if [ "$ACTIVE_VERSION" = "$latest" ]; then
    echo "当前已经是最新版本：$latest"
    pause_wait
    return
  fi

  local target_dir="$VERSIONS_DIR/$latest"
  if [ ! -d "$target_dir/.git" ]; then
    echo "正在更新到最新版本：$latest"
    git clone --branch "$latest" --depth 1 "$REPO_URL" "$target_dir"
    (
      cd "$target_dir"
      npm install
    )
  fi

  ACTIVE_VERSION="$latest"
  ensure_current_link
  save_state
  echo "酒馆已更新到：$latest"
  pause_wait
}

update_script() {
  header
  echo "正在更新脚本..."
  local tmp_file="$APP_DIR/st-manager.new.sh"
  curl -fsSL "https://raw.githubusercontent.com/luoyuewuyi/st-mobile-launcher/master/termux/st-manager.sh" -o "$tmp_file"
  chmod +x "$tmp_file"
  mv "$tmp_file" "$0"
  echo "脚本更新完成。"
  pause_wait
}

start_tavern() {
  header

  if [ -z "$ACTIVE_VERSION" ] || [ ! -d "$VERSIONS_DIR/$ACTIVE_VERSION" ]; then
    echo "请先选择版本。"
    pause_wait
    return
  fi

  if [ -f "$SUPERVISOR_PID_FILE" ]; then
    local old_pid
    old_pid="$(cat "$SUPERVISOR_PID_FILE" 2>/dev/null || true)"
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
      echo "酒馆已经在运行。"
      echo "地址：http://127.0.0.1:$SERVER_PORT"
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
        sleep 2
      done
    ' >/dev/null 2>&1 &
    echo $! > "$SUPERVISOR_PID_FILE"
  )

  echo "酒馆已启动。"
  echo "地址：http://127.0.0.1:$SERVER_PORT"
  pause_wait
}

main_menu() {
  while true; do
    header
    cat <<'EOF'
1. 启动酒馆
2. 版本选择
3. 更新酒馆
4. 更新脚本
0. 退出
EOF
    echo
    printf '输入数字：'
    read -r choice

    case "$choice" in
      1) start_tavern ;;
      2) choose_version ;;
      3) update_tavern ;;
      4) update_script ;;
      0) exit 0 ;;
      *) echo "没有这个选项。"; pause_wait ;;
    esac
  done
}

main_menu
