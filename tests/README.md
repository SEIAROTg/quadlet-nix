# Tests

To run all tests:

```sh
nix flake check \
    --override-input quadlet-nix "path:$(pwd)" \
    --override-input nixpkgs 'github:NixOS/nixpkgs/nixos-unstable' \
    --override-input home-manager 'github:nix-community/home-manager/master' \
    ./tests
```

To run individual test (e.g. `basic-rootful`):

```sh
nix run \
  --override-input quadlet-nix "path:$(pwd)" \
  --override-input nixpkgs 'github:NixOS/nixpkgs/nixos-unstable' \
  --override-input home-manager 'github:nix-community/home-manager/master' \
  './tests#checks.x86_64-linux.basic-rootful.driver'
```
