{
  description = "Nix Kubetree";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs =
    {
      systems,
      flake-parts,
      nixpkgs,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        flake-parts-lib,
        self,
        lib,
        ...
      }@mkFlakeArgs:
      let
        inherit (flake-parts-lib) importApply;
      in
      {
        flake = {
          lib.transform = import ./nix/lib/transform.nix { inherit lib; };
          nixosModules.default = importApply ./nix/modules/kubetree mkFlakeArgs;
        };
      }
    );
}
