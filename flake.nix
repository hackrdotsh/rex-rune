{
  description = "Native Linux client for Rex terminal servers";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          rex-linux = pkgs.callPackage ./nix/package.nix { };
          default = self.packages.${system}.rex-linux;
        }
      );

      checks = forAllSystems (system: {
        inherit (self.packages.${system}) rex-linux;
      });
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
