# quadlet-nix

Manages Podman containers, networks, pods, etc. on NixOS via [Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html).

## Features

- Supports Podman containers, networks, pods, volumes, etc.
- Supports declarative update and deletion of networks.
- Supports rootful and rootless (via [Home Manager](https://github.com/nix-community/home-manager)) resources behind the same interface.
- Supports [Podman auto-update][podman-auto-update].
- Supports cross-referencing between resources in Nix language.
- Full quadlet options support, typed and properly escaped.
- Reliability through effective testing.
- Simplicity.
- Whatever offered by Nix or Quadlet.

[podman-auto-update]: https://docs.podman.io/en/latest/markdown/podman-auto-update.1.html

## Motivation

This project was started in Aug 2023, as a result of [the author's frustration on some relatively simple container management needs](https://seiarotg.me/post/tidy-up-homelab-containers/), where then available technologies are either overly restrictive, or overly complex that requires non-trivial but pointless investment ad-hoc domain knowledge.

`quadlet-nix` is designed to be a simple tool that just works. Quadlet options are directly mapped into Nix, allowing users to effectively manage their Podman resources in the Nix language, without having to acquire domain knowledge in yet another tool. Prior knowledge and documentation of Podman continue to apply.

## Comparison

Below are comparisons with several alternatives for declaratively managing Podman containers on NixOS, effective as of May 2025.

<details>
<summary><a href="https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/oci-containers.nix" target="_blank">NixOS <code>virtualisation.oci-containers</code></a></summary>

- 👍 Part of NixOS, no additional dependencies.
- 👍 Rootless container support without additional dependencies.
- 👍 Supports Docker.
- 😐 Compatible with podman auto-update (requires external setup).
- 👎 Limited options.
- 👎 Lack of support for networks, pods, etc.

</details>

<details>
<summary><a href="https://github.com/hercules-ci/arion" target="_blank"><code>arion</code></a></summary>

- 👍 Supports Docker.
- 😐 More indirection and moving parts.
- 👎 Limited options.
- 👎 Incompatible with podman auto-update.

</details>

<details>
<summary><a href="https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html"  target="_blank">Vanilla Podman Quadlet</a></summary>

- 👍 Even less indirection.
- 😐 Compatible with podman auto-update (requires external setup).
- 😐 Requires more work to set up.
- 👎 Not integrated with rest of Nix configuration.

</details>

<details>
<summary><a href="https://nix-community.github.io/home-manager/options.xhtml#opt-services.podman.enable" target="_blank">Home Manager <code>services.podman</code></a></summary>

- 👍 Part of Home Manager, no additional dependencies if you are already using it.
- 👎 Lack of rootful container support.

</details>

<details>
<summary><a href="https://github.com/aksiksi/compose2nix" target="_blank"><code>compose2nix</code></a></summary>

- 👍 Supports Docker.
- 😐 Compatible with podman auto-update (requires external setup).
- 😐 More indirection and moving parts.
- 👎 Less maintainable Nix files due to generated boilerplate.
- 👎 Manual regeneration is required.
- 👎 Lack of rootless container support.
- 👎 Limited options.
- 👎 Fragmented configuration with source of truth being outside of Nix.

</details>

## How

See [seiarotg.github.io/quadlet-nix](https://seiarotg.github.io/quadlet-nix) for all options.

## Recipes

<details open>
<summary>Rootful containers</summary>

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

</details>

<details>
<summary>Rootless containers (via Home Manager)</summary>

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
    # to enable podman & podman systemd generator
    virtualisation.quadlet.enable = true;
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

</details>

<details>
<summary>Rootless containers (in system systemd)</summary>

⚠️ Use at your own risk. This is not officially supported by Podman.

```nix
{ config, ... }: {
    users.users.alice = {
        uid = 1234;
        # required for auto start before user login
        linger = true;
        # required for rootless container with multiple users
        autoSubUidGidRange = true;
    };
    virtualisation.quadlet.containers.nginx = {
        rootlessConfig.uid = config.users.users.alice.uid;
        containerConfig.image = "docker.io/library/nginx:latest";
    };
}
```

</details>

<details>
<summary>Volumes</summary>

```nix
{ config, ... }: {
    # ...
    virtualisation.quadlet = let
        inherit (config.virtualisation.quadlet) volumes;
    in {
        containers.nginx.containerConfig.image = "docker.io/library/nginx:latest";
        containers.nginx.containerConfig.volumes = [
            "${volumes.nginx-config.ref}:/etc/nginx"
        ];
        volumes.nginx-config.volumeConfig = {
            type = "bind";
            device = "/path/to/host/directory";
        };
    };
}
```

</details>

<details>
<summary>Build (inlined <code>Containerfile</code>)</summary>

```nix
{ pkgs, config, ... }: {
    # ...
    virtualisation.quadlet = let
        inherit (config.virtualisation.quadlet) builds;
        containerfile = pkgs.writeText "Containerfile" ''
          FROM docker.io/library/nginx:latest
          # ...
        '';
    in {
        containers.nginx.containerConfig.image = builds.nginx.ref;
        builds.nginx.buildConfig.file = containerfile.outPath;
    };
}
```

</details>

<details>
<summary>Build (git repository)</summary>

```nix
{ config, ... }: {
    # ...
    virtualisation.quadlet = let
        inherit (config.virtualisation.quadlet) builds;
        src = builtins.fetchGit {
          url = "https://github.com/alpinelinux/docker-alpine.git";
          rev = "4dc13cbc7caffe03c98aa99f28e27c2fb6f7e74d";
        };
    in {
        containers.example.containerConfig = {
          image = builds.alpine.ref;
          entrypoint = "/bin/sh";
          exec = "-c 'echo 123'";
        };
        containers.example.serviceConfig.RemainAfterExit = true;
        builds.alpine.buildConfig = {
          tag = "alpine:3.22";
          workdir = "${src}/x86_64";
        };
    };
}
```

Alternatively, git integration of Podman can be used through `workdir = "https://github.com/nginx/docker-nginx.git"`. However, it will be users' responsibility to make binaries such as `git` available to the build service via `PATH`.

</details>

<details>
<summary>Image</summary>

```nix
{ config, ... }: {
    # ...
    virtualisation.quadlet = let
        inherit (config.virtualisation.quadlet) images;
    in {
        containers.nginx.containerConfig.image = images.nginx.ref;
        images.nginx.imageConfig.image = "docker-archive:/path/to/local/image";
        images.nginx.imageConfig.tag = "docker.com/library/nginx:latest";
    };
}
```

</details>

<details>
<summary>Install raw Quadlet files</summary>

If you wish to write raw Quadlet files instead of using the Nix options, you may do so with `rawConfig`. Using this will cause all other options (except `autoStart`) to be ignored though.

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
</details>

<details>
<summary>Work with <code>pkgs.dockerTools</code></summary>

Podman natively supports multiple transport, including `docker-archive` that can be used with `pkgs.dockerTools`.

```nix
{ pkgs, ... }: let
    image = pkgs.dockerTools.buildImage {
        # ...
    };
in {
    virtualisation.quadlet.containers = {
        foo.containerConfig.image = "docker-archive:${image}";
    };
}
```

See: https://docs.podman.io/en/v5.5.0/markdown/podman-run.1.html#image

</details>

<details>
<summary>Dependencies</summary>

Obvious dependencies such as those between containers and their networks are automatically set up by Quadlet, and thus no additional configuration is needed.

Extra dependencies can be set up in systemd unit config. Note that `.ref` syntax is only valid in quadlet and does not work from regular systemd units.

```nix
{ config, ... }: {
    # ...
    virtualisation.quadlet = let
        inherit (config.virtualisation.quadlet) containers;
    in {
        containers = {
            database = {
                # ...
            };
            server = {
               # ...
               unitConfig.Requires = [ containers.database.ref "network-online.target" ];
               unitConfig.After = [ containers.database.ref "network-online.target" ];
            };
        };
    };
}
```

</details>

<details>
<summary>Debug & log access</summary>

`quadlet-nix` tries to put containers into full management under systemd. This means once a container crashes, it will be fully deleted and debugging mechanisms like `podman ps -a` or `podman logs` will not work.

However, status and logs are still accessible through systemd, namely, `systemctl status <service name>` and `journalctl -u <service name>`, where `<service name>` is container name, `<network name>-network`, `<pod name>-pod`, or similar. These names are the names as appeared in `virtualisation.quadlet.containers.<container name>`, rather than podman container name, in case it's different.

</details>

<details>
<summary>The option I need is not available</summary>

Check if that option is supported by Podman Quadlet here: https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html.

If it exists, please create an issue or send a PR to add.

Otherwise, please use `PodmanArgs` and `GlobalArgs` to insert additional command line arguments as `quadlet-nix` does not intend to support options beyond what Quadlet offers.

</details>
