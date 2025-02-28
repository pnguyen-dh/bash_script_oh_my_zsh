#!/bin/bash

echo "Starting Oh My Zsh installation for Debian based Linux ..."

# Update package list
echo "Updating package list..."
apt update -y

# Install necessary packages
echo "Installing required packages..."
apt install -y zsh git curl

# Install Oh My Zsh
echo "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || { echo "Oh My Zsh installation failed"; exit 1; }
else
    echo "Oh My Zsh already installed, skipping..."
fi

# Install Zsh Autosuggestions
echo "Installing Zsh Autosuggestions..."
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
else
    echo "Zsh Autosuggestions already installed, skipping..."
fi

# Install Zsh Syntax Highlighting
echo "Installing Zsh Syntax Highlighting..."
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
else
    echo "Zsh Syntax Highlighting already installed, skipping..."
fi

# Modify .zshrc to enable plugins
echo "Configuring Oh My Zsh plugins..."
ZSHRC="$HOME/.zshrc"

if grep -q "plugins=(" "$ZSHRC"; then
    sed -i 's/^plugins=(.*)$/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
else
    echo "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)" >> "$ZSHRC"
fi

# Set Zsh as default shell
echo "Changing default shell to Zsh..."
chsh -s "$(which zsh)"

# Apply changes
echo "Applying changes..."
source "$ZSHRC"

echo "Installation complete! Restart your terminal or run 'zsh' to apply changes."
