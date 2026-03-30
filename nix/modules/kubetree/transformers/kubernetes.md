# Kubernetes primitives transformer

The kubernetes primitives module can transform the following properties on a Pod
specification from an attrset to lists.

```
initContainersByName
containersByName
volumesByName
```

In the container specification the following properties are transformed:

```
envByName
portsByName
volumeMountsByPath
```

In the service spec only `portsByName` is transformed.

## Example

A normal deployment might look like this

```nix
services.k3s.manifests.netutils.content = {
  apiVersion = "apps/v1";
  kind = "Deployment";
  metadata = {
    namespace = "default";
    name = "netutils";
    labels."app.kubernetes.io/name" = "netutils";
  };
  spec = {
    selector.matchLabels."app.kubernetes.io/name" = "netutils";
    template.metadata.labels."app.kubernetes.io/name" = "netutils";
    template.spec.containers = [
      {
        name = "netutils";
        image = "netutils:latest";
        command = ["iperf2" "-s"];
        env = [
          {
            name = "MYENV";
            value = "42"
          }
        ];
        ports = [
          {
            name = "server";
            containerPort = 5001;
          }
        ];
        volumeMounts = [
          {
            name = "data";
            mountPath = "/data";
          }
        ];
      }
    ];
    template.spec.volumes = [
      {
        name = "data";
        hostPath.path = "/cluster/data";
        hostPath.type = "DirectoryOrCreate";
      }
    ];
  };
};
```

This can be converted to:

```nix
kubetree.k3s.enable = true;
kubetree.resources.netutils.deployment = {
  apiVersion = "apps/v1";
  kind = "Deployment";
  metadata = {
    namespace = "default";
    name = "netutils";
    labels."app.kubernetes.io/name" = "netutils";
  };
  spec = {
    selector.matchLabels."app.kubernetes.io/name" = "netutils";
    template.metadata.labels."app.kubernetes.io/name" = "netutils";
    template.spec.containersByName.netutils = {
      name = "netutils";
      image = "netutils:latest";
      command = ["iperf2" "-s"];
      envByName.MYENV = "42";
      portsByName.server = 5001;
      volumeMountsByPath."/data" = "data";
    };
    template.spec.volumesByName.data.hostPath = {
      path = "/cluster/data";
      type = "DirectoryOrCreate";
    };
  };
};
```

Note that the values need not be attrsets. Depending on the property, a default
is assumed (`value:` for `env:`, `containerPort:` for `ports:` etc.).
