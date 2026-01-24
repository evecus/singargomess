FROM alpine:latest AS builder

# 安装必要的工具
RUN apk add --no-cache curl

# 获取最新版 sing-box (根据架构，这里默认为 amd64)
RUN SB_VERSION=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//') && \
    curl -Lo /tmp/sing-box.tar.gz https://github.com/SagerNet/sing-box/releases/download/v${SB_VERSION}/sing-box-${SB_VERSION}-linux-amd64.tar.gz && \
    tar -xzf /tmp/sing-box.tar.gz -C /tmp && \
    mv /tmp/sing-box-*/sing-box /usr/local/bin/

# 获取最新版 cloudflared
RUN curl -Lo /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/local/bin/cloudflared

# 最终镜像
FROM alpine:latest
RUN apk add --no-cache jq coreutils bash curl

COPY --from=builder /usr/local/bin/sing-box /usr/local/bin/
COPY --from=builder /usr/local/bin/cloudflared /usr/local/bin/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 默认环境变量
ENV UUID=""
ENV DOMAIN=""
ENV PORT="8080"
ENV TOKEN=""

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
