#!/usr/bin/env bash

/render/tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
PID=$!

ADVERTISE_ROUTES=${ADVERTISE_ROUTES:-10.0.0.0/8}
until /render/tailscale up --authkey="${TAILSCALE_AUTHKEY}" --hostname="${RENDER_SERVICE_NAME}" --advertise-routes="$ADVERTISE_ROUTES"; do
  sleep 0.1
done
export ALL_PROXY=socks5://localhost:1055/
tailscale_ip=$(/render/tailscale ip)
echo "Tailscale is up at IP ${tailscale_ip}"

# --- Resolver DNS interne (CoreDNS) exposé au tailnet ---
# Domaine interne Render réel (cf. `cat /etc/resolv.conf` dans le web shell),
# ex: own-xxxxxxxx.svc.cluster.local
: "${RENDER_INTERNAL_DOMAIN:?set RENDER_INTERNAL_DOMAIN (ex: own-xxxxxxxx.svc.cluster.local)}"
export RENDER_INTERNAL_DOMAIN
export RENDER_UPSTREAM_DNS=${RENDER_UPSTREAM_DNS:-169.254.20.10}
export TS_DNS_DOMAIN=${TS_DNS_DOMAIN:-feelia.internal}

envsubst < /render/Corefile.tmpl > /render/Corefile
echo "Generated /render/Corefile:"
cat /render/Corefile

# CoreDNS écoute sur localhost:53 ; tailscaled (userspace) forwarde les
# connexions entrantes du tailnet vers localhost.
/render/coredns -conf /render/Corefile &
DNS_PID=$!
echo "CoreDNS started (pid ${DNS_PID})"

wait ${PID}
