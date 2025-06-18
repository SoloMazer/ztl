{
  description = "Flake to develop a shell with vault dependencies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        ztl = import ./ztl.nix { inherit pkgs; };
      in
      {
        devShells.default = with pkgs;
          mkShell {
            buildInputs = [
              typst
              tinymist
              ztl
            ];
          };
      }
    );
}
