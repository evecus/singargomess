#!/bin/bash

# 检查必要变量
if [ -z "$UUID" ] || [ -z "$DOMAIN" ] || [ -z "$TOKEN" ]; then
    echo "错误: 请确保设置了 UUID, DOMAIN 和 TOKEN 环境变量。"
    exit 1
fi

# 1. 生成 sing-box 配置文件
cat <<EOF > /etc/sing-box.json
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vmess",
      "tag": "vmess-in",
      "listen": "::",
      "listen_port": ${PORT},
      "users": [{ "uuid": "${UUID}", "alterId": 0 }],
      "transport": {
        "type": "ws",
        "path": "/",
        "max_early_data": 0,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    }
  ],
  "outbounds": [{ "type": "direct", "tag": "direct" }]
}
EOF

# 2. 生成 VMess 链接 (Base64 编码)
VMESS_CONFIG=$(cat <<EOF
{
  "v": "2",
  "ps": "Argo-VMess-${DOMAIN}",
  "add": "www.visa.com",
  "port": "443",
  "id": "${UUID}",
  "aid": "0",
  "scy": "auto",
  "net": "ws",
  "type": "none",
  "host": "${DOMAIN}",
  "path": "/",
  "tls": "tls",
  "sni": "${DOMAIN}",
  "alpn": ""
}
EOF
)
VMESS_LINK="vmess://$(echo -n "$VMESS_CONFIG" | base64 -w 0)"

# 3. 输出日志信息
echo "---------------------------------------------------"
echo "服务启动中..."
echo "节点域名: ${DOMAIN}"
echo "监听端口: ${PORT}"
echo "UUID: ${UUID}"
echo "---------------------------------------------------"
echo "VMess 节点链接:"
echo "${VMESS_LINK}"
echo "---------------------------------------------------"

# 4. 同时运行 Argo Tunnel 和 sing-box
# 使用 --no-autoupdate 避免 docker 环境内更新失败
cloudflared tunnel --no-autoupdate run --token ${TOKEN} &
sing-box run -c /etc/sing-box.json
