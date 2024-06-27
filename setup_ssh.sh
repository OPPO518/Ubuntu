#!/bin/bash

# 函数：检查root权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "请以root用户权限运行此脚本。"
        exit 1
    fi
}

# 函数：安装UFW
install_ufw() {
    echo "更新包列表..."
    apt-get update
    echo "安装UFW..."
    apt-get install -y ufw
    echo "启用UFW..."
    ufw enable
    echo "设置默认策略：拒绝所有传入流量，允许所有传出流量..."
    ufw default deny incoming
    ufw default allow outgoing
}

# 函数：添加端口
add_ports() {
    local ports_to_add=("$@")
    if [ ${#ports_to_add[@]} -eq 0 ]; then
        echo "未指定要添加的端口。"
        return
    fi
    echo "正在添加端口..."
    for port in "${ports_to_add[@]}"; do
        ufw allow "$port"
        echo "端口 $port 已添加"
    done
    echo "重载UFW规则..."
    ufw reload
    echo "UFW状态："
    ufw status verbose
}

# 函数：删除端口
delete_ports() {
    local ports_to_delete=("$@")
    if [ ${#ports_to_delete[@]} -eq 0 ]; then
        echo "未指定要删除的端口。"
        return
    fi
    echo "正在删除端口..."
    for port in "${ports_to_delete[@]}"; do
        ufw delete allow "$port"
        echo "端口 $port 已删除"
    done
    echo "重载UFW规则..."
    ufw reload
    echo "UFW状态："
    ufw status verbose
}

# 主程序
check_root

# 如果ufw未安装，则安装并配置
if ! command -v ufw &> /dev/null; then
    install_ufw
else
    echo "UFW 已安装，跳过安装步骤。"
fi

# 示例：使用空格分隔多个端口
ports_to_add=("22 80 443 8080")   # 要添加的端口列表
ports_to_delete=("8080")          # 要删除的端口列表

add_ports ${ports_to_add[@]}
delete_ports ${ports_to_delete[@]}

echo "UFW配置已更新。"
