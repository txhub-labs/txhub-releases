{
  lib,
  stdenvNoCC,
  fetchurl,
  sources,
}:

let
  system = stdenvNoCC.hostPlatform.system;
  src = sources.${system} or (throw "txhub: no release for ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "txhub";
  inherit (sources) version;

  src = fetchurl { inherit (src) url hash; };
  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/txhubd $out/bin/txhubd
    install -Dm755 bin/txhub $out/bin/txhub
    install -Dm644 share/doc/txhub/LICENSE $out/share/doc/txhub/LICENSE
    install -Dm644 lib/systemd/system/txhubd.service $out/lib/systemd/system/txhubd.service
    substituteInPlace $out/lib/systemd/system/txhubd.service \
      --replace-fail /usr/sbin/txhubd $out/bin/txhubd
    runHook postInstall
  '';

  meta = {
    description = "TXHub mesh VPN client: the txhubd daemon and txhub CLI";
    homepage = "https://txhub.is";
    license = lib.licenses.bsd3;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "txhub";
  };
}
