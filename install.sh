#!/bin/bash

# 设置项目信息
repo_url="https://github.com/crusj/bookmark.git"
repo_dir="$1"
binary_name="$2"

# 拉取仓库
echo "[1/3] Installing lib for bookmarks...."
# 进入项目目录
cd $repo_dir

# 使用Rust编译
echo "[2/3] cargo build --release"
cargo build --release

# 可选：移动编译后的二进制文件到指定位置
# 例如，将二进制文件移动到当前脚本所在的目录
mv target/release/$binary_name ../bookmark.so

# 可选：清理构建产物
# cargo clean

cd ..
echo "[3/3] done"
