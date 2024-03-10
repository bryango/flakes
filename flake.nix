{
  description = ''
    Management of packages developed at home.
    This flake is not in a git repository by design.
    Alternatively one can put a secret GIT_DIR in e.g. `.envrc`.
  '';

  inputs = {
    hydra-check = {
      url = "./hydra-check";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xinput-json = {
      url = "./xinput-json";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wifipem = {
      url = "./wifipem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, hydra-check, xinput-json, wifipem }:
    let
      inherit (nixpkgs) lib;
      systems = [ "x86_64-linux" ];
      forAllSystems = f: lib.genAttrs systems (system: f {
        inherit system;
        pkgs = nixpkgs.legacyPackages.${system};
        final = self.packages.${system};
      });
    in
    {
      packages = forAllSystems ({ system, pkgs, final }: {
        hydra-check = hydra-check.packages.${system}.default;
        xinput-json = xinput-json.packages.${system}.default;
        wifipem-live-capture = wifipem.packages.${system}.live-capture;
        default = pkgs.buildEnv {
          name = "home-apps";
          paths = lib.attrValues {
            inherit (final) hydra-check;
            inherit (final) xinput-json;
            inherit (final) wifipem-live-capture;
          };
        };
      });

      devShells = forAllSystems ({ pkgs, ... }:
        let
          git = pkgs.callPackage
            ({ symlinkJoin, makeBinaryWrapper, git }: symlinkJoin {
              name = "git-special-dir";
              paths = [ git ];
              nativeBuildInputs = [ makeBinaryWrapper ];
              postBuild = ''
                wrapProgram $out/bin/git --add-flags "--git-dir=../flakes.git"
              '';
            })
            { };
        in
        {
          default = pkgs.mkShell {
            packages = [ git ];
          };
        }
      );
    };
}
