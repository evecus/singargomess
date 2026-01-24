#!/bin/bash

# 检查必要环境变量
if [ -z "$UUID" ] || [ -z "$DOMAIN" ] || [ -z "$TOKEN" ]; then
    echo "错误: 请确保设置了 UUID, DOMAIN 和 TOKEN 环境变量。"
    exit 1
fi

# 固定 WebSocket 路径
WS_PATH="/YDT4hf6q3ndbRzwve1MX"
PORT="${PORT:-8080}"

# 1. 生成 sing-box 配置文件
cat <<EOF > /etc/sing-box.json
{
  "log": { "level": "warn", "timestamp": true },
  "inbounds": [
    {
      "type": "vmess",
      "tag": "vmess-in",
      "listen": "::",
      "listen_port": ${PORT},
      "users": [{ "uuid": "${UUID}", "alterId": 0 }],
      "transport": {
        "type": "ws",
        "path": "${WS_PATH}"
      }
    }
  ],
  "outbounds": [{ "type": "direct", "tag": "direct" }]
}
EOF

# 2. 生成 VMess 链接
VMESS_CONFIG=$(cat <<EOF
{
  "v": "2",
  "ps": "Argo-${DOMAIN}",
  "add": "www.visa.com",
  "port": "443",
  "id": "${UUID}",
  "aid": "0",
  "scy": "auto",
  "net": "ws",
  "type": "none",
  "host": "${DOMAIN}",
  "path": "${WS_PATH}",
  "tls": "tls",
  "sni": "${DOMAIN}",
  "alpn": ""
}
EOF
)
VMESS_LINK="vmess://$(echo -n "$VMESS_CONFIG" | base64 -w 0)"

# 3. 启动服务 (静默运行)
cloudflared tunnel --no-autoupdate run --token ${TOKEN} > /dev/null 2>&1 &
sing-box run -c /etc/sing-box.json > /dev/null 2>&1 &

# 4. 检测连接状态并输出结果
echo "正在启动服务并连接 Argo 隧道..."

# 循环探测域名是否生效
MAX_RETRIES=25
COUNT=0
while [ $COUNT -lt $MAX_RETRIES ]; do
    # 探测域名
    STATUS=$(curl -s -L -o /dev/null -w "%{http_code}" "https://${DOMAIN}" --max-time 2)
    
    if [ "$STATUS" != "000" ]; then
        echo "---------------------------------------------------"
        echo "✅ Argo 隧道连接成功！"
        echo "🚀 服务已启动 (Sing-box 运行中)"
        echo "VMess 节点链接:"
        echo "${VMESS_LINK}"
        echo "---------------------------------------------------"
        # 保持容器不退出并等待后台进程
        wait
        exit 0
    fi
    sleep 2
    COUNT=$((COUNT + 1))
done

echo "❌ 隧道连接失败，请检查 TOKEN 和域名配置。"
exit 1
