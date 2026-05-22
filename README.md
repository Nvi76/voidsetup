
# Void Linux Setup Script
Specifically for Void Linux

# 1. Shell Configs
**Bash**
```
# === setup-base.sh managed block - do not edit manually ===
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

# === end of setup-base.sh block ===
```
**Zsh**
```
# === setup-base.sh managed block - do not edit manually ===
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

# === end of setup-base.sh block ===
```
**Fish**
```
# === setup-base.sh managed block ===
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

# === end of setup-base.sh block ===
```
# 2. Git Manual
1) **Git & GitHub Setup**

After running `setup-base.sh`, an SSH key is generated automatically.
If you need to do it manually:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

2) **Add the key to GitHub**

1. Print your public key:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
2. Copy the output
3. Go to GitHub → **Settings** → **SSH and GPG keys** → **New SSH key**
4. Paste the key and save

3) **First-time push (new repo)**

```bash
cd ~/Projects/Scripts/voidsetup
git remote add origin git@github.com:YOUR_USERNAME/voidsetup.git # this is if there's no origin yet
git init
git remote set-url origin git@github.com:YOUR_USERNAME/voidsetup.git
git add .
git commit -m "Initial setup"
git push -u origin main
```

4)** Subsequent pushes**

```bash
cd ~/Projects/Scripts/voidsetup
git add .
git commit -m "description of changes"
git push
```

# 3. Custom Search Engines
```
Arch: https://archlinux.org/packages/?q=%s (archs)
Aur: https://aur.archlinux.org/packages?O=0&K=%s (aurs)
YouTube Search: https://www.youtube.com/search?q=%s (ytu)
Nixpkg Search: https://search.nixos.org/packages?channel=25.11&query=%s (nixpkg)
Brave Search: https://search.brave.com/search?q=%s
Brave Search Ask: https://search.brave.com/ask?q=%s
Startpage: https://startpage.com/search?q=%s
Ecosia: https://ecosia.org/search?q=%s
```

# 4. Fixes 
**1) If there's no windows option at boot run this command**

**For Bash:**
```
sudo cp -r /boot/efi/EFI/Microsoft /boot/efi/EFI/ && \
efibootmgr --create --disk /dev/sda --part 1 --label "Windows Boot Manager" --loader "\\EFI\\Microsoft\\Boot\\bootmgfw.efi" && \
sudo sed -i 's/^#timeout.*/timeout 10/' /boot/efi/loader/loader.conf   
```
**For Fish:**
```
sudo cp -r /boot/efi/EFI/Microsoft /boot/efi/EFI/ && \
efibootmgr --create --disk /dev/sda --part 1 --label "Windows Boot Manager" --loader "\\EFI\\Microsoft\\Boot\\bootmgfw.efi" && \
sudo sed -i 's/^#timeout.*/timeout 10/' /boot/efi/loader/loader.conf   
```

**2) If ollama.service is not working properly try to run**
```
sudo mkdir -p /usr/share/ollama && sudo chown ollama:ollama /usr/share/ollama
sudo systemctl restart ollama
```

**3) Fix Touchpad not working**
If the touchpad on your laptop doesn't work (Can't click) here's how to fix it:
```
sudo mkdir -p /etc/X11/xorg.conf.d; or exit 1
sudo nano /etc/X11/xorg.conf.d/30-touchpad.conf; or exit 1

Section "InputClass"
    Identifier "touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"
    Option "Tapping" "on"
    Option "NaturalScrolling" "on"
    Option "ClickMethod" "clickfinger"
EndSection
```

# 5. Additional things
**1) If you need to change the mouse cursor or whisker menu on xfce4 this is how**
```
sudo nano /etc/environment
# Put in this XCURSOR_THEME=[theme] for changing the mouse cursor and XCURSOR_SIZE=[size] for its size

xfce4-popup-applicationsmenu   
# put this in the keyboard shortcut
```

And make sure the /etc/nix/nix.conf file have this inside of it
   ```
    experimental-features = nix-command flakes
   ```
**2) 1. Read the jail.local file thats how the fail2ban ```/etc/fail2ban/jail.local``` file should** look like and make sure the ignore ip is set to be your device's ip
   (here's the command to check the device's ip = hostname -I)
