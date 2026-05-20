#!/usr/bin/env bash
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

# Checking
clear
echo "Did you install the nvidia drivers already or are you using other gpus not needing any drivers? (y/n):"

while true; do
    read -p "Answer [y/n]: " reply

    case $reply in
        Y|y)
            echo "Continuing..."
            break
            ;;
        N|n)
            echo "Go and install the nvidia driver first."
            break
            ;;
        *)
            echo "Please enter 'y' or 'n'."
            ;;
    esac
done

# Update system
update_system || exit 1

# ===============
#      Apps
# ===============

# Install base apps
sudo xbps-install -Sy vulkan-loader os-prober python3-tkinter python3-pip exfatprogs mesa-utils gnupg cava timeshift nix \
    noto-fonts-ttf dejavu-fonts-ttf nerd-fonts bridge-utils xf86-input-libinput xclip tmux unzip || exit 1

# Nix
if yn_default "Do you want to install NixPkg Manager? (y/n):" "Installing NixPkg Manager..." "Skipping installation."; then
    sudo ln -s /etc/sv/nix-daemon /var/service
    feature_line="experimental-features = nix-command flakes"
    if [ -f /etc/nix/nix.conf ] && ! grep -q "$feature_line" /etc/nix/nix.conf 2>/dev/null; then
        echo "$feature_line" | sudo tee -a /etc/nix/nix.conf >/dev/null
    fi
    source /etc/profile
fi

# Install Atuin
if ! command -v atuin &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh || exit 1
fi

# Homebrew
if yn_default "Do you want to install Homebrew Apps? (y/n):" "Installing Homebrew Apps..." "Skipping installation."; then

    # Load Homebrew for current session
    if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    # Homebrew apps
    if command -v brew &>/dev/null; then
        brew install fzf ranger btop thefuck trash-cli ffmpeg fastfetch
    fi
fi

# Install Flatpak if not present
if ! command -v flatpak &>/dev/null; then
    sudo xbps-install -S flatpak
fi
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Additional Browsers
clear
echo "=========================================="
echo "           Additional Browsers"
echo "=========================================="
timeout 2s sleep 2

# Helium Browser
if yn_default "Do you want to install Helium? (y/n):" "Installing browser..." "Skipping browser installation."; then
    flatpak install flathub it.mijorus.gearlever --noninteractive
    curl -fL https://github.com/imputnet/helium-linux/releases/download/0.8.5.1/helium-0.8.5.1-x86_64.AppImage -o Helium.AppImage
    flatpak run it.mijorus.gearlever ~/voidsetup/Helium.AppImage
fi

# Brave Browser
if yn_default "Do you want to install Brave Browser? (y/n):" "Installing browser..." "Skipping browser installation."; then
    sudo xbps-install -S brave
fi

# Librewolf
if yn_default "Do you want to install Librewolf? (y/n):" "Installing browser..." "Skipping browser installation."; then
    flatpak install flathub io.gitlab.librewolf-community --noninteractive
fi

# Mullvad Browser
if yn_default "Do you want to install Mullvad Browser? (y/n):" "Installing browser..." "Skipping browser installation."; then
    flatpak install flathub net.mullvad.MullvadBrowser --noninteractive
fi

# Floorp Browser
if yn_default "Do you want to install Floorp? (y/n):" "Installing browser..." "Skipping browser installation."; then
    flatpak install flathub one.ablaze.floorp --noninteractive
fi

# Zen Browser
if yn_default "Do you want to install Zen Browser? (y/n):" "Installing browser..." "Skipping browser installation."; then
    flatpak install flathub app.zen_browser.zen --noninteractive
fi

clear
echo "============================================="
echo "           Additional Tools & Games          "
echo "============================================="
timeout 2s sleep 2

# Install Additional
if yn_second "Do you want to install Additional tools? (Might not be needed for desktop usage) (y/n)" "Installing tools..." "Skipping installation."; then
    sudo xbps-install -S torbrowser-launcher
    flatpak install flathub com.protonvpn.www --noninteractive
fi

# Game Dev
if yn_default "Do you want to install GameDev Apps? (y/n):" "Installing GameDev Apps..." "Skipping GameDev Apps installation."; then
    mkdir -p ""

    echo "Installing Godot..."
    curl -fL \
        https://github.com/godotengine/godot/releases/download/4.6.2-stable/Godot_v4.6.2-stable_linux.x86_64.zip \
        -o Godot_v4.6.2-stable_linux.x86_64.zip || exit 1

    unzip -o Godot_v4.6.2-stable_linux.x86_64.zip -d

    info "Instal LDtk Manually"

    # LibreSprite
    info "Downloading LibreSprite..."
    flatpak install flathub com.github.libresprite.LibreSprite --noninteractive

    trash-put "/Godot_v4.6.2-stable_linux.x86_64.zip"
fi

# Games
if yn_default "Do you want to install Games aswell? (y/n):" "Installing Games..." "Skipping installation of games."; then
    flatpak install flathub org.luanti.luanti info.beyondallreason.bar org.openttd.OpenTTD net.openra.OpenRA net.wz2100.wz2100 --noninteractive
