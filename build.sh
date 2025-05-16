#!/bin/bash
mkdir -p armbian

# 设置镜像源
MIRROR_TUNA="https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/uefi-x86/archive"
MIRROR_NJU="https://mirrors.nju.edu.cn/armbian-releases/uefi-x86/archive"

# 版本选择
VERSION_TYPE="${VERSION_TYPE:-standard}"

if [ "$VERSION_TYPE" = "debian12_minimal" ]; then
  KEYWORD="bookworm_current"
  FILTER="minimal"
  MIRROR_URL=$MIRROR_NJU
  echo "构建 debian12_minimal Armbian..."
elif [ "$VERSION_TYPE" = "ubuntu24_minimal" ]; then
  KEYWORD="noble_current"
  FILTER="minimal"
  MIRROR_URL=$MIRROR_TUNA
  echo "构建 ubuntu24_minimal Armbian..."
else
  KEYWORD="noble_current"
  FILTER="-minimal"  # 排除 minimal
  MIRROR_URL=$MIRROR_TUNA
  echo "构建 standard Armbian..."
fi

# 下载文件列表并提取目标镜像
FILE_NAME=$(curl -s "$MIRROR_URL/" | \
  grep -oE 'Armbian_[^"]+\.img\.xz' | \
  grep "$KEYWORD" | \
  grep "$FILTER" | \
  tail -n 1)

if [[ -z "$FILE_NAME" ]]; then
  echo "错误：未找到符合条件的 Armbian 镜像文件"
  exit 1
fi

# 拼接完整下载地址
DOWNLOAD_URL="$MIRROR_URL/$FILE_NAME"
OUTPUT_PATH="armbian/$FILE_NAME"

# 创建目录
mkdir -p armbian

# 下载镜像
echo "下载地址: $DOWNLOAD_URL"
echo "下载到: $OUTPUT_PATH"
curl -L -o "$OUTPUT_PATH" "$DOWNLOAD_URL"

# 解压
if [[ $? -eq 0 ]]; then
  echo "下载成功！文件信息："
  file "$OUTPUT_PATH"
  echo "正在解压..."
  xz -d "$OUTPUT_PATH"
  ls -lh armbian/
  echo "准备合成 Armbian 安装器..."
else
  echo "下载失败！"
  exit 1
fi



mkdir -p output
docker run --privileged --rm \
        -v $(pwd)/output:/output \
        -v $(pwd)/supportFiles:/supportFiles:ro \
        -v $(pwd)/armbian/armbian.img:/mnt/armbian.img \
        debian:buster \
        /supportFiles/build.sh
