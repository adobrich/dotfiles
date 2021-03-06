#!/bin/bash

NORMAL="\\e[0m"
ERROR="\\e[0;31m"
INFO="\\e[0;33m"
HEADER="\\e[0;34m"
OK="\\e[0;32m"

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for dependencies
check_for_dependencies() {
  echo -e "$HEADER Checking dependencies"
  deps=(wget git nvim)
  for dep in "${deps[@]}"; do
    type "$dep" > /dev/null 2>&1 || {
      echo -e " $ERROR -> $NORMAL Missing dependency '${INFO}${dep}${NORMAL}'. Please install and try again."
      exit 1
    }
  done
  echo -e " $OK -> $NORMAL All dependencies available"
}

# Create symlink: $1 = source file, $2 = link path, $3 = link name
create_symlink() {
    echo -e " $OK -> $NORMAL Creating symlink for $3"
    ln -sf "$1" "$2/$3"
}

# Backup file if it exists: $1 = path, $2 = filename
backup_if_exists() {
    if [ ! -h "$1/$2" ] && [ -e "$1/$2" ]; then
      backup_name="$2_$(date +%x_%H%M%S | sed 's/\//-/g').bak"
      echo -e " $INFO -> $NORMAL Backing up $2 as '$backup_name'"
      mv "$1/$2" "$1/$backup_name"
    fi
}

setup_local_folders() {
    echo -e "$HEADER Setting up local 'bin' and 'scripts' folders $NORMAL"
    if [ ! -d "$HOME/bin" ]; then
        mkdir "$HOME/bin"
    fi
    create_symlink "$(which nvim)" "$HOME/bin" vim
    create_symlink "$SOURCE_DIR/bin/start_tmux" "$HOME/bin" start_tmux

    if [ ! -d "$HOME/scripts" ]; then
        mkdir "$HOME/scripts"
    fi

    create_symlink "$SOURCE_DIR/scripts/extract" "$HOME/scripts" extract
    . "$HOME/scripts/extract"

    wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh \
        -qO "$HOME/scripts/git-prompt.sh" \
        && echo -e " $OK -> $NORMAL Downloaded 'git-prompt.sh' to scripts folder" \
        || echo -e " $ERROR -> $NORMAL Failed to download '${INFO}git-prompt.sh${NORMAL}'"
}

process_bash_configs() {
    echo -e "$HEADER Processing 'bash configs' $NORMAL"
    config_files=(aliases bash_profile bash_prompt bashrc exports inputrc path)
    for file in "${config_files[@]}"; do
        backup_if_exists "$HOME" ".${file}"
        create_symlink "$SOURCE_DIR/${file}" "$HOME" ".$file"
        # Source newly created files
        if [ "$file" == inputrc ]; then
            continue
        else
            . "$HOME/.${file}"
        fi
    done
    unset config_files
}

process_misc_configs() {
  echo -e "$HEADER Processing 'tmux config' $NORMAL"
  backup_if_exists "$HOME" .tmux.conf
  create_symlink "$SOURCE_DIR/tmux.conf" "$HOME" ".tmux.conf"
}

process_nvim_configs() {
    echo -e "$HEADER Processing 'neovim configs' $NORMAL"
    nvim_config_path="$HOME/.config/nvim"
    if [ ! -d "$nvim_config_path" ]; then
        mkdir -p "$nvim_config_path"
    fi

    # Array since I may break my vim file up into modules at some point
    config_files=(init.vim)
    for file in "${config_files[@]}"; do
        backup_if_exists "$nvim_config_path" "$file"
        create_symlink "$SOURCE_DIR/config/nvim/${file}" "$nvim_config_path" "$file"
    done
    unset config_files
}

# Install vim plug (neovim plugin manager)
install_vim_plug_and_all_plugins() {
  wget -qNP ~/.local/share/nvim/site/autoload \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && {
    echo -e " $OK -> $NORMAL Downloading vim plug"
    echo -e " $OK -> $NORMAL Installing all plugins from 'init.vim' (this can take a while)"
    vim -e +'PlugInstall' +qa > /dev/null 2>&1
    echo -e " $OK -> $NORMAL All plugins installed"
  } || echo -e " $ERROR -> $NORMAL Failed to download '${INFO}plug.vim${NORMAL}'"
}

check_for_dependencies
setup_local_folders
process_bash_configs
process_misc_configs
process_nvim_configs
install_vim_plug_and_all_plugins

exit 0
