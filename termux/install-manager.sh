#!/data/data/com.termux/files/usr/bin/bash
set -eu

HOME_DIR="${HOME:-/data/data/com.termux/files/home}"
APP_DIR="$HOME_DIR/sillytavern-terminal"
BIN_DIR="$HOME_DIR/.local/bin"
SCRIPT_DIR="$APP_DIR/scripts"
SCRIPT_ACTIVE_LINK="$APP_DIR/current-script.sh"
MANAGER_URL="https://raw.githubusercontent.com/luoyuewuyi/st-mobile-launcher/master/termux/st-manager.sh"
SHELL_RC="$HOME_DIR/.bashrc"
AUTO_MARKER_BEGIN="# >>> st-terminal autostart >>>"
AUTO_MARKER_END="# <<< st-terminal autostart <<<"

mkdir -p "$APP_DIR" "$BIN_DIR" "$SCRIPT_DIR"

echo "== 酒馆终端管理器：安装程序 =="
echo

curl_ok() {
  command -v curl >/dev/null 2>&1 && curl --version >/dev/null 2>&1
}

wget_ok() {
  command -v wget >/dev/null 2>&1 && wget --version >/dev/null 2>&1
}

fix_env() {
  echo "[修复] 正在尝试修复环境..."
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

echo "[1/4] 检查基础环境..."
apt update || true
apt install -y git jq nodejs-lts which wget curl || true

echo "[2/4] 下载主脚本..."
VERSION_ID="$(date +%Y%m%d%H%M%S)"
VERSION_DIR="$SCRIPT_DIR/$VERSION_ID"
MANAGER_FILE="$VERSION_DIR/st-manager.sh"
mkdir -p "$VERSION_DIR"

if ! download_file "$MANAGER_URL" "$MANAGER_FILE"; then
  echo
  echo "安装失败：下载链路仍然不可用。"
  echo "这通常说明当前 Termux 已严重损坏。"
  echo "建议重装最新版 Termux 后再执行同一条安装命令。"
  exit 1
fi

chmod +x "$MANAGER_FILE"
ln -sfn "$MANAGER_FILE" "$SCRIPT_ACTIVE_LINK"

echo "[3/4] 创建启动命令..."
cat > "$BIN_DIR/st-terminal" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
if [ -L "$SCRIPT_ACTIVE_LINK" ]; then
  exec "$SCRIPT_ACTIVE_LINK"
else
  exec "$MANAGER_FILE"
fi
EOF
chmod +x "$BIN_DIR/st-terminal"

echo "[4/4] 写入自动启动..."
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
echo "安装完成。"
echo "正在进入菜单..."
sleep 1
exec "$MANAGER_FILE"
