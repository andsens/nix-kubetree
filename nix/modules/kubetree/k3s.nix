{ self, ... }:
{
  lib,
  config,
  pkgs,
  ...
}:
with builtins;
let
  cfg = config.kubetree;
  transform = self.lib.transform;
in
{
  options.kubetree.k3s = {
    enable = lib.mkEnableOption "applying kubetree.manifests to services.k3s.manifests";
    # run `nix build '.#nixosConfigurations."<HOSTNAME>".config.kubetree.k3s.payload'` to output the payload
    payload = lib.mkOption {
      description = "A derivation containing all manifests and images that will be sent to k3s";
      type = lib.types.package;
      readOnly = true;
      default = pkgs.stdenvNoCC.mkDerivation {
        name = "k3s-payload";
        dontUnpack = true;
        installPhase = ''
          runHook preInstall
          mkdir "$out"
          ${lib.join "" (
            lib.mapAttrsToList (path: value: ''
              mkdir -p "$out/${baseNameOf (dirOf path)}"
              ln -s "${value."L+".argument}" "$out/${baseNameOf (dirOf path)}/${baseNameOf path}"
            '') config.systemd.tmpfiles.settings."10-k3s"
          )}
          runHook postInstall
        '';
      };
    };
  };
  config = {
    services.k3s.manifests = lib.mkIf cfg.k3s.enable (
      mapAttrs (manifestName: items: {
        content =
          let
            list = lib.foldl' (
              list: item:
              list
              ++ (
                if transform.isResourceList item then (transform.flattenResourceList cfg item).items else [ item ]
              )
            ) [ ] (attrValues items);
          in
          if length list == 1 then head list else list;
      }) cfg.manifests
    );
  };
}
