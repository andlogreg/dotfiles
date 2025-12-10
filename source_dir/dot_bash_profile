# Only run on macOS

if [[ "$OSTYPE" == "darwin"* ]]; then
	# needed for brew
	eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# # Only run these on Ubuntu and Fedora

# if [[ $(grep -E "^(ID|NAME)=" /etc/os-release | grep -Eq "ubuntu|fedora")$? == 0 ]]; then
# 	# needed for brew to work
# 	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# fi

export XDG_CONFIG_HOME="$HOME"/.config

if [ -r ~/.bashrc ]; then
	source ~/.bashrc
fi

# # eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
# Bash completion v2. See https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/#enable-shell-autocompletion
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"
