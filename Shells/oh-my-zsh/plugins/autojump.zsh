# autojump Plugin
# Enables fast navigation between frequently used directories in Zsh.

# Activate the autojump plugin
plugins+=(autojump)

	[[ -s $HOME/.autojump/etc/profile.d/autojump.sh ]] && source $HOME/.autojump/etc/profile.d/autojump.sh

	autoload -U compinit && compinit -u


# Use 'j' command to jump to frequently visited directories
