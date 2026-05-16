#!/usr/bin/env bash

# Update ClamAV & Rkhunter
sudo sv stop clamav-freshclam || exit 1
sudo freshclam || exit 1
sudo rkhunter --update || exit 1
sudo sv start clamav-freshclam || exit 1

# Update Hblock
hblock

# Update system
sudo xbps-install -Syu || exit 1

# AI tools

        # Update Ollama
        echo "Checking for Ollama updates..."
        current_ollama=$(ollama -v 2>/dev/null | awk '{print $NF}' | sed 's/^v//')
        latest_ollama=$(curl -sL https://api.github.com/repos/ollama/ollama/releases/latest | grep -oP '"tag_name": "v\K[^"]*')

        if [ -n "$latest_ollama" ] && [ "$current_ollama" != "$latest_ollama" ]; then
            echo "New Ollama version found: $latest_ollama (Current: $current_ollama). Updating..."
            curl -fsSL https://ollama.com/install.sh | sh
        else
            echo "Ollama is up to date ($current_ollama)."
        fi

        # Update OpenCode
        echo "Checking for OpenCode updates..."
        export PATH="$PATH:$HOME/.opencode/bin"
        current_opencode=$(opencode --version 2>/dev/null | awk '{print $NF}')
        latest_opencode=$(curl -sL https://opencode.ai/install | grep -m 1 "VERSION=" | cut -d'"' -f2)

        if [ -n "$latest_opencode" ] && [ "$current_opencode" != "$latest_opencode" ]; then
            echo "New OpenCode version found: $latest_opencode (Current: $current_opencode). Updating..."
            curl -fsSL https://opencode.ai/install | bash
        else
            echo "OpenCode is up to date ($current_opencode)."
        fi

# Apps

        # Update Flatpak apps
        flatpak update -y || exit 1

        # Update Atuin
        if command -v atuin &>/dev/null; then
            atuin update
        fi

        # Update Homebrew
        if command -v brew &>/dev/null; then
            brew update || exit 1
            brew upgrade || exit 1
        fi

        # Update Nixpkgs
        if command -v nix &>/dev/null; then
            nix-channel --update || exit 1
            nix profile upgrade --all || exit 1
        else
            echo "Skipping, Nix is not installed or not in the PATH"
        fi

# Shell Tools

        # Update ble.sh (git install)
        if [ -d "$HOME/.local/share/blesh" ] && [ ! -f "$HOME/.local/share/blesh/.git" ]; then
            if command -v nix &>/dev/null && nix profile list 2>/dev/null | grep -q ble-sh; then
                echo "Updating ble.sh via nix..."
                nix profile upgrade ble-sh 2>/dev/null || true
            fi
        fi

        if [ -d "$HOME/.local/share/blesh/.git" ]; then
            echo "Updating ble.sh..."
            git -C "$HOME/.local/share/blesh" pull --recurse-submodules
            make -C "$HOME/.local/share/blesh" install PREFIX="$HOME/.local"
        fi

        # Update Oh My Zsh
        if [ -d "$HOME/.oh-my-zsh/.git" ]; then
            echo "Updating Oh My Zsh..."
            git -C "$HOME/.oh-my-zsh" pull --ff-only
        fi

        # Update zsh plugins
        ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
        if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions/.git" ]; then
            echo "Updating zsh-autosuggestions..."
            git -C "$ZSH_CUSTOM/plugins/zsh-autosuggestions" pull --ff-only
        fi
        if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/.git" ]; then
            echo "Updating zsh-syntax-highlighting..."
            git -C "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" pull --ff-only
        fi

# Power

        # Update auto-cpufreq
        if command -v auto-cpufreq &>/dev/null; then
            echo "Updating auto-cpufreq..."
            sudo auto-cpufreq --update || echo "auto-cpufreq update skipped"
        fi

echo "====================================="
echo "       All Updates Completed.        "
echo "====================================="
