# ztl 
This repository uses nix to build a bash script to manage [typst](https://typst.app/)-powered zettelkasten vaults.  
The nix flake manages all required dependencies and builds `ztl`, a custom command-line tool for managing the vault.  
I have used [basalt-lib](https://github.com/GabrielDTB/basalt-lib) typst package to create a zettelkasten structure similar to the popular obsidian app.  

## Getting Started
  
> To use the nix flake and build the `ztl` cli, a working installation of nix with `nix-command` and `flakes` enabled is required. Please find the installation instructions [here](https://nixos.org/download/) and refer the nix manual to enable flakes.
 
1. Clone the Repository
```bash
git clone https://github.com/SoloMazer/mathVault.git
cd mathVault
```

2. Enter the dev shell
Run `nix develop` inside the flake directory to fetch dependencies, build `ztl`, and enter a development shell.
```bash
nix develop
```
I recommend using a terminal text editor with Typst support (like Neovim, Helix, etc). Once inside the shell, you can use the `ztl` command to manage your vault. Run `ztl help` to list available options.

### Usage on non-nix/nixos distros

In principle it is possible to use the bash script to manage your vaults, only extra step is to install the dependencies from your distro's package manager.
Currently you'll need `ripgrep`, `fd` and `fzf`, but please check `runtimeInputs` argument for ztl in `flake.nix` for a detailed list of dependencies.
You can then run the script just the way you do for other bash scripts for your distro. 

## Contributing
I feel this project solves a very niche problem that is personal to me. Hence, I will be focusing on simple and reliable solutions that work with minimal effort, without leaving loose ends or being overly opinionated.
Feel free to contact me if you have improvements/feature requests to suggest, I would love to make this utility more useful.  

## Acknowledgements
Super thanks to [Gabe](https://github.com/GabrielDTB) for creating basalt-lib and helping me set it up.

