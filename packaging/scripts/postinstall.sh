#!/usr/bin/env bash
set -e

useradd --system \
        --home /etc/lego \
        --shell /usr/sbin/nologin \
        lego

chown lego:lego /etc/lego

systemctl daemon-reload || true
systemctl enable lego-update.timer || true

echo
echo "lego installed."
echo "To create /etc/lego/lego.yml, run:"
echo "  sudo lego-init"
echo
