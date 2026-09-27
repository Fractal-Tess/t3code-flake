# Shared systemd user unit for the NixOS and Home Manager modules.
{ lib, cfg }:
{
  Unit = {
    Description = "T3 Code server";
    After = [ "network-online.target" ];
    Wants = [ "network-online.target" ];
  };

  Service = {
    ExecStart = lib.escapeShellArgs (
      [
        (lib.getExe cfg.package)
        "serve"
        "--host"
        cfg.host
        "--port"
        (toString cfg.port)
      ]
      ++ lib.optionals (cfg.baseDir != null) [
        "--base-dir"
        cfg.baseDir
      ]
      ++ cfg.extraArgs
      ++ [ cfg.workingDirectory ]
    );
    WorkingDirectory = cfg.workingDirectory;
    Environment = lib.mapAttrsToList (name: value: "${name}=${value}") (
      {
        PATH = lib.concatStringsSep ":" cfg.path;
        T3CODE_NO_BROWSER = "1";
      }
      // cfg.environment
    );
    Restart = "on-failure";
    RestartSec = 5;
  };

  Install.WantedBy = [ "default.target" ];
}
