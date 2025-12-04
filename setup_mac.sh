#!/bin/bash

# eval "$(/opt/homebrew/bin/brew shellenv)" for brew

# TODO to make bash the defautl: `chsh -s /bin/bash`
# TODO alacritty install
# TODO install UbuntuMono NerdFont


# TODO install devpod https://devpod.sh
# devpod provider add docker

# install brew packages
brew install starship font-ubuntu-mono-nerd-font kubectx

# create directories
# TODO this should also be in bashrc
export XDG_CONFIG_HOME="$HOME"/.config
mkdir -p "$XDG_CONFIG_HOME"/alacritty
mkdir -p "$XDG_CONFIG_HOME"/alacritty/themes
mkdir -p "$XDG_CONFIG_HOME"/aerospace
mkdir -p "$XDG_CONFIG_HOME"/k9s


# symlinks
ln -sf "$PWD/alacritty/alacritty.toml" "$XDG_CONFIG_HOME"/alacritty/alacritty.toml
ln -sf "$PWD/aerospace/aerospace.toml" "$XDG_CONFIG_HOME"/aerospace/aerospace.toml
ln -sf "$PWD/starship/starship.toml" "$XDG_CONFIG_HOME"/starship.toml
ln -sf "$PWD/k9s" "$XDG_CONFIG_HOME"/k9s
ln -sf "$PWD/.tmux.conf" "$HOME"/.tmux.conf
ln -sf "$PWD/.bashrc" "$HOME"/.bashrc
ln -sf "$PWD/.bash_profile" "$HOME"/.bash_profile
ln -sf "$PWD/.zprofile" "$HOME"/.zprofile
ln -sf "$PWD/.zshrc" "$HOME"/.zshrc
ln -sf "$PWD/nvim" "$XDG_CONFIG_HOME"/nvim
ln -sf "$PWD/lazygit" "$XDG_CONFIG_HOME"/lazygit
ln -sf "$PWD/scripts" "$XDG_CONFIG_HOME"/scripts
