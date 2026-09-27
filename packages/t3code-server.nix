{
  lib,
  stdenvNoCC,
  asar,
  makeWrapper,
  nodejs_24,
  t3code,
}:

# The desktop AppImage bundles the same headless server that `npx t3` ships,
# so reuse it rather than tracking a second upstream artifact.
stdenvNoCC.mkDerivation {
  pname = "t3code-server";
  inherit (t3code) version;

  dontUnpack = true;

  nativeBuildInputs = [
    asar
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    resources=${t3code.appimageContents}/resources
    app="$out/lib/t3code"

    asar extract "$resources/app.asar" "$app"
    cp -rT "$resources/app.asar.unpacked" "$app"
    chmod -R u+w "$app"
    rm -rf "$app/apps/desktop"

    makeWrapper ${lib.getExe nodejs_24} "$out/bin/t3" \
      --add-flags "$app/apps/server/dist/bin.mjs"

    runHook postInstall
  '';

  meta = t3code.meta // {
    description = "Headless T3 Code server for connecting from the browser or other devices";
    mainProgram = "t3";
  };
}
