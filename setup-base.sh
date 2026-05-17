#!/usr/bin/env bash
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

# Chmod +x all files
chmod +x updater.sh removeconf.sh setup-desktop.sh ai_confs.sh

# Backup hosts & Copy file
sudo cp /etc/hosts "$HOME/voidsetup/hosts.backup"
cp ~/voidsetup/updater.sh ~/.updater.sh || exit 1

# ===============
#     System
# ===============

# Enable Non-free and Multilib repos (Required for Brave/NVIDIA/Steam)
sudo xbps-install -u xbps || exit 1
sudo xbps-install -Sy void-repo-nonfree void-repo-multilib || exit 1
update_system

# Install base packages & security apps
sudo xbps-install -y base-devel fish-shell figlet wget curl jq xinput nano libinput xf86-input-libinput evtest clamav fail2ban ufw gufw firejail apparmor libapparmor rkhunter git || exit 1

# Fix touchpad not working
sudo mkdir -p /etc/X11/xorg.conf.d || exit 1

if [ ! -f /etc/X11/xorg.conf.d/30-touchpad.conf ]; then
sudo tee /etc/X11/xorg.conf.d/30-touchpad.conf > /dev/null << 'EOF'
Section "InputClass"
    Identifier "touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"
    Option "Tapping" "on"
    Option "NaturalScrolling" "on"
    Option "ClickMethod" "clickfinger"
EndSection
EOF
fi

# ===============
#    Security
# ===============

# Hblock
if yn_default "Do you want to install Hblock? (y/n):" "Installing Hblock..." "Skipping Installation."; then
    curl -o /tmp/hblock 'https://raw.githubusercontent.com/hectorm/hblock/v3.5.1/hblock'
    echo 'd010cb9e0f3c644e9df3bfb387f42f7dbbffbbd481fb50c32683bbe71f994451  /tmp/hblock' | shasum -c
    sudo mv /tmp/hblock /usr/local/bin/hblock
    sudo chown 0:0 /usr/local/bin/hblock
    sudo chmod 755 /usr/local/bin/hblock
    hblock
fi

# Download Portmaster
if yn_default "Do you want to install Portmaster? (y/n): " "Installing Portmaster..." "Skipping Installation"; then
    curl -fsSL https://updates.safing.io/latest/linux_all/packages/install.sh | sudo bash
fi

# Firejail Configuration
if yn_default "Install & Configure Firejail?" "Installing Firejail..." "Skipping Firejail."; then
    firejail_install
fi

# Rkhunter
if yn_default "Install & Configure Rkhunter?"; then
    sudo xbps-install -S rkhunter
    if command -v rkhunter &>/dev/null; then
        echo "Fixing rkhunter configuration..."
        sudo sed -i 's/^MIRRORS_MODE=1/MIRRORS_MODE=0/' /etc/rkhunter.conf
        sudo sed -i 's/^UPDATE_MIRRORS=0/UPDATE_MIRRORS=1/' /etc/rkhunter.conf
        sudo sed -i 's/^WEB_CMD="\/bin\/false"/WEB_CMD=""/' /etc/rkhunter.conf

        sudo rkhunter --propupd || true
        sudo rkhunter --update || true
        sudo rkhunter --config-check || true
    fi
fi

# Fail2ban
if yn_default "Install & Configure Fail2ban?" "Installing Fail2ban..." "Skipping Fail2ban."; then
    sudo xbps-install -S fail2ban

    if ! sudo test -f /etc/fail2ban/jail.local; then
        sudo bash -c "cat << 'EOF' > /etc/fail2ban/jail.local
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
backend = auto

[recidive]
enabled = true
logpath = /var/log/fail2ban.log
bantime = 604800
findtime = 86400
maxretry = 2
EOF"

        sudo sv reload fail2ban && \
        echo "Fail2Ban configuration applied." || \
        echo "Reload failed."
    else
        echo "jail.local already exists. No changes made."
    fi
fi

# Clamav
if yn_default "Install & Configure ClamAV?"; then
    sudo xbps-install -S clamav
    enable_svc clamav-freshclam
fi

# UFW
if yn_default "Install & Configure UFW?"; then
    sudo xbps-install -S ufw
    sudo ufw default deny incoming || exit 1
    sudo ufw default allow outgoing || exit 1
    sudo ufw enable || exit 1
    enable_svc ufw
fi

# ===============
#   Development
# ===============

