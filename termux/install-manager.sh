#!/data/data/com.termux/files/usr/bin/bash
set -eu

HOME_DIR="${HOME:-/data/data/com.termux/files/home}"
APP_DIR="$HOME_DIR/sillytavern-terminal"
BIN_DIR="$HOME_DIR/.local/bin"
SCRIPT_DIR="$APP_DIR/scripts"
SCRIPT_ACTIVE_LINK="$APP_DIR/current-script.sh"
MANAGER_URL="https://raw.githubusercontent.com/luoyuewuyi/st-mobile-launcher/master/termux/st-manager.sh"
BASH_RC="$HOME_DIR/.bashrc"
BASH_PROFILE="$HOME_DIR/.bash_profile"
PROFILE_FILE="$HOME_DIR/.profile"
HOOK_LINE='command -v st-terminal >/dev/null 2>&1 && st-terminal'
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
OLD_MARKER_BEGIN="# >>> st-terminal autostart >>>"
OLD_MARKER_END="# <<< st-terminal autostart <<<"

mkdir -p "$APP_DIR" "$BIN_DIR" "$SCRIPT_DIR"

say() {
  printf '%s\n' "$1"
}

curl_ok() {
  command -v curl >/dev/null 2>&1 && curl --version >/dev/null 2>&1
}

wget_ok() {
  command -v wget >/dev/null 2>&1 && wget --version >/dev/null 2>&1
}

apt_ok() {
  command -v apt >/dev/null 2>&1
}

sources_ok() {
  [ -s /data/data/com.termux/files/usr/etc/apt/sources.list ]
}

ensure_hook_line() {
  local file="$1"
  if [ -f "$file" ]; then
    grep -Fq "$HOOK_LINE" "$file" || printf '\n%s\n' "$HOOK_LINE" >> "$file"
  else
    printf '%s\n' "$HOOK_LINE" > "$file"
  fi
}

ensure_path_line() {
  local file="$1"
  if [ -f "$file" ]; then
    grep -Fq "$PATH_LINE" "$file" || printf '%s\n' "$PATH_LINE" >> "$file"
  else
    printf '%s\n' "$PATH_LINE" > "$file"
  fi
}

clean_old_autostart() {
  local file="$1"
  [ -f "$file" ] || return 0

  local tmp_file
  tmp_file="$(mktemp)"

  awk -v begin="$OLD_MARKER_BEGIN" -v end="$OLD_MARKER_END" -v hook="$HOOK_LINE" '
    $0 == begin { skip = 1; next }
    skip && $0 == end { skip = 0; next }
    skip { next }
    {
      trimmed = $0
      gsub(/^[ \t]+|[ \t]+$/, "", trimmed)
      if (trimmed == hook) next
      if (index(trimmed, "st-terminal") && index(trimmed, "autostart")) next
      if (index(trimmed, "ST_TERMINAL_RUNNING")) next
      if (trimmed == "st-terminal") next
      print
    }
  ' "$file" > "$tmp_file"

  mv "$tmp_file" "$file"
}

diagnose_env() {
  say "== 酒馆终端管理器：环境诊断 =="
  say ""

  if ! apt_ok; then
    say "[诊断] 当前环境里没有 apt。"
    say "[结论] 这不像正常的 Termux。"
    return 1
  fi

  if ! sources_ok; then
    say "[诊断] 还没有配置镜像源。"
    say "[建议] 先运行 termux-change-repo 选择镜像源。"
  else
    say "[诊断] 镜像源文件存在。"
  fi

  if curl_ok; then
    say "[诊断] curl：正常"
  else
    say "[诊断] curl：异常"
    say "[提示] 常见原因是 openssl / libcurl / libngtcp2 库版本不一致。"
  fi

  if wget_ok; then
    say "[诊断] wget：正常"
  else
    say "[诊断] wget：不可用或未安装"
  fi

  say ""
  return 0
}

fix_env() {
  say "[修复] 正在尝试修复下载环境..."
  apt update || true
  apt full-upgrade -y || apt upgrade -y || true
  apt install --reinstall -y \
    ca-certificates \
    openssl \
    curl \
    libcurl \
    libngtcp2 \
    libnghttp2 \
    zlib || true
  apt install -y git jq nodejs-lts which wget || true
}

download_file() {
  local url="$1"
  local out="$2"

  if curl_ok; then
    curl -fsSL "$url" -o "$out"
    return 0
  fi

  if wget_ok; then
    wget -qO "$out" "$url"
    return 0
  fi

  fix_env

  if curl_ok; then
    curl -fsSL "$url" -o "$out"
    return 0
  fi

  if wget_ok; then
    wget -qO "$out" "$url"
    return 0
  fi

  return 1
}

diagnose_env || true

say "[1/4] 检查基础环境..."
apt update || true
apt install -y git jq nodejs-lts which wget curl || true

say "[2/4] 下载主脚本..."
VERSION_ID="$(date +%Y%m%d%H%M%S)"
VERSION_DIR="$SCRIPT_DIR/$VERSION_ID"
MANAGER_FILE="$VERSION_DIR/st-manager.sh"
mkdir -p "$VERSION_DIR"

if ! download_file "$MANAGER_URL" "$MANAGER_FILE"; then
  say ""
  say "安装失败。"
  say ""
  say "诊断结论："
  if ! sources_ok; then
    say "- 镜像源可能没有配置好"
  fi
  if ! curl_ok; then
    say "- curl 仍然不可用"
  fi
  if ! wget_ok; then
    say "- wget 也不可用"
  fi
  say ""
  say "建议："
  say "1. 先运行 termux-change-repo 选择镜像源"
  say "2. 再运行：apt update && apt full-upgrade -y"
  say "3. 如果还是不行，重装最新版 Termux"
  exit 1
fi

chmod +x "$MANAGER_FILE"
ln -sfn "$MANAGER_FILE" "$SCRIPT_ACTIVE_LINK"

say "[3/4] 创建启动命令..."
cat > "$BIN_DIR/st-terminal" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
APP_DIR="$APP_DIR"
EXIT_FLAG_FILE="\$APP_DIR/exit.flag"

if [ -n "\${ST_TERMINAL_RUNNING:-}" ]; then
  if [ -L "$SCRIPT_ACTIVE_LINK" ]; then
    exec "$SCRIPT_ACTIVE_LINK"
  else
    exec "$MANAGER_FILE"
  fi
fi

export ST_TERMINAL_RUNNING=1

while true; do
  if [ -L "$SCRIPT_ACTIVE_LINK" ]; then
    "$SCRIPT_ACTIVE_LINK"
  else
    "$MANAGER_FILE"
  fi

  if [ -f "\$EXIT_FLAG_FILE" ]; then
    rm -f "\$EXIT_FLAG_FILE"
    break
  fi

  sleep 1
done

unset ST_TERMINAL_RUNNING
EOF
chmod +x "$BIN_DIR/st-terminal"

say "[4/4] 写入自动启动..."
clean_old_autostart "$BASH_RC"
clean_old_autostart "$BASH_PROFILE"
clean_old_autostart "$PROFILE_FILE"
ensure_path_line "$BASH_RC"
ensure_path_line "$BASH_PROFILE"
ensure_path_line "$PROFILE_FILE"
ensure_hook_line "$BASH_RC"
ensure_hook_line "$BASH_PROFILE"
ensure_hook_line "$PROFILE_FILE"

say ""
say "安装完成。"
say "以后打开 Termux 会自动进入菜单。"
sleep 1
exec "$MANAGER_FILE"
