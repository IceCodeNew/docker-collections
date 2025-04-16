#!/usr/bin/env bash
set -e -o pipefail

cd /home/nonroot/.ssh/ || exit 1

args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
    -[kK]|--default-key)
        _DEFAULT_KEY="$2"
        # 将密钥路径修改为 /home/nonroot/.ssh/ 下
        key_file=$(basename "$_DEFAULT_KEY")
        # 添加修改后的参数
        args+=("$1" "/home/nonroot/.ssh/$key_file")
        shift 2
        ;;
    # 保持其他参数不变
    -[nNsSeEcCvV]|--no-color|--separate-output|--allow-empty-line|--allow-cursor-control|--version)
        args+=("$1")
        shift
        ;;
    -[tTwW]|--host-tags|--terminal-width)
        args+=("$1" "$2")
        shift 2
        ;;
    [!-]*)
        _HOSTS_CSV="$1"
        # 将 hosts.csv 路径修改为 /home/nonroot/ 下
        hosts_file=$(basename "$_HOSTS_CSV")
        # 添加修改后的参数
        args+=("/home/nonroot/$hosts_file")
        shift
        # 停止处理剩余参数
        args+=("$@")
        break
        ;;
    esac
done

# 执行 ananta 命令并传入修改后的参数
exec catatonit -- ananta "${args[@]}"
