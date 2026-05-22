#!/usr/bin/env bash
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

# NVIDIA check
clear
header "Nvidia / GPU Drivers Check"

if yn "Did you install the Nvidia drivers already?"; then
    info "Proceeding..."
else
    if yn "Install Nvidia Drivers?" Y; then
        info "Installing NVIDIA drivers..."
        if sudo xbps-install -S nvidia; then
            ok "NVIDIA setup complete. Please reboot."
            exit 0
        else
            err "Failed to install NVIDIA drivers."
            exit 1
        fi
    else
        info "NVIDIA driver installation skipped."
        exit 0
    fi
fi

# Update system
update_system; ok "System updated" || exit 1

# ===============
#      Apps
# ===============

# Install base apps
sudo xbps-install -Sy vulkan-loader os-prober python3-tkinter python3-pip exfatprogs mesa-utils gnupg cava timeshift nix \
    noto-fonts-ttf dejavu-fonts-ttf nerd-fonts bridge-utils xf86-input-libinput xclip tmux unzip || exit 1

# Nix
if yn "Do you want to install NixPkg Manager?" Y; then
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
if yn "Do you want to install Homebrew Apps?" Y; then

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

clear
header "Additional Browsers"

# Helium Browser
if yn "Do you want to install Helium?" Y; then
    flatpak install flathub it.mijorus.gearlever --noninteractive
    curl -fL https://github.com/imputnet/helium-linux/releases/download/0.8.5.1/helium-0.8.5.1-x86_64.AppImage -o Helium.AppImage
    flatpak run it.mijorus.gearlever "$SCRIPT_DIR"/Helium.AppImage
fi

# Brave Browser
if yn "Do you want to install Brave Browser?" Y; then
    sudo xbps-install -S brave
fi

# Librewolf
if yn "Do you want to install Librewolf?" Y; then
    flatpak install flathub io.gitlab.librewolf-community --noninteractive
fi

# Mullvad Browser
if yn "Do you want to install Mullvad Browser?" Y; then
    flatpak install flathub net.mullvad.MullvadBrowser --noninteractive
fi

# Floorp Browser
if yn "Do you want to install Floorp?" Y; then
    flatpak install flathub one.ablaze.floorp --noninteractive
fi

# Zen Browser
if yn "Do you want to install Zen Browser?" Y; then
    flatpak install flathub app.zen_browser.zen --noninteractive
fi

clear
header "Additional Tools & Games"

# Install Additional
if yn_second "Do you want to install Additional tools? (Might not be needed for desktop usage)" Y; then
    sudo xbps-install -S torbrowser-launcher
    flatpak install flathub com.protonvpn.www --noninteractive
fi

# Game Dev
if yn "Do you want to install GameDev Apps?" Y; then
    mkdir -p "$HOME/Applications"

    info "Installing Godot..."
    curl -fL \
        https://github.com/godotengine/godot/releases/download/4.6.2-stable/Godot_v4.6.2-stable_linux.x86_64.zip \
        -o "$HOME/Applications/Godot_v4.6.2-stable_linux.x86_64.zip" || exit 1

    unzip -o "$HOME/Applications/Godot_v4.6.2-stable_linux.x86_64.zip" -d "$HOME/Applications"

    info "Instal LDtk Manually"

    # LibreSprite
    info "Downloading LibreSprite..."
    flatpak install flathub com.github.libresprite.LibreSprite --noninteractive

    trash-put "$HOME/Applications/Godot_v4.6.2-stable_linux.x86_64.zip"
fi

# Games
if yn "Do you want to install Games aswell?" Y; then
    flatpak install flathub org.luanti.luanti info.beyondallreason.bar org.openttd.OpenTTD net.openra.OpenRA net.wz2100.wz2100 --noninteractive
fi

# Code
if yn "Do you want to install VSCode" Y; then
    flatpak install flathub com.visualstudio.code --noninteractive
fi

# Codium
if yn "Do you want to install VSCodium" Y; then
    flatpak install flathub com.vscodium.codium --noninteractive
fi

# Logseq
if yn "Do you want to install Logseq" Y; then
    flatpak install flathub com.logseq.Logseq --noninteractive
fi

# Educational Apps
if yn "Do you want to Educational Apps?" Y; then
    edu_apps
fi

# VirtManager
if yn "Do you want to install VirtManager?" Y; then
    sudo xbps-install -S qemu libvirt virt-manager
    sudo usermod -aG kvm,libvirt $USER
    enable_svc libvirtd
    enable_svc virtlogd
fi

# AI Tools
clear
header "AI Tools"

# Ollama
if yn "Do you want to install Ollama?" Y; then
    curl -fsSL https://ollama.com/install.sh | sh
fi

# OpenCode
if yn "Do you want to install OpenCode?" Y; then
    curl -fsSL https://opencode.ai/install | bash
fi

# Oterm
if yn "Do you want to install Oterm?" Y; then
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
if yn "Do you want to install Alpaca?" Y; then
    flatpak install flathub com.jeffser.Alpaca --noninteractive
fi

# Run AI configuration
has_ollama=$(command -v ollama)
has_opencode=$(command -v opencode)

if [ -n "$has_ollama" ] || [ -n "$has_opencode" ]; then
    clear
    info "Configuring AI tools..."
    "$SCRIPT_DIR"/ai_confs.sh
fi

# Install Flatpak apps
if yn "Do you want to install flatpak apps?" Y; then
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
header "Power Management"
echo "Which power management tool would you like to install?"
echo "1) auto-cpufreq"
echo "2) TLP"
echo "3) Skip Installation"

case $(pick "Choice [1-3]:" 1 3) in
    '1')
        info "Installing auto-cpufreq..."
        update_system
        git clone https://github.com/AdnanHodzic/auto-cpufreq.git || exit 1
        cd auto-cpufreq || exit 1
        sudo ./auto-cpufreq-installer || exit 1
        cd .. && rm -rf auto-cpufreq

        header "Power Management Setup Complete"
        ;;
    '2')
        info "Installing TLP..."
        sudo xbps-install -S tlp tlp-rdw || exit 1
        enable_svc tlp

        header "Power Management Setup Complete"
        ;;
    '3')
        info "Skipping..."
        ;;
    *)
        err "Invalid option."
        ;;
esac

# Final Checks
update_system; ok "Final system update complete" || exit 1

clear
header "Setup Complete. Please Reboot Your PC"
