#!/usr/bin/env bash
set -euo pipefail
curl -fsSL https://api.github.com/repos/go-acme/lego/releases/latest \
  | jq -r '.tag_name | ltrimstr("v")'
