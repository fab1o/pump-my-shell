#!/bin/bash
# This script is used to install the pump plugin for Oh My Zsh for the 1st time

set -e

# Download latest release from GitHub
#echo " ⬇️ downloading latest release..."
echo " installing pump-my-shell..."

if ! command -v zsh &>/dev/null; then
  echo " Oh My Zsh is not installed and required to continue."
  printf " install Zsh: \033[94mhttps://ohmyz.sh\033[0m"
  echo ""
  echo " or run the following to install all dependencies:"
  echo '  bash -c "$(curl -fsSL https://raw.githubusercontent.com/fab1o/pump-my-shell/refs/heads/main/scripts/install_deps.sh)"'
  echo ""
  exit 1
  # echo "Would you like to install Zsh along with all necessary dependencies?"
  # if read -r -p "Press [y] to install or [n] to exit: " response; then
  #   case $response in
  #     [Yy]* ) 
  #       /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/fab1o/pump-my-shell/refs/heads/main/scripts/install_deps.sh)"
  #       ;;
  #     [Nn]* ) 
  #       exit 1
  #       ;;
  #     * ) 
  #       exit 1
  #       ;;
  #   esac
  # fi
fi

if ! command -v gum &>/dev/null; then
  echo " pump-my-shell recommends gum for better user experience"
  printf " install gum: \033[94mhttps://github.com/charmbracelet/gum\033[0m"
  echo ""
fi

RELEASE_API="https://api.github.com/repos/fab1o/pump-my-shell/releases/latest"
TAG=$(curl -s $RELEASE_API | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z $TAG ]; then
  echo " failed to fetch the latest release version, try again later"
  exit 1
fi

DOWNLOAD_URL="https://github.com/fab1o/pump-my-shell/archive/refs/tags/${TAG}.zip"
curl -fsSL -o pump-my-shell.zip "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
  echo " failed to download the latest release, try again later"
  exit 1
fi

rm -rf temp >/dev/null &>/dev/null
mkdir -p temp
unzip -q -o pump-my-shell.zip -d temp
if [ $? -ne 0 ]; then
  echo " failed to unzip the downloaded file, try again later"
  rm pump-my-shell.zip
  rm -rf temp
  exit 1
fi
#echo " ✅ downloaded pump-my-shell version $TAG"

rm pump-my-shell.zip >/dev/null &>/dev/null

if command -v zsh &>/dev/null; then
  pushd "temp/pump-my-shell-$TAG" &>/dev/null
  if [ $? -ne 0 ]; then
    rm -rf temp >/dev/null 2>&1
    echo " failed to change directory to temp/pump-my-shell-$TAG, try running: "
    echo "  sudo unzip -q -o pump-my-shell.zip -d temp && cd temp/pump-my-shell-$TAG && zsh ./scripts/update.zsh && zsh ./scripts/edit_zshrc.zsh"
    exit 1
  fi

  zsh ./scripts/update.zsh
  zsh ./scripts/edit_zshrc.zsh
  bash ./scripts/check_zshrc.sh

  popd &>/dev/null
else
  echo " no Zsh found, install Oh My Zsh, then run the script again to finish the installation"
  echo " \033[94m https://ohmyz.sh/\033[0m"
fi

rm -rf temp >/dev/null &>/dev/null
echo ""
printf " then type and run\033[93m help \033[0m"
echo ""
