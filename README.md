# ztl 
This repository uses nix to build a bash script to manage [typst](https://typst.app/)-powered zettelkasten vaults.  
The nix flake manages all required dependencies and builds `ztl`, a custom command-line tool for managing the vault.  
I have used [basalt-lib](https://github.com/GabrielDTB/basalt-lib) typst package to create a zettelkasten structure similar to the popular obsidian app.  

## Getting Started
  
> To use the nix flake and build the `ztl` cli, a working installation of nix with `nix-command` and `flakes` enabled is required. Please find the installation instructions [here](https://nixos.org/download/) and refer the nix manual to enable flakes.

Simply run the following command to enter a devShell.  
```bash
nix develop github:solomazer/ztl
```
Once inside the shell, you can use the `ztl` command to manage your vault.
Run `ztl help` to list available options.  
I recommend using a terminal text editor with Typst support (like Neovim, Helix, etc).

### Usage on non-nix/nixos distros

> I haven't tested if this method works, but based on my research it should. Let me know if you face any issues.

1. Clone the repo in your projects folder.
```bash
git clone https://github.com/SoloMazer/mathVault.git
cd mathVault
```

2. Symlink the script to bin and make it executable.
```bash
mkdir -p ~/bin # If you haven't already
ln -s ztl.sh ~/bin/ztl
chmod +x ~/bin/ztl
```
3. Add `~bin` to your PATH by editing `~/.bashrc` (or `~/.profile`)
```bash
export PATH="$HOME/bin:$PATH"
```

4. Reload your shell
```bash
source ~/.bashrc
```

5. Install dependencies:
You'll need to install the script dependencies from your distro's package manager.
Currently you'll need `ripgrep`, `fd` and `fzf`, but please check `runtimeInputs` argument for ztl in `flake.nix` for a detailed list of dependencies.

Now you can run `ztl` command from terminal. Run `ztl help` to display usage.

## Contributing
I feel this project solves a very niche problem that is personal to me. Hence, I will be focusing on simple and reliable solutions that work with minimal effort, without leaving loose ends or being overly opinionated.
Feel free to contact me if you have improvements/feature requests to suggest, I would love to make this utility more useful.  

## Acknowledgements
Super thanks to [Gabe](https://github.com/GabrielDTB) for creating basalt-lib and helping me set it up.

