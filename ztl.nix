{ pkgs }:
pkgs.writeShellApplication {
  name = "ztl";

  runtimeInputs = with pkgs; [
    coreutils
    fzf
  ];

  text = ''

#!/usr/bin/env bash
set -euo pipefail

show_help() {
cat << EOF
Usage: ztl [COMMAND]

Commands:
  init                    Initialize vault with current directory as vault root
  new/n <filename>        Create new file at working directory
  rm                      Interactively remove file from vault
  help                    Show this help message
EOF
}

# Initialization function
init_vault() {

  if [ -d "$(pwd)/vault" ]; then
    echo "Error: Vault is already Initialized."
    echo "Use 'ztl repair' to regenerate the vault"
    exit 1
  fi

  # create vault resources
  mkdir "$(pwd)/vault"                   #create a folder to store vault files
  touch "$(pwd)/vault/vault.typ"         #create a vault.typ file for basalt-lib
  touch "$(pwd)/vault/vault.csv"         #create a csv file to store note paths
  touch "$(pwd)/vault/snippets.typ"      #create a global snippets file
  mkdir "$(pwd)/vault/templates"         #create a folder to store templates

# Setup vault.typ with some broilerplate for basalt-lib
cat << 'VAULT_FILE_BROILERPLATE' > "$(pwd)/vault/vault.typ"
#import "@preview/basalt-lib:1.0.0": new-vault, xlink, as-branch
#import "./snippets.typ"

#let vault = new-vault(
  note-paths: csv("./vault.csv").flatten(),
  include-from-vault: path => include path,
  formatters: ()
)
VAULT_FILE_BROILERPLATE

# Cat some broilerplate code to snippets.typ
cat << 'VAULT_SNIPPETS_BROILERPLATE' > "$(pwd)/vault/snippets.typ"
// Define your global snippet varibables here, eg:
// #let pi = 3.14159
VAULT_SNIPPETS_BROILERPLATE

# Display vault init log to console
cat << EOF
Initialization complete.
  Vault Root:        $(pwd)
EOF
}

locate_vault_root() {
  local CURRENT_DIR
  CURRENT_DIR=$(pwd)
  while true; do
    if [ -d "$CURRENT_DIR/vault" ]; then
      echo "$CURRENT_DIR"
      return 0
    elif [ "$CURRENT_DIR" == "$HOME" ]; then
      return 1
    fi
    CURRENT_DIR=$(dirname "$CURRENT_DIR")
  done
}

create_new_file(){
  local vault_home="$1/vault"
  local filename="$3.typ"
  local relative_csv
  local relative_typ

  if [ -e "$filename" ]; then
    echo "Error: '$filename' already exists. Choose a different name."
    exit 1
  fi
  
  mkdir -p "$(dirname "$filename")"
  touch "$filename"
  relative_typ="$(realpath --relative-to="$(dirname "$(pwd)"/"$filename")" "$vault_home")/vault.typ"
  
# Setup new file with some broilerplate for basalt-lib
cat << NEW_FILE_BROILERPLATE > "$filename"
#import "$relative_typ": *
#show: vault.new-note.with(
  name: "note1",
  //other metadata here
)

Insightful note content...
NEW_FILE_BROILERPLATE

  relative_csv=$(realpath --relative-to="$vault_home" "$(pwd)/$filename")

  grep -qxF "$relative_csv" "$vault_home/vault.csv" || echo "$relative_csv" >> "$vault_home/vault.csv"
  sort -ubfV "$vault_home/vault.csv" -o "$vault_home/vault.csv"

  echo "Succesfully added: $filename"
  echo "to the vault: $(dirname "$vault_home")."
}

remove_vault_file(){
  local vault_csv="$1/vault/vault.csv"
  
  local selected_file
  selected_file=$(awk '{print substr($0, 4) "\t" $0}' "$vault_csv" | fzf --delimiter='\t' --with-nth=1 --accept-nth=2)
  display_selected_file=$(echo "$selected_file" | sed 's/^\.\.\///')


  if [ -n "$selected_file" ]; then
    cd "$1/vault" || return
    echo "Are you sure you want to remove '$display_selected_file'? (y/n): "
    read -r confirmation

    if [[ "$confirmation" =~ ^[Yy]$ || -z "$confirmation" ]]; then
      rm "$selected_file"
      echo "Successfully deleted: $display_selected_file"
      
      # Remove the matching line from vault.csv
      grep -Fxv "$selected_file" "$vault_csv" > "$vault_csv.tmp" && mv "$vault_csv.tmp" "$vault_csv"
      echo "Removed link from $vault_csv"
    else
      echo "Delection aborted."
    fi
  else
    echo "No file selected."
  fi
}

main() {
  if [ "$#" -eq 0 ]; then
    show_help
    exit 1
  fi
  case "$1" in
    init)
      init_vault
      ;;
    new|n)
      if ! VAULT_ROOT_FOUND=$(locate_vault_root); then
        echo "Vault root not found in current directory or its parents upto $HOME."
        echo "Please run 'ztl init' to set a vault root."
        exit 1
      fi
      if [ "$#" -lt 2 ]; then
        echo "Error: Please provide a filename."
        echo "Usage: ztl new/n [filename]"
        exit 1
      fi 
      create_new_file "$VAULT_ROOT_FOUND" "$@"
      ;;
    rm)
      if ! VAULT_ROOT_FOUND=$(locate_vault_root); then
        echo "Vault root not found in current directory or its parents upto $HOME."
        echo "Please run 'ztl init' to set a vault root."
        exit 1
      fi
      remove_vault_file "$VAULT_ROOT_FOUND"
      ;;
    help)
      show_help
      ;;
    *)
      show_help
      ;;
  esac
}

main "$@"





  '';
}

