#!/usr/bin/env bash
set -Eeuo pipefail

# =========================================================
# AI Tools setup helper
# =========================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

OPENCODE_CONFIG_DIR="${HOME}/.config/opencode"
OPENCODE_CONFIG_FILE="${OPENCODE_CONFIG_DIR}/opencode.json"

TARGET="all"

print_header() {
  echo
  echo -e "${BLUE}=========================================================${NC}"
  echo -e "${BLUE}               $1${NC}"
  echo -e "${BLUE}=========================================================${NC}"
}

info() {
  echo -e "${YELLOW}➜ $1${NC}"
}

success() {
  echo -e "${GREEN}✓ $1${NC}"
}

error() {
  echo -e "${RED}✗ $1${NC}"
}

pause_continue() {
  read -rp "Press Enter to continue..."
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

flatpak_app_installed() {
  flatpak info "$1" >/dev/null 2>&1
}

is_ollama_running() {
  curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1
}

require_command() {
  local cmd="$1"

  if ! command_exists "$cmd"; then
    error "$cmd is not installed."
    return 1
  fi

  success "$cmd is installed."
  return 0
}

wait_for_ollama() {
  if is_ollama_running; then
    success "Ollama service is already running."
    return
  fi

  error "Ollama service is not running."

  echo
  echo "Start it with:"
  echo
  echo "  ollama serve"
  echo

  info "Waiting for Ollama to become available..."

  until is_ollama_running; do
    sleep 2
    echo -n "."
  done

  echo
  success "Ollama is now running."
}

install_instructions() {
  echo
  echo "Installation commands (Void Linux):"
  echo
  echo "Ollama:"
  echo "  curl -fsSL https://ollama.com/install.sh | sh"
  echo
  echo "OpenCode:"
  echo "  curl -fsSL https://opencode.ai/install | bash"
  echo
  echo "Alpaca:"
  echo "  flatpak install flathub com.jeffser.Alpaca --noninteractive"
  echo
}

show_target_menu() {
  echo
  echo "Which tool do you want to configure?"
  echo "1) Ollama"
  echo "2) OpenCode"
  echo "3) Ollama + OpenCode"
  echo "4) Ollama + Alpaca"
  echo "5) Alpaca"
  echo "6) All"
  echo
  read -rp "Enter choice [1-6]: " choice

  case "$choice" in
    1) TARGET="ollama" ;;
    2) TARGET="opencode" ;;
    3) TARGET="ollama_opencode" ;;
    4) TARGET="ollama_alpaca" ;;
    5) TARGET="alpaca" ;;
    6) TARGET="all" ;;
    *) echo "Invalid choice, defaulting to all."; TARGET="all" ;;
  esac

  echo
  info "Selected: $TARGET"
}

create_base_opencode_config() {
  mkdir -p "$OPENCODE_CONFIG_DIR"

  cat > "$OPENCODE_CONFIG_FILE" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "name": "Ollama",
      "options": {
        "baseURL": "http://127.0.0.1:11434/v1"
      },
      "models": {},
      "capabilities": {
        "autoDetect": true,
        "enableAll": true
      }
    }
  },
  "mode": {
    "build": {
      "permission": {
        "read": "allow",
        "edit": "allow",
        "glob": "allow",
        "grep": "allow",
        "list": "allow",
        "bash": "allow",
        "task": "allow",
        "todowrite": "allow",
        "question": "allow",
        "webfetch": "allow",
        "websearch": "allow",
        "codesearch": "allow",
        "lsp": "allow",
        "skill": "allow",
        "repo_clone": "allow",
        "repo_overview": "allow"
      }
    },
    "plan": {
      "permission": {
        "read": "allow",
        "edit": "allow",
        "glob": "allow",
        "grep": "allow",
        "list": "allow",
        "bash": "allow",
        "task": "allow",
        "todowrite": "allow",
        "question": "allow",
        "webfetch": "allow",
        "websearch": "allow",
        "codesearch": "allow",
        "lsp": "allow",
        "skill": "allow",
        "repo_clone": "allow",
        "repo_overview": "allow"
      }
    }
  },
  "default_agent": "build"
}
EOF

  success "Created OpenCode config."
}

detect_installed_models() {
  ollama list 2>/dev/null | awk 'NR>1 {print $1}'
}

