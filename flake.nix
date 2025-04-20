{
  description = ''
    Manage "dirty", unlocked flakes developed at home.
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
      inputs.fenix.follows = "fenix";
    };
    wifipem = {
      url = "git+file:./wifipem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, hydra-check, xinput-json, wifipem, ... }:
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
      } // lib.optionalAttrs isLinux {
        xinput-json = xinput-json.packages.${system}.default;
        wifipem-live-capture = wifipem.packages.${system}.live-capture;
      });
    };
}
