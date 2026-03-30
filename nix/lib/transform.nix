{ lib, ... }:
with builtins;
rec {

  updatePath =
    resource: path: update:
    lib.recursiveUpdate resource (if length path > 0 then lib.setAttrByPath path update else update);

  replacePath =
    resource: path: update:
    if length path > 0 then updatePath (removeAttrByPath path resource) path update else update;

  removeAttrByPath =
    attrPath: e:
    let
      lenAttrPath = length attrPath;
      removeAttrByPath' =
        n: s:
        (
          let
            attr = elemAt attrPath n;
          in
          if n == lenAttrPath - 1 then
            removeAttrs s [ attr ]
          else if s ? ${attr} then
            removeAttrs s [ attr ] // { ${attr} = removeAttrByPath' (n + 1) s.${attr}; }
          else
            s
        );
    in
    removeAttrByPath' 0 e;

  mergeAttrsIntoList =
    keyPath: list: attrs:
    let
      updated =
        lib.foldl'
          (
            { newList, attrsLeft }:
            item:
            let
              key = lib.attrByPath keyPath null item;
              update = lib.attrByPath [ key ] null attrsLeft;
            in
            if update != null then
              {
                newList = newList ++ [
                  (lib.recursiveUpdate item update)
                ];
                attrsLeft = removeAttrs [ key ] attrsLeft;
              }
            else
              {
                newList = newList;
                attrsLeft = attrsLeft;
              }
          )
          {
            newList = [ ];
            attrsLeft = attrs;
          }
          list;
      attrsTail = lib.mapAttrsToList (key: item: replacePath item keyPath key) updated.attrsLeft;
    in
    updated.newList ++ attrsTail;

  transformKeyedList =
    {
      keyedListPath,
      keyPath,
      mergeWithPath,
      nonAttrKeyPath ? null,
    }:
    cfg: resource:
    let
      _keyedListPath = lib.splitString "." keyedListPath;
      _keyPath = lib.splitString "." keyPath;
      _mergeWithPath = lib.splitString "." mergeWithPath;
      keyedList = lib.attrByPath _keyedListPath { } resource;
      unkeyedList = (lib.attrByPath _mergeWithPath [ ] resource);
      normalizedUpdates =
        if nonAttrKeyPath != null then
          mapAttrs (
            name: value:
            if isAttrs value then value else lib.setAttrByPath (lib.splitString "." nonAttrKeyPath) value
          ) keyedList
        else
          keyedList;
      transformedList = mergeAttrsIntoList _keyPath unkeyedList normalizedUpdates;
      cleanedResource = removeAttrByPath _keyedListPath resource;
    in
    if length transformedList > 0 then
      replacePath cleanedResource _mergeWithPath transformedList
    else
      cleanedResource;

  applyPaths =
    pathMap:
    let
      transformerList =
        (lib.attrByPath [ "_transformers" ] [ ] pathMap)
        ++ (lib.mapAttrsToList (
          key: pathMap: cfg: resource:
          addErrorContext "while transforming '${key}'" (
            if key == "[]" then
              map (item: applyPaths pathMap cfg item) resource
            else if hasAttr key resource then
              resource
              // {
                "${key}" = applyPaths pathMap cfg resource."${key}";
              }
            else
              resource
          )
        ) (removeAttrs pathMap [ "_transformers" ]));
    in
    if isAttrs pathMap then
      chainTransformers transformerList
    else
      throw "The transformer pathmap must be an attrset (found ${typeOf pathMap})";

  chainTransformers =
    transformers: cfg: resource:
    lib.foldl' (updatedResource: transformer: transformer cfg updatedResource) resource transformers;

  showResource = cfg: resource: trace (toJSON resource) resource;

  flattenResourceList =
    cfg: resource:
    if isResourceList resource then
      replacePath resource [ "items" ] (
        lib.foldl' (
          list: item: list ++ (if isResourceList item then (flattenResourceList cfg item).items else [ item ])
        ) [ ] resource.items
      )
    else
      resource;

  isKind =
    group: kind: resource:
    let
      rGroup = head (split "/" (lib.attrByPath [ "apiVersion" ] "" resource));
      rKind = head (split "/" (lib.attrByPath [ "kind" ] "" resource));
    in
    rGroup == group && rKind == kind;

  isResourceList = isKind "v1" "List";

  transformerFor =
    resource:
    let
      group = head (split "/" (lib.attrByPath [ "apiVersion" ] "" resource));
      identity = (cfg: resource: resource);
    in
    if hasAttr "kind" resource then
      cfg: resource:
      addErrorContext "while transforming ${group}/${resource.kind}" (
        applyPaths (lib.attrByPath [
          group
          resource.kind
        ] { "." = [ identity ]; } cfg.transformers) cfg resource
      )
    else
      cfg: resource: throw "Resource has no Kind specified: ${toJSON resource}";

  transformResource = cfg: resource: (transformerFor resource) cfg resource;
}