get_model_capabilities() {
  local model="$1"

  local info
  info="$(ollama show "$model" 2>/dev/null || true)"

  local HAS_TOOLS=false
  local HAS_VISION=false
  local IS_EMBEDDING=false
  local IS_REASONING=false
  local IS_INSTRUCT=false
  local HAS_MULTIMODAL=false

  if echo "$info" | grep -qi "tools"; then
    HAS_TOOLS=true
  fi

  if echo "$info" | grep -qi "vision"; then
    HAS_VISION=true
  fi

  if echo "$info" | grep -qi "embedding"; then
    IS_EMBEDDING=true
  fi

  if echo "$model" | grep -Eqi 'r1|reason|thinking|qwq|deepseek-r1'; then
    IS_REASONING=true
  fi

  if echo "$model" | grep -Eqi 'instruct|chat|coder|qwen|llama3'; then
    IS_INSTRUCT=true
  fi

  if echo "$info" | grep -qi "multimodal"; then
    HAS_MULTIMODAL=true
  fi

  echo "$HAS_TOOLS $HAS_VISION $IS_EMBEDDING $IS_REASONING $IS_INSTRUCT $HAS_MULTIMODAL"
}

update_opencode_models() {
  local models=("$@")

  local tmp
  tmp="$(mktemp)"

  cp "$OPENCODE_CONFIG_FILE" "$tmp"

  for model in "${models[@]}"; do
    local caps
    caps="$(get_model_capabilities "$model")"

    local HAS_TOOLS HAS_VISION IS_EMBEDDING IS_REASONING IS_INSTRUCT HAS_MULTIMODAL
    read -r HAS_TOOLS HAS_VISION IS_EMBEDDING IS_REASONING IS_INSTRUCT HAS_MULTIMODAL <<< "$caps"

    info "Configuring model: $model"

    local cap_features="{}"

    if [[ "$HAS_TOOLS" == "true" ]]; then
      cap_features="$(echo "$cap_features" | jq '. + {tools: true}')"
    fi
    if [[ "$HAS_VISION" == "true" || "$HAS_MULTIMODAL" == "true" ]]; then
      cap_features="$(echo "$cap_features" | jq '. + {vision: true}')"
    fi
    if [[ "$IS_REASONING" == "true" ]]; then
      cap_features="$(echo "$cap_features" | jq '. + {reasoning: true}')"
    fi
    if [[ "$IS_INSTRUCT" == "true" ]]; then
      cap_features="$(echo "$cap_features" | jq '. + {instruct: true}')"
    fi
    if [[ "$IS_EMBEDDING" == "true" ]]; then
      cap_features="$(echo "$cap_features" | jq '. + {embedding: true}')"
    fi

    local model_options="{}"
    if [[ "$HAS_TOOLS" == "true" ]]; then
      model_options="$(echo "$model_options" | jq '. + {tools: true, function_calling: true}')"
    fi

    jq \
      --arg model "$model" \
      --argjson capabilities "$cap_features" \
      --argjson options "$model_options" \
      '
      .provider.ollama.models[$model] = {
        "name": $model,
        "capabilities": $capabilities,
        "options": $options
      }
      ' "$tmp" > "${tmp}.new"

    mv "${tmp}.new" "$tmp"
  done

  mv "$tmp" "$OPENCODE_CONFIG_FILE"
}

