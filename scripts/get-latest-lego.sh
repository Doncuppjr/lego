TAG="$(curl -fsSL https://api.github.com/repos/go-acme/lego/releases/latest | jq -r .tag_name)"
VERSION="${TAG#v}"

ASSET="lego_${TAG}_linux_amd64.tar.gz"
CHECKSUMS="lego_${VERSION}_checksums.txt"

curl -fsSLO "https://github.com/go-acme/lego/releases/download/${TAG}/${ASSET}"
curl -fsSLO "https://github.com/go-acme/lego/releases/download/${TAG}/${CHECKSUMS}"

grep " ${ASSET}$" "${CHECKSUMS}" | sha256sum -c -

tar -xzf "${ASSET}"
