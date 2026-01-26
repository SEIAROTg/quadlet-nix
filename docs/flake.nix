{
  description = "quadlet-nix docs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    quadlet-nix.url = "path:..";
  };

  outputs =
    {
      nixpkgs,
      quadlet-nix,
      self,
      ...
    }:
    let
      allSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      perSystem = f: nixpkgs.lib.genAttrs allSystems f;
    in
    {
      packages = perSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = pkgs.lib;
          buildDocs =
            module:
            let
              moduleFn = import module;
              # filters out assertions, config, etc. that cause problems.
              filteredModuleFn = args: { inherit (moduleFn args) options; };
              eval = lib.evalModules {
                modules = [
                  { _module.args.pkgs = pkgs; }
                  (lib.mirrorFunctionArgs moduleFn filteredModuleFn)
                ];
              };
              options = lib.filterAttrs (name: _: name != "_module") eval.options;
            in
            pkgs.nixosOptionsDoc { inherit options; };

          pages = {
            nixosModules.quadlet = buildDocs quadlet-nix.nixosModules.quadlet;
            homeManagerModules.quadlet = buildDocs quadlet-nix.homeManagerModules.quadlet;
          };

        in
        {
          inherit pages;

          book = pkgs.stdenv.mkDerivation {
            pname = "quadlet-nix-docs-book";
            version = "0.1";
            src = self;

            nativeBuildInputs = [
              pkgs.mdbook
            ];

            dontConfigure = true;
            dontFixup = true;

            buildPhase = ''
              runHook preBuild
              cp ${quadlet-nix}/README.md src/introduction.md
              cp ${pages.nixosModules.quadlet.optionsCommonMark} src/nixos-options.md
              cp ${pages.homeManagerModules.quadlet.optionsCommonMark} src/home-manager-options.md
              mdbook build
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              mv book $out
              runHook postInstall
            '';
          };
        }
      );
    };
}
