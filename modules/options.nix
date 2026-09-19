{ lib, package }:
{
  programs.t3code = {
    enable = lib.mkEnableOption "the T3 Code desktop app";

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
      description = "T3 Code package to install.";
    };
  };
}
