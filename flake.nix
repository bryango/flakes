{
  description = ''
    Manage "dirty", unlocked flakes developed at home.
    This flake is in a secret git repository hidden from nix.
    Specify the secret git directory with $gitDir below.
  '';

  /** pull in "dirty" flakes here and redirect their dependencies */
  inputs = {
    hydra-check = {
      url = "git+file:./hydra-check";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xinput-json = {
      url = "git+file:./xinput-json";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wifipem = {
      url = "git+file:./wifipem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, hydra-check, xinput-json, wifipem }:
    let
      /** the .git directory for this flake, hidden from nix */
      gitDir = "../flakes.git";
      systems = [ "x86_64-linux" ];

      inherit (nixpkgs) lib;
      forAllSystems = f: lib.genAttrs systems (system: f {
        inherit system;
        pkgs = nixpkgs.legacyPackages.${system};
        final = self.packages.${system};
      });
    in
    {
      packages = forAllSystems ({ system, pkgs, final }: {
        default = pkgs.buildEnv {
          name = "home-apps";
          /** toggle packages to link in the profile */
          paths = lib.attrValues {
            inherit (final) hydra-check;
            inherit (final) xinput-json;
            inherit (final) wifipem-live-capture;
          };
        };

        # expose packages here
        hydra-check = hydra-check.packages.${system}.default;
        xinput-json = xinput-json.packages.${system}.default;
        wifipem-live-capture = wifipem.packages.${system}.live-capture;

        /** a special git with --git-dir=${gitDir} for this flake only */
        git-special-dir = pkgs.callPackage
          ({ symlinkJoin, makeBinaryWrapper, git }: symlinkJoin {
            name = "git-special-dir";
            paths = [ git ];
            nativeBuildInputs = [ makeBinaryWrapper ];
            postBuild = ''
              wrapProgram $out/bin/git --add-flags "--git-dir=${gitDir}"
            '';
          })
          { };
      });

      devShells = forAllSystems ({ pkgs, final, ... }: {
        default = pkgs.mkShell {
          packages = with final; [
            /** use the special git with `--git-dir=${gitDir}` */
            git-special-dir
          ];
        };
      });
    };
}
