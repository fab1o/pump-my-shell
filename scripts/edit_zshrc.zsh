#!/bin/zsh
# This script is used to edit the .zshrc file to add the pump plugin and its config

set -e

DEST_DIR="$HOME/.oh-my-zsh/plugins/pump"
zshrc_file="$HOME/.zshrc"

if [ ! -f "$DEST_DIR/pump.omp.json" ]; then
  echo " pump.omp.json not found in $DEST_DIR"
  echo ""
  echo " please re-install pump-my-shell, run:"
  echo '  bash -c "$(curl -fsSL https://raw.githubusercontent.com/fab1o/pump-my-shell/refs/heads/main/scripts/install.sh)"'
  echo ""
  exit 1
fi

if [ ! -f "$zshrc_file" ]; then
  echo ""
  echo "\e[93m edit your .zshrc file and add pump to your plugins:\e[0m"
  echo ""
  echo "plugins=(pump)"
  echo ""
  echo "\e[93m also add the following to your .zshrc file:\e[0m"
  echo ""
  echo "# pump-my-shell config"
  echo 'if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then"'
  echo '  eval "$(oh-my-posh init zsh --config $HOME/.oh-my-zsh/plugins/pump/pump.omp.json)"'
  echo "fi"
  echo "# pump-my-shell config"
  echo ""
  exit 1;
fi

CONFIG_SNIPPET=$(cat << 'EOF'

# pump-my-shell config
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config $HOME/.oh-my-zsh/plugins/pump/pump.omp.json)"
fi
# pump-my-shell config
EOF
)

if ! grep -q 'pump.omp.json' "$zshrc_file"; then
  echo "$CONFIG_SNIPPET" >> "$zshrc_file"
  echo " added pump.omp.json to your $zshrc_file"
fi

FOUND_PUMP=0
plugins_line=$(grep -E '\s*plugins=\(.*\)' "$zshrc_file")
if [[ -n "$plugins_line" ]]; then
  # Extract the content between the parentheses using parameter expansion safely
  plugins_contents=${plugins_line##*\(}
  plugins_contents=${plugins_contents%\)*}

  # Convert the content into an array (respects Zsh word splitting)
  plugins_array=(${(z)plugins_contents})

  # Check if "pump" is in the array
  for plugin in "${plugins_array[@]}"; do
    if [[ "$plugin" == "pump" ]]; then
      FOUND_PUMP=1
    fi
  done
fi

if [[ $FOUND_PUMP -eq 0 ]]; then
  sed -i '' -E 's/^[[:space:]]*#?[[:space:]]*plugins=\((.*)\)/plugins=(\1 pump)/' "$zshrc_file"
fi
