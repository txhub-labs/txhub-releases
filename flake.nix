{
  description = "TXHub client for NixOS: the txhubd daemon, the txhub CLI and a NixOS module";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      # Version, tarball URLs and hashes. Rewritten by the release pipeline.
      sources = builtins.fromJSON (builtins.readFile ./sources.json);
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        txhub = pkgs.callPackage ./package.nix { inherit sources; };
        default = txhub;
      });

      overlays.default = final: prev: {
        txhub = final.callPackage ./package.nix { inherit sources; };
      };

      nixosModules.txhub =
        { lib, pkgs, ... }:
        {
          imports = [ ./module.nix ];
          services.txhub.package = lib.mkDefault self.packages.${pkgs.stdenv.hostPlatform.system}.txhub;
        };
      nixosModules.default = self.nixosModules.txhub;

      checks = forAllSystems (
        pkgs:
        let
          eval =
            txhub:
            (nixpkgs.lib.nixosSystem {
              modules = [
                self.nixosModules.default
                {
                  nixpkgs.hostPlatform = pkgs.stdenv.hostPlatform.system;
                  boot.loader.grub.enable = false;
                  fileSystems."/" = {
                    device = "none";
                    fsType = "tmpfs";
                  };
                  system.stateVersion = "25.11";
                  services.txhub = txhub // {
                    enable = true;
                  };
                }
              ];
            }).config;
          plain = eval { };
          withKey = eval { authKeyFile = "/run/secrets/txhub-auth-key"; };
          keyInStore = eval { authKeyFile = "${pkgs.emptyFile}"; };
          text = builtins.unsafeDiscardStringContext;
          failedAssertions = c: builtins.filter (a: !a.assertion) c.assertions;
        in
        {
          # Evaluates the module and checks the generated units, without
          # downloading the release tarball.
          module =
            assert failedAssertions plain == [ ];
            assert failedAssertions withKey == [ ];
            assert failedAssertions keyInStore != [ ];
            pkgs.runCommand "txhub-module-eval"
              {
                daemon = text plain.systemd.units."txhubd.service".text;
                autoconnect = text withKey.systemd.units."txhub-autoconnect.service".text;
                autoconnectScript = text withKey.systemd.services.txhub-autoconnect.script;
                passAsFile = [
                  "daemon"
                  "autoconnect"
                  "autoconnectScript"
                ];
              }
              ''
                grep -q -- '--socket=/run/txhub/txhubd.sock' "$daemonPath"
                grep -q -- '--port=41641' "$daemonPath"
                grep -q -- '--tun=txhub0' "$daemonPath"
                # daemon environment settings
                grep -q 'TS_LOGS_DIR=/var/lib/txhub' "$daemonPath"
                grep -qx 'TimeoutStartSec=5min' "$autoconnectPath"
                grep -Eq -- "--auth-key='?file:/run/secrets/txhub-auth-key" "$autoconnectScriptPath"
                grep -q -- '--timeout=2m' "$autoconnectScriptPath"
                grep -q 'NeedsLogin' "$autoconnectScriptPath"
                ! grep -q 'NeedsMachineAuth' "$autoconnectScriptPath"
                grep -q 'gave up waiting' "$autoconnectScriptPath"
                touch $out
              '';
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
