#!/bin/bash
# This script is used to install the pump plugin for Oh My Zsh for the 1st time

set -e

echo " installing pump-my-shell..."

if ! command -v zsh &>/dev/null; then
  echo " Oh My Zsh is not installed and required to continue." >&2
  echo " install Zsh: \033[94mhttps://ohmyz.sh\033[0m" >&2
  echo "" >&2
  echo " or run the following to install all dependencies:" >&2
  echo '  bash -c "$(curl -fsSL https://raw.githubusercontent.com/fab1o/pump-my-shell/refs/heads/main/scripts/install_deps.sh)"' >&2
  echo "" >&2
  exit 1
fi

if ! command -v gum &>/dev/null; then
  echo " pump-my-shell recommends gum for better user experience"
  echo " install gum: \033[94mhttps://github.com/charmbracelet/gum\033[0m" >&2 
fi

RELEASE_API="https://api.github.com/repos/fab1o/pump-my-shell/releases/latest"
TAG=$(curl -H "Cache-Control: no-cache" -s $RELEASE_API | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z $TAG ]; then
  echo " failed to fetch the latest release version, try again later" >&2
  exit 1
fi

DOWNLOAD_URL="https://github.com/fab1o/pump-my-shell/archive/refs/tags/${TAG}.zip"
curl -H "Cache-Control: no-cache" -fsSL -o pump-my-shell.zip "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
  echo " failed to download the latest release, try again later" >&2
  exit 1
fi

rm -rf temp >/dev/null &>/dev/null
mkdir -p temp
unzip -q -o pump-my-shell.zip -d temp

if [ $? -ne 0 ]; then
  echo " failed to unzip the downloaded file, try again later" >&2
  rm pump-my-shell.zip
  rm -rf temp
  exit 1
fi

rm pump-my-shell.zip >/dev/null &>/dev/null

if command -v zsh &>/dev/null; then
  pushd "temp/pump-my-shell-$TAG" &>/dev/null

  if [ $? -ne 0 ]; then
    echo " failed to change directory to temp/pump-my-shell-$TAG, try running: " >&2
    echo "  sudo unzip -q -o pump-my-shell.zip -d temp && cd temp/pump-my-shell-$TAG && zsh ./scripts/update.zsh && zsh ./scripts/edit_zshrc.zsh" >&2
  else
    zsh ./scripts/edit_zshrc.zsh
    bash ./scripts/update_internal.sh
    bash ./scripts/check_zshrc.sh

    echo ""
    echo " then run: help"
    echo ""
  fi

  popd &>/dev/null
else
  echo " no Zsh found, install Oh My Zsh, then run the script again to finish the installation" >&2
  echo " \033[94m https://ohmyz.sh/\033[0m" >&2
fi

rm -rf temp >/dev/null &>/dev/null
