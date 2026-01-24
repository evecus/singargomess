docker run -d \
  --name singargo-node \
  --restart always \
  -e UUID="你的UUID" \
  -e DOMAIN="你的Cloudflare域名" \
  -e TOKEN="你的Argo隧道Token" \
  -e PORT="8080" \
  ghcr.io/evecus/singargo:latest
