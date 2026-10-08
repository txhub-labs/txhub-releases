# TXHub on NixOS

TXHub ships a Nix flake with a NixOS module for x86-64 and ARM64. It installs the
`txhubd` service and the `txhub` command from the same release files as the
other Linux packages.

## Install

Add TXHub to your system flake and import the module:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    txhub.url = "github:txhub-labs/txhub-releases";
    txhub.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, txhub, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      modules = [
        txhub.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

Then turn it on in `configuration.nix`:

```nix
services.txhub.enable = true;
```

and rebuild:

```sh
sudo nixos-rebuild switch --flake .#my-machine
```

This starts `txhubd` at boot, puts `txhub` on your `PATH`, loads the `tun`
kernel module and opens UDP port 41641 in the firewall so devices can connect
directly.

The flake follows the latest stable TXHub release. To update:

```sh
nix flake update txhub
sudo nixos-rebuild switch --flake .#my-machine
```

## Sign in

```sh
sudo txhub up
```

The command prints a link. Open it in a browser and sign in to your TxNet.

### Unattended sign-in with an auth key

For servers, create an auth key in the dashboard (**Settings → Auth keys**), put
it in a file only root can read, and point the module at it:

```nix
services.txhub = {
  enable = true;
  authKeyFile = "/run/secrets/txhub-auth-key";
  extraUpFlags = [ "--accept-routes" ];
};
```

At boot, if the machine is signed out, it signs in with the key. Use a path
outside the Nix store, for example from your secrets manager; never put the key
itself in your configuration. `extraUpFlags` apply at sign-in; on a machine that
is already signed in, change settings with `sudo txhub set`.

## Everyday use

```sh
txhub status                  # this machine and its peers
txhub ip                      # this machine's TxNet addresses
txhub ping <device>           # test the connection to a device
sudo txhub down               # disconnect
sudo txhub up                 # reconnect
```

Logs: `journalctl -u txhubd -f`

## Exit nodes and shared networks

NixOS needs a little preparation before a machine can use or be an
[exit node](exit-nodes.md), or share a local network with your TxNet. Set
`useRoutingFeatures`:

```nix
services.txhub.useRoutingFeatures = "client";  # use exit nodes / shared networks
services.txhub.useRoutingFeatures = "server";  # be an exit node / share a network
services.txhub.useRoutingFeatures = "both";    # both
```

- **`server`** turns on IPv4 and IPv6 forwarding, which an exit node needs to
  pass traffic on to the internet.
- **`client`** sets the firewall's reverse-path check to `loose`. With an exit
  node, replies from the internet arrive over the TXHub interface, while the
  normal routing table would send those addresses out through your regular
  network connection. The strict check drops such packets; `loose` only requires
  that the sender is reachable at all.

After rebuilding, follow the normal steps:

```sh
sudo txhub set --advertise-exit-node   # offer this machine (then approve it in the dashboard)
txhub exit-node list                   # see available exit nodes
sudo txhub set --exit-node=<device>    # use one
sudo txhub set --exit-node=            # stop
```

## Options

| Option | Default | What it does |
|---|---|---|
| `services.txhub.enable` | `false` | Run TXHub. |
| `services.txhub.package` | the flake's package | The TXHub package to use. |
| `services.txhub.port` | `41641` | UDP port for direct connections (`0` picks one at random). |
| `services.txhub.openFirewall` | `true` | Open that UDP port in the firewall. |
| `services.txhub.interfaceName` | `"txhub0"` | Network interface name. `"userspace-networking"` runs without one. |
| `services.txhub.trustInterface` | `true` | Trust the TXHub interface in the firewall, so your TxNet devices can reach this machine. Your TxNet's access rules still apply. |
| `services.txhub.extraDaemonFlags` | `[ ]` | Extra flags for `txhubd`. |
| `services.txhub.authKeyFile` | `null` | File holding an auth key for unattended sign-in. |
| `services.txhub.extraUpFlags` | `[ ]` | Extra flags for the unattended `txhub up`. |
| `services.txhub.useRoutingFeatures` | `"none"` | `"client"`, `"server"` or `"both"`, see above. |

The flake also provides `packages.<system>.txhub` and `overlays.default` if you
only want the `txhub` package.

## Uninstall

To remove this machine from your TxNet as well, sign out first:

```sh
sudo txhub logout
```

Then delete `services.txhub` from your configuration, remove the module and the
`txhub` input from your flake, and rebuild. The service and command are gone after
the rebuild; to also delete the saved machine state:

```sh
sudo rm -rf /var/lib/txhub
```
