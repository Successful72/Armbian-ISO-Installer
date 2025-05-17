#!/bin/bash

# 创建目录
mkdir -p armbian

# 镜像源地址（不能使用国内镜像源！GitHub Actions无法访问国内镜像源，后者一般会封锁GitHub Actions的访问请求）
MIRROR_PRIMARY="https://mirror.twds.com.tw/armbian-dl/uefi-x86/archive/" # 台湾数字串流镜像源
TORRENT_PRIMARY="https://dl.armbian.com/uefi-x86/archive"

# 版本选择
VERSION_TYPE="${VERSION_TYPE:-standard}"

if [ "$VERSION_TYPE" = "debian12_minimal" ]; then
  KEYWORD="bookworm_current"
  FILTER="minimal"
  echo "即将构建基于DeBian 12系统的最小压缩版Armbian ISO镜像……"
elif [ "$VERSION_TYPE" = "ubuntu24_minimal" ]; then
  KEYWORD="noble_current"
  FILTER="minimal"
  echo "即将构建基于Ubuntu 22.04系统的最小压缩版Armbian ISO镜像……"
else
  KEYWORD="noble_current"
  FILTER="-minimal"  # 排除 minimal
  echo "即将构建标准版Armbian镜像……"
fi

# 下载文件名
echo "正在获取镜像文件名..."
FILE_NAME=$(curl -s "$MIRROR_PRIMARY/" | \
  grep -oE 'Armbian_[^"]+\.img\.xz' | \
  grep "$KEYWORD" | \
  grep "$FILTER" | \
  tail -n 1)

if [[ -z "$FILE_NAME" ]]; then
  echo "错误：未找到符合条件的 Armbian 镜像文件" # 若执行过程中出现该错误，就说明镜像源地址不对，需要更换一个
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
IMAGE_RENAME="armbian/armbian.img.xz" # 这里必须将Armbian镜像名称修改为armbian.img.xz，否则最后制作的ISO镜像无法使用！(具体表现为：原本应为1.4G的ISO镜像只有280M)

echo "文件信息："
mv "$OUTPUT_PATH" "$IMAGE_RENAME"
file "$IMAGE_RENAME"
echo "正在解压..."
xz -d "$IMAGE_RENAME"
ls -lh armbian/
echo "准备合成 Armbian 安装器..."

mkdir -p output
docker run --privileged --rm \
        -v $(pwd)/output:/output \
        -v $(pwd)/supportFiles:/supportFiles:ro \
        -v $(pwd)/armbian/armbian.img:/mnt/armbian.img \
        debian:buster \
        /supportFiles/build.sh
