# TXHub on Linux

Packages for Debian/Ubuntu (`.deb`) and Fedora/RHEL (`.rpm`), on x86-64 and ARM64.
There's no desktop app on Linux yet; you use the `txhub` command.

## Install

Debian / Ubuntu (x86-64):

```sh
curl -fLO https://github.com/txhub-labs/txhub-releases/releases/latest/download/txhub-linux-amd64.deb
sudo apt install ./txhub-linux-amd64.deb
```

Fedora / RHEL (x86-64):

```sh
curl -fLO https://github.com/txhub-labs/txhub-releases/releases/latest/download/txhub-linux-x86_64.rpm
sudo dnf install ./txhub-linux-x86_64.rpm
```

On ARM64 machines, use `txhub-linux-arm64.deb` or `txhub-linux-aarch64.rpm`
instead. Installing starts the `txhubd` service and enables it at boot.

## Sign in

```sh
sudo txhub up
```

The command prints a link. Open it in a browser and sign in to your TxNet.

For servers, sign in unattended with an auth key from the dashboard
(**Settings → Auth keys**):

```sh
sudo txhub up --authkey=tskey-...
```

## Everyday use

```sh
txhub status                  # this machine and its peers
txhub ip                      # this machine's TxNet addresses
txhub ping <device>           # test the connection to a device
sudo txhub down               # disconnect
sudo txhub up                 # reconnect
sudo txhub up --accept-routes # also reach networks other devices share
```

Exit nodes: see [Exit nodes](exit-nodes.md).

## Logs

```sh
journalctl -u txhubd -f
```

## Uninstall

```sh
sudo apt remove txhub     # Debian / Ubuntu
sudo dnf remove txhub     # Fedora / RHEL
```
