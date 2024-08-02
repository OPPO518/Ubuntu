#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# 添加日志函数
function LOGD() {
    echo -e "${yellow}[DEG] $* ${plain}"
}

function LOGE() {
    echo -e "${red}[ERR] $* ${plain}"
}

function LOGI() {
    echo -e "${green}[INF] $* ${plain}"
}

# 确保脚本以 root 用户运行
if [[ $EUID -ne 0 ]]; then
    LOGE "错误: 必须使用 root 用户运行此脚本!"
    exit 1
fi

# 确认函数
confirm() {
    local prompt="$1"
    local default="$2"
    local answer
    read -r -p "$prompt [默认$default]: " answer
    answer=${answer:-$default}
    [[ "$answer" == "y" || "$answer" == "Y" ]]
}

# 申请 SSL 证书
ssl_cert_issue() {
    echo -E ""
    LOGD "****** 使用说明 ******"
    LOGI "该脚本将使用 Acme 脚本申请证书，使用时需保证:"
    LOGI "1. 知晓 Cloudflare 注册邮箱"
    LOGI "2. 知晓 Cloudflare Global API Key"
    LOGI "3. 域名已通过 Cloudflare 进行解析到当前服务器"
    LOGI "4. 证书将安装在 /root/cert 目录"
    confirm "我已确认以上内容 [y/n]" "y"
    if [ $? -eq 0 ]; then
        cd ~
        LOGI "安装 Acme 脚本"
        curl https://get.acme.sh | sh
        if [ $? -ne 0 ]; then
            LOGE "安装 acme 脚本失败"
            exit 1
        fi
        CF_Domain=""
        CF_GlobalKey=""
        CF_AccountEmail=""
        certPath=/root/cert
        mkdir -p $certPath
        LOGD "请设置域名:"
        read -p "输入你的域名: " CF_Domain
        LOGD "你的域名设置为: ${CF_Domain}"
        LOGD "请设置 API 密钥:"
        read -p "输入你的密钥: " CF_GlobalKey
        LOGD "你的 API 密钥为: ${CF_GlobalKey}"
        LOGD "请设置注册邮箱:"
        read -p "输入你的邮箱: " CF_AccountEmail
        LOGD "你的注册邮箱为: ${CF_AccountEmail}"
        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        if [ $? -ne 0 ]; then
            LOGE "修改默认 CA 为 Lets' Encrypt 失败, 脚本退出"
            exit 1
        fi
        export CF_Key="${CF_GlobalKey}"
        export CF_Email="${CF_AccountEmail}"
        ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${CF_Domain} -d *.${CF_Domain} --log
        if [ $? -ne 0 ]; then
            LOGE "证书签发失败, 脚本退出"
            exit 1
        else
            LOGI "证书签发成功, 安装中..."
        fi
        ~/.acme.sh/acme.sh --installcert -d ${CF_Domain} -d *.${CF_Domain} --ca-file ${certPath}/ca.cer \
        --cert-file ${certPath}/${CF_Domain}.cer --key-file ${certPath}/${CF_Domain}.key \
        --fullchain-file ${certPath}/fullchain.cer
        if [ $? -ne 0 ]; then
            LOGE "证书安装失败, 脚本退出"
            exit 1
        else
            LOGI "证书安装成功, 开启自动更新..."
        fi
        ~/.acme.sh/acme.sh --upgrade --auto-upgrade
        if [ $? -ne 0 ]; then
            LOGE "自动更新设置失败, 脚本退出"
            ls -lah ${certPath}
            chmod 755 ${certPath}
            exit 1
        else
            LOGI "证书已安装且已开启自动更新, 具体信息如下"
            ls -lah ${certPath}
            chmod 755 ${certPath}
        fi
    else
        exit 0
    fi
}

# 显示使用方法
show_usage() {
    echo "SSL 证书申请脚本使用方法:"
    echo "------------------------------------------"
    echo "申请 SSL 证书"
    echo "------------------------------------------"
}

# 主程序入口
if [[ $# -gt 0 ]]; then
    case $1 in
    "申请 SSL 证书")
        ssl_cert_issue
        ;;
    *)
        show_usage
        ;;
    esac
else
    ssl_cert_issue
fi
