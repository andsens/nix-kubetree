# transform 


## `lib.transform.updatePath` 

Set `resource`'s value at `path` to `update`.

### Arguments

`resource`: The attrset to update

`path` (`[String]`): Attribute path (as used by `lib.setAttrByPath`) to
set. Pass `[ ]` to update `resource` itself.

`update`: The value to set at `path`

### Example

```nix
updatePath { a.b = 1; a.c = 2; } [ "a" "b" ] 42
=> { a.b = 42; a.c = 2; }
```

## `lib.transform.replacePath` 

Replace `resource`'s value at `path` with `update`, discarding whatever
was there before.

Passing `[ ]` for `path` returns `update` as-is, discarding `resource`
entirely.

### Arguments

`resource`: The attrset to update

`path` (`[String]`): Attribute path at which to replace the current
value with `update`. Pass `[ ]` to replace `resource` itself.

`update`: The value to place at `path`

### Example

```nix
replacePath { a = { x = 1; y = 2; }; } [ "a" ] { y = 3; }
=> { a = { y = 3; }; }
```

## `lib.transform.removeAttrByPath` 

Remove the attribute found at `attrPath` from `e`, leaving every other
attribute in the tree untouched. If any element of `attrPath` doesn't
exist in `e`, `e` is returned unmodified.

### Arguments

`attrPath` (`[String]`): Path of attribute names leading to the
attribute that should be removed

`e`: The attrset to remove the attribute from

### Example

```nix
removeAttrByPath [ "a" "b" ] { a = { b = 1; c = 2; }; d = 3; }
=> { a = { c = 2; }; d = 3; }
```

## `lib.transform.mergeAttrsIntoList` 

Merge an attrset of keyed updates into `list`, matching each update to
the list item whose value at `keyPath` equals the update's attribute
name.

Matched items are merged with their update in their original position;
items without a matching update are kept as-is. Updates that don't
match any existing item are appended to the end of the returned list,
with their attribute name written into the new item at `keyPath`.

### Arguments

`keyPath` (`[String]`): Attribute path, within each list item, holding
the value that update keys are matched against

`list`: The list of items to merge updates into

`attrs` (`{ [KeyValue] :: AttrSet }`): An attrset of updates, keyed by
the value they should be matched against in `list`'s items

### Example

```nix
mergeAttrsIntoList [ "name" ]
  [ { name = "a"; x = 1; } { name = "b"; x = 2; } ]
  { a = { x = 99; }; c = { x = 3; }; }
=> [ { name = "a"; x = 99; } { name = "b"; x = 2; } { name = "c"; x = 3; } ]
```

