#!/bin/zsh
# This script is used to update the pump plugin for Oh My Zsh running on zsh locally from npm

set -e

SRC_DIR="./lib"
DEST_DIR="$HOME/.oh-my-zsh/plugins/pump"

mkdir -p "$DEST_DIR"
yes | cp -Rf $SRC_DIR/pump.omp.json "$DEST_DIR/pump.omp.json"
yes | cp -Rf $SRC_DIR/pump.plugin.zsh "$DEST_DIR/pump.plugin.zsh"

# jq require brew install jq
# VERSION=$(jq -r '.version' package.json)
VERSION=$(grep '"version"' package.json | head -1 | sed -E 's/.*"version": *"([^"]+)".*/\1/')
echo "$VERSION" > $DEST_DIR/.version

echo " pump in version $VERSION! Now restart your terminal"

# no longer update the config file, instead, just copy if it doesn't exist
#zsh ./scripts/update_config.zsh

DEST_DIR_CONFIG="$HOME/.oh-my-zsh/plugins/pump/config"
DEST_CONFIG="$DEST_DIR_CONFIG/pump.zshenv"
SRC_CONFIG="./config/pump.zshenv"

if [[ ! -f "$DEST_CONFIG" ]]; then
  mkdir -p "$DEST_DIR_CONFIG"
  cp "$SRC_CONFIG" "$DEST_CONFIG"
fi
