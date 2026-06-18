#!/usr/bin/env bash
set -e

install -d -m 0755 /etc/lego /etc/lego/hooks /etc/lego/hooks/pre.d /etc/lego/hooks/deploy.d /etc/lego/hooks/post.d
install -d -m 0700 /var/lib/lego

systemctl daemon-reload || true
systemctl enable --now lego-update.timer || true

echo
echo "lego installed."
echo "To create /etc/lego/lego.yml, run:"
echo "  sudo lego-init"
echo
echo "Optional hook examples are installed under:"
echo "  /usr/share/doc/lego/examples/hooks"
echo
