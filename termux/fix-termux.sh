#!/data/data/com.termux/files/usr/bin/bash
set -eu

echo "== 酒馆终端管理器：环境修复 =="
echo

if ! command -v apt >/dev/null 2>&1; then
  echo "当前环境没有 apt，这不像正常的 Termux。"
  exit 1
fi

echo "[1/5] 检查镜像源..."
if [ ! -s /data/data/com.termux/files/usr/etc/apt/sources.list ]; then
  if command -v termux-change-repo >/dev/null 2>&1; then
    echo "正在尝试初始化镜像源..."
    printf '1\n' | termux-change-repo || true
  fi
fi

echo "[2/5] 更新软件源..."
apt update || true

echo "[3/5] 升级系统包..."
apt full-upgrade -y || apt upgrade -y || true

echo "[4/5] 重装核心网络依赖..."
apt install --reinstall -y \
  ca-certificates \
  openssl \
  curl \
  libcurl \
  libngtcp2 \
  libnghttp2 \
  zlib || true

echo "[5/5] 安装基础组件..."
apt install -y git jq nodejs-lts which || true

echo
echo "修复步骤执行完毕。"
echo "如果 curl 还是报同样的符号错误，说明这个 Termux 已经坏得比较深。"
echo "这种情况下最快办法通常是重装最新版 Termux。"
