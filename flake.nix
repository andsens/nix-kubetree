{
  description = "Nix Kubetree";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    docs.url = "github:andsens/nix-docs";
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
        systems = import systems;
        flake = {
          lib.importsApply = map (path: importApply path { inherit self inputs; });
          lib.transform = import ./nix/lib/transform.nix { inherit lib; };
          nixosModules.default = importApply ./nix/modules/kubetree mkFlakeArgs;
        };
        perSystem =
          { pkgs, system, ... }:
          let
            lib-docs = inputs.docs.lib.docs.lib {
              inherit pkgs;
              paths.lib = ./nix/lib;
            };
            options-docs = inputs.docs.lib.docs.options {
              inherit pkgs;
              repoPath = toString self;
              repoLinkPrefix = "https://github.com/andsens/nix-kubetree/blob/main";
              options =
                (lib.evalModules { modules = lib.attrValues self.nixosModules ++ [ { _module.check = false; } ]; })
                .options.kubetree;
            };
          in
          {
            apps.update-docs.program = inputs.docs.lib.docs.updateRepo {
              inherit pkgs;
              paths."docs/lib" = "${lib-docs}/lib";
              paths."docs/options.md" = options-docs.optionsCommonMark;
            };
            packages = {
              lib-docs = lib-docs;
              options-docs = options-docs.optionsCommonMark;
            };
          };
      }
    );
}
