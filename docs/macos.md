# TXHub on macOS

Works on Apple Silicon and Intel Macs.

## Install

1. Download [TXHub-macos.dmg](https://github.com/txhub-labs/txhub-releases/releases/latest/download/TXHub-macos.dmg),
   open it and drag **TXHub** to **Applications**.
2. Open TXHub from Applications. The builds aren't notarized yet, so macOS may say
   the app "cannot be opened because the developer cannot be verified".
   Right-click **TXHub.app → Open** and confirm, or run:
   ```sh
   xattr -dr com.apple.quarantine /Applications/TXHub.app
   ```
3. The first time, TXHub asks for your password once to install its background
   service. The TXHub icon then appears in the menu bar.

## Sign in

1. Click the TXHub icon in the menu bar, then **Log in…**.
2. Your browser opens. Sign in to your TxNet.
3. The menu shows **Connected** and lists your devices.

## Everyday use

- **Connect / disconnect:** the switch at the top of the menu.
- **Devices:** click a device to copy its address.
- **Accounts:** click your account to switch between accounts or TxNets, add
  another account, or log out. Each account shows its TxNet in parentheses.
- **Exit nodes:** see [Exit nodes](exit-nodes.md).
- **Extra networks:** when other devices share access to extra networks, the
  menu shows **Use**. Click it to reach them.
- **Advanced:** version info, and **Reinstall daemon…** if the background service
  stops responding.

## Command line

The CLI is inside the app:

```sh
/Applications/TXHub.app/Contents/Helpers/txhub --socket=/var/run/txhubd.sock status
```

Tip: add an alias to your shell profile:

```sh
alias txhub='/Applications/TXHub.app/Contents/Helpers/txhub --socket=/var/run/txhubd.sock'
```

## Uninstall

```sh
sudo /Applications/TXHub.app/Contents/Helpers/uninstall-daemon.sh
```

Then drag TXHub from Applications to the Trash.
