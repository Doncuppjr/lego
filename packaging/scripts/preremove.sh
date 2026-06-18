#!/usr/bin/env bash
set -e

systemctl disable --now lego-update.timer || true
