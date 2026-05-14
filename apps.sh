#!/usr/bin/env bash

# Checking
clear
echo "Did you installed the nvidia drivers already or are you using other gpus not needing any drivers? (y/n):"

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
sudo xbps-install -Syu

# Install Cliapps
sudo xbps-install -Sy vulkan-loader os-prober python3-tkinter python3-pip exfatprogs \
mesa-utils gnupg cava timeshift nix noto-fonts-ttf dejavu-fonts-ttf nerd-fonts bridge-utils xf86-input-libinput xclip

# Configure Nix
sudo ln -s /etc/sv/nix-daemon /var/service
nix_config="/etc/nix/nix.conf"
feature_line="experimental-features = nix-command flakes"
if [ -f "$nix_config" ] && ! grep -q "$feature_line" "$nix_config" 2>/dev/null; then
    echo "$feature_line" | sudo tee -a "$nix_config" >/dev/null
fi
source /etc/profile

# Install Atuin
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh || exit 1

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || exit 1

# Load Homebrew for current session
if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Install Homebrew apps
if command -v brew &>/dev/null; then
    brew install neovim fzf ranger btop thefuck trash-cli ffmpeg fastfetch
fi

# Install Flatpak if not present
sudo xbps-install -y flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Flatpak apps
flatpak install flathub com.rtosta.zapzap \
    org.gimp.GIMP com.github.tchx84.Flatseal \
    net.agalwood.Motrix com.logseq.Logseq  \
    org.kde.kdenlive it.mijorus.gearlever \
    org.localsend.localsend_app org.kde.kate -y

# Install Additional Browsers
clear
echo "=========================================="
echo "           Additional Browsers"
echo "=========================================="
timeout 2 sleep 2

# Helium Browser
clear
echo "Do you want to install Helium? (y/n):"

while true; do
    read -t 5 -p "Answer [y/n]: " reply
    if [ -z "$reply" ]; then
        reply="Y"
    fi
    case $reply in
        Y|y)
            echo "Installing browser..."

            # Download Helium Browser
            curl -fL https://github.com/imputnet/helium-linux/releases/download/0.8.5.1/helium-0.8.5.1-x86_64.AppImage -o Helium.AppImage

            flatpak run it.mijorus.gearlever ~/voidsetup/Helium.AppImage

            break
            ;;
        N|n)
            echo "Skipping browser installation."
            break
            ;;
        *)
            echo "Please enter 'y' or 'n'."
            ;;
    esac
done

clear
echo "============================================="
echo "           Additional Tools & Games          "
echo "============================================="
timeout 2 sleep 2

# Game Dev
clear
echo "Do you want to install GameDev Apps? (y/n):"
while true; do
    read -t 5 -p "Answer [y/n]: " reply
    if [ -z "$reply" ]; then
        reply="Y"
    fi
    case $reply in
        Y|y)
            echo "Installing Godot..."
                curl -fL \
                    https://godot-releases.nbg1.your-objectstorage.com/4.6.2-stable/Godot_v4.6.2-stable_linux.x86_64.zip \
                    -o Godot_v4.6.2-stable_linux.x86_64.zip || exit 1

                unzip Godot_v4.6.2-stable_linux.x86_64.zip
            echo "Installing LDtk..."
                curl -fL \
                    https://itchio-mirror.cb031a832f44726753d6267436f3b414.r2.cloudflarestorage.com/upload2/game/740403/9503070?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=3edfcce40115d057d0b5606758e7e9ee%2F20260505%2Fauto%2Fs3%2Faws4_request&X-Amz-Date=20260505T142657Z&X-Amz-Expires=60&X-Amz-SignedHeaders=host&X-Amz-Signature=75fafce31d8729e512db446c0c5f9f16a8590dec129accad7ef14a5da1785195 \
                    -o LDtk.zip || exit 1

                unzip LDtk.zip
                flatpak install flathub it.mijorus.gearlever  --noninteractive
                flatpak run it.mijorus.gearlever ~/voidsetup/LDtk*.AppImage

            echo "Installing Libresprite..."
                curl -fL \
                    https://release-assets.githubusercontent.com/github-production-release-asset/67058735/604a01b8-e17f-40b3-840b-acef790e90c2?sp=r&sv=2018-11-09&sr=b&spr=https&se=2026-05-05T15%3A18%3A26Z&rscd=attachment%3B+filename%3Dlibresprite-development-linux-x86_64.zip&rsct=application%2Foctet-stream&skoid=96c2d410-5711-43a1-aedd-ab1947aa7ab0&sktid=398a6654-997b-47e9-b12b-9515b896b4de&skt=2026-05-05T14%3A17%3A56Z&ske=2026-05-05T15%3A18%3A26Z&sks=b&skv=2018-11-09&sig=t9zwdbb2OzeKYoVfmi3V07%2BKuOcR74AcesAQ%2Fo7w2pU%3D&jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmVsZWFzZS1hc3NldHMuZ2l0aHVidXNlcmNvbnRlbnQuY29tIiwia2V5Ijoia2V5MSIsImV4cCI6MTc3Nzk5MjYyMywibmJmIjoxNzc3OTkwODIzLCJwYXRoIjoicmVsZWFzZWFzc2V0cHJvZHVjdGlvbi5ibG9iLmNvcmUud2luZG93cy5uZXQifQ.aGc4EYg0yAUJRGKq0PaAOFk8VRCVu9-BswcFaKz35Zg&response-content-disposition=attachment%3B%20filename%3Dlibresprite-development-linux-x86_64.zip&response-content-type=application%2Foctet-stream \
                    -o libresprite.zip || exit 1

            unzip libresprite.zip
            flatpak run it.mijorus.gearlever ~/voidsetup/LibreSprite*.AppImage

            trash-put Godot_v4.6.2-stable_linux.x86_64.zip
            trash-put LDtk.zip
            trash-put libresprite.zip
            break
            ;;
        N|n)
            echo "Skipping GameDev Apps installation."
            break
            ;;
        '')
            echo "Please enter 'y' or 'n'."
            ;;
    esac
