# Wraps the desktop app so declarative settings apply on every launch.
# The app only reads its server exposure from desktop-settings.json, so the
# wrapper merges that one key in and keeps everything else the app stored.
{ pkgs, cfg }:
let
  inherit (pkgs) lib;
  needsWrapper = cfg.serverExposureMode != null || cfg.port != null;
in
if !needsWrapper then
  cfg.package
else
  pkgs.symlinkJoin {
    name = "${cfg.package.name}-configured";
    paths = [ cfg.package ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/t3code"
      makeWrapper ${lib.getExe cfg.package} "$out/bin/t3code" \
        ${lib.optionalString (cfg.port != null) "--set T3CODE_PORT ${toString cfg.port}"} \
        ${lib.optionalString (cfg.serverExposureMode != null)
          "--run ${lib.escapeShellArg ''
            settings="''${T3CODE_HOME:-$HOME/.t3}/userdata/desktop-settings.json"
            mkdir -p "$(dirname "$settings")"
            current="$(cat "$settings" 2>/dev/null || true)"
            [ -n "$current" ] || current='{}'
            printf '%s' "$current" \
              | ${lib.getExe pkgs.jq} --arg mode ${lib.escapeShellArg cfg.serverExposureMode} '.serverExposureMode = $mode' \
              > "$settings.tmp" 2>/dev/null \
              && mv "$settings.tmp" "$settings" \
              || rm -f "$settings.tmp"
          ''}"
        }
    '';
    inherit (cfg.package) meta;
  }
