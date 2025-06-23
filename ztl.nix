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

# ------------------------------------------------------ #
#                   DISPLAY HELP MENU                    #
# ------------------------------------------------------ #
show_help() {
cat << EOF
Usage: ztl [COMMAND]

Commands:
  init                            Initialize vault with current directory as vault root
  new/n <filename>                Create new file at working directory
  rm                              Interactively remove file from vault
  compile/c                       Compile selected file and its links and open the file
  repair                          Regenerate vault resources
  help                            Show this help message
EOF
return
}

# ------------------------------------------------------ #
#                LOCATE VAULT RESOURCES                  #
# ------------------------------------------------------ #
vault_finder() {
  
  local current_dir
  current_dir=$(pwd)

  vault_resources() { 
    # define vault resources
    VAULT_ROOT="$VAULT_HOME/vault"
    VAULT_TYP="$VAULT_ROOT/vault.typ"
    VAULT_CSV="$VAULT_ROOT/vault.csv"
    VAULT_SNIPPET="$VAULT_ROOT/snippets.typ"
    VAULT_TEMPLATE="$VAULT_ROOT/templates"
    return
  }
  
  while true; do
    if [ -d "$current_dir/vault" ]; then
      VAULT_HOME="$current_dir"
      vault_resources
      success_cmd
      break
    elif [ "$current_dir" == "$HOME" ]; then
      VAULT_HOME="$(pwd)"
      vault_resources
      failure_cmd
      break
    fi
    current_dir=$(dirname "$current_dir")
  done

  return
}

# ------------------------------------------------------ #
#                   Vault Initialization                 #
# ------------------------------------------------------ #
init_vault() {

  success_cmd() {
    echo "A vault is already initialized at: $VAULT_HOME."
    echo "Nested vaults are not supported. Use above vault or choose another directory."
    exit 1
  }
  failure_cmd() {
    echo "Initializing your vault..."
    return
  }
  vault_finder
  
  # create vault resources
  mkdir "$VAULT_ROOT"
  mkdir "$VAULT_TEMPLATE"
  touch "$VAULT_TYP"
  touch "$VAULT_CSV"
  touch "$VAULT_SNIPPET"

# Setup vault.typ with some broilerplate for basalt-lib
cat << 'VAULT_FILE_BROILERPLATE' > "$(pwd)/vault/vault.typ"
#import "@preview/basalt-lib:1.0.0": new-vault, xlink, as-branch

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
  Vault Home:        $VAULT_HOME
EOF

return 0
}

# ------------------------------------------------------ #
#              FILE CREATION AND LINK MANAGER            #
# ------------------------------------------------------ #
create_file(){
  success_cmd() {
    echo ""
  }
  failure_cmd() {
    echo "Vault is not initialized."
    echo "Please run 'ztl init' to initialize current directory."
    exit 1
  }
  vault_finder
  if [ "$#" -lt 2 ]; then
    echo "Error: Please provide a filename."
    echo "Usage: ztl new/n [filename]"
    exit 1
  fi 

  file="$2.typ"
  file_path="$(pwd)/$file"
  file_name="$(basename "$2")"
  
  if [ -e "$file_path" ]; then
    echo "Error: '$file_path' already exists. Choose a different name."
    exit 1
  fi

  mkdir -p "$(dirname "$2")"
  touch "$file"

  relative_typ="$(realpath --relative-to="$(dirname "$file_path")" "$VAULT_TYP")"
  relative_snip="$(realpath --relative-to="$(dirname "$file_path")" "$VAULT_SNIPPET")"

# Setup new file with some broilerplate for basalt-lib
cat << NEW_FILE_BROILERPLATE > "$file"
#import "$relative_typ": *
#import "$relative_snip"
#show: vault.new-note.with(
  name: "$file_name",
  //other metadata here
)