done

# Games
clear
echo "Do you want to install Games aswell? (y/n):"
while true; do
    read -t 5 -p "Answer [y/n]: " reply
    if [ -z "$reply" ]; then
        reply="Y"
    fi
    case $reply in
        Y|y)
            echo "Installing Games..."
            flatpak install flathub org.luanti.luanti info.beyondallreason.bar org.openttd.OpenTTD net.openra.OpenRA net.wz2100.wz2100
            break
            ;;
        N|n)
            echo "Skipping installation of games."
            break
            ;;
        '')
            echo "Please enter 'y' or 'n'."
            ;;
    esac
done

# VirtManager
clear
echo "Do you want to install VirtManager? (y/n):"
while true; do
    read -t 5 -p "Answer [y/n]: " reply
    if [ -z "$reply" ]; then
        reply="Y"
    fi
    case $reply in
        Y|y)
            echo "Installing VirtManager..."
                sudo xbps-install -Sy qemu libvirt virt-manager

                # Configure KVM/Libvirt & Enabling services via runit
                sudo usermod -aG kvm,libvirt $USER
                sudo ln -s /etc/sv/libvirtd /var/service/
                sudo ln -s /etc/sv/virtlogd /var/service/

            break
            ;;
        N|n)
            echo "Skipping VirtManager installation."
            break
            ;;
        '')
            echo "Please enter 'y' or 'n'."
            ;;
    esac
done

# AI Tools
clear
echo "=========================================="
echo "                AI Tools"
echo "=========================================="
timeout 2 sleep 2

# Ollama
clear
echo "Do you want to install Ollama? (y/n):"
while true; do
    read -t 5 -p "Answer [y/n]: " reply
    if [ -z "$reply" ]; then
        reply="Y"
    fi
    case $reply in
        Y|y)
            echo "Installing Ollama..."
            curl -fsSL https://ollama.com/install.sh | sh
            break
            ;;
        N|n)
            echo "Skipping Ollama installation."
            break
            ;;
        '')
            echo "Please enter 'y' or 'n'."
            ;;
    esac
done

# Oterm
clear
echo "Do you want to install Oterm? (y/n):"
while true; do
    read -t 5 -p "Answer [y/n]: " reply
    if [ -z "$reply" ]; then
        reply="Y"
    fi
    case $reply in
        Y|y)
            echo "Installing Oterm..."
            brew install oterm

            mkdir -p "$(oterm --data-dir 2>/dev/null || echo ~/.local/share/oterm)" && \
            config="$(oterm --data-dir 2>/dev/null || echo ~/.local/share/oterm)/config.json" && \
            if [ -f "$config" ]; then
            tmp=$(mktemp) && jq '. + {"splash-screen": false}' "$config" > "$tmp" && mv "$tmp" "$config"
            else
            echo '{"splash-screen": false}' > "$config"
            fi

            break
            ;;
        N|n)
            echo "Skipping Oterm installation."
            break
            ;;
        *)
            echo "Please enter 'y' or 'n'."
            ;;
    esac
done

