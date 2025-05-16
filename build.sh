#!/bin/bash
mkdir -p armbian

# 设置 Armbian 镜像源（可切换为清华或南大）
MIRROR_TUNA="https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/uefi-x86/archive"
MIRROR_NJU="https://mirrors.nju.edu.cn/armbian-releases/uefi-x86/archive"

# 读取版本类型
VERSION_TYPE="${VERSION_TYPE:-standard}"

# 判断使用哪个版本，构造关键字
if [ "$VERSION_TYPE" = "debian12_minimal" ]; then
  KEYWORD="bookworm_current.*minimal.*img.xz"
  MIRROR_URL=$MIRROR_NJU
  echo "构建 debian12_minimal Armbian..."
elif [ "$VERSION_TYPE" = "ubuntu24_minimal" ]; then
  KEYWORD="noble_current.*minimal.*img.xz"
  MIRROR_URL=$MIRROR_TUNA
  echo "构建 ubuntu24_minimal Armbian..."
else
  KEYWORD="noble_current.*(?<!minimal).*img.xz"
  MIRROR_URL=$MIRROR_TUNA
  echo "构建 standard Armbian..."
fi

# 获取最新文件名
FILE_NAME=$(curl -s "$MIRROR_URL/" | grep -oP "Armbian_.*${KEYWORD}" | sort -V | tail -n1)

if [[ -z "$FILE_NAME" ]]; then
  echo "错误：未找到符合条件的 Armbian 镜像文件"
  exit 1
fi

# 构造完整下载链接
DOWNLOAD_URL="$MIRROR_URL/$FILE_NAME"
OUTPUT_PATH="armbian/$FILE_NAME"

# 创建输出目录
mkdir -p armbian

# 下载镜像
echo "下载地址: $DOWNLOAD_URL"
echo "下载到: $OUTPUT_PATH"
curl -L -o "$OUTPUT_PATH" "$DOWNLOAD_URL"

# 解压镜像
if [[ $? -eq 0 ]]; then
  echo "下载成功，文件信息："
  file "$OUTPUT_PATH"
  echo "解压中..."
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
