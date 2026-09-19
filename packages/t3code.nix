{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
  makeWrapper,
}:

let
  pname = "t3code";
  version = "0.0.42";

  sources = {
    x86_64-linux = {
      asset = "T3-Code-${version}-x86_64.AppImage";
      hash = "sha256-jcH8zavC7TpZo5RMx3LvEZMbk1FAHAlj7TBdX5bjzfQ=";
    };
    aarch64-linux = {
      asset = "T3-Code-${version}-arm64.AppImage";
      hash = "sha256-wlbYctNY6fLJEyiwFUxjEfousWOG7294j82hLXPPKDY=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/${source.asset}";
    inherit (source) hash;
  };
  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands = ''
    if [ -d ${appimageContents}/usr/share ]; then
      mkdir -p "$out/share"
      cp -r ${appimageContents}/usr/share/* "$out/share/"
    fi

    desktop_file="$(find "$out/share/applications" -type f -name '*.desktop' -print -quit 2>/dev/null || true)"
    if [ -z "$desktop_file" ] && [ -f ${appimageContents}/t3code.desktop ]; then
      desktop_file="$out/share/applications/t3code.desktop"
      install -Dm444 ${appimageContents}/t3code.desktop "$desktop_file"
    fi

    substituteInPlace "$desktop_file" \
      --replace-fail "Exec=AppRun" "Exec=t3code"

    install -Dm444 ${appimageContents}/t3code.png "$out/share/pixmaps/t3code.png"

    desktop_basename="$(basename "$desktop_file")"
    wrapProgram "$out/bin/t3code" \
      --set CHROME_DESKTOP "$desktop_basename" \
      --prefix XDG_DATA_DIRS : "$out/share"
  '';

  meta = {
    description = "Agentic coding interface for running coding agents on your machine";
    homepage = "https://t3.codes";
    changelog = "https://github.com/pingdotgg/t3code/releases/tag/v${version}";
    downloadPage = "https://github.com/pingdotgg/t3code/releases";
    license = lib.licenses.mit;
    mainProgram = "t3code";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = builtins.attrNames sources;
  };
}