# OpenCode
clear
echo "Do you want to install OpenCode? (y/n):"
while true; do
    read -t 5 -p "Answer [y/n]: " reply
    if [ -z "$reply" ]; then
        reply="Y"
    fi
    case $reply in
        Y|y)
            echo "Installing OpenCode..."
            curl -fsSL https://opencode.ai/install | bash
            break
            ;;
        N|n)
            echo "Skipping OpenCode installation."
            break
            ;;
        '')
            echo "Please enter 'y' or 'n'."
            ;;
    esac
done

# Alpaca
clear
echo "Do you want to install Alpaca? (y/n):"
while true; do
    read -t 5 -p "Answer [y/n]: " reply
    if [ -z "$reply" ]; then
        reply="Y"
    fi
    case $reply in
        Y|y)
            echo "Installing Alpaca..."
            flatpak install flathub com.jeffser.Alpaca --noninteractive
            break
            ;;
        N|n)
            echo "Skipping Alpaca installation."
            break
            ;;
        '')
            echo "Please enter 'y' or 'n'."
            ;;
    esac
done

# Run ai_confs.sh if Ollama or OpenCode were installed
has_ollama=$(command -v ollama)
has_opencode=$(command -v opencode)

if [ -n "$has_ollama" ] || [ -n "$has_opencode" ]; then
    clear
    echo "Configuring AI tools..."
    ~/voidsetup/ai_confs.sh
fi

clear
echo "Do you want to install VSCode (y/n):"
while true; do
    read -t 5 -p "Answer [y/n]: " reply
    if [ -z "$reply" ]; then
        reply="Y"
    fi
    case $reply in
        Y|y)
            echo "Installing VSCode..."
            flatpak install flathub com.visualstudio.code
            break
            ;;
        N|n)
            echo "Skipping VSCode installation."
            break
            ;;
        '')
            echo "Please enter 'y' or 'n'."
            ;;
    esac
done


# Codium
clear
echo "Do you want to install VSCodium (y/n):"
while true; do
    reply=""
    read -t 5 -p "Answer [y/n]: " reply
    if [ -z "$reply" ]; then
        reply="Y"
    fi
    case $reply in
        Y|y)
            echo "Installing VSCodium..."
            flatpak install flathub com.vscodium.codium
            break
            ;;
        N|n)
            echo "Skipping VSCodium installation."
            break
            ;;
        *)
            echo "Please enter 'y' or 'n'."
            ;;
    esac
done

clear
echo "======================"
echo "     80% Complete     "
echo "======================"
timeout 1 sleep 1

# Reload Shell
source "$HOME/.bashrc" 2>/dev/null || true

# Installing LazyVim
clear
echo "============================"
echo "     Installing LazyVim     "
echo "============================"

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

# Run Neovim
nvim

# Shell Configuration
configure_shells() {
    clear
    echo "================================================="
    echo "           Setup & Configure Shells"
    echo "================================================="
    echo "Which shell(s) would you like to configure?"
    echo "1) Bash (ble.sh, bash-completion, atuin, homebrew, nix)"
    echo "2) Zsh (Oh My Zsh, autosuggestions, syntax-highlighting)"
    echo "3) Fish (Config, aliases)"
    echo "4) All of the above"
    echo "5) Skip"

    read -p $'\e[32mEnter choice [1-5]: \e[0m' shell_choice

    configure_bash() {
        clear
        echo "================================================="
        echo "               Configuring Bash"
        echo "================================================="

        # bash-completion
        echo "Installing bash-completion..."
        sudo xbps-install -Sy bash-completion

        # Install Atuin
        curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh || exit 1

        # ble.sh
        clear
        echo "Do you want to install ble.sh? (y/n):"
        while true; do
            read -t 5 -rp "Answer [y/n]: " reply
            reply=${reply:-Y}
            case $reply in
                [Yy])
                    echo "How would you like to install ble.sh?"
                    echo "1) Git"
                    echo "2) Nix"
                    read -p $'\e[32mEnter choice [1-2]: \e[0m' ble_choice
                    case $ble_choice in
                        '1')
                            git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh
                            make -C /tmp/ble.sh install PREFIX="$HOME/.local"
                                grep -q "blesh/ble.sh" "$HOME/.bashrc" 2>/dev/null || cat >> "$HOME/.bashrc" << 'EOF'

# ble.sh
[ -f "$HOME/.local/share/blesh/ble.sh" ] && source "$HOME/.local/share/blesh/ble.sh"
EOF
                            ;;
                        '2')
                            nix profile install nixpkgs#ble-sh
                                grep -q "blesh/ble.sh" "$HOME/.bashrc" 2>/dev/null || cat >> "$HOME/.bashrc" << 'EOF'

