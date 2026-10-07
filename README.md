# TXHub releases

Installers for the TXHub client. Sign up and manage your txnet at [txhub.is](https://txhub.is).

## Download the latest version

| Platform | Download |
|---|---|
| Windows (64-bit) | [TXHub-windows-amd64.msi](https://github.com/txhub-labs/txhub-releases/releases/latest/download/TXHub-windows-amd64.msi) |
| macOS (Apple Silicon + Intel) | [TXHub-macos.dmg](https://github.com/txhub-labs/txhub-releases/releases/latest/download/TXHub-macos.dmg) |
| Debian / Ubuntu (x86-64) | [txhub-linux-amd64.deb](https://github.com/txhub-labs/txhub-releases/releases/latest/download/txhub-linux-amd64.deb) |
| Debian / Ubuntu (ARM64) | [txhub-linux-arm64.deb](https://github.com/txhub-labs/txhub-releases/releases/latest/download/txhub-linux-arm64.deb) |
| Fedora / RHEL (x86-64) | [txhub-linux-x86_64.rpm](https://github.com/txhub-labs/txhub-releases/releases/latest/download/txhub-linux-x86_64.rpm) |
| Fedora / RHEL (ARM64) | [txhub-linux-aarch64.rpm](https://github.com/txhub-labs/txhub-releases/releases/latest/download/txhub-linux-aarch64.rpm) |
| Windows Server (CLI only) | [txhub-server-windows-amd64.zip](https://github.com/txhub-labs/txhub-releases/releases/latest/download/txhub-server-windows-amd64.zip) |

Each release includes a `SHA256SUMS` file for checking downloads. Beta builds
are under [all releases](https://github.com/txhub-labs/txhub-releases/releases).

## Install

- **Windows:** run the `.msi`.
- **macOS:** open the `.dmg` and drag TXHub to Applications.
- **Debian / Ubuntu:** `sudo apt install ./txhub-linux-amd64.deb`, then `sudo txhub up`.
- **Fedora / RHEL:** `sudo dnf install ./txhub-linux-x86_64.rpm`, then `sudo txhub up`.

This repository only hosts release files.
