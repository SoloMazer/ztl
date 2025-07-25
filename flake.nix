{
  description = "A flake to build, run and develop intuita";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      packages.default = pkgs.rustPlatform.buildRustPackage {
        pname = "intuita";
        version = "0.1.0";
        src = ./.;

        nativeBuildInputs = with pkgs; [
          rustc
          cargo
        ];

        cargoLock = {
          lockFile = ./Cargo.lock;
        };

        buildType = "release";
      };

      apps.default = flake-utils.lib.mkApp {
        drv = self.packages.${system}.default;
      };
    });
}
