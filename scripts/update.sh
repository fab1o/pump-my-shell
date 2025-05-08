#!/bin/bash
# This script is used to update the pump plugin for Oh My Zsh running on bash from curl

set -e

sleep 1
RELEASE_API="https://api.github.com/repos/fab1o/pump-my-shell/releases/latest"
TAG=$(curl -H "Cache-Control: no-cache" -s $RELEASE_API | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z $TAG ]; then
  echo " failed to fetch the latest release version, try again later"
  exit 1
fi
sleep 1
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

rm pump-my-shell.zip &>/dev/null

if [ $? -ne 0 ]; then
  echo " failed to unzip the downloaded file, try again later" >&2
  rm pump-my-shell.zip
  rm -rf temp
  exit 1
fi

pushd "temp/pump-my-shell-$TAG" &>/dev/null

if [ $? -ne 0 ]; then
  echo " failed to change directory to temp/pump-my-shell-$TAG, try running: " >&2
  echo "  sudo unzip -q -o pump-my-shell.zip -d temp && cd temp/pump-my-shell-$TAG && zsh ./scripts/update.zsh && zsh ./scripts/edit_zshrc.zsh" >&2
else
  bash ./scripts/update_internal.sh
  bash ./scripts/check_zshrc.sh

  echo ""
  echo " then run: help"
  echo ""
fi

popd &>/dev/null
rm -rf temp >/dev/null &>/dev/null