# ble.sh
[ -f "$HOME/.local/share/blesh/ble.sh" ] && source "$HOME/.local/share/blesh/ble.sh"
EOF

cat > ~/.blerc << 'EOF'
# Performance tweaks
bleopt highlight_syntax=off
bleopt highlight_filename=off
bleopt complete_auto_delay=100
EOF
                            ;;
                        *)
                            echo "Invalid choice. Skipping ble.sh."
                            ;;
                    esac
                    break
                    ;;
                [Nn])
                    echo "Skipping ble.sh installation."
                    break
                    ;;
                *)
                    echo "Please answer y or n."
                    ;;
            esac
        done

grep -q "=== apps.sh managed block" "$HOME/.bashrc" 2>/dev/null || cat >> "$HOME/.bashrc" << 'BASHEOF'
# === apps.sh managed block - do not edit manually ===
eval "$(atuin init bash)"

[ -f "$HOME/.local/share/blesh/ble.sh" ] && source "$HOME/.local/share/blesh/ble.sh"

alias lsa="ls -a"
alias update="~/.updater.sh"
alias scan="clamscan -r"
alias trm="trash-put"
alias trestore="trash-restore"
alias tbin="trash-empty"
alias listt="trash-list"
alias copy="wl-copy <"
alias paste="wl-paste >"
alias rkscan="sudo rkhunter --check --sk"
alias kate="flatpak run org.kde.kate"

# Extra functions
function gitpush_installscript() {
    cd ~/Projects/Scripts/linuxmintsetup && git add . && git commit -m "New changes" && git push -u origin main
    cd ~/Projects/Scripts/fedorasetup && git add . && git commit -m "New changes" && git push -u origin main
    cd ~/Projects/Scripts/voidsetup && git add . && git commit -m "New changes" && git push -u origin main
    cd ~/Projects/Scripts/cachysetup && git add . && git commit -m "New changes" && git push -u origin main
}

# Add your other functions here

blesh_optimize() {
    local blesh_dir="${XDG_DATA_HOME:-$HOME/.local/share}/blesh"
    local blerc="${XDG_CONFIG_HOME:-$HOME/.config}/blesh/init.sh"

    if [[ ! -f "$blesh_dir/ble.sh" ]]; then
        echo "Installing ble.sh..."
        git clone --recursive --depth 1 --shallow-submodules "https://github.com/akinomyoga/ble.sh.git" "$blesh_dir"
        make -C "$blesh_dir" install PREFIX="${XDG_DATA_HOME:-$HOME}/.local" strip_comment=yes
        mkdir -p "$(dirname "$blerc")"
    fi

    cat > "$blerc" << 'EOF'
# Performance-optimized ble.sh settings
bleopt complete_auto_delay=200
bleopt highlight_syntax=
bleopt complete_auto_history=

# History limits to reduce overhead
HISTSIZE=5000
HISTFILESIZE=10000
shopt -s histappend

# Visual bell
bleopt edit_bell=vbell
EOF

    if [[ $- == *i* ]] && [[ ! ${BLE_VERSION:-} ]]; then
        source "$blesh_dir/ble.sh" --attach=auto
        echo "ble.sh installed and optimized! Restart shell or run 'ble-attach'."
    fi
}

# Homebrew
if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Thefuck
if command -v thefuck &>/dev/null; then
    eval "$(thefuck --alias)"
fi

# OpenCode
export PATH="$PATH:$HOME/.opencode/bin"
if command -v opencode &>/dev/null; then
    source <(opencode completion bash 2>/dev/null) 2>/dev/null || true
fi

