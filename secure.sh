#!/bin/bash

# Ensure sudo access
sudo -v

# Chmod +x all files
chmod +x updater.sh apps.sh powermng.sh ai_confs.sh

# Backup directory & Copy file
sudo cp /etc/hosts "$HOME/voidsetup/hosts.backup"
cp ~/voidsetup/updater.sh ~/.updater.sh

# Enable Non-free and Multilib repos (Required for Brave/NVIDIA/Steam)
sudo xbps-install -u xbps || exit 1
sudo xbps-install -Sy void-repo-nonfree void-repo-multilib || exit 1
sudo xbps-install -Syu || exit 1

# Install base packages & security apps
sudo xbps-install -y base-devel fish-shell curl figlet wget xinput nano libinput xf86-input-libinput evtest clamav fail2ban ufw gufw firejail firejail-profiles apparmor libapparmor libapparmor-devel rkhunter || exit 1

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

# Installing hblock
curl -o /tmp/hblock 'https://raw.githubusercontent.com/hectorm/hblock/v3.5.1/hblock'
echo 'd010cb9e0f3c644e9df3bfb387f42f7dbbffbbd481fb50c32683bbe71f994451  /tmp/hblock' | shasum -c || exit 1
sudo mv /tmp/hblock /usr/local/bin/hblock
sudo chown 0:0 /usr/local/bin/hblock
sudo chmod 755 /usr/local/bin/hblock
hblock

# Install portmaster
curl -fsSL https://updates.safing.io/latest/linux_all/packages/install.sh | sudo bash

# Rkhunter Fix to allow updates
echo "Fixing rkhunter configuration..."
sudo sed -i 's/^MIRRORS_MODE=1/MIRRORS_MODE=0/' /etc/rkhunter.conf
sudo sed -i 's/^UPDATE_MIRRORS=0/UPDATE_MIRRORS=1/' /etc/rkhunter.conf
sudo sed -i 's/^WEB_CMD="\/bin\/false"/WEB_CMD=""/' /etc/rkhunter.conf

# Rkhunter Config
sudo rkhunter --propupd
sudo rkhunter --update
sudo rkhunter --config-check

# UFW Configuration
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable

# Apparmor Config
PARAMS="apparmor=1 security=apparmor lsm=landlock,lockdown,yama,integrity,apparmor,bpf"

echo "-- Installing packages --"
sudo xbps-install -S --noconfirm --needed apparmor libapparmor libapparmor-devel

add_params_once() {
    local file="$1"
    local key="$2"

    if grep -q "apparmor=1" "$file"; then
        echo "AppArmor already configured in $file"
        return
    fi

    echo "➜ Backing up $file"
    sudo cp "$file" "$file.bak.$(date +%s)"

    echo "➜ Adding kernel parameters to $file"
    sudo sed -i "s|^$key=\"|$key=\"$PARAMS |" "$file"
}

# Add the lines
add_params_once /etc/default/grub GRUB_CMDLINE_LINUX_DEFAULT

echo "➜ Regenerating grub config"
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Enable AppArmor caching
sudo install -Dm644 /dev/null /etc/apparmor/parser.conf
echo "write-cache" | sudo tee -a /etc/apparmor/parser.conf >/dev/null
echo "Optimize=compress-fast" | sudo tee -a /etc/apparmor/parser.conf >/dev/null
echo "cache-loc=/var/cache/apparmor" | sudo tee -a /etc/apparmor/parser.conf >/dev/null

clear
echo "=================================================="
echo "        AppArmor, Firejail Config Success         "
echo "      Reboot is REQUIRED for kernel params."
echo "=================================================="

echo "AppArmor status:"
sudo aa-status || echo "AppArmor not loaded (normal before reboot)"

# Firejail Configuration
clear
echo "================================================="
echo "           Setup & Config Firejail?"
echo "================================================="
echo "Do you want to install & config Firejail? (Recommended) WARNING will make system more secure but a bit harder to use (Still works though)"
echo "1) Yes, Setup Firejail"
echo "2) No, Don't Setup Firejail"

