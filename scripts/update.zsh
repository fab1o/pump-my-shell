#!/bin/zsh
# This script is used to update the pump plugin for Oh My Zsh running on zsh locally from npm

set -e

SRC_DIR="./lib"
DEST_DIR="$HOME/.oh-my-zsh/plugins/pump"

#echo " 🔁 Syncing files to $DEST_DIR..."
mkdir -p "$DEST_DIR" >/dev/null 2>&1
cp -R $SRC_DIR/pump.omp.json "$DEST_DIR/pump.omp.json"
cp -R $SRC_DIR/pump.plugin.zsh "$DEST_DIR/pump.plugin.zsh"

VERSION=$(awk -F'"' '/"version"/ {print $4}' package.json)
#VERSION=$(grep '"version"' package.json | sed -E 's/.*"version": *"([^"]+)".*/\1/')
echo "$VERSION" > $DEST_DIR/.version

zsh ./scripts/update_config.zsh

echo " pump in version $VERSION! - restart your terminal"
