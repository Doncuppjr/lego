# lego APT repo publisher

Builds the latest upstream `go-acme/lego` release into Debian packages and publishes an APT repository for Ubuntu 22.04, 24.04, and 26.04 via GitHub Pages.

Suites:

- Ubuntu 22.04: `jammy`
- Ubuntu 24.04: `noble`
- Ubuntu 26.04: `resolute`

## Repository setup

1. Create a new GitHub repo, for example `doncuppjr/lego-apt`.
2. Add these files.
3. Go to **Settings → Pages** and set source to **GitHub Actions**.
4. Add a repository secret named `APT_GPG_PRIVATE_KEY` containing an ASCII-armored GPG private key.
5. Add a repository variable named `APT_GPG_KEY_ID` with the signing key ID or fingerprint.
6. Run the workflow manually, or wait for the daily schedule.

## Client install

Replace `OWNER` and `REPO` with your GitHub repo path.

```bash
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://OWNER.github.io/REPO/lego-archive-keyring.gpg | sudo tee /etc/apt/keyrings/lego-archive-keyring.gpg >/dev/null
. /etc/os-release
printf 'deb [signed-by=/etc/apt/keyrings/lego-archive-keyring.gpg] https://OWNER.github.io/REPO %s main\n' "$VERSION_CODENAME" | sudo tee /etc/apt/sources.list.d/lego.list
sudo apt update
sudo apt install lego
```

## Notes

- The package installs `/usr/bin/lego`.
- The workflow checks the latest GitHub release, downloads upstream Linux tarballs, converts them to `.deb`, signs repository metadata, and deploys via GitHub Pages.
- amd64 and arm64 are included.
