{ lib, package }:
{
  programs.t3code = {
    enable = lib.mkEnableOption "the T3 Code desktop app";

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
      description = "T3 Code package to install.";
    };

    serverExposureMode = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "local-only"
          "network-accessible"
        ]
      );
      default = null;
      example = "network-accessible";
      description = ''
        Where the desktop app's built-in server listens. `local-only` binds
        127.0.0.1; `network-accessible` binds 0.0.0.0 so other devices can
        pair. The value is written into desktop-settings.json on every launch.
        Null leaves the in-app setting alone.
      '';
    };

    port = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = null;
      example = 3773;
      description = ''
        Port for the desktop app's built-in server (T3CODE_PORT). Null lets the
        app pick the first free port from 3773.
      '';
    };

    cli.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install the `t3` command (for `t3 pair`, `t3 project`, and so on)
        without running the headless server.
      '';
    };
  };
}
