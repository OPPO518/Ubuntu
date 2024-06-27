#!/bin/bash

# 确保脚本以 root 身份运行
if [[ $EUID -ne 0 ]]; then
   echo "此脚本必须以 root 身份运行" 
   exit 1
fi

# 生成 SSH 密钥对（如果密钥不存在）
KEY_PATH="$HOME/.ssh/id_rsa"
if [ ! -f "$KEY_PATH" ]; then
    echo "生成新的 SSH 密钥对..."
    ssh-keygen -t rsa -b 4096 -f $KEY_PATH -N ""
else
    echo "SSH 密钥对已经存在，跳过生成步骤..."
fi

# 创建 .ssh 目录（如果不存在）
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 将公钥添加到 authorized_keys
cat "$KEY_PATH.pub" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 禁用密码登录
echo "禁用密码登录..."
SSHD_CONFIG="/etc/ssh/sshd_config"
if grep -q "^PasswordAuthentication" $SSHD_CONFIG; then
    sed -i "s/^PasswordAuthentication.*/PasswordAuthentication no/" $SSHD_CONFIG
else
    echo "PasswordAuthentication no" >> $SSHD_CONFIG
fi

if grep -q "^ChallengeResponseAuthentication" $SSHD_CONFIG; then
    sed -i "s/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/" $SSHD_CONFIG
else
    echo "ChallengeResponseAuthentication no" >> $SSHD_CONFIG
fi

# 重启 SSH 服务以应用更改
echo "重启 SSH 服务..."
systemctl restart ssh

echo "设置完成。请使用私钥连接服务器。"
