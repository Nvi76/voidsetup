#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# == Package manager (Void Linux) ==
update_system() { sudo xbps-install -Syu; }
enable_svc()    { sudo ln -s /etc/sv/"$1" /var/service/; }

# == UI helpers ==
RED='\033[91m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\[\033[1;38;5;27m\]'; NC='\033[0m'
info()  { echo -e "${YELLOW}=> $1${NC}"; }
ok()    { echo -e "${GREEN}=> $1${NC}"; }
err()   { echo -e "${RED}=> $1${NC}"; }
header(){ echo; echo -e "${BLUE}══ $1 ══${NC}"; }

pick() {
    local prompt="$1" min="$2" max="$3"
    while true; do
        read -rp "$prompt " choice
        [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= min && choice <= max )) && echo "$choice" && return
        err "Enter a number $min-$max."
    done
}

yn() {
    local prompt="${1:-Continue?}" default="${2:-Y}"
    local timeout=5
    local reply
    while true; do
        if ! read -r -t "$timeout" -rp "$prompt [y/n] (default $default in ${timeout}s): " reply; then
            echo
            [[ "$default" == [Yy] ]] && return 0 || return 1
        fi

        case "${reply,,}" in
            y|yes|Y) return 0 ;;
            n|no|N)  return 1 ;;
            *) err "Please enter y or n." ;;
        esac
    done
}

edu_apps() {
    echo "Select packages to install:"
    echo "1) Preschool (TK)"
    echo "2) Primary (SD)"
    echo "3) Secondary (SMP-SMA)"
    echo "4) Tertiary (Collage Level)"
    echo "5) All"
    case $(pick "Choice [1-5]" 1 5) in
        1) sudo xbps-install -S gcompris tuxpaint ;;
        2) sudo xbps-install -S tuxmath tuxtype marble ;;
        3) sudo xbps-install -S kalzium kstars geogebra ;;
        4) sudo xbps-install -S inkscape gimp ;;
        5) sudo xbps-install -S gcompris tuxpaint tuxmath tuxtype marble kalzium kstars geogebra inkscape gimp ;;
        *) echo "Invalid option" ;;
    esac
}

# == Security Configs ==
firejail_install() {

clear
header "Firejail Setup"
echo "Do you want to install & config Firejail? (Recommended) WARNING will make system more secure but a bit harder to use (Still works though)"
echo "1) Yes, Setup Firejail (Laptop)"
echo "2) Yes, Setup Firejail (PC)"
echo "3) No, Don't Setup Firejail"

case $(pick "Choice [1-3]" 1 3) in
    '1')
        # Install necessary packages
        sudo xbps-install -Syu
        sudo xbps-install -S firejail

        # Make folders
        sudo mkdir -p /etc/firejail/firecfg.d
        mkdir -p "$HOME/.config/firejail"
        mkdir -p "$HOME/Allowed"
        mkdir -p "$HOME/Allowed/AllowedCodes"
        mkdir -p "$HOME/Allowed/AllowedDocs"
        mkdir -p "$HOME/Allowed/AllowedPics"
        mkdir -p "$HOME/.local/share/applications"
        mkdir -p "$HOME/.mozilla/firefox"

        # Copy configuration files (Laptop-specific configs)
        cp "$SCRIPT_DIR"/firejail-configs/helium.profile ~/.config/firejail/helium.profile
        cp "$SCRIPT_DIR"/firejail-configs/brave.local ~/.config/firejail/brave.local
        cp "$SCRIPT_DIR"/firejail-configs/firefox.local ~/.config/firejail/firefox.local
        cp "$SCRIPT_DIR"/firejail-configs/librewolf.local ~/.config/firejail/librewolf.local

        ok "Firejail Config Success"

        # Do firecfg
        sudo firecfg
        ;;

    '2')
        # Install necessary packages
        sudo xbps-install -Syu
        sudo xbps-install -S firejail

        # Make folders
        sudo mkdir -p /etc/firejail/firecfg.d
        mkdir -p "$HOME/.config/firejail"
        mkdir -p "$HOME/Allowed"
        mkdir -p "$HOME/Allowed/AllowedCodes"
        mkdir -p "$HOME/Allowed/AllowedDocs"
        mkdir -p "$HOME/Allowed/AllowedPics"
        mkdir -p "$HOME/.local/share/applications"
        mkdir -p "$HOME/.config/net.imput.helium"
        mkdir -p "$HOME/.cache/net.imput.helium"

        # Copy configuration files (PC-specific configs)
        cp "$SCRIPT_DIR"/firejail-configs/helium.profile ~/.config/firejail/helium.profile
        cp "$SCRIPT_DIR"/firejail-configs/brave.local ~/.config/firejail/brave.local
        cp "$SCRIPT_DIR"/firejail-configs/firefox.local ~/.config/firejail/firefox.local
        cp "$SCRIPT_DIR"/firejail-configs/librewolf.local ~/.config/firejail/librewolf.local

        sudo tee /etc/firejail/firecfg.d/ExcludedApps.conf > /dev/null << 'EOF'
        !libreoffice
        !libreoffice-startcenter
        !org.libreoffice.LibreOffice
        !libreoffice-calc
        !libreoffice-writer
        !libreoffice-impress
        !libreoffice-draw
        !libreoffice-base
        !libreoffice-math
