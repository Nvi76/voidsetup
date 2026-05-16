#!/usr/bin/env bash
set -euo pipefail

# 1. Remove firejail
echo "======================================"
echo "           Remove Firejail?"
echo "======================================"
echo "Do you want to remove SecConf Firejail? WARNING will make changes to system and stuff"
echo "1) Yes, Remove Firejail"
echo "2) No, Don't Remove Firejail"

# Use ANSI escape codes for colored prompt
read -p $'\e[32mEnter choice [1-2]: \e[0m' choice

case $choice in
    '1')
     # Remove Firejail
        sudo xbps-remove -R firejail || { echo "Failed to remove Firejail, is it installed?"; exit 1; }

    # Remove Folders & Profiles
        sudo rm -rf /etc/firejail || true
        sudo rm -rf ~/.config/firejail || true

        echo "================================="
        echo "        Firejail Removed         "
        echo "================================="
        ;;

    '2')
        echo "================================"
        echo "        Cancelling......        "
        echo "================================"
        ;;

      *)
        echo "Invalid option."
        exit 1
esac

# 2. Remove Additionals
clear
echo "Remove Additionals?"
while true; do
    read -rp "Answer [y/n]: " reply
    case "$reply" in
        [Yy]*)
            clear
            remove_if_installed() {
                local packages=("$@")
                local to_remove=()

                for package in "${packages[@]}"; do
                    if xbps-query "$package" &>/dev/null; then
                        to_remove+=("$package")
                    else
                        echo "$package is not installed"
                    fi
                done

                if [ ${#to_remove[@]} -eq 0 ]; then
                    echo "None of the packages are installed."
                    return 0
                elif [ ${#to_remove[@]} -eq ${#packages[@]} ]; then
                    echo "All packages are installed. Removing all..."
                else
                    echo "Removing only the installed packages..."
                fi

                sudo xbps-remove -R "${to_remove[@]}"
            }

            remove_if_installed torbrowser-launcher i2pd
            flatpak remove --noninteractive com.protonvpn.www 2>/dev/null || true
            break
            ;;
        [Nn]*)
            echo "Skipping removal."
            break
            ;;
        *)
            echo "Please enter 'y' or 'n'."
            ;;
    esac
done

# 3. Remove AI Apps (OpenCode, Ollama, Alpaca)
clear
echo "======================================"
echo "           Remove AI Apps?"
echo "======================================"
echo "This will remove OpenCode, Ollama, and Alpaca along with their configs."
echo "Do you want to continue?"
echo "1) Yes, Remove AI Apps"
echo "2) No, Skip"

read -p $'\e[32mEnter choice [1-2]: \e[0m' choice

case $choice in
    '1')
        echo "Removing AI apps..."

        if command -v opencode &>/dev/null; then
            sudo rm -f "$(command -v opencode)" 2>/dev/null || true
            echo "Removed OpenCode binary."
        fi

        if command -v ollama &>/dev/null; then
            sudo rm -f "$(command -v ollama)" 2>/dev/null || true
            sudo rm -f /etc/sv/ollama 2>/dev/null || true
            sudo rm -f /var/service/ollama 2>/dev/null || true
            echo "Removed Ollama."
        fi

        if flatpak info com.jeffser.Alpaca &>/dev/null; then
            flatpak remove -y com.jeffser.Alpaca 2>/dev/null || true
            echo "Removed Alpaca."
        fi

        rm -rf ~/.config/opencode 2>/dev/null || true
        rm -rf ~/.ollama 2>/dev/null || true
        echo "Removed AI app configs."

        echo "================================="
        echo "        AI Apps Removed          "
        echo "================================="
        ;;

    '2')
        echo "Skipping AI removal."
        ;;
esac

# 4. Remove GameDev Apps (Godot, LDtk, Libresprite)
clear
echo "======================================"
echo "         Remove GameDev Apps?"
echo "======================================"
echo "This will remove Godot, LDtk, and Libresprite along with their configs."
echo "Do you want to continue?"
echo "1) Yes, Remove GameDev Apps"
echo "2) No, Skip"

read -p $'\e[32mEnter choice [1-2]: \e[0m' choice

case $choice in
    '1')
        echo "Removing GameDev apps..."

        rm -f ~/voidsetup/Godot* 2>/dev/null || true
        rm -f ~/voidsetup/LDtk* 2>/dev/null || true
        rm -f ~/voidsetup/LibreSprite* 2>/dev/null || true

        rm -rf ~/.config/godot 2>/dev/null || true
        rm -rf ~/.config/ldtk 2>/dev/null || true
        rm -rf ~/.local/share/LibreSprite 2>/dev/null || true
        rm -rf ~/.local/share/libresprite 2>/dev/null || true
        rm -rf ~/.config/GearLever 2>/dev/null || true
        echo "Removed GameDev apps and configs."

        echo "================================="
        echo "      GameDev Apps Removed       "
        echo "================================="
        ;;

    '2')
        echo "Skipping GameDev removal."
        ;;
esac
