{
  description = "T3 Code desktop app packaged for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      packagesFor =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          t3code = pkgs.callPackage ./packages/t3code.nix { };
        in
        {
          inherit t3code;
          t3code-server = pkgs.callPackage ./packages/t3code-server.nix { inherit t3code; };
        };
    in
    {
      packages = forAllSystems (system: packagesFor system // { default = (packagesFor system).t3code; });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.t3code}/bin/t3code";
          meta.description = "Run T3 Code";
        };
        server = {
          type = "app";
          program = "${self.packages.${system}.t3code-server}/bin/t3";
          meta.description = "Run the headless T3 Code server";
        };
      });

      checks = forAllSystems (system: {
        inherit (self.packages.${system}) t3code t3code-server;
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      overlays.default = final: _previous: {
        t3code = final.callPackage ./packages/t3code.nix { };
        t3code-server = final.callPackage ./packages/t3code-server.nix { };
      };

      nixosModules.default = import ./modules/nixos.nix { inherit self; };
      homeManagerModules.default = import ./modules/home-manager.nix { inherit self; };
    };
}