fi

# Code
if yn_default "Do you want to install VSCode (y/n):" "Installing VSCode..." "Skipping VSCode installation."; then
    flatpak install flathub com.visualstudio.code --noninteractive
fi

# Codium
if yn_default "Do you want to install VSCodium (y/n):" "Installing VSCodium..." "Skipping VSCodium installation."; then
    flatpak install flathub com.vscodium.codium --noninteractive
fi

# Logseq
if yn_default "Do you want to install Logseq (y/n):" "Installing Logseq..." "Skipping Logseq installation."; then
    flatpak install flathub com.logseq.Logseq --noninteractive
fi

# Educational Apps
if yn_default "Do you want to Educational Apps? (y/n):" "Installing Educational Apps..." "Skipping installation of Educational Apps..."; then
    edu_apps
fi

# VirtManager (GnomeBoxes)
if yn_default "Do you want to install VirtManager? (y/n):" "Installing VirtManager..." "Skipping VirtManager installation."; then
    sudo xbps-install -S qemu libvirt virt-manager
    sudo usermod -aG kvm,libvirt $USER
    enable_svc libvirtd
    enable_svc virtlogd
fi

# AI Tools
clear
echo "=============================="
echo "           AI Tools"
echo "=============================="
timeout 2s sleep 2

# Ollama
if yn_default "Do you want to install Ollama? (y/n):" "Installing Ollama..." "Skipping Ollama installation."; then
    curl -fsSL https://ollama.com/install.sh | sh
fi

# OpenCode
if yn_default "Do you want to install OpenCode? (y/n):" "Installing OpenCode..." "Skipping OpenCode installation."; then
    curl -fsSL https://opencode.ai/install | bash
fi

# Oterm
if yn_default "Do you want to install Oterm? (y/n):" "Installing Oterm..." "Skipping Oterm installation."; then
    brew install oterm

    mkdir -p "$(oterm --data-dir 2>/dev/null || echo ~/.local/share/oterm)" && \
    config="$(oterm --data-dir 2>/dev/null || echo ~/.local/share/oterm)/config.json" && \
    if [ -f "$config" ]; then
    tmp=$(mktemp) && jq '. + {"splash-screen": false}' "$config" > "$tmp" && mv "$tmp" "$config"
    else
    echo '{"splash-screen": false}' > "$config"
    fi
fi

# Alpaca
if yn_default "Do you want to install Alpaca? (y/n):" "Installing Alpaca..." "Skipping Alpaca installation."; then
    flatpak install flathub com.jeffser.Alpaca --noninteractive
fi

# Run AI configuration
has_ollama=$(command -v ollama)
has_opencode=$(command -v opencode)

if [ -n "$has_ollama" ] || [ -n "$has_opencode" ]; then
    clear
    echo "Configuring AI tools..."
    ~/voidsetup/ai_confs.sh
fi

# Install Flatpak apps
if yn_default "Do you want to install flatpak apps?" "Installing flatpak apps..." "Skipping installation."; then
    flatpak install flathub \
    com.rtosta.zapzap \
    org.telegram.desktop \
    org.gimp.GIMP \
    com.github.tchx84.Flatseal \
    net.agalwood.Motrix \
    org.localsend.localsend_app \
    org.kde.kate \
    org.kde.kdenlive \
    it.mijorus.gearlever \
    --noninteractive
fi

# Power Management
echo "================================================"
echo "           Power / Battery Utilities"
echo "================================================"
echo "Which power management tool would you like to install?"
echo "1) auto-cpufreq"
echo "2) TLP"
echo "3) Skip Installation"

read -p "Enter choice [1-3]: " choice

case $choice in
    '1')
        echo "Installing auto-cpufreq..."
        update_system
        git clone https://github.com/AdnanHodzic/auto-cpufreq.git || exit 1
        cd auto-cpufreq || exit 1
        sudo ./auto-cpufreq-installer || exit 1
        cd .. && rm -rf auto-cpufreq

        echo "================================================"
        echo "       Power Management Setup Complete.         "
        echo "================================================"
        ;;
    '2')
        echo "Installing TLP..."
        sudo xbps-install -S tlp tlp-rdw || exit 1
        enable_svc tlp

        echo "================================================"
        echo "       Power Management Setup Complete.         "
        echo "================================================"
        ;;
    '3')
        echo "Exiting."
        ;;
    *)
        echo "Invalid option."
        exit 1
        ;;
esac

# NVIDIA drivers
echo "==========================================="
echo "        Nvidia Driver Installation         "
echo "==========================================="
read -p "Install NVIDIA drivers? [y/N]: " install_nvidia

if [ "$install_nvidia" = "y" ] || [ "$install_nvidia" = "Y" ]; then
    echo "Installing NVIDIA drivers..."
    sudo xbps-install -S nvidia
    echo "NVIDIA setup complete. Please reboot."
else
    echo "Skipping NVIDIA driver installation."
fi

# Final Checks
update_system || exit 1

echo "=================================================="
echo "     Setup Complete :> , Please Reboot Your PC    "
echo "=================================================="