EOF

        ok "Firejail Config Success"

        # Do firecfg
        sudo firecfg
        ;;

    '3')
        clear
        info "Skipping firejail installation..."
        ;;
    *)
        err "Invalid choice."
        ;;
esac
}

# == Shell Configs ==

configure_bash() {

    clear
    header "Bash"

    # bash-completion
    info "Installing bash-completion..."
    sudo xbps-install -S bash-completion

    # Install Atuin
    if ! command -v atuin &>/dev/null; then
        curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh || exit 1
    fi

    # ble.sh
    clear
    if yn "Do you want to install ble.sh?" Y; then
        echo "How would you like to install ble.sh?"
        echo "1) Git"
        echo "2) Nix"
        case $(pick "[1-2]" 1 2) in
            '1')
            git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh
            make -C /tmp/ble.sh install PREFIX="$HOME/.local"
            ;;
            '2')
            nix profile install nixpkgs#ble-sh
            ;;
            *)
            err "Invalid choice. Skipping ble.sh."
        esac

        grep -q "blesh/ble.sh" "$HOME/.bashrc" 2>/dev/null || cat >> "$HOME/.bashrc" << 'EOF'
# ble.sh
[ -f "$HOME/.local/share/blesh/ble.sh" ] && source "$HOME/.local/share/blesh/ble.sh"
EOF

        cat > ~/.blerc << 'EOF'
bleopt complete_auto_delay=200
bleopt highlight_syntax=
bleopt complete_auto_history=
HISTSIZE=5000
HISTFILESIZE=10000
shopt -s histappend
bleopt edit_bell=vbell
EOF
    fi

    # Clear pre-existing managed sections using a quick pass of sed
    sed -i '/^# === apps.sh managed block ===$/,/^# === end of apps.sh block ===$/d' "$HOME/.bashrc" 2>/dev/null || true

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
gitpush_installscript() {
    for dir in linuxmintsetup fedorasetup voidsetup cachysetup nixsetup; do
        cd ~/Projects/Scripts/"$dir" 2>/dev/null || continue
        git add . && git diff --cached --quiet || git commit -m "New changes"
        git push 2>/dev/null || true
    done
}

gitpush_installscript_force() {
    for dir in linuxmintsetup fedorasetup voidsetup cachysetup nixsetup; do
        cd ~/Projects/Scripts/"$dir" 2>/dev/null || continue
        git add . && git diff --cached --quiet || git commit -m "New changes"
        git push --force 2>/dev/null || true
    done
}

# Copy Ai models to folder
ollama_model() {
  local model_name=$1

  if [ -z "$model_name" ]; then
    echo "Usage: copy_ollama_model <model-name>"
    return 1
  fi

  ollama export "$model_name" "./${model_name//:/_}.bin"
  echo "Model '$model_name' exported to $(pwd)/${model_name//:/_}.bin"
}

ollama_models_all() {
  local export_dir="./ollama-backup"
  mkdir -p "$export_dir"

  ollama list --format json | jq -r '.[].name' | while read model; do
    echo "Exporting $model..."
    ollama export "$model" "$export_dir/${model//:/_}.bin"
  done

  echo "All models exported to $export_dir"
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
    ok "Bash configured at ~/.bashrc"
    sleep 1
}

configure_zsh() {

    clear
    header "Zsh"

    # Install zsh
    sudo xbps-install -S zsh

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
    if ! command -v atuin &>/dev/null; then
        curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh || exit 1
    fi

    # Clear pre-existing managed sections using a quick pass of sed
    sed -i '/^# === apps.sh managed block ===$/,/^# === end of apps.sh block ===$/d' "$HOME/.zshrc" 2>/dev/null || true

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
gitpush_installscript() {
    for dir in linuxmintsetup fedorasetup voidsetup cachysetup nixsetup; do
        cd ~/Projects/Scripts/"$dir" 2>/dev/null || continue
        git add . && git diff --cached --quiet || git commit -m "New changes"
        git push 2>/dev/null || true
    done
}

gitpush_installscript_force() {
    for dir in linuxmintsetup fedorasetup voidsetup cachysetup nixsetup; do
        cd ~/Projects/Scripts/"$dir" 2>/dev/null || continue
        git add . && git diff --cached --quiet || git commit -m "New changes"
        git push --force 2>/dev/null || true
    done
}

# Copy Ai models to folder
ollama_model() {
  local model_name=$1

  if [ -z "$model_name" ]; then
    echo "Usage: copy_ollama_model <model-name>"
    return 1
  fi

  ollama export "$model_name" "./${model_name//:/_}.bin"
  echo "Model '$model_name' exported to $(pwd)/${model_name//:/_}.bin"
}

ollama_models_all() {
  local export_dir="./ollama-backup"
  mkdir -p "$export_dir"

  ollama list --format json | jq -r '.[].name' | while read model; do
    echo "Exporting $model..."
    ollama export "$model" "$export_dir/${model//:/_}.bin"
  done

  echo "All models exported to $export_dir"
}

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
    ok "Zsh configured at ~/.zshrc"
    sleep 1
}

