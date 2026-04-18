#!/data/data/com.termux/files/usr/bin/bash
set -eu

echo "== ST Terminal Manager: Termux Fix =="
echo

if ! command -v apt >/dev/null 2>&1; then
  echo "apt not found. This does not look like a normal Termux environment."
  exit 1
fi

echo "[1/5] Selecting mirror if needed..."
if [ ! -s /data/data/com.termux/files/usr/etc/apt/sources.list ]; then
  if command -v termux-change-repo >/dev/null 2>&1; then
    printf '1\n' | termux-change-repo || true
  fi
fi

echo "[2/5] Updating apt metadata..."
apt update || true

echo "[3/5] Full upgrade..."
apt full-upgrade -y || apt upgrade -y || true

echo "[4/5] Reinstalling core networking packages..."
apt install --reinstall -y \
  ca-certificates \
  openssl \
  curl \
  libcurl \
  libngtcp2 \
  libnghttp2 \
  zlib || true

echo "[5/5] Installing base packages..."
apt install -y git jq nodejs-lts which || true

echo
echo "Fix step finished."
echo "If curl still fails after this, your Termux install is likely broken beyond safe repair."
echo "In that case, reinstall the latest Termux build and run this script again."