# Git Setup
if yn_default "Configure Git?"; then
    echo "Setting up Git..."
    read -p "Enter your name: " git_name
    read -p "Enter your email: " git_email

    git config --global user.name "$git_name" || exit 1
    git config --global user.email "$git_email" || exit 1

    echo "Git configured with name: $git_name and email: $git_email"

    # Generate SSH key for GitHub
    if [ ! -f "$HOME/.ssh/id_ed25519.pub" ]; then
        mkdir -p "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "$git_email" -N "" -f "$HOME/.ssh/id_ed25519"
        echo "SSH key generated. Add this to GitHub -> Settings -> SSH keys:"
        cat "$HOME/.ssh/id_ed25519.pub"
    else
        echo "SSH key already exists at ~/.ssh/id_ed25519.pub"
    fi
fi

# Homebrew
if yn_default "Do you want to install Homebrew? (y/n):" "Installing Homebrew..." "Skipping installation."; then
    # Install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || exit 1

    # Load Homebrew for current session
    if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

fi

# Installing LazyVim
if yn_default "Do you want to install Neovim? & configure LazyVim?" "Starting installation & configuration of Neovim..." "Skipping installation & configuration"; then

    # Homebrew apps
    brew install neovim || {
    echo "Warning neovim installation failed. is homebrew installed?"
    exit 1
    }

    # Files & Folders
    mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true
    mv ~/.local/share/nvim ~/.local/share/nvim.bak 2>/dev/null || true
    mv ~/.local/state/nvim ~/.local/state/nvim.bak 2>/dev/null || true
    mv ~/.cache/nvim ~/.cache/nvim.bak 2>/dev/null || true

    # Clone LazyVim starter
    echo "Cloning LazyVim starter..."
    git clone https://github.com/LazyVim/starter ~/.config/nvim

    # Remove git history
    rm -rf ~/.config/nvim/.git

    # Enable system clipboard
    mkdir -p ~/.config/nvim/lua/config
    grep -q "clipboard.*unnamedplus" ~/.config/nvim/lua/config/options.lua 2>/dev/null || echo 'vim.opt.clipboard = "unnamedplus"' >> ~/.config/nvim/lua/config/options.lua

    # Neovim Config
    nvim
fi

# Enabling service (Runit)
if command -v apparmor_status &>/dev/null; then
   enable_svc apparmor || exit 1
fi

# Fail2ban
if command -v fail2ban-client &>/dev/null; then
    enable_svc fail2ban || exit 1
fi

# Clamav & Rkhunter
if command -v clamscan &>/dev/null; then
    sudo sv stop clamav-freshclam || exit 1
    sudo freshclam || exit 1
    sudo sv start clamav-freshclam || exit 1
fi

if command -v rkhunter &>/dev/null; then
    sudo rkhunter --update || exit 1
fi

# ================
#   Shell Config
# ================

# Shell Configuration
configure_shells() {
    clear
    echo "================================================="
    echo "           Setup & Configure Shells"
    echo "================================================="
    echo "Setup & Configure Shells"
    echo "1) Bash (ble.sh, bash-completion, atuin)"
    echo "2) Zsh (Oh My Zsh, autosuggestions, syntax-highlighting)"
    echo "3) Fish (Config, aliases)"
    echo "4) All of the above"
    echo "5) Skip"
    read -p $'\e[32mEnter choice [1-5]: \e[0m' shell_choice
    case $shell_choice in
        '1') configure_bash ;;
        '2') configure_zsh ;;
        '3') configure_fish ;;
        '4') configure_bash; configure_zsh; configure_fish ;;
        '5') echo "Skipping Shell Configuration." ;;
        *) echo "Invalid choice."; exit 1 ;;
    esac

    # Set default shell
    clear
    echo "======================================="
    echo "           Set Default Shell"
    echo "======================================="
    echo "1) Keep Bash"
    echo "2) Fish"
    echo "3) Zsh"
    echo "4) Skip"
    read -p $'\e[32mEnter choice [1-4]: \e[0m' choice
    case $choice in
        '1') sudo chsh -s /bin/bash ;;
        '2') sudo chsh -s "$(which fish)" "$USER" ;;
        '3') sudo chsh -s "$(which zsh)" "$USER" ;;
        '4') echo "Skipping..." ;;
        *) echo "Invalid choice." ;;
    esac
}

configure_shells

clear
echo "========================================"
echo "       Security Setup Complete.         "
echo "========================================"
