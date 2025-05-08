#!/bin/bash
# This script is used to automatically install the dependencies for Pump My Shell

set -e

echo " 🚀 Starting Pump My Shell setup..."

# 1. Install Homebrew
if ! command -v brew &>/dev/null; then
  echo " 🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -H "Cache-Control: no-cache" -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo " ✅ Homebrew already installed."
fi

# 2. Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo " 🔧 Installing Oh My Zsh..."
  sh -c "$(curl -H "Cache-Control: no-cache" -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  source "$HOME/.zshrc"
else
  echo " ✅ Oh My Zsh already installed."
fi

# 3. Install Oh My Posh
if ! command -v oh-my-posh &>/dev/null; then
  echo " ✨ Installing Oh My Posh..."
  brew install jandedobbeleer/oh-my-posh/oh-my-posh
else
  echo " ✅ Oh My Posh already installed."
fi

# 4. Install Nerd Fonts
FONT_DIR="$HOME/Library/Fonts"
FONT_CHECK=$(ls "$FONT_DIR" | grep -i "MesloLGM.*Nerd.*Font" || true)

if [ -n "$FONT_CHECK" ]; then
  echo " ✅ MesloLGM Nerd Font already installed."
else
  echo " 🔤 Installing MesloLGM Nerd Font..."
  MESLO_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
  curl -Lo Meslo.zip "$MESLO_FONT_URL"
  unzip -o Meslo.zip -d "$FONT_DIR"
  rm Meslo.zip
  echo " ✅ Nerd Font installed. Make sure to select it in your terminal preferences."
fi

# 5. Install gum
if ! command -v gum &>/dev/null; then
  echo " 🌿 Installing gum..."
  brew install gum
else
  echo " ✅ gum already installed."
fi

# 6. Install GitHub CLI
if ! command -v gh &>/dev/null; then
  echo " 🐙 Installing GitHub CLI..."
  brew install gh
else
  echo " ✅ GitHub CLI already installed."
fi

# 7. Install glow (optional but recommended)
if ! command -v glow &>/dev/null; then
  echo " 🌿 Installing glow..."
  brew install glow
else
  echo " ✅ glow already installed."
fi
echo ""
