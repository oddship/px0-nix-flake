{
  description = "Source-built, automatically updated Nix package for px0";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system: {
        default = self.packages.${system}.px0;
        px0 = nixpkgs.legacyPackages.${system}.callPackage ./package.nix { };
      });
      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.px0}/bin/px0";
          meta.description = "Open px0 in your browser";
        };
      });
      overlays.default = final: prev: { px0 = final.callPackage ./package.nix { }; };
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          package = self.packages.${system}.px0;
          smoke = pkgs.runCommand "px0-smoke" { nativeBuildInputs = [ pkgs.python3 ]; } ''
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"
            python ${./tests/smoke.py} ${self.packages.${system}.px0}/bin/px0
            touch "$out"
          '';
        }
      );
      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShellNoCC {
          packages = with nixpkgs.legacyPackages.${system}; [
            go_1_26
            nodejs
            nix-update
            nixfmt
            jq
            gh
            actionlint
          ];
        };
      });
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
