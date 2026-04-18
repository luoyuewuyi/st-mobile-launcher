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

COLOR_RESET="\033[0m"
COLOR_TITLE="\033[1;36m"
COLOR_OK="\033[1;32m"
COLOR_WARN="\033[1;33m"
COLOR_INFO="\033[1;34m"
COLOR_MUTED="\033[0;37m"

print_line() {
  printf '%b\n' "$1"
}

print_ok() {
  print_line "${COLOR_OK}$1${COLOR_RESET}"
}

print_warn() {
  print_line "${COLOR_WARN}$1${COLOR_RESET}"
}

print_info() {
  print_line "${COLOR_INFO}$1${COLOR_RESET}"
}

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
  printf '\n按回车继续... '
  read -r _
}

header() {
  clear
  print_line "${COLOR_TITLE}╔════════════════════════════════════════════╗${COLOR_RESET}"
  print_line "${COLOR_TITLE}║        SillyTavern 终端管理器             ║${COLOR_RESET}"
  print_line "${COLOR_TITLE}╚════════════════════════════════════════════╝${COLOR_RESET}"
  print_line "${COLOR_MUTED}QQ群号：1097394254${COLOR_RESET}"
  echo
  echo "工作目录：$APP_DIR"
  if [ -n "$ACTIVE_VERSION" ]; then
    echo "当前版本：$ACTIVE_VERSION"
  else
    echo "当前版本：未选择"
  fi
  echo "服务端口：$SERVER_PORT"
  echo
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
  print_info "官方版本列表："
  echo
  nl -w2 -s'. ' "$TAGS_CACHE" | head -n 50
  echo
  pause_wait
}

install_selected_version() {
  header
  print_info "正在获取官方版本列表..."
  refresh_tags
  echo
  nl -w2 -s'. ' "$TAGS_CACHE" | head -n 50
  echo
  printf '请输入版本序号或精确版本号：'
  read -r selection

  local chosen=""
  if echo "$selection" | grep -Eq '^[0-9]+$'; then
    chosen="$(sed -n "${selection}p" "$TAGS_CACHE" || true)"
  else
    chosen="$selection"
  fi

  if [ -z "$chosen" ]; then
    print_warn "输入无效。"
    pause_wait
    return
  fi

  local target_dir="$VERSIONS_DIR/$chosen"
  if [ -d "$target_dir/.git" ]; then
    print_warn "版本 $chosen 已经安装过了。"
  else
    print_info "正在安装版本 $chosen ..."
    git clone --branch "$chosen" --depth 1 "$REPO_URL" "$target_dir"
    (
      cd "$target_dir"
      npm install
    )
  fi

  ACTIVE_VERSION="$chosen"
  ensure_current_link
  save_state
  print_ok "版本 $chosen 已设为当前版本。"
  pause_wait
}

install_latest_version() {
  header
  print_info "正在获取最新官方版本..."
  refresh_tags
  local latest
  latest="$(head -n 1 "$TAGS_CACHE")"

  if [ -z "$latest" ]; then
    print_warn "无法获取最新版本。"
    pause_wait
    return
  fi

  local target_dir="$VERSIONS_DIR/$latest"
  if [ ! -d "$target_dir/.git" ]; then
    print_info "正在安装最新版本 $latest ..."
    git clone --branch "$latest" --depth 1 "$REPO_URL" "$target_dir"
    (
      cd "$target_dir"
      npm install
    )
  fi

  ACTIVE_VERSION="$latest"
  ensure_current_link
  save_state
  print_ok "最新版本 $latest 已设为当前版本。"
  pause_wait
}

list_installed_versions() {
  header
  print_info "已安装版本："
  echo

  local versions
  versions="$(find "$VERSIONS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -Vr || true)"
  if [ -z "$versions" ]; then
    print_warn "还没有安装任何版本。"
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
    print_warn "还没有安装任何版本。"
    pause_wait
    return
  fi

  print_info "请选择一个已安装版本："
  echo
  echo "$versions" | nl -w2 -s'. '
  echo
  printf '请输入序号：'
  read -r selection

  local chosen
  chosen="$(echo "$versions" | sed -n "${selection}p" || true)"
  if [ -z "$chosen" ]; then
    print_warn "输入无效。"
    pause_wait
    return
  fi

  ACTIVE_VERSION="$chosen"
  ensure_current_link
  save_state
  print_ok "已切换到版本 $chosen"
  pause_wait
}

