#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

# Remove firejail
header "Firejail"
echo "Do you want to remove SecConf Firejail? WARNING will make changes to system and stuff"
echo "1) Yes, Remove Firejail"
echo "2) No, Don't Remove Firejail"

case $(pick "Choice [1-2]" 1 2) in
    '1')
     # Remove Firejail
        sudo xbps-remove -Rns firejail || { echo "Failed to remove Firejail, is it installed?"; exit 1; }

    # Remove Folders & Profiles
        sudo rm -rf /etc/firejail || true
        sudo rm -rf ~/.config/firejail || true

        ok "Firejail removed"
        ;;

    '2')
        info "Skipping..."
        ;;

      *)
        err "Invalid option."
esac

# Remove Additionals
if yn "Remove Additionals?"; then
clear
remove_if_installed() {
    local packages=("$@")
    local to_remove=()

    for package in "${packages[@]}"; do
        if xbps-query "$package" &>/dev/null; then
            to_remove+=("$package")
        else
            info "$package is not installed"
        fi
    done

    if [ ${#to_remove[@]} -eq 0 ]; then
        info "None of the packages are installed."
    return 0
    elif [ ${#to_remove[@]} -eq ${#packages[@]} ]; then
        info "All packages are installed. Removing all..."
    else
        info "Removing only the installed packages..."
    fi
    sudo xbps-remove -R "${to_remove[@]}"
}

remove_if_installed torbrowser-launcher proton-vpn-cli i2pd
else
    info "Skipping..."
fi

# Remove AI Tools
clear
header "AI Tools"
echo "This will remove OpenCode, Ollama, and Alpaca along with their configs."
echo "Do you want to continue?"
echo "1) Yes, Remove AI Apps"
echo "2) No, Skip"

case $(pick "Choice [1-2]" 1 2) in
    '1')
        info "Removing AI apps..."

        if command -v opencode &>/dev/null; then
            sudo rm -f "$(command -v opencode)" 2>/dev/null || true
            ok "Removed OpenCode binary."
        fi

        if command -v ollama &>/dev/null; then
            sudo rm -f "$(command -v ollama)" 2>/dev/null || true
            sudo rm -f /etc/sv/ollama 2>/dev/null || true
            sudo rm -f /var/service/ollama 2>/dev/null || true
            ok "Removed Ollama."
        fi

        if flatpak info com.jeffser.Alpaca &>/dev/null; then
            flatpak remove -y com.jeffser.Alpaca 2>/dev/null || true
            ok "Removed Alpaca."
        fi

        rm -rf ~/.config/opencode 2>/dev/null || true
        rm -rf ~/.ollama 2>/dev/null || true
        ok "Removed AI app configs."
        ;;

    '2')
        info "Skipping AI removal."
        ;;
esac

# Remove GameDev Apps
clear
header "GameDev Apps"
echo "This will remove Godot, LDtk, and Libresprite along with their configs."
echo "Do you want to continue?"
echo "1) Yes, Remove GameDev Apps"
echo "2) No, Skip"

case $(pick "Choice [1-2]" 1 2) in
    '1')
        info "Removing GameDev apps..."
        rm -f "$SCRIPT_DIR"/Godot* 2>/dev/null || true
        rm -f "$SCRIPT_DIR"/LibreSprite* 2>/dev/null || true
        ok "Removed GameDev apps and configs."
        ;;

    '2')
        info "Skipping GameDev removal."
        ;;
    *)
        err "Invalid Choice"
        ;;
esac
