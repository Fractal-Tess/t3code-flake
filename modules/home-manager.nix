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
  cfg = config.programs.t3code;
in
{
  options = import ./options.nix { inherit lib package; };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