Insightful note content...
NEW_FILE_BROILERPLATE

  relative_csv="$(realpath --relative-to="$(dirname "$VAULT_CSV")" "$file_path")"
  grep -qxF "$relative_csv" "$VAULT_CSV" || echo "$relative_csv" >> "$VAULT_CSV"
  sort -ubfV "$VAULT_CSV" -o "$VAULT_CSV"

  echo "Successfully added '$file' to the vault at: $VAULT_HOME"
  return
}

# ------------------------------------------------------ #
#            FILE REMOVAL AND RESIDUE CLEANUP            #
# ------------------------------------------------------ #
remove_file(){
  success_cmd() {
    printf '\n'
  }
  failure_cmd() {
    echo "Vault is not initialized."
    echo "Please run 'ztl init' to initialize current directory."
    exit 1
  }
  vault_finder

  selected_file=$(fd . -e typ --exclude vault --strip-cwd-prefix --base-directory "$VAULT_HOME" | fzf)

  #Removes link from vault.csv
  grep -Fxv "../$selected_file" "$VAULT_CSV" > "$VAULT_CSV.tmp" && mv "$VAULT_CSV.tmp" "$VAULT_CSV"

  #File removal logic
  rm "$VAULT_HOME/$selected_file"

  #Display broken links if any
  if rg -g '!vault/' "#xlink\(name: \"$(basename "$selected_file" .typ)\"\)" "$VAULT_HOME"; then
    RED=$(printf '\033[31m')
    RESET=$(printf '\033[0m')
    printf '\n%sBroken links found in above files!%s\n\n' "$RED" "$RESET"
  fi

  echo "Successfully removed: $VAULT_HOME/$selected_file."
  return
}

# ------------------------------------------------------ #
#            Compile files and its links                 #
# ------------------------------------------------------ #
compile_file() {
  success_cmd() {
    printf '\n';
  }
  failure_cmd() {
    echo "Vault is not initialized."
    echo "Please run 'ztl init' to initialize current directory."
    exit 1
  }

  vault_finder

  # Select the main file to watch
  local selected_file
  selected_file="$VAULT_HOME/$(fd . -e typ --exclude vault \
    --strip-cwd-prefix --base-directory "$VAULT_HOME" | fzf)"
  [[ -z "$selected_file" ]] && echo "No file selected." && exit 1

  # Extract linked note names and compile them
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    if path=$(fd "$name.typ" -e typ --exclude vault --base-directory "$VAULT_HOME"); then
      echo "Compiling link: $name.typ"
      typst compile --root "$VAULT_HOME" "$VAULT_HOME/$path"
    else
      echo "Warning: '$name.typ' not found in vault." >&2
    fi
  done < <(
    rg -oP '#xlink\(name:\s*"\K[^\"]+(?=\")' "$selected_file"
  )

  # Finally, watch the selected file (with open)
  typst watch --root "$VAULT_HOME" "$selected_file" --open
}

repair_vault(){
  success_cmd() {
    echo "Vault found at: $VAULT_HOME"
    return
  }
  failure_cmd() {
    echo "Vault is not initialized."
    echo "Please run 'ztl init' to initialize current directory."
    exit 1
  }
  vault_finder

  echo "Do you want to repair this vault? (y/n):"
  read -r confirmation

  if [[ "$confirmation" =~ ^[Yy]$ || -z "$confirmation" ]]; then
    cd "$VAULT_HOME"
    rm -r "vault"
    init_vault
    
    fd . -e typ --exclude vault \
      | sed 's|^\./||' \
      | awk -v OFS=',' '{ print "../" $0 }' \
      > "$VAULT_CSV"
    
    sort -ubfV "$VAULT_CSV" -o "$VAULT_CSV"

    echo "Vault repaired successfully!"
    exit 0
  else
    echo "Vault repair aborted."
    exit 1
  fi
}

# ------------------------------------------------------ #
#                      MAIN FUNCTION                     #
# ------------------------------------------------------ #
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
        create_file "$@"
        ;;
      rm)
        remove_file
        ;;
      compile|c)
        compile_file
        ;;
      repair)
        repair_vault
        ;;
      help|*)
        show_help
        ;;
    esac
    exit 0
  }

main "$@"

'';
}
