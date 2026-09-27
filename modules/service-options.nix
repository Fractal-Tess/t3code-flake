{ lib, serverPackage }:
{
  services.t3code-server = {
    enable = lib.mkEnableOption "the headless T3 Code server as a systemd user service";

    package = lib.mkOption {
      type = lib.types.package;
      default = serverPackage;
      description = "T3 Code server package to run.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "Interface to bind. Use 0.0.0.0 or a VPN address to reach it from other devices.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3773;
      description = "Port for the HTTP/WebSocket server.";
    };

    baseDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "%h/.t3-server";
      description = ''
        T3 Code data directory. Null uses T3 Code's default (~/.t3), which is
        shared with the desktop app.
      '';
    };

    workingDirectory = lib.mkOption {
      type = lib.types.str;
      default = "%h";
      description = "Working directory for provider sessions.";
    };

    path = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/run/wrappers/bin"
        "%h/.nix-profile/bin"
        "/etc/profiles/per-user/%u/bin"
        "/run/current-system/sw/bin"
      ];
      description = "PATH entries for the service, so it can find git and provider CLIs such as claude or codex.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Extra environment variables for the service.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra arguments passed to `t3 serve`.";
    };
  };
}
