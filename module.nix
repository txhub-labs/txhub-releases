{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.txhub;
  userspace = cfg.interfaceName == "userspace-networking";
  daemonFlags = [
    "--state=/var/lib/txhub/txhubd.state"
    "--statedir=/var/lib/txhub"
    "--socket=/run/txhub/txhubd.sock"
    "--port=${toString cfg.port}"
    "--tun=${cfg.interfaceName}"
    "--no-logs-no-support"
  ]
  ++ cfg.extraDaemonFlags;
in
{
  options.services.txhub = {
    enable = lib.mkEnableOption "TXHub, the txhubd daemon and the txhub command";

    package = lib.mkPackageOption pkgs "txhub" { };

    port = lib.mkOption {
      type = lib.types.port;
      default = 41641;
      description = "UDP port txhubd listens on for direct connections between devices. 0 picks a random port.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open {option}`services.txhub.port` (UDP) in the firewall, so peers can connect directly instead of through a relay.";
    };

    interfaceName = lib.mkOption {
      type = lib.types.str;
      default = "txhub0";
      description = ''
        Name of the TXHub network interface. Set to `"userspace-networking"` to
        run without a kernel interface (no TUN device; other programs reach the
        TxNet only through txhubd's proxy features).
      '';
    };

    trustInterface = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Add the TXHub interface to {option}`networking.firewall.trustedInterfaces`,
        so devices on your TxNet can reach services on this machine. Access is
        still limited by your TxNet's access rules.
      '';
    };

    extraDaemonFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--verbose=1" ];
      description = "Extra command-line flags for txhubd.";
    };

    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/run/secrets/txhub-auth-key";
      description = ''
        File holding an auth key (dashboard: Settings, Auth keys). When set, the
        machine signs in by itself at boot whenever it is signed out. Use a path
        outside the Nix store (for example from a secrets manager); the file is
        read at runtime and never copied into the store.
      '';
    };

    extraUpFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "--accept-routes"
        "--hostname=web-1"
      ];
      description = ''
        Extra flags for the automatic `txhub up` run by {option}`services.txhub.authKeyFile`.
        They apply when the machine signs in. To change settings on a machine
        that is already signed in, use `sudo txhub set`.
      '';
    };

    useRoutingFeatures = lib.mkOption {
      type = lib.types.enum [
        "none"
        "client"
        "server"
        "both"
      ];
      default = "none";
      example = "server";
      description = ''
        Prepare the system for exit nodes and shared networks (subnet routes).
        `"client"` lets this machine use them: it sets the reverse-path check to
        loose, which they need. `"server"` lets this machine be an exit node or
        share a network: it turns on IP forwarding. `"both"` does both.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.authKeyFile == null || !lib.hasPrefix builtins.storeDir (toString cfg.authKeyFile);
        message = ''
          services.txhub.authKeyFile (${toString cfg.authKeyFile}) is inside the Nix store,
          where every user on the machine can read it. Point it at a file outside the
          store instead, for example one provided by your secrets manager.
        '';
      }
    ];

    environment.systemPackages = [ cfg.package ];

    boot.kernelModules = lib.mkIf (!userspace) [ "tun" ];

    boot.kernel.sysctl =
      lib.mkIf (cfg.useRoutingFeatures == "server" || cfg.useRoutingFeatures == "both")
        {
          "net.ipv4.conf.all.forwarding" = lib.mkOverride 97 true;
          "net.ipv6.conf.all.forwarding" = lib.mkOverride 97 true;
        };

    networking.firewall = {
      allowedUDPPorts = lib.mkIf (cfg.openFirewall && cfg.port != 0) [ cfg.port ];
      trustedInterfaces = lib.mkIf (cfg.trustInterface && !userspace) [ cfg.interfaceName ];
      # With an exit node or shared network, replies from the internet or that
      # network arrive on the TXHub interface, but the main routing table sends
      # those addresses out through the regular uplink. The strict reverse-path
      # check sees the mismatch and drops the replies; "loose" only requires
      # that the source is routable at all.
      checkReversePath = lib.mkIf (
        cfg.useRoutingFeatures == "client" || cfg.useRoutingFeatures == "both"
      ) (lib.mkDefault "loose");
    };

    # Leave the TXHub interface to txhubd.
    networking.dhcpcd.denyInterfaces = lib.mkIf (!userspace) [ cfg.interfaceName ];
    networking.networkmanager.unmanaged = lib.mkIf (!userspace) [ cfg.interfaceName ];
    systemd.network.wait-online.ignoredInterfaces = lib.mkIf (!userspace) [ cfg.interfaceName ];

    systemd.services.txhubd = {
      description = "TXHub network daemon (txhubd)";
      documentation = [ "https://control.txhub.is" ];
      after = [ "network-pre.target" ];
      wants = [ "network-pre.target" ];
      wantedBy = [ "multi-user.target" ];
      # Keep the connection up during nixos-rebuild switch; restart afterwards.
      stopIfChanged = false;

      # txhubd runs these to set up routes, firewall rules and DNS.
      path = [
        (if config.networking.nftables.enable then pkgs.nftables else pkgs.iptables)
        pkgs.iproute2
        pkgs.procps
        pkgs.getent
        pkgs.kmod
      ]
      ++ lib.optional config.networking.resolvconf.enable config.networking.resolvconf.package;

      # Daemon environment settings: keep logs under the state dir, and use
      # nftables directly when the system firewall does.
      environment = {
        TS_LOGS_DIR = "/var/lib/txhub";
      }
      // lib.optionalAttrs config.networking.nftables.enable {
        TS_DEBUG_FIREWALL_MODE = "nftables";
      };

      serviceConfig = {
        ExecStart = "${lib.getExe' cfg.package "txhubd"} ${lib.escapeShellArgs daemonFlags}";
        Restart = "on-failure";
        RuntimeDirectory = "txhub";
        RuntimeDirectoryMode = "0755";
        StateDirectory = "txhub";
        StateDirectoryMode = "0700";
        CacheDirectory = "txhub";
      };
    };

    systemd.services.txhub-autoconnect = lib.mkIf (cfg.authKeyFile != null) {
      description = "Sign in to TXHub with an auth key";
      after = [ "txhubd.service" ];
      wants = [ "txhubd.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        cfg.package
        pkgs.jq
      ];
      serviceConfig = {
        Type = "oneshot";
        TimeoutStartSec = "5min";
      };
      script = ''
        # Wait (up to 60 s) until txhubd answers on its socket and knows its state.
        tries=0
        until state="$(txhub status --json --peers=false 2>/dev/null | jq -r .BackendState)" \
          && [ -n "$state" ] && [ "$state" != NoState ]; do
          tries=$((tries + 1))
          if [ "$tries" -ge 120 ]; then
            echo "gave up waiting for txhubd to start" >&2
            exit 1
          fi
          sleep 0.5
        done
        if [ "$state" = NeedsLogin ]; then
          txhub up --auth-key=${lib.escapeShellArg "file:${toString cfg.authKeyFile}"} --timeout=2m ${lib.escapeShellArgs cfg.extraUpFlags}
        fi
      '';
    };
  };
}
