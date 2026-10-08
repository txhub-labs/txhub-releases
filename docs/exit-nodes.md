# Exit nodes

An exit node sends all of a device's internet traffic through another device on
your TxNet. Use one to browse from your office or home connection while
travelling, or to give a machine a fixed public IP address.

Setting one up takes two steps:

1. **Offer it:** turn on *Run as exit node* on the device that should carry the traffic.
2. **Approve it:** a TxNet admin approves it in the dashboard.

Then any device on the TxNet can pick it.

## 1. Offer a device as an exit node

### Windows and macOS

Open the TXHub tray/menu and turn on **Run as exit node** (under **Exit Node**).
It shows "Waiting for admin approval" until an admin approves it, then
"Other devices can route through this one".

Or from the command line:

- Windows, in an administrator PowerShell:
  ```powershell
  & "C:\Program Files\TXHub\txhub.exe" set --advertise-exit-node
  ```
- macOS:
  ```sh
  /Applications/TXHub.app/Contents/Helpers/txhub --socket=/var/run/txhubd.sock set --advertise-exit-node
  ```

The device has to stay awake and online for others to use it. Turn off sleep on
a Mac or PC that serves as an exit node.

### Linux

First let the kernel forward traffic, then offer the exit node:

```sh
echo 'net.ipv4.ip_forward = 1'          | sudo tee    /etc/sysctl.d/99-txhub.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-txhub.conf
sudo sysctl -p /etc/sysctl.d/99-txhub.conf

sudo txhub set --advertise-exit-node
```

If the machine runs **firewalld** (Fedora, RHEL), also allow masquerading:

```sh
sudo firewall-cmd --permanent --add-masquerade && sudo firewall-cmd --reload
```

To stop offering it: `sudo txhub set --advertise-exit-node=false`.

## 2. Approve it in the dashboard

A TxNet admin opens [app.txhub.is](https://app.txhub.is) → **Machines**, opens the
device (it's tagged **Exit Node (pending)**) and clicks **Enable Exit Node**.

## 3. Use an exit node

### Windows and macOS

In the tray/menu, open **Exit Node** and pick a device. Pick **None** to stop.

A device can't use an exit node and be one at the same time. Picking an exit node
turns off **Run as exit node** on that device, and turning it on stops using one.

### Linux

```sh
txhub exit-node list                                  # available exit nodes
sudo txhub set --exit-node=<device>                   # start using one
sudo txhub set --exit-node=<device> --exit-node-allow-lan-access   # keep reaching your local network
sudo txhub set --exit-node=                           # stop
```

### Check that it works

Visit an "what is my IP" site, or run `curl https://ifconfig.me`. It should show the
exit node's public address.

## Troubleshooting

- **The exit node isn't in the list:** it hasn't been approved yet, or it's offline.
  Check the device in the dashboard.
- **Selected, but no internet:** on a Linux exit node, check that forwarding is on
  (`sysctl net.ipv4.ip_forward` should print `1`) and that firewalld allows masquerading.
