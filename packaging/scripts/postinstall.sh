#!/usr/bin/env bash
set -e

systemctl daemon-reload || true
systemctl enable lego-update.timer || true

echo
echo "lego installed."
echo "To create /etc/lego/lego.yml, run:"
echo "  sudo lego-init"
echo
