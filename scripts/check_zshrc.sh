#!/bin/bash

set -e

zshrc_file="$HOME/.zshrc"

if ! grep -q '^plugins=' $zshrc_file; then
  echo " plugins not found in your $zshrc_file file, please add it manually:"
  echo ""
  echo "\033[93m plugins=(pump)\033[0m"
  echo ""
  echo " also, make sure the snippet below is at the bottom of the file:"
  echo ""
  echo "# pump-my-shell config"
  echo 'if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then"'
  echo '  eval "$(oh-my-posh init zsh --config $HOME/.oh-my-zsh/plugins/pump/pump.omp.json)"'
  echo "fi"
  echo "# pump-my-shell config"
  echo ""
  exit 1
fi