start_server() {
  header

  if [ -z "$ACTIVE_VERSION" ] || [ ! -d "$VERSIONS_DIR/$ACTIVE_VERSION" ]; then
    print_warn "还没有选择当前版本，请先安装或切换版本。"
    pause_wait
    return
  fi

  if [ -f "$SUPERVISOR_PID_FILE" ]; then
    local old_pid
    old_pid="$(cat "$SUPERVISOR_PID_FILE" 2>/dev/null || true)"
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
      print_warn "酒馆保活进程已在运行，PID：$old_pid"
      echo "访问地址：http://127.0.0.1:$SERVER_PORT"
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

  print_ok "SillyTavern 已启动：$ACTIVE_VERSION"
  echo "保活状态：已开启"
  echo "访问地址：http://127.0.0.1:$SERVER_PORT"
  echo "日志文件：$log_file"
  pause_wait
}

stop_server() {
  header

  if [ ! -f "$SUPERVISOR_PID_FILE" ]; then
    print_warn "当前没有运行中的酒馆服务。"
    pause_wait
    return
  fi

  local supervisor_pid
  supervisor_pid="$(cat "$SUPERVISOR_PID_FILE" 2>/dev/null || true)"
  local child_pid
  child_pid="$(cat "$CHILD_PID_FILE" 2>/dev/null || true)"

  if [ -n "$supervisor_pid" ] && kill -0 "$supervisor_pid" 2>/dev/null; then
    kill "$supervisor_pid" 2>/dev/null || true
    print_ok "已停止保活进程：$supervisor_pid"
  else
    print_warn "保活进程已经停止。"
  fi

  if [ -n "$child_pid" ] && kill -0 "$child_pid" 2>/dev/null; then
    kill "$child_pid" 2>/dev/null || true
    print_ok "已停止酒馆进程：$child_pid"
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
    print_warn "还没有选择当前版本。"
    pause_wait
    return
  fi

  print_info "正在刷新 $ACTIVE_VERSION 的依赖..."
  (
    cd "$VERSIONS_DIR/$ACTIVE_VERSION"
    npm install
  )
  print_ok "依赖刷新完成。"
  pause_wait
}

show_latest_log() {
  header
  local latest_log
  latest_log="$(find "$LOG_DIR" -type f -name '*.log' | sort | tail -n 1 || true)"

  if [ -z "$latest_log" ]; then
    print_warn "还没有日志文件。"
    pause_wait
    return
  fi

  print_info "最新日志：$latest_log"
  echo
  tail -n 40 "$latest_log"
  pause_wait
}

change_port() {
  header
  printf '请输入新端口（当前 %s）：' "$SERVER_PORT"
  read -r new_port

  if ! echo "$new_port" | grep -Eq '^[0-9]+$'; then
    print_warn "端口输入无效。"
    pause_wait
    return
  fi

  SERVER_PORT="$new_port"
  save_state
  print_ok "端口已改为 $SERVER_PORT"
  pause_wait
}

main_menu() {
  while true; do
    header
    cat <<'EOF'
┌──────────────────────────────────────────┐
│ 1. 首次环境准备                         │
│ 2. 查看官方版本列表                     │
│ 3. 安装指定版本                         │
│ 4. 安装最新官方版本                     │
│ 5. 查看已安装版本                       │
│ 6. 切换当前版本                         │
│ 7. 启动 SillyTavern                     │
│ 8. 停止 SillyTavern                     │
│ 9. 刷新当前版本依赖                     │
│ 10. 查看最新日志                        │
│ 11. 修改服务端口                        │
│ 0. 退出                                 │
└──────────────────────────────────────────┘
EOF
    echo
    printf '请输入选项数字：'
    read -r choice

    case "$choice" in
      1) header; print_info "正在安装基础依赖..."; base_setup; print_ok "基础依赖安装完成。"; pause_wait ;;
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
      *) print_warn "没有这个选项，请重新输入。"; pause_wait ;;
    esac
  done
}

main_menu
