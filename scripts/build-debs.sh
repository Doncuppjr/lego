#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?version required, e.g. 5.2.2}"
mkdir -p dist work
rm -rf work/*

for ARCH in amd64 arm64; do
  case "$ARCH" in
    amd64) UPSTREAM_ARCH="x86_64" ;;
    arm64) UPSTREAM_ARCH="arm64" ;;
  esac

  TARBALL="lego_v${VERSION}_linux_${UPSTREAM_ARCH}.tar.gz"
  URL="https://github.com/go-acme/lego/releases/download/v${VERSION}/${TARBALL}"

  rm -rf work
  mkdir -p work
  curl -fsSL "$URL" -o "work/${TARBALL}"
  tar -xzf "work/${TARBALL}" -C work lego
  chmod 0755 work/lego

  export VERSION ARCH
  nfpm package --packager deb --config packaging/nfpm.yaml --target "dist/lego_${VERSION}_1_${ARCH}.deb"
done