detect_and_enable_model_capabilities() {
  local model="$1"

  local model_info
  model_info="$(ollama show "$model" 2>/dev/null || true)"

  local capabilities="{}"
  local model_options="{}"

  local cap_tools="false"
  local cap_vision="false"
  local cap_reasoning="false"
  local cap_instruct="false"
  local cap_embedding="false"
  local cap_multimodal="false"
  local cap_function_calling="false"
  local cap_json_output="false"

  if echo "$model_info" | grep -qi "tools"; then
    cap_tools="true"
    cap_function_calling="true"
  fi

  if echo "$model_info" | grep -qi "vision"; then
    cap_vision="true"
    cap_multimodal="true"
  fi

  if echo "$model_info" | grep -qi "multimodal"; then
    cap_multimodal="true"
    cap_vision="true"
  fi

  if echo "$model_info" | grep -qi "embedding"; then
    cap_embedding="true"
  fi

  if echo "$model_info" | grep -qi "reasoning"; then
    cap_reasoning="true"
  fi

  if echo "$model_info" | grep -qi "Function calling"; then
    cap_function_calling="true"
    cap_tools="true"
  fi

  if echo "$model" | grep -Eqi 'r1|reason|thinking|qwq|deepseek-r1|cog|chain'; then
    cap_reasoning="true"
  fi

  if echo "$model" | grep -Eqi 'instruct|chat|coder|qwen|llama3|phi|nemotron'; then
    cap_instruct="true"
  fi

  if echo "$model" | grep -Eqi 'vision|llava|moondream|minicpm|bakllava|gemma3|qwen2\.5.*image|phi.*vision'; then
    cap_vision="true"
    cap_multimodal="true"
  fi

  if echo "$model_info" | grep -qi "json"; then
    cap_json_output="true"
  fi

  capabilities="$(jq -n \
    --argjson tools "$cap_tools" \
    --argjson vision "$cap_vision" \
    --argjson reasoning "$cap_reasoning" \
    --argjson instruct "$cap_instruct" \
    --argjson embedding "$cap_embedding" \
    --argjson multimodal "$cap_multimodal" \
    --argjson function_calling "$cap_function_calling" \
    --argjson json_output "$cap_json_output" \
    '{
      tools: $tools,
      vision: $vision,
      reasoning: $reasoning,
      instruct: $instruct,
      embedding: $embedding,
      multimodal: $multimodal,
      function_calling: $function_calling,
      json_output: $json_output
    }')"

  if [[ "$cap_tools" == "true" || "$cap_function_calling" == "true" ]]; then
    model_options="$(jq -n '{tools: true, function_calling: true}')"
  fi

  local tmp
  tmp="$(mktemp)"
  cp "$OPENCODE_CONFIG_FILE" "$tmp"

  jq --arg model "$model" --argjson caps "$capabilities" --argjson opts "$model_options" \
    '.provider.ollama.models[$model].capabilities = $caps | .provider.ollama.models[$model].options = $opts' \
    "$tmp" > "${tmp}.new"

  mv "${tmp}.new" "$tmp"
  mv "$tmp" "$OPENCODE_CONFIG_FILE"
}

show_alpaca_instructions() {
  print_header "Alpaca Configuration"

  cat <<EOF
Alpaca does NOT automatically connect to external Ollama servers.

To connect Alpaca to Ollama:

1. Open Alpaca
2. Open the menu (☰)
3. Go to:
     Preferences → Manage Instances
4. Click:
     Add Instance
5. Select:
     Ollama
6. Enter your Ollama server URL

Examples:

Local Ollama:
  http://127.0.0.1:11434

Another PC on your network:
  http://192.168.1.50:11434

Remote server with domain:
  https://ollama.example.com

IMPORTANT:
If using another computer/server, Ollama must listen on external interfaces.

Example:
  OLLAMA_HOST=0.0.0.0 ollama serve

You may also need to open firewall port 11434.

After adding the instance:
- Click Connect
- Select your installed models
- Start chatting

EOF
}

check_model_context() {
  local model="$1"
  local current_ctx

  current_ctx="$(ollama show "$model" 2>/dev/null | grep -i "context length" | awk '{print $NF}' || echo "unknown")"

  if [[ "$current_ctx" == "unknown" ]]; then
    return 1
  fi

  local num_ctx
  num_ctx="$(ollama show "$model" 2>/dev/null | grep -i "num.ctx" | awk '{print $2}' || echo "4096")"

  if [[ "$num_ctx" -lt 8192 ]]; then
    echo "WARNING: $model has context window of $num_ctx (recommended: 16384+ for OpenCode)"
    return 0
  fi

  return 1
}

show_context_window_instructions() {
  print_header "Context Window Configuration"

  cat <<EOF
IMPORTANT: OpenCode requires a larger context window (recommended: 16384+ tokens).
Ollama defaults to 4096 tokens, which may cause models to hang.

To increase context window for a model:

1. Run: ollama run MODEL_NAME
   Example: ollama run qwen2.5:1.5b

2. Inside the prompt, set larger context:
   >>> /set parameter num_ctx 16384

3. Save as a new variant:
   >>> /save MODEL_NAME-16k

4. Exit: >>> /bye

5. Use the new variant in OpenCode config.

Quick commands for your installed models:
EOF

  local installed
  mapfile -t installed < <(detect_installed_models)

  for model in "${installed[@]}"; do
    local msg
    if check_model_context "$model"; then
      echo "  ollama run $model"
      echo "    /set parameter num_ctx 16384"
      echo "    /save ${model}-16k"
      echo
    fi
  done

  echo "Alternatively, set OLLAMA_CONTEXT_LENGTH environment variable:"
  echo "  export OLLAMA_CONTEXT_LENGTH=16384"
  echo "  ollama serve"
  echo
}

