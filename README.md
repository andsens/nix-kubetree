# nix-kubetree

Pluggable module for performing tree transformations on Nix kubernetes manifests.

Comes with a built-in kubernetes primitives module that provides various
properties on normal pod specifications, which eases both the writing and
improves the readability of manifests.  
See the [docs](nix/modules/kubetree/transformers/kubernetes.md) for more.

## Configuring resources

Resources are specified on `kubetree.resources.<MANIFESTNAME>.<ITEMNAME>`:

```nix
kubetree.resources.netutils.deployment = {
  apiVersion = "apps/v1";
  kind = "Deployment";
  metadata = {
    namespace = "default";
    name = "netutils";
  };
  spec = {
    selector.matchLabels."app.kubernetes.io/name" = "netutils";
    ...
  };
};
```

The transformed resources will be available at `kubetree.manifests.<MANIFESTNAME>.<ITEMNAME>`

## `services.k3s` integration

The manifests can be applied to k3s automatically. Enable with
`kubetree.k3s.enable = true`.

## Adding your own transformers

Enhancing kubetree with your own transformers is fairly straightforward.
Simply configure the functions on
`kubetree.transformers.<APIGROUP>.<KIND>.<SPECPATH>._transformers = [<FN>]`.

An example explains this better:

```nix
kubetree.transformers.v1.Pod.spec.containers."[]"._transformers = [ (
  cfg: resource: resource // { imagePullPolicy = "Always" }
) ];
```

This transformer adds `imagePullPolicy: Always` to all containers on all Pods.  
The `"[]"` part of the config path instructs kubetree to apply the
transformation to all items in a list.  
`cfg` is `config.kubetree`, meaning you can enhance the configuration tree with
your own namespaced settings and have them available when your transformer is
evaluated.