This is the function that powers the "ByName" attrsets used throughout
kubetree's Kubernetes primitives (e.g. `containersByName`, `envByName`);
see [`transformKeyedList`](#libtransformtransformkeyedlist).

## `lib.transform.transformKeyedList` 

Build a transformer that expands an attrset shorthand such as
`containersByName` into the equivalent Kubernetes list (`containers`),
merging it with any list of the same name already present on
`resource`. If the result is empty, `mergeWithPath` is left absent
rather than set to `[ ]`.

Values in the keyed attrset need not be attrsets themselves: when
`nonAttrKeyPath` is set, a plain value (e.g. `"42"`) is expanded to an
attrset with that value at `nonAttrKeyPath`. This is what lets you
write `envByName.MYENV = "42";` instead of
`envByName.MYENV.value = "42";`.

### Arguments

`keyedListPath` (`[String]`): Attribute path (relative to `resource`) of
the attrset to read updates from, e.g. `[ "containersByName" ]`

`keyPath` (`[String]`): Attribute path (within each item of the target
list) that updates are matched against, e.g. `[ "name" ]`

`mergeWithPath` (`[String]`): Attribute path (relative to `resource`) of
the list to merge the updates into, e.g. `[ "containers" ]`

`nonAttrKeyPath` (`[String]`): Attribute path (within each new item)
that a non-attrset update value should be written to, e.g.
`[ "value" ]` for `env` entries (*optional*)

### Example

```nix
kubetree.transformers.v1.Service.spec._transformers = [
  (transform.transformKeyedList {
    keyedListPath = [ "portsByName" ];
    keyPath = [ "name" ];
    mergeWithPath = [ "ports" ];
    nonAttrKeyPath = [ "port" ];
  })
];
```

Turns

```nix
spec.portsByName.http = 8080;
```

into

```nix
spec.ports = [ { name = "http"; port = 8080; } ];
```

Built on [`mergeAttrsIntoList`](#libtransformmergeattrsintolist).
This is the function backing every `*ByName` transformer in
[`transformers/kubernetes.nix`](../../nix/modules/kubetree/transformers/kubernetes.nix)
(`containersByName`, `envByName`, `portsByName`, `volumeMountsByPath`,
`volumesByName`).

## `lib.transform.applyPaths` 

The engine behind `kubetree.transformers`: turns a `pathMap` -- a nested
attrset that mirrors the shape of a resource, as configured on
`kubetree.transformers.<APIGROUP>.<KIND>` -- into a single
`cfg: resource: resource` transformer function. Every `_transformers`
list found in `pathMap` is run at the matching position in `resource`,
leaving the rest of the resource untouched; the special path segment
`"[]"` applies its transformers to every item of a list instead of to a
single attribute.

This is what lets a config path like
`kubetree.transformers.v1.Pod.spec.containers."[]"._transformers` reach
into `resource.spec.containers` and run its transformers on each
container.

### Arguments

`pathMap`: A nested attrset of `{ [AttrName|"[]"] :: pathMap; _transformers :: [ (cfg: resource: resource) ]; }`

### Example

```nix
(transform.applyPaths {
  spec.containers."[]"._transformers = [
    (cfg: container: container // { imagePullPolicy = "Always"; })
  ];
}) cfg resource
```

Each level's `_transformers` list is run via
[`chainTransformers`](#libtransformchaintransformers).

## `lib.transform.chainTransformers` 

Thread `resource` through a list of `cfg: resource: resource`
transformer functions in order, feeding each transformer's output into
the next.

### Arguments

`transformers` (`[ (cfg: resource: resource) ]`): The transformer
functions to apply, in order

`cfg`: Passed unchanged to every transformer (this is `config.kubetree`
when called through `kubetree.transformers`)

`resource`: The value to transform

### Example

```nix
chainTransformers [
  (cfg: r: r // { a = 1; })
  (cfg: r: r // { b = 2; })
] cfg { }
=> { a = 1; b = 2; }
```

## `lib.transform.showResource` 

A debugging transformer: prints `resource` as JSON to stderr (via
`builtins.trace`) and returns it unchanged. Drop it into a
`_transformers` list to inspect what a resource looks like at that point
in the pipeline.

### Arguments

`cfg`: Unused, present for compatibility with the `cfg: resource:
resource` transformer signature

`resource`: The value to print and pass through

### Example

```nix
kubetree.transformers.v1.Pod.spec._transformers = [ transform.showResource ];
```

## `lib.transform.flattenResourceList` 

If `resource` is a Kubernetes `v1/List`, recursively flatten any `List`
resources nested in its `items` so the result is a single `List` whose
`items` contains no further `List`s. Any other resource is returned
unchanged.

### Arguments

`cfg`: Unused, present for compatibility with the `cfg: resource:
resource` transformer signature

`resource`: The resource to flatten

### Example

```nix
transform.flattenResourceList cfg {
  apiVersion = "v1";
  kind = "List";
  items = [
    { apiVersion = "v1"; kind = "ConfigMap"; }
    {
      apiVersion = "v1";
      kind = "List";
      items = [ { apiVersion = "v1"; kind = "Service"; } ];
    }
  ];
}
=> {
  apiVersion = "v1";
  kind = "List";
  items = [
    { apiVersion = "v1"; kind = "ConfigMap"; }
    { apiVersion = "v1"; kind = "Service"; }
  ];
}
```

See [`isResourceList`](#libtransformisresourcelist)
for the check used to recognize a `v1/List`.

## `lib.transform.isKind` 

Check whether `resource`'s `apiVersion` belongs to `group` and its
`kind` equals `kind`. The API group is the part of `apiVersion` before
the `/`, or the whole string when there is no `/` (matching the way
core resources such as `v1/Pod` are keyed by `"v1"` in
`kubetree.transformers`).

### Arguments

`group` (`String`): The API group to match against, e.g. `"apps"` or
`"v1"`

`kind` (`String`): The `kind` to match against, e.g. `"Deployment"`

`resource`: The resource to check

### Example

```nix
isKind "apps" "Deployment" { apiVersion = "apps/v1"; kind = "Deployment"; }
=> true
```

## `lib.transform.isResourceList` 

Check whether `resource` is a Kubernetes `v1/List`, i.e. a bag of
resources produced by expanding one resource into several.

### Arguments

`resource`: The resource to check

### Example

```nix
isResourceList { apiVersion = "v1"; kind = "List"; items = [ ]; }
=> true
```

Used by `kubetree.k3s.enable` and
[`flattenResourceList`](#libtransformflattenresourcelist)
to know when a resource needs unwrapping.

## `lib.transform.transformerFor` 

Look up the transformer configured for `resource`'s API group and
`kind` under `cfg.transformers.<APIGROUP>.<KIND>` and turn it into a
`cfg: resource: resource` function. If nothing is configured for that
group/kind, the returned function is a no-op.

Throws if `resource` has no `kind`.

### Arguments

`resource`: The resource to find a transformer for

### Example

```nix
(transform.transformerFor resource) cfg resource
```

Built on [`applyPaths`](#libtransformapplypaths);
you'll normally reach for
[`transformResource`](#libtransformtransformresource)
instead, which calls this and applies the result in one step.

## `lib.transform.transformResource` 

Apply all transformers configured for `resource`'s API group and `kind`
(under `cfg.transformers.<APIGROUP>.<KIND>`) to `resource`, and return
the result. This is `kubetree`'s main entry point for transforming a
single resource, and is what `kubetree.manifests` calls for every
resource in `kubetree.resources`.

Since a transformer can turn one resource into a resource of a
different `kind` (e.g. a custom `WorkloadMacro` into a `Deployment`),
it's common to list `transform.transformResource` itself as the last
entry in a `_transformers` list, so the newly produced resource gets
transformed again according to its own `kind`.

### Arguments

`cfg`: The config to look up transformers on and pass to them (this is
`config.kubetree`)

`resource`: The resource to transform

### Example

```nix
kubetree.transformers."cluster.local".DeploymentMacro._transformers = [
  myMacros.transformDeploymentMacro
  transform.transformResource
];
```

## `lib.transform.mkResourceHelper` 

Convenience helpers for writing transformers that read values out of
`resource` by dot-path, for use in custom `_transformers` functions
(`cfg: resource: ...`).

### Arguments

`resource`: The resource to build helpers for

### Output

An attrset with:

- `dotPath` (`path: default: value`): Look up a dot-separated attribute
  path in `resource` (e.g. `"spec.dataPath"`), returning `default` if
  any part of the path is missing. Pass `"."` for `path` to get
  `resource` itself.
- `inheritPaths` (`paths: attrs`): Given a list of dot-paths, look each
  one up in `resource` with `dotPath` and collect the ones that
  resolved to a non-null value into a flat attrset, keyed by the last
  segment of each path.

### Example

```nix
transformWorkloadMacro =
  cfg: resource:
  let
    inherit (transform.mkResourceHelper resource) dotPath inheritPaths;
    dataPath = dotPath "spec.dataPath" null;
  in
  {
    metadata.labels."has-data" = dataPath != null;
  }
  // (inheritPaths [ "spec.allowIngress" "spec.allowEgress" ]);
```


