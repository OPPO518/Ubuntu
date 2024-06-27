#!/bin/bash

# 确保脚本以 root 身份运行
if [[ $EUID -ne 0 ]]; then
   echo "此脚本必须以 root 身份运行" 
   exit 1
fi

# 新用户的用户名
NEW_USER="newuser"

# 生成 SSH 密钥对（如果密钥不存在）
KEY_PATH="/home/$NEW_USER/.ssh/id_rsa"
if [ ! -f "$KEY_PATH" ]; then
    echo "生成新的 SSH 密钥对..."
    mkdir -p /home/$NEW_USER/.ssh
    ssh-keygen -t rsa -b 4096 -f $KEY_PATH -N ""
    chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
else
    echo "SSH 密钥对已经存在，跳过生成步骤..."
fi

# 添加新用户（如果不存在）
if id "$NEW_USER" &>/dev/null; then
    echo "用户 $NEW_USER 已经存在，跳过创建步骤..."
else
    echo "添加新用户 $NEW_USER..."
    useradd -m -s /bin/bash $NEW_USER
    usermod -aG sudo $NEW_USER
fi

# 将公钥添加到新用户的 authorized_keys
echo "配置 SSH 密钥登录..."
cat "$KEY_PATH.pub" >> /home/$NEW_USER/.ssh/authorized_keys
chown $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh/authorized_keys
chmod 600 /home/$NEW_USER/.ssh/authorized_keys

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

echo "设置完成。请使用新用户 $NEW_USER 的私钥连接服务器，并使用 'sudo -i' 获得 root 权限。"
