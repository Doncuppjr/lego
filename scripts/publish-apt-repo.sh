#!/usr/bin/env bash
set -euo pipefail

: "${APT_GPG_KEY_ID:?APT_GPG_KEY_ID required}"
: "${APT_GPG_PRIVATE_KEY:?APT_GPG_PRIVATE_KEY required}"
: "${APT_GPG_PASSPHRASE:?APT_GPG_PASSPHRASE required}"

REPO_URL="${REPO_URL:-https://${GITHUB_REPOSITORY_OWNER:-doncuppjr}.github.io/${GITHUB_REPOSITORY#*/}}"
KEYRING_VERSION="${KEYRING_VERSION:-1.0}"
KEYRING_PKG="doncuppjr-keyring_${KEYRING_VERSION}_all.deb"
SUITES=(focal jammy noble resolute trixie)

mkdir -p public aptrepo/conf dist
sed "s/APT_GPG_KEY_ID_PLACEHOLDER/${APT_GPG_KEY_ID}/g" aptrepo/conf/distributions > public/distributions.tmp
mkdir -p public/conf
mv public/distributions.tmp public/conf/distributions

# Import private key for repo signing.
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

cat > ~/.gnupg/gpg-agent.conf <<EOF
allow-loopback-pinentry
default-cache-ttl 3600
max-cache-ttl 3600
EOF

cat > ~/.gnupg/gpg.conf <<EOF
pinentry-mode loopback
batch
yes
EOF

gpgconf --kill gpg-agent || true
gpgconf --launch gpg-agent

printf '%s' "$APT_GPG_PRIVATE_KEY" | gpg --batch --import

# Export public key in binary keyring form for clients and the keyring package.
gpg --batch --yes --output public/doncuppjr.gpg --export "$APT_GPG_KEY_ID"

# Keep compatibility with older install notes, but prefer doncuppjr.gpg going forward.
cp public/doncuppjr.gpg public/lego-archive-keyring.gpg

# Build bootstrap keyring/source package.
KEYROOT="work/doncuppjr-keyring"
rm -rf "$KEYROOT"
mkdir -p   "$KEYROOT/DEBIAN"   "$KEYROOT/usr/share/keyrings"   "$KEYROOT/etc/apt/sources.list.d"

install -m 0644 public/doncuppjr.gpg "$KEYROOT/usr/share/keyrings/doncuppjr.gpg"

cat > "$KEYROOT/DEBIAN/control" <<EOF
Package: doncuppjr-keyring
Version: ${KEYRING_VERSION}
Section: misc
Priority: optional
Architecture: all
Maintainer: Donald Cupp <doncuppjr@yahoo.com>
Description: APT signing key and source list for the DonCuppJR package repository
 Installs the DonCuppJR APT repository signing key and configures the matching
 APT source for the current Debian or Ubuntu codename.
EOF

cat > "$KEYROOT/DEBIAN/postinst" <<EOF
#!/usr/bin/env bash
set -e

if [ -r /etc/os-release ]; then
  . /etc/os-release
fi

CODENAME="\${VERSION_CODENAME:-}"
if [ -z "\$CODENAME" ] && command -v lsb_release >/dev/null 2>&1; then
  CODENAME="\$(lsb_release -sc)"
fi

case "\$CODENAME" in
  focal|jammy|noble|resolute|trixie) ;;
  *)
    echo "Unsupported or unknown OS codename: \${CODENAME:-unknown}" >&2
    echo "Supported suites: focal, jammy, noble, resolute, trixie" >&2
    exit 1
    ;;
esac

cat > /etc/apt/sources.list.d/doncuppjr.list <<SRC
deb [signed-by=/usr/share/keyrings/doncuppjr.gpg] ${REPO_URL} \$CODENAME main
SRC
EOF

cat > "$KEYROOT/DEBIAN/prerm" <<'EOF'
#!/usr/bin/env bash
set -e

if [ "${1:-}" = "remove" ] || [ "${1:-}" = "purge" ]; then
  rm -f /etc/apt/sources.list.d/doncuppjr.list
fi
EOF

chmod 0755 "$KEYROOT/DEBIAN/postinst" "$KEYROOT/DEBIAN/prerm"
dpkg-deb --build "$KEYROOT" "public/${KEYRING_PKG}"
cp "public/${KEYRING_PKG}" dist/

# Unlock/cache the private key for reprepro.
echo "test" > /tmp/gpg-test.txt
gpg --batch --yes   --pinentry-mode loopback   --passphrase "$APT_GPG_PASSPHRASE"   --local-user "$APT_GPG_KEY_ID"   --detach-sign /tmp/gpg-test.txt
rm -f /tmp/gpg-test.txt /tmp/gpg-test.txt.sig

# Include packages in each supported Debian/Ubuntu suite.
for suite in "${SUITES[@]}"; do
  for deb in dist/*.deb; do
    reprepro --basedir public includedeb "$suite" "$deb"
  done
done

# Basic landing page.
cat > public/index.html <<HTML
<!doctype html>
<title>DonCuppJR APT Repository</title>
<h1>DonCuppJR APT Repository</h1>
<p>Suites: focal, jammy, noble, resolute, trixie. Component: main.</p>
<h2>Bootstrap install</h2>
<pre>wget ${REPO_URL}/doncuppjr-keyring_${KEYRING_VERSION}_all.deb
sudo dpkg -i doncuppjr-keyring_${KEYRING_VERSION}_all.deb
sudo apt update
sudo apt install lego</pre>
<h2>Manual source</h2>
<pre>deb [signed-by=/usr/share/keyrings/doncuppjr.gpg] ${REPO_URL} \$(. /etc/os-release; echo \$VERSION_CODENAME) main</pre>
HTML
