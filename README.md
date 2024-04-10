# quadlet-nix

Manages Podman containers and networks on NixOS via [Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html).

## Why

Compared to alternatives like [`virtualisation.oci-containers`](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/oci-containers.nix) or [`arion`](https://github.com/hercules-ci/arion), `quadlet-nix` is special in that:

|                                                       | `quadlet-nix` | `oci-containers` | `arion` |
|-------------------------------------------------------|---------------|------------------|---------|
| **Supports networks**                                 | ✅            | ❌               | ✅      |
| **Updates / deletes networks on change**              | ✅            | /                | ❌      |
| **Supports [podman-auto-update][podman-auto-update]** | ✅            | ✅               | ❌      |
| **Supports rootless containers**                      | ✅            | ❌               | ❓      |

[podman-auto-update]: https://docs.podman.io/en/latest/markdown/podman-auto-update.1.html


## How (rootful)

See [`container.nix`](./container.nix) and [`network.nix`](./network.nix) for all options.

### `flake.nix`

```nix
{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
        quadlet-nix.inputs.nixpkgs.follows = "nixpkgs";
    };
    outputs = { nixpkgs, quadlet-nix, ... }@attrs: {
        nixosConfigurations.machine = nixpksg.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
                ./configuration.nix
                quadlet-nix.nixosModules.quadlet
            ];
        };
    };
}
```

### `configuration.nix`

```nix
{
    # ...
    virtualisation.quadlet = {
        containers = {
            nginx.containerConfig.image = "docker.io/library/nginx:latest";
            nginx.containerConfig.networks = [ "host" "internal.network" ];
            nginx.serviceConfig.TimeoutStartSec = "60";
        };
        networks = {
            internal.networkConfig.subnets = [ "10.0.123.1/24" ];
        };
    };
}
```

## How (rootless)

See [`container.nix`](./container.nix) and [`network.nix`](./network.nix) for all options.

### `flake.nix`

```nix
{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        home-manager.url = "github:nix-community/home-manager";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
        quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
        quadlet-nix.inputs.nixpkgs.follows = "nixpkgs";
        quadlet-nix.inputs.home-manager.follows = "home-manager";
    };
    outputs = { nixpkgs, quadlet-nix, home-manager, ... }@attrs: {
        nixosConfigurations.machine = nixpksg.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
                ./configuration.nix
                home-manager.nixosModules.home-manager
                quadlet-nix.nixosModules.quadlet
            ];
        };
    };
}
```

### `configuration.nix`

```nix
{
    # ...
    users.users.alice = {
        # ... insert your user config here
        # The follow lines are the important ones for rootless podman
        home = "/home/alice";
        linger = true;
        autoSubUidGidRange = true;
    };
    home-manager.users.alice =
        { pkgs, config, ... }:
        {
            imports = [ inputs.quadlet-nix.homeManagerModules.default ];
            home.stateVersion = "21.11";
            home.homeDirectory = "/home/alice";
            systemd.user.startServices = "sd-switch"; # This is crucial to ensure the systemd services are (re)started
            virtualisation.user.quadlet.containers = {
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
