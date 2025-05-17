#!/bin/bash

# 创建目录
mkdir -p armbian

set -e

# 镜像源（优先使用官方 CDN）
MIRROR_PRIMARY="https://mirror.twds.com.tw/armbian-dl/uefi-x86/archive/"
TORRENT_PRIMARY="https://dl.armbian.com/uefi-x86/archive"

# 版本选择
VERSION_TYPE="${VERSION_TYPE:-standard}"

if [ "$VERSION_TYPE" = "debian12_minimal" ]; then
  KEYWORD="bookworm_current"
  FILTER="minimal"
  echo "构建 debian12_minimal Armbian..."
elif [ "$VERSION_TYPE" = "ubuntu24_minimal" ]; then
  KEYWORD="noble_current"
  FILTER="minimal"
  echo "构建 ubuntu24_minimal Armbian..."
else
  KEYWORD="noble_current"
  FILTER="-minimal"  # 排除 minimal
  echo "构建 standard Armbian..."
fi

# 下载文件名
echo "正在获取镜像文件名..."
FILE_NAME=$(curl -s "$MIRROR_PRIMARY/" | \
  grep -oE 'Armbian_[^"]+\.img\.xz' | \
  grep "$KEYWORD" | \
  grep "$FILTER" | \
  tail -n 1)

if [[ -z "$FILE_NAME" ]]; then
  echo "错误：未找到符合条件的 Armbian 镜像文件"
  exit 1
fi

# 下载路径
DOWNLOAD_URL="$MIRROR_PRIMARY/$FILE_NAME"
OUTPUT_PATH="armbian/$FILE_NAME"
TORRENT_URL="$TORRENT_PRIMARY/${FILE_NAME}.torrent"


# 下载主镜像
echo "下载地址: $DOWNLOAD_URL"
echo "下载到: $OUTPUT_PATH"

echo "尝试使用 curl 下载..."
if curl -L --connect-timeout 10 --retry 3 -o "$OUTPUT_PATH" "$DOWNLOAD_URL"; then
  echo "下载成功！"
else
  echo "curl 下载失败，准备使用 aria2 + torrent 模式下载..."

  # 检查 aria2 是否存在
  if ! command -v aria2c >/dev/null; then
    echo "未安装 aria2，正在安装..."
    apt-get update && apt-get install -y aria2
  fi

  echo "使用 aria2 下载种子文件：$TORRENT_URL"
  aria2c -d armbian -o "$FILE_NAME" "$TORRENT_URL"

  if [[ ! -f "$OUTPUT_PATH" ]]; then
    echo "Aria2 下载失败，退出。"
    exit 1
  fi
fi

# 解压
echo "文件信息："
file "$OUTPUT_PATH"
echo "正在解压..."
xz -d "$OUTPUT_PATH"
ls -lh armbian/
echo "准备合成 Armbian 安装器..."




mkdir -p output
docker run --privileged --rm \
        -v $(pwd)/output:/output \
        -v $(pwd)/supportFiles:/supportFiles:ro \
        -v $(pwd)/armbian/armbian.img:/mnt/armbian.img \
        debian:buster \
        /supportFiles/build.sh
