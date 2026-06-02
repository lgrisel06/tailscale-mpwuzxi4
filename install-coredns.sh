#!/usr/bin/env bash
set -x
COREDNS_VERSION=${COREDNS_VERSION:-1.12.0}
CD_FILE=coredns_${COREDNS_VERSION}_linux_amd64.tgz
wget -q "https://github.com/coredns/coredns/releases/download/v${COREDNS_VERSION}/${CD_FILE}" \
  && tar xzf "${CD_FILE}"
cp coredns /render/
chmod +x /render/coredns
