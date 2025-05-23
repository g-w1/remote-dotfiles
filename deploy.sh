#!/bin/bash
set -euo pipefail
USAGE=$(cat <<-END
    Usage: ./deploy.sh [OPTIONS] [--aliases <alias1,alias2,...>], eg. ./deploy.sh --vim --aliases=speechmatics,custom
    Creates ~/.zshrc and ~/.tmux.conf with location
    specific config

    OPTIONS:
        --vim                   deploy very simple vimrc config 
        --aliases               specify additional alias scripts to source in .zshrc, separated by commas
END
)

export DOT_DIR=$(dirname $(realpath $0))
export CONFIG_DIR=$DOT_DIR/config

VIM="false"
ALIASES=()
while (( "$#" )); do
    case "$1" in
        -h|--help)
            echo "$USAGE" && exit 1 ;;
        --vim)
            VIM="true" && shift ;;
        --aliases=*)
            IFS=',' read -r -a ALIASES <<< "${1#*=}" && shift ;;
        --) # end argument parsing
            shift && break ;;
        -*|--*=) # unsupported flags
            echo "Error: Unsupported flag $1" >&2 && exit 1 ;;
    esac
done

echo "deploying on machine..."
echo "using extra aliases: ${ALIASES[@]}"

# Tmux setup
echo "source $DOT_DIR/config/tmux.conf" > $HOME/.tmux.conf

# Vimrc
if [[ $VIM == "true" ]]; then
    echo "deploying .vimrc"
    echo "source $DOT_DIR/config/vimrc" > $HOME/.vimrc
fi

# git setup
# if you fork this, you should change git/email and git/name
git config --global user.email "`cat git/email`"
git config --global user.name "`cat git/name`"

# zshrc setup
echo "source $DOT_DIR/config/zshrc.sh" > $HOME/.zshrc
# Append additional alias scripts if specified
if [ -n "${ALIASES+x}" ]; then
    for alias in "${ALIASES[@]}"; do
        echo "source $DOT_DIR/config/aliases_${alias}.sh" >> $HOME/.zshrc
    done
fi

# Helix setup
cp $CONFIG_DIR/helix.toml $HOME/.config/helix/config.toml

echo "changing default shell to zsh"
chsh -s $(which zsh)

zsh
