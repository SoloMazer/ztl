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
          runtimeInputs = with pkgs; [
            coreutils
            fzf
            ripgrep
            fd
            typst
          ];
          # source = "./.";
          text = builtins.readFile "./ztl.sh";
        };
      in {
        devShells.default = with pkgs;
          mkShell {
            shellHook = ''
              export ZTL_SRC=${./.}
            '';
            buildInputs = [
              ztl
            ];
          };
      }
    );
}
