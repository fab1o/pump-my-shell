#!/bin/bash
# This script is used to update the pump plugin for Oh My Zsh running on bash from curl

set -e

RELEASE_API="https://api.github.com/repos/fab1o/pump-my-shell/releases/latest"
TAG=$(curl -H "Cache-Control: no-cache" -s $RELEASE_API | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z $TAG ]; then
  echo " failed to fetch the latest release version, try again later"
  exit 1
fi

DOWNLOAD_URL="https://github.com/fab1o/pump-my-shell/archive/refs/tags/${TAG}.zip"
curl -H "Cache-Control: no-cache" -fsSL -o pump-my-shell.zip "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
  echo " failed to download the latest release, try again later"
  exit 1
fi

rm -rf temp &>/dev/null
mkdir -p temp &>/dev/null
unzip -q -o pump-my-shell.zip -d temp
if [ $? -ne 0 ]; then
  echo " failed to unzip the downloaded file, try again later"
  rm pump-my-shell.zip &>/dev/null
  rm -rf temp &>/dev/null
  exit 1
fi
#echo " ✅ downloaded pump-my-shell version $TAG"

rm pump-my-shell.zip &>/dev/null

pushd "temp/pump-my-shell-$TAG" &>/dev/null
if [ $? -ne 0 ]; then
    rm -rf temp &>/dev/null
    echo " failed to change directory to temp/pump-my-shell-$TAG, try running: "
    echo "  sudo unzip -q -o pump-my-shell.zip -d temp && cd temp/pump-my-shell-$TAG && zsh ./scripts/update.zsh"
    exit 1
fi

if command -v zsh &>/dev/null; then
  bash ./scripts/update_internal.sh
else
  echo " no Zsh found, install Oh My Zsh, then run the script again to finish the installation"
  echo " \033[94m https://ohmyz.sh/\033[0m"
fi

popd &>/dev/null
rm -rf temp &>/dev/null
echo ""
