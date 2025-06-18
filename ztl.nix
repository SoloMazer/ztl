{ pkgs }:
pkgs.writeShellApplication {
  name = "ztl";

  runtimeInputs = with pkgs; [
    coreutils
    fzf
    papers
  ];

  text = ''

#!/usr/bin/env bash
set -euo pipefail

# Utility functions

fail() {
  echo "Error: $*" >&2
  exit 1
}

show_help() {
cat <<EOF
Usage: ztl [OPTIONS]

Options:
  init                        Initialize a new vault in the current directory
  --new, -n <file-name>       Create a new Typst file with boilerplate
  --compile, -c               Compile, watch and open the file in viewer
  --help                      Show this help message
EOF
}

find_vault_root() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/vault" ]; then
      echo "$dir/vault"
      return
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

# Boilerplate functions

vault_home_broilerplate() {
cat <<EOF > "$VAULT_DIR/vault.typ"
#import "@preview/basalt-lib:1.0.0": new-vault, xlink, as-branch

#let vault = new-vault(
  note-paths: csv("note-paths.csv").flatten(),
  include-from-vault: path => include path,
  formatters: (),
)
EOF
}

new_file_broilerplate() {
  local filename="$1"
  local basename="$2"
  local rel_path="$3"
  mkdir -p "$(dirname "$filename")"

cat <<EOF > "$filename"
#import "$rel_path/vault.typ": *
#import "$rel_path/snippets.typ"
#show: vault.new-note.with(
  name: "$basename"
)
//Insightful note content
EOF
}

# Option functions

init_vault() {
  [ ! -d "$VAULT_DIR" ] || fail "Vault is already initialized."
  mkdir -p "$VAULT_DIR"
  vault_home_broilerplate
  touch "$PATH_CSV"
  touch "$VAULT_DIR/snippets.typ"
}

create_new_file() {
  local name="$1"
  local filename="$name.typ"
  local basename
  local note_dir
  local rel_path

  [ -d "$VAULT_DIR" ] || fail "Vault not initialized. Run 'ztl init'."
  [ -f "$filename" ] && fail "$filename already exists."

  basename="$(basename "$name")"
  note_dir="$(dirname "$filename")"
  rel_path="$(realpath --relative-to="$note_dir" "$VAULT_DIR")"

  new_file_broilerplate "$filename" "$basename" "$rel_path"

  relative_to_vault="$(realpath --relative-to="$(dirname "$PATH_CSV")" "$filename")"
  note_path="./$relative_to_vault"

  grep -qxF "$note_path" "$PATH_CSV" || echo "$note_path" >> "$PATH_CSV"
  sort -u "$PATH_CSV" -o "$PATH_CSV"
}

compile_file() {
  [ -d "$VAULT_DIR" ] || fail "Vault not initialized. Run 'ztl --init'."
  [ -f "$PATH_CSV" ] || fail "No note-paths.csv found."

  local selected abs_path
  selected=$(fzf < "$PATH_CSV") || fail "No file selected."

  abs_path="$(realpath --canonicalize-missing "$(dirname "$PATH_CSV")/$selected")"

  typst compile --root "$(dirname "$VAULT_DIR")" "$abs_path" || fail "Typst compile failed."

  typst watch "$abs_path" --root "$(dirname "$VAULT_DIR")" --open || fail "Typst watch failed."
}

# Main function

main() {
  if [ "$#" -eq 0 ]; then
    show_help
    exit 1
  fi

  case "$1" in
    init)
      VAULT_DIR="$PWD/vault"
      PATH_CSV="$VAULT_DIR/note-paths.csv"
      init_vault
      ;;
    --help)
      show_help
      ;;
    -n|--new)
      VAULT_DIR="$(find_vault_root || fail "Vault not initialized. Run 'ztl init' at the vault root.")"
      PATH_CSV="$VAULT_DIR/note-paths.csv"
      [ "$#" -ge 2 ] || fail "Missing file name"
      filename="$2"
      shift 2
      create_new_file "$filename"
      ;;
    -c|--compile)
      VAULT_DIR="$(find_vault_root || fail "Vault not initialized. Run 'ztl init' at the vault root.")"
      PATH_CSV="$VAULT_DIR/note-paths.csv"
      compile_file
      ;;
    *)
      show_help
      fail "Unknown option: $1"
      ;;
  esac
}

main "$@"

  '';
}

