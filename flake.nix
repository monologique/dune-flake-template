{
  description = "Dune flake template";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=24.11";
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      eachSystem =
        fn:
        (nixpkgs.lib.genAttrs systems (
          system:
          fn {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          }
        ));

      systems = [
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-darwin"
        "aarch64-linux"
      ];

      projectName = "hello";
    in
    {

      packages = eachSystem (
        { pkgs, system }:
        {
          default = self.packages.${system}.${projectName};

          "${projectName}" = pkgs.ocamlPackages.buildDunePackage {
            pname = projectName;
            version = "0.1.0";
            src = ./.;
            buildInputs = [ ];
          };
        }
      );

      apps = eachSystem (
        { system, ... }:
        {
          default = self.apps.${system}.${projectName};

          "${projectName}" = {
            type = "app";
            program = "${self.packages.${system}.${projectName}}/bin/${projectName}";
          };
        }
      );

      checks = eachSystem (
        { pkgs, system }:
        {
          "${projectName}" = self.packages.${system}.default.overrideAttrs (oldAttrs: {
            name = "${projectName}-tests";
            doCheck = true;
            buildInputs = with pkgs; [ ocamlPackages.alcotest ] ++ (oldAttrs.buildInputs or [ ]);
          });

          pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              deadnix.enable = true;
              treefmt = {
                enable = true;
                settings.formatters = with pkgs; [
                  nixfmt-rfc-style
                  ocamlPackages.ocamlformat
                  taplo
                  yamlfmt
                ];
              };
            };
          };
        }
      );

      devShells = eachSystem (
        { pkgs, system }:
        {
          default = self.devShells.${system}.${projectName};

          "${projectName}" = pkgs.mkShellNoCC {
            inherit (self.checks.${system}.pre-commit-check) shellHook;

            buildInputs =
              with pkgs;
              [
                dune_3
                ocamlPackages.ocaml
                ocamlPackages.findlib
                ocamlPackages.ocaml-lsp
                ocamlPackages.utop
                nixd
              ]
              ++ self.checks.${system}.pre-commit-check.enabledPackages
              ++ self.checks.${system}.${projectName}.buildInputs;
          };
        }
      );
      formatter = eachSystem ({ pkgs, ... }: pkgs.treefmt);
    };
}
