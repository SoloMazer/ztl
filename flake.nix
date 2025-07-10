{
  description = "Flake to develop a shell with vault dependencies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
        zty = pkgs.writeShellApplication {
          name = "ztl";
          runtimeInputs = with pkgs; [
            coreutils
            fzf
            ripgrep
            fd
            typst
            sioyek
          ];
          text = builtins.readFile ./zty.sh;
        };
      in {
        devShells.default = with pkgs;
          mkShell {
            buildInputs = [
              zty
            ];
          };
      }
    );
}
