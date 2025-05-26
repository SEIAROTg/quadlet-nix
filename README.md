# quadlet-nix

Manages Podman containers, networks, pods, etc. on NixOS via [Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html).

## Why

Compared to alternatives like [`virtualisation.oci-containers`](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/oci-containers.nix) or [`arion`](https://github.com/hercules-ci/arion), `quadlet-nix` is special in that:

|                                                          | `quadlet-nix` | `oci-containers` | `arion` |
| -------------------------------------------------------- | ------------- | ---------------- | ------- |
| **Supports networks / pods**                             | ✅            | ❌               | ✅      |
| **Updates / deletes networks on change**                 | ✅            | /                | ❌      |
| **Supports [podman-auto-update][podman-auto-update]**    | ✅            | ✅               | ❌      |
| **Supports rootless containers**                         | ✅            | ❌               | ❓      |

[podman-auto-update]: https://docs.podman.io/en/latest/markdown/podman-auto-update.1.html

## How

See [seiarotg.github.io/quadlet-nix](https://seiarotg.github.io/quadlet-nix) for all options.

### Example (rootful)

#### `flake.nix`

```nix
{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
    };
    outputs = { nixpkgs, quadlet-nix, ... }@attrs: {
        nixosConfigurations.machine = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
                ./configuration.nix
                quadlet-nix.nixosModules.quadlet
            ];
        };
    };
}
```

#### `configuration.nix`

```nix
{ config, ... }: {
    # ...
    virtualisation.quadlet = let
        inherit (config.virtualisation.quadlet) networks pods;
    in {
        containers = {
            nginx.containerConfig.image = "docker.io/library/nginx:latest";
            nginx.containerConfig.networks = [ "podman" networks.internal.ref ];
            nginx.containerConfig.pod = pods.foo.ref;
            nginx.serviceConfig.TimeoutStartSec = "60";
        };
        networks = {
            internal.networkConfig.subnets = [ "10.0.123.1/24" ];
        };
        pods = {
            foo = { };
        };
    };
}
```

### Example (rootless)

#### `flake.nix`

```nix
{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        home-manager.url = "github:nix-community/home-manager";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
        quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
    };
    outputs = { nixpkgs, quadlet-nix, home-manager, ... }@attrs: {
        nixosConfigurations.machine = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
                ./configuration.nix
                home-manager.nixosModules.home-manager
                # to enable podman & podman systemd generator
                quadlet-nix.nixosModules.quadlet
            ];
        };
    };
}
```

#### `configuration.nix`

```nix
{
    # ...
    users.users.alice = {
        # ...
        # required for auto start before user login
        linger = true;
        # required for rootless container with multiple users
        autoSubUidGidRange = true;
    };
    home-manager.users.alice = { pkgs, config, ... }: {
        # ...
        imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];
        # This is crucial to ensure the systemd services are (re)started on config change
        systemd.user.startServices = "sd-switch";
        virtualisation.quadlet.containers = {
            echo-server = {
                autoStart = true;
                serviceConfig = {
                    RestartSec = "10";
                    Restart = "always";
                };
                containerConfig = {
                    image = "docker.io/mendhak/http-https-echo:31";
                    publishPorts = [ "127.0.0.1:8080:8080" ];
                    userns = "keep-id";
                };
            };
        };
    };
}
```

### Example (raw config)

`quadlet-nix` can also accept existing quadlet files without rewriting in Nix via `rawConfig`. Using this will cause all other options (except `autoStart`) to be ignored though.

```nix
{ config, ... }: {
    # ...
    virtualisation.quadlet = let
        inherit (config.virtualisation.quadlet) networks pods;
    in {
        containers = {
            nginx.rawConfig = ''
                [Container]
                Image=docker.io/library/nginx:latest
                Network=podman
                Network=${networks.internal.ref}
                Pod=${pods.foo.ref}
                [Service]
                TimeoutStartSec=60
            '';
        };
        networks = {
            internal.networkConfig.subnets = [ "10.0.123.1/24" ];
        };
        pods = {
            foo = { };
        };
    };
}
```
