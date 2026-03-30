{ self, ... }:
{ lib, config, ... }:
let
  cfg = config.kubetree;
in
{
  options.kubetree = with builtins; {
    resources = lib.mkOption {
      description = "A nested attrset mapping of manifest name -> item name -> resource";
      type = lib.types.attrsOf (lib.types.attrsOf (lib.types.attrsOf lib.types.anything));
    };
    transformers = lib.mkOption {
      description = "A nested attrset mapping of APIGroup -> Kind -> resource dot-path -> '_transform' -> [transformer]";
      type = lib.types.attrsOf (lib.types.attrsOf (lib.types.attrsOf lib.types.anything));
      default = { };
    };
    manifests = lib.mkOption {
      description = "Map of all converted resources";
      type = lib.types.attrs;
      readOnly = true;
      default = mapAttrs (
        manifestName: items:
        mapAttrs (
          itemName: resource:
          addErrorContext "while evaluating the manifest kubetree.resources.${manifestName}.${itemName}" (
            self.lib.transform.transformResource cfg resource
          )
        ) items
      ) config.kubetree.resources;
    };
  };
  imports = [
    (import ./transformers/kubernetes.nix { inherit self; })
    (import ./k3s.nix { inherit self; })
  ];
}
