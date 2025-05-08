#!/bin/bash

zshrc_file="$HOME/.zshrc"

if [ ! -f "$zshrc_file" ] || ! grep -q '^plugins=' $zshrc_file; then
  echo " plugins not found in your $zshrc_file file, please add it manually:" >&2
  echo "" >&2
  echo "  plugins=(pump)" >&2
  echo "" >&2
  echo " also, make sure the snippet below is at the bottom of the file:" >&2
  echo "" >&2
  echo "# pump-my-shell config" >&2
  echo 'if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then"' >&2
  echo '  eval "$(oh-my-posh init zsh --config $HOME/.oh-my-zsh/plugins/pump/pump.omp.json)"' >&2
  echo "fi" >&2
  echo "# pump-my-shell config" >&2
  echo "" >&2
  exit 1
fi
