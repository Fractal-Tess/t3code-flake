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
      packageFor = system: nixpkgs.legacyPackages.${system}.callPackage ./packages/t3code.nix { };
    in
    {
      packages = forAllSystems (
        system:
        let
          t3code = packageFor system;
        in
        {
          inherit t3code;
          default = t3code;
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.t3code}/bin/t3code";
          meta.description = "Run T3 Code";
        };
      });

      checks = forAllSystems (system: {
        t3code = self.packages.${system}.t3code;
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      overlays.default = final: _previous: {
        t3code = final.callPackage ./packages/t3code.nix { };
      };

      nixosModules.default = import ./modules/nixos.nix { inherit self; };
      homeManagerModules.default = import ./modules/home-manager.nix { inherit self; };
    };
}
