#!/usr/bin/env bash

echo "================================================"
echo "           Power / Battery Utilities            "
echo "================================================"
echo "Which power management tool would you like to install?"
echo "1) Auto-Cpufreq"
echo "2) TLP"
echo "3) Exit"

read -p "Enter choice [1-3]: " choice

case $choice in
    1)
        echo "Installing auto-cpufreq..."
        sudo xbps-install -Syu || exit 1
        git clone https://github.com/AdnanHodzic/auto-cpufreq.git || exit 1
        cd auto-cpufreq; sudo ./auto-cpufreq-installer || exit 1
        ;;
    2)
        echo "Installing TLP..."
        sudo xbps-install -S tlp tlp-rdw || exit 1
        sudo ln -s /etc/sv/tlp /var/service/ || exit 1
        ;;
    3)
        echo "Exiting."
        exit 0
        ;;
    *)
        echo "Invalid option."
        exit 1
        ;;
esac

# Nvidia drivers
echo "==========================================="
echo "        Nvidia Driver Installation         "
echo "==========================================="
read -p "Install NVIDIA drivers? [y/N]: " install_nvidia

if [ "$install_nvidia" = "y" ] || [ "$install_nvidia" = "Y" ]; then
    echo "Installing NVIDIA drivers..."

    # Installing Nvidia drivers
    sudo xbps-install -y nvidia

    echo "NVIDIA setup complete. Please reboot."
else
    echo "Skipping NVIDIA driver installation."
fi

echo "================================================"
echo "        Power Management Setup Complete.        "
echo "================================================"
