{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  package = self.packages.${system}.t3code;
  serverPackage = self.packages.${system}.t3code-server;
  cfg = config.programs.t3code;
  serverCfg = config.services.t3code-server;
in
{
  options = lib.recursiveUpdate (import ./options.nix { inherit lib package; }) (
    import ./service-options.nix { inherit lib serverPackage; }
  );

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [ cfg.package ];
    })

    (lib.mkIf serverCfg.enable {
      home.packages = [ serverCfg.package ];
      systemd.user.services.t3code-server = import ./service.nix {
        inherit lib;
        cfg = serverCfg;
      };
    })
  ];
}
