# lego APT repo publisher

Builds the latest upstream `go-acme/lego` release into Debian packages and publishes an APT repository via GitHub Pages.

Suites:

- Ubuntu 20.04: `focal`
- Ubuntu 22.04: `jammy`
- Ubuntu 24.04: `noble`
- Ubuntu 26.04: `resolute`
- Debian 13: `trixie`

## Repository setup

1. Create the GitHub repository.
2. Go to **Settings → Pages** and set source to **GitHub Actions**.
3. Add a repository secret named `APT_GPG_PRIVATE_KEY` containing an ASCII-armored GPG private key.
4. Add a repository secret named `APT_GPG_PASSPHRASE` with that key's passphrase.
5. Add a repository variable named `APT_GPG_KEY_ID` with the signing key fingerprint.
6. Run the workflow manually, or wait for the daily schedule.

## Client install

```bash
wget https://doncuppjr.github.io/lego/doncuppjr-keyring_1.0_all.deb
sudo dpkg -i doncuppjr-keyring_1.0_all.deb
sudo apt update
sudo apt install lego
```

The keyring package installs:

- `/usr/share/keyrings/doncuppjr.gpg`
- `/etc/apt/sources.list.d/doncuppjr.list`

The source list is generated from `/etc/os-release` so the same bootstrap package works across supported suites.

## Notes

- The package installs `/usr/bin/lego`.
- The package also installs `lego-update.service`, `lego-update.timer`, and `lego-init`.
- The workflow checks the latest GitHub release, downloads upstream Linux tarballs, converts them to `.deb`, signs repository metadata, and deploys via GitHub Pages.
- `amd64` and `arm64` are included for lego packages.
