{
  description = ''
    Manage "dirty", unlocked flakes developed at home.
  '';

  /** pull in "dirty" flakes here and redirect their dependencies */
  inputs = {
    self.submodules = true;
    hydra-check = {
      url = ./hydra-check;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-track = {
      url = ./nixpkgs-track;
      flake = false; # custom packaging
    };
    xinput-json = {
      url = ./xinput-json;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
    };
    wifipem = {
      url = ./wifipem;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, hydra-check, xinput-json, wifipem, nixpkgs-track, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" ];

      inherit (nixpkgs) lib;
      forAllSystems = f: lib.genAttrs systems (system: f {
        inherit system;
        pkgs = nixpkgs.legacyPackages.${system};
        final = self.packages.${system};
        isLinux = lib.hasSuffix "linux" system;
        isDarwin = lib.hasSuffix "darwin" system;
      });
    in
    {
      packages = forAllSystems ({ system, pkgs, final, isLinux, isDarwin }: {
        default = pkgs.buildEnv {
          name = "home-apps";
          /** toggle packages to link in the profile */
          paths = lib.attrValues (removeAttrs final [
            "default"
          ]);
        };

        # expose packages here
        hydra-check = hydra-check.packages.${system}.default;
        nixpkgs-track = pkgs.nixpkgs-track.overrideAttrs ({ pname ? "", meta ? {}, ... }: {
          pname = "${pname}-dev";
          src = nixpkgs-track;
          cargoDeps = pkgs.rustPlatform.importCargoLock {
            lockFile = "${nixpkgs-track}/Cargo.lock";
          };
          meta = meta // {
            maintainers = with lib.maintainers; [
              bryango
            ];
            # to correctly generate meta.position for backtrace:
            inherit (meta) description;
          };
        });
      } // lib.optionalAttrs isLinux {
        xinput-json = xinput-json.packages.${system}.default;
        wifipem-live-capture = wifipem.packages.${system}.live-capture;
      });
    };
}
