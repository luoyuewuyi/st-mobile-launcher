#!/data/data/com.termux/files/usr/bin/bash
set -eu

BASE_URL="https://raw.githubusercontent.com/luoyuewuyi/st-mobile-launcher/master/termux/install-manager.sh"
STAMP="$(date +%s)"
INSTALLER_URL="${BASE_URL}?t=${STAMP}"
TMP_ROOT="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
TMP_FILE="$(mktemp "$TMP_ROOT/st-install-manager.XXXXXX.sh")"

cleanup_old_tmp() {
  rm -f "$TMP_ROOT"/st-install-manager*.sh 2>/dev/null || true
}

download_with_curl() {
  command -v curl >/dev/null 2>&1 && curl --version >/dev/null 2>&1 && curl -fL --retry 2 --retry-delay 1 -H "Cache-Control: no-cache" "$INSTALLER_URL" -o "$TMP_FILE"
}

download_with_wget() {
  command -v wget >/dev/null 2>&1 && wget --version >/dev/null 2>&1 && wget -qO "$TMP_FILE" "$INSTALLER_URL"
}

mkdir -p "$TMP_ROOT"
cleanup_old_tmp

if ! download_with_curl; then
  if ! download_with_wget; then
    apt update || true
    apt install -y wget curl || true
    download_with_curl || download_with_wget || {
      echo "下载安装器失败。"
      echo "请先运行：termux-change-repo"
      echo "然后执行：apt update && apt full-upgrade -y"
      exit 1
    }
  fi
fi

chmod +x "$TMP_FILE"
exec "$TMP_FILE"
