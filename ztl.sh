#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------ #
#                   DISPLAY HELP MENU                    #
# ------------------------------------------------------ #
show_help() {
	cat <<EOF
Usage: ztl [COMMAND]

Commands:
  init                            Initialize vault at pwd
  new/n <filename>                Add new file to vault at pwd 
  rm                              Interactively remove file from vault
  compile/c                       Interactively select and open file from vault
  repair                          Repair vault resources (global settings are preserved)
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
		VAULT_ROOT="$VAULT_HOME/vault"
		VAULT_TYP="$VAULT_ROOT/vault.typ"
		VAULT_CSV="$VAULT_ROOT/vault.csv"
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
		return
	}
	failure_cmd() {
		echo "Initializing your vault..."
		return
	}
	vault_finder

	# create vault resources
	mkdir "$VAULT_ROOT"
	touch "$VAULT_TYP"
	touch "$VAULT_CSV"

	# Setup vault.typ with some broilerplate for basalt-lib
	cat <<'VAULT_FILE_BROILERPLATE' >"$VAULT_TYP"
#import "@preview/basalt-lib:1.0.0": new-vault, xlink, as-branch
#let vault = new-vault(
  note-paths: csv("./vault.csv").flatten(),
  include-from-vault: path => include path,
  formatters: (
    // refer https://github.com/GabrielDTB/basalt-lib?tab=readme-ov-file#formatting
  )
)
VAULT_FILE_BROILERPLATE

	cat <<EOF
Initialization complete.
Vault Home: $VAULT_HOME
EOF

	return
}

# ------------------------------------------------------ #
#              FILE CREATION AND LINK MANAGER            #
# ------------------------------------------------------ #
create_file() {
	success_cmd() {
		printf '\n'
		return
	}
	failure_cmd() {
		echo "Vault is not initialized."
		echo "Please run 'ztl init' to initialize current directory."
		return
	}
	vault_finder
	if [ "$#" -ne 2 ]; then
		echo "Please provide filename as a single argument."
		echo "Usage: ztl new/n [filename]"
		return
	fi

	file="$2.typ"
	file_path="$(pwd)/$file"
	file_name="$(basename "$2")"

	if [ -e "$file_path" ]; then
		echo "Error: '$file_path' already exists. Choose a different name."
		return
	fi

	mkdir -p "$(dirname "$2")"
	touch "$file"

	relative_typ="$(realpath --relative-to="$(dirname "$file_path")" "$VAULT_TYP")"

	# Setup new file with some broilerplate for basalt-lib
	cat <<NEW_FILE_BROILERPLATE >"$file"
#import "$relative_typ": *
#show: vault.new-note.with(
  name: "$file_name",
  //other metadata here
)

Insightful note content...
NEW_FILE_BROILERPLATE

	relative_csv="$(realpath --relative-to="$(dirname "$VAULT_CSV")" "$file_path")"
	grep -qxF "$relative_csv" "$VAULT_CSV" || echo "$relative_csv" >>"$VAULT_CSV"
	sort -ubfV "$VAULT_CSV" -o "$VAULT_CSV"

	echo "Added '$file' to vault successfully."
	echo "File location: $VAULT_HOME/$file."
	return
}

# ------------------------------------------------------ #
#            FILE REMOVAL AND RESIDUE CLEANUP            #
# ------------------------------------------------------ #
remove_file() {
	success_cmd() {
		printf '\n'
		return
	}
	failure_cmd() {
		echo "Vault is not initialized."
		echo "Please run 'ztl init' to initialize current directory."
		return
	}
	vault_finder

	if [ "$#" -ne 1 ]; then
		echo "Error: Argument is not required."
		echo "This command launches an interactive selector."
		echo "Usage: ztl rm"
		return
	fi

	selected_file=$(fd . -e typ --exclude vault --strip-cwd-prefix --base-directory "$VAULT_HOME" | fzf)

	#Removes link from vault.csv
	grep -Fxv "../$selected_file" "$VAULT_CSV" >"$VAULT_CSV.tmp" && mv "$VAULT_CSV.tmp" "$VAULT_CSV"

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
		printf '\n'
		return
	}
	failure_cmd() {
		echo "Vault is not initialized."
		echo "Please run 'ztl init' to initialize current directory."
		return
	}

	vault_finder

	if [ "$#" -ne 1 ]; then
		echo "Error: Argument is not required."
		echo "This command launches an interactive selector."
		echo "Usage: ztl compile/c"
		return
	fi

	local selected_file
	selected_file="$VAULT_HOME/$(fd . -e typ --exclude vault --strip-cwd-prefix --base-directory "$VAULT_HOME" | fzf)"

	if [[ -z "$selected_file" ]]; then
		echo "No file selected."
		return
	fi

	typst watch --root "$VAULT_HOME" "$selected_file" --open sioyek
}

repair_vault() {
	success_cmd() {
		echo "Vault found at: $VAULT_HOME"
		return
	}
	failure_cmd() {
		echo "Vault is not initialized."
		echo "Please run 'ztl init' to initialize current directory."
		return
	}
	vault_finder

	if [ "$#" -ne 1 ]; then
		echo "Error: Argument is not required."
		echo "You will be shown a confiramtion prompt."
		echo "Usage: ztl repair"
		return
	fi

	echo "Do you want to repair this vault? (y/n):"
	read -r confirmation

	if [[ "$confirmation" =~ ^[Yy]$ || -z "$confirmation" ]]; then
		cd "$VAULT_HOME"
		cp "$VAULT_TYP" "$VAULT_HOME"
		rm -r "vault"
		init_vault
		cat "$VAULT_HOME/vault.typ" >"$VAULT_TYP"
		rm "$VAULT_HOME/vault.typ"

		fd . -e typ --exclude vault |
			sed 's|^\./||' |
			awk -v OFS=',' '{ print "../" $0 }' \
				>"$VAULT_CSV"

		sort -ubfV "$VAULT_CSV" -o "$VAULT_CSV"

		echo "Vault repaired successfully!"
	else
		echo "Vault repair aborted."
	fi

	return
}

# ------------------------------------------------------ #
#                      MAIN FUNCTION                     #
# ------------------------------------------------------ #
main() {
	if [ "$#" -eq 0 ]; then
		show_help
		exit
	fi
	case "$1" in
	init)
		init_vault
		exit
		;;
	new | n)
		create_file "$@"
		exit
		;;
	rm)
		remove_file "$@"
		exit
		;;
	compile | c)
		compile_file "$@"
		exit
		;;
	repair)
		repair_vault "$@"
		exit
		;;
	help | *)
		show_help
		exit
		;;
	esac
}

main "$@"
