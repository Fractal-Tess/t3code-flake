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
  unit = import ./service.nix {
    inherit lib;
    cfg = serverCfg;
  };
in
{
  options = lib.recursiveUpdate (import ./options.nix { inherit lib package; }) (
    lib.recursiveUpdate (import ./service-options.nix { inherit lib serverPackage; }) {
      services.t3code-server = {
        user = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Only start the user service for this user. Null starts it for every user.";
        };

        openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open the server port on all interfaces.";
        };
      };
    }
  );

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.systemPackages = [ cfg.package ];
    })

    (lib.mkIf serverCfg.enable {
      environment.systemPackages = [ serverCfg.package ];

      systemd.user.services.t3code-server = {
        description = unit.Unit.Description;
        after = unit.Unit.After;
        wants = unit.Unit.Wants;
        wantedBy = unit.Install.WantedBy;
        unitConfig.ConditionUser = lib.mkIf (serverCfg.user != null) serverCfg.user;
        serviceConfig = unit.Service;
      };

      networking.firewall.allowedTCPPorts = lib.mkIf serverCfg.openFirewall [ serverCfg.port ];
    })
  ];
}
