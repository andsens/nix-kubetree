## kubetree\.k3s\.enable

Whether to enable applying kubetree\.manifests to services\.k3s\.manifests\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [nix/modules/kubetree/default\.nix](https://github.com/andsens/nix-kubetree/blob/main/nix/modules/kubetree/default.nix)



## kubetree\.k3s\.payload



A derivation containing all manifests and images that will be sent to k3s



*Type:*
package *(read only)*



*Default:*

```nix
""
```

*Declared by:*
 - [nix/modules/kubetree/default\.nix](https://github.com/andsens/nix-kubetree/blob/main/nix/modules/kubetree/default.nix)



## kubetree\.kubernetes\.enable



Whether to enable Kubernetes primitives transformers\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [nix/modules/kubetree/default\.nix](https://github.com/andsens/nix-kubetree/blob/main/nix/modules/kubetree/default.nix)



## kubetree\.manifests



Map of all converted resources



*Type:*
attribute set *(read only)*



*Default:*

```nix
""
```

*Declared by:*
 - [nix/modules/kubetree/default\.nix](https://github.com/andsens/nix-kubetree/blob/main/nix/modules/kubetree/default.nix)



## kubetree\.resources



A nested attrset mapping of manifest name -> item name -> resource



*Type:*
attribute set of attribute set of attribute set of anything



*Default:*

```nix
{ }
```

*Declared by:*
 - [nix/modules/kubetree/default\.nix](https://github.com/andsens/nix-kubetree/blob/main/nix/modules/kubetree/default.nix)



## kubetree\.transformers



A nested attrset mapping of APIGroup -> Kind -> resource dot-path -> ‘_transform’ -> \[transformer]



*Type:*
attribute set of attribute set of attribute set of anything



*Default:*

```nix
{ }
```

*Declared by:*
 - [nix/modules/kubetree/default\.nix](https://github.com/andsens/nix-kubetree/blob/main/nix/modules/kubetree/default.nix)


