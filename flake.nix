{
  description = "Flake to develop a shell with vault dependencies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
        ztl = pkgs.writeShellApplication {
          name = "ztl";
          runtimeEnv = {
            src = "${toString ./src}";
            viewer = "sioyek";
          };
          runtimeInputs = with pkgs; [
            coreutils
            fzf
            ripgrep
            fd
            typst
            sioyek
          ];
          text = builtins.readFile ./ztl.sh;
        };
      in {
        devShells.default = with pkgs;
          mkShell {
            buildInputs = [
              ztl
            ];
          };
      }
    );
}
