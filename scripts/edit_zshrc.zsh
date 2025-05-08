#!/bin/zsh
# This script is used to edit the .zshrc file to add the pump plugin and its config

set -e

zshrc_file="$HOME/.zshrc"

if [ ! -f "$zshrc_file" ]; then
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
  echo " updated '$zshrc_file' with pump-my-shell"
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
  tmp_file="$(mktemp "${zshrc_file}.XXXX")" || exit 1

  if sed -E 's/^[[:space:]]*#?[[:space:]]*plugins=\(([^)]*)\)/plugins=(\1 pump)/' "$zshrc_file" > "$tmp_file"; then
    mv "$tmp_file" "$zshrc_file"
  else
    echo " error: failed to update $zshrc_file" >&2
    rm -f "$tmp_file"
    exit 1
  fi

  echo " added pump to your plugins=(...)"
fi