# Use ANSI escape codes for colored prompt
read -p $'\e[32mEnter choice [1-2]: \e[0m' choice

case $choice in
    '1')
        # Install necessary packages
        sudo xbps-install -Syu
        sudo xbps-install -Sy firejail

        # Make folders
        sudo mkdir -p /etc/firejail/firecfg.d
        mkdir -p "$HOME/.config/firejail"
        mkdir -p "$HOME/Allowed"
        mkdir -p "$HOME/Allowed/AllowedCodes"
        mkdir -p "$HOME/Allowed/AllowedDocs"
        mkdir -p "$HOME/Allowed/AllowedDownloads"
        mkdir -p "$HOME/Allowed/AllowedPics"
        mkdir -p "$HOME/.local/share/applications"

        # Copy configuration files
        cp ~/voidsetup/firejail-configs/helium.profile ~/.config/firejail/helium.profile
        cp ~/voidsetup/firejail-configs/brave.local ~/.config/firejail/brave.local
        cp ~/voidsetup/firejail-configs/firefox.local ~/.config/firejail/firefox.local
        cp ~/voidsetup/firejail-configs/librewolf.local ~/.config/firejail/librewolf.local
        cp ~/voidsetup/firejail-configs/codium.local ~/.config/firejail/codium.local
        cp ~/voidsetup/firejail-configs/code.local ~/.config/firejail/code.local

        echo "==========================================="
        echo "          Firejail Config Success          "
        echo "==========================================="

        # Do firecfg
        sudo firecfg
        ;;

    '2')
        clear
        echo "=================================================="
        echo "          Skipping Firejail Installation.         "
        echo "=================================================="
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Fail2ban Configuration
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
filter = sshd[mode=aggressive]

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

# Enabling Services (Runit)
sudo ln -s /etc/sv/clamav-freshclam /var/service/ || exit 1
sudo ln -s /etc/sv/fail2ban /var/service/ || exit 1
sudo ln -s /etc/sv/ufw /var/service || exit 1
sudo ln -s /etc/sv/apparmor /var/service || exit 1

# Portmaster
sudo mkdir -p /usr/local/sv/portmaster
cat << 'EOF' | sudo tee /usr/local/sv/portmaster/run
#!/bin/sh
exec /opt/safing/portmaster/portmaster-start core --data=/opt/safing/portmaster/
EOF

sudo chmod +x /usr/local/sv/portmaster/run
sudo ln -s /usr/local/sv/portmaster /etc/runit/runsvdir/default/
sudo sv up portmaster

# Git Setup
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

# Homebrew install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || exit 1

# Update ClamAV
sudo sv stop clamav-freshclam || exit 1
sudo freshclam || exit 1
sudo rkhunter --check --sk
sudo sv start clamav-freshclam || exit 1

# Desktop Enviroment
install_cinnamon() {
    # Update system
    sudo xbps-install -Su

    # Install Cinnamon and essential services
    sudo xbps-install -y dbus xorg cinnamon lightdm

    # Enable D-Bus and LightDM
    sudo ln -s /etc/sv/dbus /var/service/
    sudo ln -s /etc/sv/lightdm /var/service/

    # Remove XFCE and orphaned dependencies
    sudo xbps-remove -R xfce4
    sudo xbps-remove -Oo

    echo "Installation complete. Reboot to start using Cinnamon."
}


# Set Desktop Enviroment
clear
echo "======================================="
echo "         Set Desktop Enviroment"
echo "======================================="
echo "1) Keep Xfce"
echo "2) Use Cinnamon"
echo "3) Skip"

read -p $'\e[32mEnter choice [1-3]: \e[0m' choice

case $choice in
    '1')
        echo "Keeping Xfce.."
        timeout 1s sleep 1
        ;;

    '2')
        # Installing Cinnamon
        install_cinnamon
        timeout 1s sleep 1
        ;;

    '3')
        clear
        echo "================================"
        echo "          Skipping.....         "
        echo "================================"
        ;;
    *)
        echo "Invalid choice."
        ;;
esac

echo "======================================="
echo "       Security Setup Complete.        "
echo "======================================="