configure_fish() {

    clear
    header "Fish"

    # Install fish if not present
    if ! command -v fish &>/dev/null; then
        sudo xbps-install -S fish
    fi

    # Install Atuin
    if ! command -v atuin &>/dev/null; then
        curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh || exit 1
    fi

    # Configure fish
    FISH_CONFIG_DIR="$HOME/.config/fish"
    FISH_CONFIG_FILE="$FISH_CONFIG_DIR/config.fish"
    mkdir -p "$FISH_CONFIG_DIR"

    # Clear pre-existing managed sections using a quick pass of sed
    sed -i '/^# === apps.sh managed block ===$/,/^# === end of apps.sh block ===$/d' "$FISH_CONFIG_FILE" 2>/dev/null || true
    # Apply config
    cat > "$FISH_CONFIG_FILE" << 'FISHEOF'
# === apps.sh managed block ===
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
    for dir in linuxmintsetup fedorasetup voidsetup cachysetup nixsetup
        cd ~/Projects/Scripts/$dir 2>/dev/null; or continue
        git add .; and git diff --cached --quiet; or git commit -m "New changes"
        git push 2>/dev/null; or true
    end
end

function gitpush_installscript_force
    for dir in linuxmintsetup fedorasetup voidsetup cachysetup nixsetup
        cd ~/Projects/Scripts/$dir 2>/dev/null; or continue
        git add .; and git diff --cached --quiet; or git commit -m "New changes"
        git push --force 2>/dev/null; or true
    end
end

# Copy Ai models to folder
function ollama_model
    set -l model_name $argv[1]

    if test -z "$model_name"
        echo "Usage: ollama_model <model-name>"
        return 1
    end

    set -l parts (string split ":" "$model_name")
    set -l model $parts[1]
    set -l tag "latest"
    if test (count $parts) -ge 2
        set tag $parts[2]
    end

    set -l manifest_path "$HOME/.ollama/models/manifests/registry.ollama.ai/library/$model/$tag"

    if not test -f "$manifest_path"
        echo "Model '$model_name' not found in Ollama store"
        return 1
    end

    set -l digest (jq -r '.layers[] | select(.mediaType == "application/vnd.ollama.image.model") | .digest' "$manifest_path")

    if test -z "$digest"
        echo "Could not find model data layer for '$model_name'"
        return 1
    end

    set -l blob_name (string replace ":" "-" "$digest")
    set -l blob_path "$HOME/.ollama/models/blobs/$blob_name"

    if not test -f "$blob_path"
        echo "Model blob not found at $blob_path"
        return 1
    end

    set -l filename (string replace ":" "_" "$model_name").bin
    cp "$blob_path" "./$filename"
    echo "Model '$model_name' exported to "(pwd)"/"$filename
end

function ollama_models_all
    set -l export_dir "./ollama-backup"
    mkdir -p "$export_dir"

    for manifest_path in $HOME/.ollama/models/manifests/registry.ollama.ai/library/*/*
        set -l name (basename (dirname "$manifest_path"))
        set -l tag (basename "$manifest_path")
        set -l model "$name:$tag"

        echo "Exporting $model..."
        set -l digest (jq -r '.layers[] | select(.mediaType == "application/vnd.ollama.image.model") | .digest' "$manifest_path")

        if test -n "$digest"
            set -l blob_name (string replace ":" "-" "$digest")
            set -l blob_path "$HOME/.ollama/models/blobs/$blob_name"

            if test -f "$blob_path"
                set -l filename (string replace ":" "_" "$model").bin
                cp "$blob_path" "$export_dir/$filename"
            end
        end
    end

    echo "All models exported to $export_dir"
end

# Homebrew
if test -f /home/linuxbrew/.linuxbrew/bin/brew
    /home/linuxbrew/.linuxbrew/bin/brew shellenv | source
end

# Thefuck
if command -v thefuck >/dev/null
    thefuck --alias | source
end

# === end of apps.sh block ===
FISHEOF
    ok "Fish configured at $FISH_CONFIG_FILE"
    sleep 1
}
