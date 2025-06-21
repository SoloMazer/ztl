{ pkgs }:
pkgs.writeShellApplication {
  name = "ztl";

  runtimeInputs = with pkgs; [
    coreutils
    fzf
    ripgrep
    fd
    typst
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
  compile/c               Compile and open selected typst file
  repair                  Regenerate vault resources at vault root
  help                    Show this help message
EOF
}

# Initialization function
init_vault() {


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
  local notename
  notename="$(echo "$3" | awk -F'/' '{print $NF}')"

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
  name: "$notename",
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
  local vault_root="$1"
  local vault_csv="$1/vault/vault.csv"
  
  local selected_file
  selected_file=$(awk '{print substr($0, 4) "\t" $0}' "$vault_csv" | fzf --delimiter='\t' --with-nth=1 --accept-nth=2)
  display_selected_file=$(echo "$selected_file" | sed 's/^\.\.\///')


  if [ -n "$selected_file" ]; then
    cd "$1/vault" || return
    echo "Are you sure you want to remove '$display_selected_file'? (y/n): "
    read -r confirmation

    if [[ "$confirmation" =~ ^[Yy]$ || -z "$confirmation" ]]; then
    
      notename="$(basename "$selected_file" .typ)"
      
      grep -Fxv "$selected_file" "$vault_csv" > "$vault_csv.tmp" && mv "$vault_csv.tmp" "$vault_csv"
      rm "$selected_file"

      if cd "$vault_root" && rg -g '!vault/' "#xlink\(name: \"$notename\"\)"; then
        RED=$(printf '\033[31m')
        RESET=$(printf '\033[0m')
        printf '%sBroken links found in above files!%s\n' "$RED" "$RESET"
      fi

      echo "Successfully deleted: $display_selected_file"
      exit 0
    else
      echo "Delection aborted."
      exit 1
    fi
  else
    echo "No file selected."
    exit 1
  fi
}

compile_selected_file() {
  local vault_root="$1"
  cd "$vault_root" || return
  
  local selected_file
  selected_file=$(fd . -e typ --exclude vault | fzf)

  typst watch --root "$vault_root" "$selected_file" --open
}

vault_not_found() {
  if ! VAULT_ROOT_FOUND=$(locate_vault_root); then
    echo "Vault root not found in current directory or its parents upto $HOME."
    echo "Please run 'ztl init' to set a vault root."
    exit 1
  fi
}

repair_vault() {
  local vault_root="$1"
  echo "Vault Root detected at: $vault_root"
  echo "Do you want to repair this vault? (y/n):"
  read -r confirmation

  if [[ "$confirmation" =~ ^[Yy]$ || -z "$confirmation" ]]; then
    rm -r "$vault_root/vault"
    cd "$vault_root"
    init_vault

    fd . -e typ --exclude vault \
      | sed 's|^\./||' \
      | awk -v OFS=',' '{ print "../" $0 }' \
      > "$vault_root/vault/vault.csv"

    echo "Vault repaired successfully."
    exit 0
  else
    echo "Vault repair aborted."
    exit 1
  fi
}

main() {
  if [ "$#" -eq 0 ]; then
    show_help
    exit 1
  fi
  case "$1" in
    init)
      if VAULT_ROOT_FOUND=$(locate_vault_root); then
        echo "Existing vault root found at: $VAULT_ROOT_FOUND."
        echo "Nested vaults are not supported, please use the parent vault."
        exit 1
      fi
      init_vault
      ;;
    new|n)
      vault_not_found
      if [ "$#" -lt 2 ]; then
        echo "Error: Please provide a filename."
        echo "Usage: ztl new/n [filename]"
        exit 1
      fi 
      create_new_file "$VAULT_ROOT_FOUND" "$@"
      ;;
    rm)
      vault_not_found
      remove_vault_file "$VAULT_ROOT_FOUND"
      ;;
    compile|c)
      vault_not_found
      compile_selected_file "$VAULT_ROOT_FOUND"
      ;;
    repair)
      vault_not_found
      repair_vault "$VAULT_ROOT_FOUND"
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

