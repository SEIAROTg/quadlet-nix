# Tests

To run all tests:

```sh
nix flake check \
    --recreate-lock-file \
    --override-input quadlet-nix "path:$(pwd)" \
    --override-input nixpkgs 'github:NixOS/nixpkgs/nixos-unstable' \
    --override-input home-manager 'github:nix-community/home-manager/master' \
    ./tests
```

To run individual test (e.g. `basic-rootful`):

```sh
nix run \
  --recreate-lock-file \
  --override-input quadlet-nix "path:$(pwd)" \
  --override-input nixpkgs 'github:NixOS/nixpkgs/nixos-unstable' \
  --override-input home-manager 'github:nix-community/home-manager/master' \
  './tests#checks.x86_64-linux.basic-rootful.driver'
```