# === end of apps.sh block ===
BASHEOF
        echo "Bash configured at ~/.bashrc"
        timeout 1s sleep 1
    }

    configure_zsh() {
        clear
        echo "================================================="
        echo "               Configuring Zsh"
        echo "================================================="

        # Install zsh
        sudo xbps-install -Sy zsh

        # Install Oh My Zsh
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi

        # Install zsh-autosuggestions
        if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
            git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
        fi

        # Install zsh-syntax-highlighting
        if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
            git clone https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
        fi

        # Configure .zshrc plugins
        if grep -q "^plugins=" "$HOME/.zshrc" 2>/dev/null; then
            sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
        fi

        # Install Atuin
        curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh || exit 1



            grep -q "=== apps.sh managed block" "$HOME/.zshrc" 2>/dev/null || cat >> "$HOME/.zshrc" << 'ZSHEOF'
# === apps.sh managed block - do not edit manually ===
eval "$(atuin init zsh)"

# Aliases
alias lsa="ls -a"
alias update="~/.updater.sh"
alias scan="clamscan -r"
alias trm="trash-put"
alias trestore="trash-restore"
alias tbin="trash-empty"
alias listt="trash-list"
alias copy="wl-copy <"
alias paste="wl-paste >"
alias rkscan="sudo rkhunter --check --sk"
alias kate="flatpak run org.kde.kate"

# Extra functions
function gitpush_installscript() {
    cd ~/Projects/Scripts/linuxmintsetup && git add . && git commit -m "New changes" && git push -u origin main
    cd ~/Projects/Scripts/fedorasetup && git add . && git commit -m "New changes" && git push -u origin main
    cd ~/Projects/Scripts/voidsetup && git add . && git commit -m "New changes" && git push -u origin main
    cd ~/Projects/Scripts/cachysetup && git add . && git commit -m "New changes" && git push -u origin main
}

# Add your other functions here

# Homebrew
if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Thefuck
if command -v thefuck &>/dev/null; then
    eval "$(thefuck --alias)"
fi

# Opencode
export PATH="$PATH:$HOME/.opencode/bin"
if command -v opencode &>/dev/null; then
    source <(opencode completion zsh 2>/dev/null) 2>/dev/null || true
fi

# === end of apps.sh block ===
ZSHEOF
        echo "Zsh configured at ~/.zshrc"
        timeout 1s sleep 1
    }

    configure_fish() {
        clear
        echo "================================================="
        echo "                Configuring Fish"
        echo "================================================="

        # Install fish if not present
        sudo xbps-install -Sy fish

        # Install Atuin
        curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh || exit 1



        # Configure fish
        FISH_CONFIG_DIR="$HOME/.config/fish"
        FISH_CONFIG_FILE="$FISH_CONFIG_DIR/config.fish"
        mkdir -p "$FISH_CONFIG_DIR"

            cat > "$FISH_CONFIG_FILE" << 'FISHEOF'
if status is-interactive
    set -gx ATUIN_NOBIND true
    atuin init fish | source

    bind \e\[A _atuin_bind_up
    bind \cr _atuin_search

    if bind -M insert >/dev/null 2>&1
        bind -M insert \e\[A _atuin_bind_up
        bind -M insert \cr _atuin_search
    end

    bind \e\[3\;5~ kill-word
    bind \cH backward-kill-word
end

# Aliases
alias lsa "ls -a "
alias update "~/.updater.sh "
alias scan "clamscan -r "
alias trm "trash-put "
alias trestore "trash-restore "
alias tbin "trash-empty "
alias listt "trash-list "
alias copy "wl-copy < "
alias paste "wl-paste > "
alias rkscan "sudo rkhunter --check --sk "
alias kate "flatpak run org.kde.kate "

# Extra functions
function gitpush_installscript
    cd ~/Projects/Scripts/linuxmintsetup && git add . && git commit -m "New changes" && git push -u origin main
    cd ~/Projects/Scripts/fedorasetup && git add . && git commit -m "New changes" && git push -u origin main
    cd ~/Projects/Scripts/voidsetup && git add . && git commit -m "New changes" && git push -u origin main
    cd ~/Projects/Scripts/cachysetup && git add . && git commit -m "New changes" && git push -u origin main
end

# Add your other functions here

# Homebrew
if test -f /home/linuxbrew/.linuxbrew/bin/brew
    /home/linuxbrew/.linuxbrew/bin/brew shellenv | source
end

# Thefuck
if command -v thefuck >/dev/null
    thefuck --alias | source
end

FISHEOF
        echo "Fish configured at $FISH_CONFIG_FILE"
        timeout 1s sleep 1
    }

    case $shell_choice in
        '1')
            configure_bash
            ;;

        '2')
            configure_zsh
            ;;

        '3')
            configure_fish
            ;;

        '4')
            configure_bash
            configure_zsh
            configure_fish
            ;;

        '5')
            echo "=================================================="
            echo "          Skipping Shell Configuration.          "
            echo "=================================================="
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
}

configure_shells

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
    '1')
        echo "Keeping Bash.."
        sudo chsh -s /bin/bash
        timeout 1s sleep 1
        ;;

    '2')
        sudo chsh -s "$(which fish)" "$USER"
        timeout 1s sleep 1
        ;;
    '3')
        sudo chsh -s "$(which zsh)" "$USER"
        timeout 1s sleep 1
        ;;

    '4')
        clear
        echo "================================"
        echo "          Skipping.....         "
        echo "================================"
        ;;
    *)
        echo "Invalid choice."
        ;;
esac

# Run powermng
source powermng.sh

echo "=================================================="
echo "     Setup Complete :> , Please Reboot Your PC    "
echo "=================================================="
