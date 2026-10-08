# TXHub on Windows

## Install

1. Download [TXHub-windows-amd64.msi](https://github.com/txhub-labs/txhub-releases/releases/latest/download/TXHub-windows-amd64.msi) and run it.
   The builds aren't code-signed yet, so SmartScreen may show "Windows protected
   your PC". Click **More info → Run anyway**.
2. The installer adds the TXHub background service and starts the tray app. The
   TXHub icon appears in the notification area. If you don't see it, check the **^** overflow.

## Sign in

1. Click the TXHub tray icon, then **Log in…**.
2. Your browser opens. Sign in to your TxNet.
3. The flyout shows **Connected** and lists your devices.

## Everyday use

- **Connect / disconnect:** the switch at the top of the flyout.
- **Devices:** every device on your TxNet, with its address and whether it's online.
- **Accounts:** click your account to switch between accounts or TxNets, add
  another account, or log out. Each account shows its TxNet in parentheses.
- **Exit nodes:** see [Exit nodes](exit-nodes.md).
- **Extra networks:** when other devices share access to extra networks, the
  flyout shows **Use these networks**. Click it to reach them.

## Command line

The CLI is installed at `C:\Program Files\TXHub\txhub.exe`. In an
**administrator** PowerShell:

```powershell
& "C:\Program Files\TXHub\txhub.exe" status
```

## Windows Server (no tray)

For servers, use [txhub-server-windows-amd64.zip](https://github.com/txhub-labs/txhub-releases/releases/latest/download/txhub-server-windows-amd64.zip).
It has the service and CLI only. Unzip it and, in an administrator PowerShell:

```powershell
.\install-txhub-windows.ps1
```

For unattended setup, create an auth key in the dashboard
(**Settings → Auth keys**) and set `$env:TXHUB_AUTHKEY` before running the script.

## Uninstall

**Settings → Apps → Installed apps → TXHub → Uninstall.**
