# mathVault
This repository stores my personal university notes, all written in [typst](https://typst.app/).  
The nix flake manages all required dependencies and builds `ztl`, a custom command-line tool for managing the vault.  
I have used [basalt-lib](https://github.com/GabrielDTB/basalt-lib) typst package to create a zettelkasten structure similar to the popular obsidian app.  

## Getting Started
  
> To use the nix flake and build the `ztl` cli, a working installation of nix with `nix-command` and `flakes` enabled is required. Please find the installation instructions [here](https://nixos.org/download/) and refer the nix manual to enable flakes.
 
1. Clone the Repository
```bash
git clone https://github.com/SoloMazer/mathVault.git
cd mathVault
```

2. Start with a Clean Vault (Optional)
If you wish to remove all the existing notes and vault resources and start with a blank canvas, run:
```bash
fd --type d --max-depth 1 --exec rm -rf {}
```

3. Enter the dev shell
Run `nix develop` inside the flake directory to fetch dependencies, build `ztl`, and enter a development shell.
```bash
nix develop
```
I recommend using a terminal text editor with Typst support (like Neovim, Helix, etc). Once inside the shell, you can use the `ztl` command to manage your vault effectively. Run `ztl help` to list available options.

## Contributing
This is a personal vault and is not as polished as professional tools, however if you find any errors or have any suggestions for improvements, feel free to open an issue or pull request.

## License
All notes here are free to use for non-commercial purposes. If you're a student like me, I hope these notes help you :)

## Acknowledgements
Super thanks to [Gabe](https://github.com/GabrielDTB) for creating basalt-lib and helping me set it up.