pull_models_interactive() {
  echo
  read -rp "Enter Ollama models to install, they must be space separated (Examples: Laptop = qwen2.5-coder:7b gemma3:4b(image) moondream:1.8b(image lightweight), and PC = qwen2.5-coder:7b llama3.1:8b(general) gemma3:4b, or press Enter to skip: " models_input

  if [[ -z "${models_input// }" ]]; then
    info "Skipping model installation."
    return
  fi

  IFS=' ' read -r -a models <<< "$models_input"

  for model in "${models[@]}"; do
    info "Pulling model: $model"

    if ollama pull "$model"; then
      success "Installed model: $model"
    else
      error "Failed to install: $model"
    fi
  done
}

main() {
  clear
  print_header "AI Tools Configuration"

  show_target_menu

  echo
  info "Checking dependencies..."

  need_install=false

  if [[ "$TARGET" == "ollama" || "$TARGET" == "ollama_opencode" || "$TARGET" == "ollama_alpaca" || "$TARGET" == "all" ]]; then
    if ! command_exists ollama; then
      error "Ollama is not installed."
      need_install=true
    else
      success "Ollama is installed."
    fi
  fi

  if [[ "$TARGET" == "opencode" || "$TARGET" == "ollama_opencode" || "$TARGET" == "all" ]]; then
    if ! command_exists opencode; then
      error "OpenCode is not installed."
      need_install=true
    else
      success "OpenCode is installed."
    fi
  fi

  if [[ "$TARGET" == "alpaca" || "$TARGET" == "ollama_alpaca" || "$TARGET" == "all" ]]; then
    if ! flatpak_app_installed com.jeffser.Alpaca; then
      error "Alpaca is not installed."
      need_install=true
    else
      success "Alpaca is installed."
    fi
  fi

  if $need_install; then
    echo
    error "Some applications are missing. Install them from apps.sh first."
    install_instructions
    exit 1
  fi

  if [[ "$TARGET" == "ollama" || "$TARGET" == "ollama_opencode" || "$TARGET" == "ollama_alpaca" || "$TARGET" == "all" ]]; then
    wait_for_ollama
    pull_models_interactive
  fi

  if [[ "$TARGET" == "opencode" || "$TARGET" == "ollama_opencode" || "$TARGET" == "all" ]]; then
    print_header "OpenCode Configuration"

    create_base_opencode_config

    info "Detecting installed Ollama models..."

    mapfile -t installed_models < <(detect_installed_models)

    if [[ ${#installed_models[@]} -eq 0 ]]; then
      error "No installed Ollama models detected."
    else
      echo
      echo "Detected models:"
      printf '  - %s\n' "${installed_models[@]}"
      echo

      update_opencode_models "${installed_models[@]}"

      for model in "${installed_models[@]}"; do
        detect_and_enable_model_capabilities "$model"
      done


    fi

    show_context_window_instructions
  fi

  if [[ "$TARGET" == "alpaca" || "$TARGET" == "ollama_alpaca" || "$TARGET" == "all" ]]; then
    print_header "Alpaca Configuration"
    show_alpaca_instructions
  fi

  print_header "Connection Verification"

  if curl -fsS --max-time 5 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    success "Ollama API is responding"
  else
    error "Cannot reach Ollama API at http://127.0.0.1:11434"
    echo "  Ensure Ollama is running: ollama serve"
  fi

  print_header "Setup Complete"

  echo -e "${GREEN}Configured: $TARGET${NC}"
  echo
  if [[ "$TARGET" == "opencode" || "$TARGET" == "ollama_opencode" || "$TARGET" == "all" ]]; then
    echo "OpenCode config:"
    echo "  $OPENCODE_CONFIG_FILE"
    echo
  fi
  if [[ "$TARGET" == "ollama" || "$TARGET" == "ollama_opencode" || "$TARGET" == "ollama_alpaca" || "$TARGET" == "all" ]]; then
    echo "Installed Ollama models:"
    ollama list || true
  fi
  echo
}

main "$@"
