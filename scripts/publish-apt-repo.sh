#!/usr/bin/env bash
set -euo pipefail

: "${APT_GPG_KEY_ID:?APT_GPG_KEY_ID required}"

mkdir -p public aptrepo/conf
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

printf '%s' "${APT_GPG_PRIVATE_KEY:?APT_GPG_PRIVATE_KEY required}" | gpg --batch --import

# Export public key in binary keyring form for client install.
gpg --batch --yes --output public/lego-archive-keyring.gpg --export "$APT_GPG_KEY_ID"

# Unlock/cache the private key for reprepro
echo "test" > /tmp/gpg-test.txt
gpg --batch --yes \
  --pinentry-mode loopback \
  --passphrase "$APT_GPG_PASSPHRASE" \
  --local-user "$APT_GPG_KEY_ID" \
  --detach-sign /tmp/gpg-test.txt

rm -f /tmp/gpg-test.txt /tmp/gpg-test.txt.sig

# Include packages in each supported Ubuntu suite.
for suite in focal jammy noble resolute trixie; do
  for deb in dist/*.deb; do
    reprepro --basedir public includedeb "$suite" "$deb"
  done
done

# Basic landing page.
cat > public/index.html <<HTML
<!doctype html>
<title>lego APT Repository</title>
<h1>lego APT Repository</h1>
<p>Suites: jammy, noble, resolute. Component: main.</p>
<pre>deb [signed-by=/etc/apt/keyrings/lego-archive-keyring.gpg] https://OWNER.github.io/REPO \\$(. /etc/os-release; echo \\$VERSION_CODENAME) main</pre>
HTML
