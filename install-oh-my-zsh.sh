#!/usr/bin/env bash

set -Eeuo pipefail

readonly OMZ_DIR="$HOME/.oh-my-zsh"
readonly ZSHRC="$HOME/.zshrc"
readonly ZSH_PLUGINS=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

echo "Starting Oh My Zsh installation for Debian-based Linux..."

# Run the script as the normal account so files are installed into the
# correct home directory. Only package operations use sudo.
if (( EUID == 0 )); then
    echo "Error: Do not run this entire script with sudo."
    echo "Run it as your normal user; it will invoke sudo when required."
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    echo "Error: sudo is required for package installation."
    exit 1
fi

echo "Updating package list..."
sudo apt-get update

echo "Installing required packages..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    git \
    zsh

echo "Installing Oh My Zsh..."
if [[ ! -d "$OMZ_DIR/.git" ]]; then
    if [[ -e "$OMZ_DIR" ]]; then
        echo "Error: $OMZ_DIR exists but is not an Oh My Zsh Git repository."
        exit 1
    fi

    git clone --depth=1 \
        https://github.com/ohmyzsh/ohmyzsh.git \
        "$OMZ_DIR"
else
    echo "Oh My Zsh is already installed."
fi

# Create the standard configuration only when the user does not already
# have one. Existing configuration is preserved.
if [[ ! -f "$ZSHRC" ]]; then
    echo "Creating $ZSHRC from the Oh My Zsh template..."
    cp "$OMZ_DIR/templates/zshrc.zsh-template" "$ZSHRC"
else
    echo "$ZSHRC already exists; preserving it."
fi

readonly CUSTOM_DIR="${ZSH_CUSTOM:-$OMZ_DIR/custom}"

echo "Installing Zsh Autosuggestions..."
if [[ ! -d "$CUSTOM_DIR/plugins/zsh-autosuggestions/.git" ]]; then
    git clone --depth=1 \
        https://github.com/zsh-users/zsh-autosuggestions.git \
        "$CUSTOM_DIR/plugins/zsh-autosuggestions"
else
    echo "Zsh Autosuggestions is already installed."
fi

echo "Installing Zsh Syntax Highlighting..."
if [[ ! -d "$CUSTOM_DIR/plugins/zsh-syntax-highlighting/.git" ]]; then
    git clone --depth=1 \
        https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$CUSTOM_DIR/plugins/zsh-syntax-highlighting"
else
    echo "Zsh Syntax Highlighting is already installed."
fi

echo "Configuring Oh My Zsh plugins..."

PLUGIN_LINE="plugins=(${ZSH_PLUGINS[*]})"
TMP_FILE="$(mktemp)"

trap 'rm -f "$TMP_FILE"' EXIT

# Replace either a one-line or multiline plugins=(...) section.
# If none exists, insert it before Oh My Zsh is sourced.
awk -v plugin_line="$PLUGIN_LINE" '
BEGIN {
    replacing_plugins = 0
    configured = 0
}

{
    if (!configured &&
        !replacing_plugins &&
        $0 ~ /^[[:space:]]*plugins=\(/) {

        print plugin_line
        configured = 1

        if ($0 !~ /\)[[:space:]]*(#.*)?$/) {
            replacing_plugins = 1
        }

        next
    }

    if (replacing_plugins) {
        if ($0 ~ /\)[[:space:]]*(#.*)?$/) {
            replacing_plugins = 0
        }

        next
    }

    if (!configured &&
        $0 ~ /^[[:space:]]*source[[:space:]].*oh-my-zsh\.sh/) {

        print plugin_line
        configured = 1
    }

    print
}

END {
    if (!configured) {
        print ""
        print plugin_line
    }
}
' "$ZSHRC" > "$TMP_FILE"

# Writing into the existing file preserves its current ownership and mode.
cat "$TMP_FILE" > "$ZSHRC"

chmod 600 "$ZSHRC"

ZSH_BIN="$(command -v zsh)"

echo "Zsh executable: $ZSH_BIN"

if [[ "${SHELL:-}" != "$ZSH_BIN" ]]; then
    echo "Changing the default shell to Zsh..."
    chsh -s "$ZSH_BIN"
else
    echo "Zsh is already the default shell."
fi

echo
echo "Installation complete."
echo "Start Zsh now with:"
echo
echo "    exec zsh -l"
