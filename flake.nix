{
  description = "Dune flake template";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
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
            meta = {
              description = "Dune flake template";
              mainProgram = self.packages.${system}.${projectName};
            };
          };
        }
      );

      checks = eachSystem (
        { pkgs, system }:
        {
          "dune-tests" = self.packages.${system}.default.overrideAttrs (oldAttrs: {
            name = "${projectName}-tests";
            doCheck = true;
            buildInputs = with pkgs; [ ocamlPackages.alcotest ] ++ (oldAttrs.buildInputs or [ ]);
          });

          pre-commit = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              actionlint.enable = true;
              deadnix.enable = true;
              flake-checker.enable = true;
              treefmt = {
                enable = true;
                settings.formatters = with pkgs; [
                  nixfmt-rfc-style
                  ocamlPackages.ocamlformat
                  taplo
                  yamlfmt
                  nodePackages.prettier
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

          "${projectName}" = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit) shellHook;

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
              ++ self.checks.${system}.pre-commit.enabledPackages
              ++ self.checks.${system}.dune-tests.buildInputs;
          };
        }
      );
      formatter = eachSystem ({ pkgs, ... }: pkgs.treefmt);
    };
}
