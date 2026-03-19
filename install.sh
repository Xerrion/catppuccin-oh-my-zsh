#!/usr/bin/env bash
# Catppuccin for Oh My Zsh - Install / Configure / Uninstall
# https://github.com/Xerrion/catppuccin-oh-my-zsh
#
# Targets bash 3.2+ for macOS compatibility (no namerefs, no associative arrays).
#
# Usage:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/Xerrion/catppuccin-oh-my-zsh/main/install.sh)"
#   bash install.sh --non-interactive
#   bash install.sh --uninstall
#   bash install.sh --keep-zshrc
#
set -euo pipefail

# shellcheck disable=SC2059  # Color constants in printf format strings are intentional

INSTALLER_VERSION="2.0.0"
REPO_URL="https://github.com/Xerrion/catppuccin-oh-my-zsh.git"

# ---------------------------------------------------------------------------
# TTY and color detection
# ---------------------------------------------------------------------------

is_tty() {
  [[ -t 1 ]] && [[ -t 0 ]]
}

setup_colors() {
  if is_tty && [[ "${TERM:-}" != "dumb" ]]; then
    # Catppuccin Mocha palette (truecolor)
    CLR_ROSEWATER='\033[38;2;245;224;220m'
    CLR_FLAMINGO='\033[38;2;242;205;205m'
    CLR_PINK='\033[38;2;245;194;231m'
    CLR_MAUVE='\033[38;2;203;166;247m'
    CLR_RED='\033[38;2;243;139;168m'
    CLR_MAROON='\033[38;2;235;160;172m'
    CLR_PEACH='\033[38;2;250;179;135m'
    CLR_YELLOW='\033[38;2;249;226;175m'
    CLR_GREEN='\033[38;2;166;227;161m'
    CLR_TEAL='\033[38;2;148;226;213m'
    CLR_SKY='\033[38;2;137;220;235m'
    CLR_SAPPHIRE='\033[38;2;116;199;236m'
    CLR_BLUE='\033[38;2;137;180;250m'
    CLR_LAVENDER='\033[38;2;180;190;254m'
    CLR_TEXT='\033[38;2;205;214;244m'
    CLR_SUBTEXT='\033[38;2;166;173;200m'
    CLR_OVERLAY='\033[38;2;108;112;134m'
    CLR_SURFACE='\033[38;2;69;71;90m'
    CLR_BOLD='\033[1m'
    CLR_DIM='\033[2m'
    CLR_RESET='\033[0m'
  else
    CLR_ROSEWATER='' CLR_FLAMINGO='' CLR_PINK='' CLR_MAUVE='' CLR_RED=''
    CLR_MAROON='' CLR_PEACH='' CLR_YELLOW='' CLR_GREEN='' CLR_TEAL=''
    CLR_SKY='' CLR_SAPPHIRE='' CLR_BLUE='' CLR_LAVENDER=''
    CLR_TEXT='' CLR_SUBTEXT='' CLR_OVERLAY='' CLR_SURFACE=''
    CLR_BOLD='' CLR_DIM='' CLR_RESET=''
  fi
}

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

info() {
  printf "${CLR_BLUE}  info${CLR_RESET}  %s\n" "$*"
}

warn() {
  printf "${CLR_YELLOW}  warn${CLR_RESET}  %s\n" "$*"
}

error() {
  printf "${CLR_RED} error${CLR_RESET}  %s\n" "$*" >&2
}

success() {
  printf "${CLR_GREEN}    ok${CLR_RESET}  %s\n" "$*"
}

step() {
  printf "\n${CLR_MAUVE}${CLR_BOLD}  %s${CLR_RESET}\n\n" "$*"
}

abort_handler() {
  printf "\n"
  warn "Installation cancelled."
  exit 130
}

trap abort_handler INT

# ---------------------------------------------------------------------------
# Input helpers
# ---------------------------------------------------------------------------

# Read a single keypress without requiring Enter.
# Falls back to line-based read if stty is unavailable.
read_key() {
  local key=""
  if is_tty && command -v stty &>/dev/null; then
    local old_settings
    old_settings="$(stty -g)"
    stty -echo -icanon min 1 time 0 2>/dev/null || true
    key="$(dd bs=1 count=1 2>/dev/null)" || true
    stty "$old_settings" 2>/dev/null || true
    printf "\n"
  else
    read -r key
  fi
  echo "$key"
}

# Show a prompt and read a single key. Validates against allowed chars.
# Usage: ask_key "Choice" "12345q" -> stores result in ASK_RESULT
ASK_RESULT=""
ask_key() {
  local prompt_text="$1"
  local valid_chars="$2"

  while true; do
    printf "${CLR_MAUVE}  > ${CLR_TEXT}%s [${CLR_SUBTEXT}%s${CLR_TEXT}]:${CLR_RESET} " "$prompt_text" "$valid_chars"
    local key
    key="$(read_key)"
    key="$(echo "$key" | tr '[:upper:]' '[:lower:]')"

    if [[ -n "$key" && "$valid_chars" == *"$key"* ]]; then
      ASK_RESULT="$key"
      return 0
    fi
    warn "Invalid input. Please press one of: $valid_chars"
  done
}

# Ask yes/no, single keypress. Default on Enter.
# Usage: ask_yn "Proceed?" "y" -> 0=yes, 1=no
ask_yn() {
  local prompt_text="$1"
  local default="${2:-y}"
  local hint

  if [[ "$default" == "y" ]]; then
    hint="Y/n"
  else
    hint="y/N"
  fi

  printf "${CLR_MAUVE}  > ${CLR_TEXT}%s ${CLR_SUBTEXT}[%s]:${CLR_RESET} " "$prompt_text" "$hint"
  local key
  key="$(read_key)"
  key="$(echo "$key" | tr '[:upper:]' '[:lower:]')"

  # Empty = Enter = default
  if [[ -z "$key" || "$key" == $'\n' || "$key" == $'\r' ]]; then
    key="$default"
  fi

  [[ "$key" == "y" ]]
}

# ---------------------------------------------------------------------------
# Globals (set by wizard or CLI flags)
# ---------------------------------------------------------------------------

NON_INTERACTIVE=false
DO_UNINSTALL=false
DO_HELP=false
KEEP_ZSHRC=false

# Config values
CFG_FLAVOR="mocha"
CFG_PRESET="none"

# Resolved paths (set by preflight_checks)
THEME_DIR=""
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
BACKUP_PATH=""

# ---------------------------------------------------------------------------
# CLI argument parsing
# ---------------------------------------------------------------------------

parse_args() {
  for arg in "$@"; do
    case "$arg" in
      --non-interactive) NON_INTERACTIVE=true ;;
      --uninstall)       DO_UNINSTALL=true ;;
      --keep-zshrc)      KEEP_ZSHRC=true ;;
      --help|-h)         DO_HELP=true ;;
      *)                 error "Unknown flag: $arg"; show_help; exit 1 ;;
    esac
  done

  # Auto-detect non-interactive when stdin is not a TTY
  if ! is_tty && ! $NON_INTERACTIVE && ! $DO_UNINSTALL && ! $DO_HELP; then
    NON_INTERACTIVE=true
  fi
}

show_help() {
  printf "${CLR_TEXT}Catppuccin for Oh My Zsh - Installer v%s${CLR_RESET}\n\n" "$INSTALLER_VERSION"
  printf "Usage:\n"
  printf "  bash install.sh                    Interactive wizard\n"
  printf "  bash install.sh --non-interactive  Install with env-var config\n"
  printf "  bash install.sh --uninstall        Remove theme\n"
  printf "  bash install.sh --keep-zshrc       Install files but don't modify .zshrc\n"
  printf "  bash install.sh --help             Show this message\n\n"
  printf "Environment variables (--non-interactive):\n"
  printf "  CATPPUCCIN_FLAVOR   mocha|frappe|macchiato|latte   (default: mocha)\n"
  printf "  CATPPUCCIN_PRESET   none|minimal|classic|powerline|rainbow|p10k  (default: none)\n"
  printf "  KEEP_ZSHRC          yes  (skip .zshrc modification)\n\n"
  printf "Examples:\n"
  printf "  # One-liner install with defaults\n"
  printf "  sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/Xerrion/catppuccin-oh-my-zsh/main/install.sh)\"\n\n"
  printf "  # Non-interactive with Frappe flavor and powerline preset\n"
  printf "  CATPPUCCIN_FLAVOR=frappe CATPPUCCIN_PRESET=powerline bash install.sh --non-interactive\n"
}

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------

preflight_checks() {
  local zsh_custom="${ZSH_CUSTOM:-${ZSH:-}/custom}"

  if [[ -z "${ZSH:-}" || ! -d "${ZSH:-}" ]]; then
    error "Oh My Zsh not found (\$ZSH is unset or directory missing)."
    error "Install Oh My Zsh first: https://ohmyz.sh"
    exit 1
  fi

  if ! command -v git &>/dev/null; then
    error "git is required but not found in \$PATH."
    exit 1
  fi

  THEME_DIR="${zsh_custom}/themes/catppuccin-oh-my-zsh"

  if [[ ! -f "$ZSHRC" ]]; then
    warn ".zshrc not found at $ZSHRC"
    warn "A new .zshrc will need to be created after installation."
  fi

  if [[ -d "$THEME_DIR" ]]; then
    handle_existing_install
  fi
}

handle_existing_install() {
  warn "Existing installation found at $THEME_DIR"
  printf "\n"

  if $NON_INTERACTIVE; then
    info "Non-interactive mode: updating existing installation."
    info "Pulling latest changes..."
    git -C "$THEME_DIR" pull --ff-only 2>&1 | while IFS= read -r line; do
      printf "    ${CLR_DIM}%s${CLR_RESET}\n" "$line"
    done || {
      warn "git pull failed, will remove and re-clone."
      rm -rf "$THEME_DIR"
    }
    return 0
  fi

  printf "${CLR_TEXT}  What would you like to do?${CLR_RESET}\n"
  printf "    ${CLR_MAUVE}1)${CLR_TEXT} Update ${CLR_SUBTEXT}(git pull)${CLR_RESET}\n"
  printf "    ${CLR_MAUVE}2)${CLR_TEXT} Reinstall ${CLR_SUBTEXT}(remove and re-clone)${CLR_RESET}\n"
  printf "    ${CLR_MAUVE}q)${CLR_TEXT} Quit${CLR_RESET}\n"

  ask_key "Choice" "12q"

  case "$ASK_RESULT" in
    1)
      info "Updating via git pull..."
      git -C "$THEME_DIR" pull --ff-only 2>&1 | while IFS= read -r line; do
        printf "    ${CLR_DIM}%s${CLR_RESET}\n" "$line"
      done || {
        error "git pull failed. Try reinstalling (option 2)."
        exit 1
      }
      success "Updated to latest version."
      ;;
    2)
      info "Removing existing installation..."
      rm -rf "$THEME_DIR"
      success "Removed. Will re-clone."
      ;;
    q)
      warn "Aborted."
      exit 0
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Wizard: Welcome
# ---------------------------------------------------------------------------

wizard_welcome() {
  printf "\n"
  printf "${CLR_LAVENDER}${CLR_BOLD}"
  printf "      /\\_/\\ \n"
  printf "     ( o.o )  ${CLR_ROSEWATER}Catppuccin for Oh My Zsh${CLR_LAVENDER}\n"
  printf "      > ^ <   ${CLR_SUBTEXT}v%s${CLR_LAVENDER}\n" "$INSTALLER_VERSION"
  printf "${CLR_RESET}"
  printf "${CLR_OVERLAY}      -------${CLR_RESET}\n"
  printf "\n"
  printf "  ${CLR_TEXT}This wizard will guide you through installation.${CLR_RESET}\n"
  printf "  ${CLR_SUBTEXT}Press${CLR_TEXT} q ${CLR_SUBTEXT}at any prompt to quit.${CLR_RESET}\n"
}

# ---------------------------------------------------------------------------
# Wizard Step 1: Flavor
# ---------------------------------------------------------------------------

wizard_flavor() {
  step "Step 1/3 - Choose a flavor"

  # Show flavor options with color swatches
  printf "    ${CLR_MAUVE}1)${CLR_RESET}  "
  printf "\033[38;2;220;224;232m Latte \033[0m"
  printf "      ${CLR_SUBTEXT}Light background${CLR_RESET}\n"

  printf "    ${CLR_MAUVE}2)${CLR_RESET}  "
  printf "\033[38;2;198;208;245m Frappe \033[0m"
  printf "     ${CLR_SUBTEXT}Medium-dark${CLR_RESET}\n"

  printf "    ${CLR_MAUVE}3)${CLR_RESET}  "
  printf "\033[38;2;202;211;245m Macchiato \033[0m"
  printf "  ${CLR_SUBTEXT}Dark${CLR_RESET}\n"

  printf "    ${CLR_MAUVE}4)${CLR_RESET}  "
  printf "\033[38;2;205;214;244m Mocha \033[0m"
  printf "      ${CLR_SUBTEXT}Darkest ${CLR_DIM}(default)${CLR_RESET}\n"

  printf "\n"

  # Show a prompt preview in each flavor
  printf "  ${CLR_SUBTEXT}Preview:${CLR_RESET}\n"
  flavor_preview "latte"   "\033[38;2;64;160;43m" "\033[38;2;30;102;245m" "\033[38;2;23;146;153m" "\033[48;2;239;241;245m"
  flavor_preview "frappe"  "\033[38;2;166;209;137m" "\033[38;2;140;170;238m" "\033[38;2;129;200;190m" "\033[48;2;48;52;70m"
  flavor_preview "macchiato" "\033[38;2;166;218;149m" "\033[38;2;138;173;244m" "\033[38;2;139;213;202m" "\033[48;2;36;39;58m"
  flavor_preview "mocha"   "\033[38;2;166;227;161m" "\033[38;2;137;180;250m" "\033[38;2;148;226;213m" "\033[48;2;30;30;46m"
  printf "\n"

  ask_key "Flavor" "1234q"
  [[ "$ASK_RESULT" == "q" ]] && { warn "Aborted."; exit 0; }

  case "$ASK_RESULT" in
    1) CFG_FLAVOR="latte" ;;
    2) CFG_FLAVOR="frappe" ;;
    3) CFG_FLAVOR="macchiato" ;;
    4) CFG_FLAVOR="mocha" ;;
  esac

  success "Flavor: $CFG_FLAVOR"
}

flavor_preview() {
  local name="$1" green="$2" blue="$3" teal="$4" bg="$5"
  printf "    ${CLR_DIM}%-10s${CLR_RESET} " "$name"
  printf "${green}>${CLR_RESET} ${blue}~/projects${CLR_RESET} ${teal} main${CLR_RESET}\n"
}

# ---------------------------------------------------------------------------
# Wizard Step 2: Preset
# ---------------------------------------------------------------------------

wizard_preset() {
  step "Step 2/3 - Choose a preset"

  printf "  ${CLR_SUBTEXT}Presets configure layout, style, segments, and more in one step.${CLR_RESET}\n"
  printf "  ${CLR_SUBTEXT}You can customize individual settings later in .zshrc.${CLR_RESET}\n\n"

  # Preset options with inline previews
  printf "    ${CLR_MAUVE}1)${CLR_TEXT}  Minimal${CLR_RESET}\n"
  printf "       ${CLR_SUBTEXT}One-line, clean. Just the essentials.${CLR_RESET}\n"
  preset_preview_minimal
  printf "\n"

  printf "    ${CLR_MAUVE}2)${CLR_TEXT}  Classic${CLR_RESET}\n"
  printf "       ${CLR_SUBTEXT}Two-line with user, host, directory, git. Traditional feel.${CLR_RESET}\n"
  preset_preview_classic
  printf "\n"

  printf "    ${CLR_MAUVE}3)${CLR_TEXT}  Powerline ${CLR_DIM}(recommended)${CLR_RESET}\n"
  printf "       ${CLR_SUBTEXT}Colored backgrounds with powerline arrows. Transient prompt.${CLR_RESET}\n"
  preset_preview_powerline
  printf "\n"

  printf "    ${CLR_MAUVE}4)${CLR_TEXT}  Rainbow${CLR_RESET}\n"
  printf "       ${CLR_SUBTEXT}Every segment has a unique color. Maximum flair.${CLR_RESET}\n"
  preset_preview_rainbow
  printf "\n"

  printf "    ${CLR_MAUVE}5)${CLR_TEXT}  p10k${CLR_RESET}\n"
  printf "       ${CLR_SUBTEXT}Closest match to Powerlevel10k. Great for p10k migrants.${CLR_RESET}\n"
  preset_preview_p10k
  printf "\n"

  printf "    ${CLR_MAUVE}6)${CLR_TEXT}  None ${CLR_SUBTEXT}(defaults only, configure manually)${CLR_RESET}\n"
  printf "\n"

  ask_key "Preset" "123456q"
  [[ "$ASK_RESULT" == "q" ]] && { warn "Aborted."; exit 0; }

  case "$ASK_RESULT" in
    1) CFG_PRESET="minimal" ;;
    2) CFG_PRESET="classic" ;;
    3) CFG_PRESET="powerline" ;;
    4) CFG_PRESET="rainbow" ;;
    5) CFG_PRESET="p10k" ;;
    6) CFG_PRESET="none" ;;
  esac

  success "Preset: $CFG_PRESET"
}

# --- Preset previews using Catppuccin Mocha colors ---
# These show an approximate rendering of what the prompt will look like.

preset_preview_minimal() {
  printf "       ${CLR_GREEN}>${CLR_RESET} ${CLR_BLUE}~/projects${CLR_RESET} ${CLR_TEAL} main ${CLR_GREEN}*${CLR_RESET}\n"
}

preset_preview_classic() {
  printf "       ${CLR_PINK}user${CLR_OVERLAY} . ${CLR_BLUE}~/projects${CLR_OVERLAY} . ${CLR_TEAL} main ${CLR_GREEN}*${CLR_RESET}    ${CLR_OVERLAY}|${CLR_RESET} ${CLR_GREEN}v${CLR_RESET} ${CLR_YELLOW}2s${CLR_RESET} ${CLR_MAUVE}12:34${CLR_RESET}\n"
  printf "       ${CLR_GREEN}>${CLR_RESET} \n"
}

preset_preview_powerline() {
  # Simulate powerline segments with background colors
  printf "       "
  printf "\033[38;2;17;17;27;48;2;137;180;250m  \033[0m"
  printf "\033[38;2;137;180;250;48;2;137;180;250m\033[38;2;17;17;27m ~/projects \033[0m"
  printf "\033[38;2;137;180;250;48;2;148;226;213m\033[0m"
  printf "\033[48;2;148;226;213m\033[38;2;17;17;27m  main * \033[0m"
  printf "\033[38;2;148;226;213m\033[0m"
  printf "             "
  printf "\033[38;2;69;71;90m\033[48;2;69;71;90m\033[38;2;205;214;244m v \033[0m"
  printf "\033[38;2;69;71;90m\033[48;2;69;71;90m\033[38;2;205;214;244m 12:34 \033[0m\033[0m"
  printf "\n"
  printf "       ${CLR_GREEN}>${CLR_RESET} \n"
}

preset_preview_rainbow() {
  printf "       "
  printf "\033[38;2;17;17;27;48;2;137;180;250m  \033[0m"
  printf "\033[38;2;137;180;250;48;2;203;166;247m\033[0m"
  printf "\033[48;2;203;166;247m\033[38;2;17;17;27m user \033[0m"
  printf "\033[38;2;203;166;247;48;2;116;199;236m\033[0m"
  printf "\033[48;2;116;199;236m\033[38;2;17;17;27m ~/dev \033[0m"
  printf "\033[38;2;116;199;236;48;2;148;226;213m\033[0m"
  printf "\033[48;2;148;226;213m\033[38;2;17;17;27m  main \033[0m"
  printf "\033[38;2;148;226;213m\033[0m"
  printf "    "
  printf "\033[38;2;249;226;175m\033[48;2;249;226;175m\033[38;2;17;17;27m  22.1 \033[0m"
  printf "\033[38;2;166;227;161m\033[48;2;166;227;161m\033[38;2;17;17;27m  4s \033[0m\033[0m"
  printf "\n"
  printf "       ${CLR_GREEN}>${CLR_RESET} \n"
}

preset_preview_p10k() {
  printf "       "
  printf "\033[38;2;17;17;27;48;2;137;180;250m  \033[0m"
  printf "\033[38;2;137;180;250;48;2;137;180;250m\033[38;2;17;17;27m ~/projects \033[0m"
  printf "\033[38;2;137;180;250;48;2;148;226;213m\033[0m"
  printf "\033[48;2;148;226;213m\033[38;2;17;17;27m  main * \033[0m"
  printf "\033[38;2;148;226;213m\033[0m"
  printf "       "
  printf "\033[38;2;69;71;90m\033[48;2;69;71;90m\033[38;2;205;214;244m v \033[0m"
  printf "\033[38;2;69;71;90m\033[48;2;249;226;175m\033[0m"
  printf "\033[48;2;249;226;175m\033[38;2;17;17;27m  3.12 \033[0m"
  printf "\033[38;2;249;226;175m\033[0m"
  printf "\n"
  printf "       ${CLR_GREEN}>${CLR_RESET} \n"
}

# ---------------------------------------------------------------------------
# Wizard Step 3: Confirmation with .zshrc preview
# ---------------------------------------------------------------------------

wizard_confirm() {
  step "Step 3/3 - Review and confirm"

  local config_block
  config_block="$(build_config_block)"

  printf "  ${CLR_TEXT}${CLR_BOLD}Configuration:${CLR_RESET}\n"
  printf "    ${CLR_SUBTEXT}Flavor:${CLR_RESET}  %s\n" "$CFG_FLAVOR"
  printf "    ${CLR_SUBTEXT}Preset:${CLR_RESET}  %s\n" "$CFG_PRESET"
  printf "\n"

  printf "  ${CLR_TEXT}${CLR_BOLD}Files:${CLR_RESET}\n"
  printf "    ${CLR_SUBTEXT}Theme:${CLR_RESET}   %s\n" "$THEME_DIR"
  printf "    ${CLR_SUBTEXT}Config:${CLR_RESET}  %s\n" "$ZSHRC"
  printf "\n"

  if ! $KEEP_ZSHRC && [[ -f "$ZSHRC" ]]; then
    # Detect current theme
    local current_theme
    current_theme="$(detect_current_theme)"
    if [[ -n "$current_theme" && "$current_theme" != "catppuccin" ]]; then
      printf "  ${CLR_TEXT}${CLR_BOLD}Changes to .zshrc:${CLR_RESET}\n"
      printf "    ${CLR_RED}- ZSH_THEME=\"%s\"${CLR_RESET}\n" "$current_theme"
      printf "    ${CLR_GREEN}+ ZSH_THEME=\"catppuccin\"${CLR_RESET}\n"
      printf "\n"
    fi

    printf "  ${CLR_TEXT}${CLR_BOLD}Config block to add:${CLR_RESET}\n"
    while IFS= read -r cline; do
      printf "    ${CLR_GREEN}+ %s${CLR_RESET}\n" "$cline"
    done <<< "$config_block"
    printf "\n"

    printf "  ${CLR_SUBTEXT}A backup of .zshrc will be created before any changes.${CLR_RESET}\n"
    printf "\n"
  elif $KEEP_ZSHRC; then
    printf "  ${CLR_SUBTEXT}.zshrc will not be modified (--keep-zshrc).${CLR_RESET}\n"
    printf "  ${CLR_SUBTEXT}You will need to set ZSH_THEME=\"catppuccin\" manually.${CLR_RESET}\n\n"
  fi

  if ! ask_yn "Proceed with installation?" "y"; then
    warn "Aborted."
    exit 0
  fi
}

# Detect the current ZSH_THEME value from .zshrc
detect_current_theme() {
  if [[ ! -f "$ZSHRC" ]]; then
    echo ""
    return
  fi
  # Match: optional export, optional whitespace, ZSH_THEME=, quoted value
  local line
  line="$(grep -E '^[[:space:]]*(export[[:space:]]+)?ZSH_THEME=' "$ZSHRC" 2>/dev/null | tail -1)" || true
  if [[ -n "$line" ]]; then
    # Extract value between quotes
    echo "$line" | sed -E 's/.*ZSH_THEME=["\x27]([^"\x27]*)["\x27].*/\1/'
  fi
}

# ---------------------------------------------------------------------------
# Config block generation
# ---------------------------------------------------------------------------

build_config_block() {
  local block="# --- Catppuccin Config ---"

  # Flavor
  [[ "$CFG_FLAVOR" != "mocha" ]] && block+=$'\n'"CATPPUCCIN_FLAVOR=\"$CFG_FLAVOR\""

  # Preset
  [[ "$CFG_PRESET" != "none" ]] && block+=$'\n'"CATPPUCCIN_PRESET=\"$CFG_PRESET\""

  block+=$'\n'"# --- End Catppuccin Config ---"
  printf '%s' "$block"
}

# ---------------------------------------------------------------------------
# Installation
# ---------------------------------------------------------------------------

do_install() {
  local zsh_custom="${ZSH_CUSTOM:-${ZSH}/custom}"
  local symlink_path="${zsh_custom}/themes/catppuccin.zsh-theme"

  # Clone if the directory does not already exist (may exist from update path)
  if [[ ! -d "$THEME_DIR" ]]; then
    info "Cloning repository..."
    git clone --depth 1 "$REPO_URL" "$THEME_DIR" 2>&1 | while IFS= read -r line; do
      printf "    ${CLR_DIM}%s${CLR_RESET}\n" "$line"
    done
    success "Repository cloned."
  fi

  # Create symlink so ZSH_THEME="catppuccin" resolves
  info "Creating theme symlink..."
  ln -sf "$THEME_DIR/catppuccin.zsh-theme" "$symlink_path"
  success "Symlink: $symlink_path"
}

# ---------------------------------------------------------------------------
# .zshrc patching
# ---------------------------------------------------------------------------

patch_zshrc() {
  if $KEEP_ZSHRC; then
    info "Skipping .zshrc modification (--keep-zshrc)."
    return 0
  fi

  if [[ ! -f "$ZSHRC" ]]; then
    warn "No .zshrc found at $ZSHRC. Skipping .zshrc modification."
    warn "Add ZSH_THEME=\"catppuccin\" to your .zshrc manually."
    return 0
  fi

  # Backup
  BACKUP_PATH="${ZSHRC}.pre-catppuccin"
  if [[ -f "$BACKUP_PATH" ]]; then
    # Don't overwrite existing backup - add timestamp
    BACKUP_PATH="${ZSHRC}.pre-catppuccin.$(date +%Y%m%d_%H%M%S)"
  fi
  info "Backing up .zshrc to $BACKUP_PATH"
  cp "$ZSHRC" "$BACKUP_PATH"

  local config_block
  config_block="$(build_config_block)"

  local tmpfile
  tmpfile="$(mktemp)"

  # Remove any existing catppuccin config block
  remove_old_config_block "$ZSHRC" "$tmpfile"

  # Replace ZSH_THEME and inject config
  inject_theme_and_config "$tmpfile" "$config_block"

  mv "$tmpfile" "$ZSHRC"
  success ".zshrc updated."
}

remove_old_config_block() {
  local src="$1" dest="$2"
  awk '
    /^# --- Catppuccin Config ---$/ { skip=1; next }
    /^# --- End Catppuccin Config ---$/ { skip=0; next }
    !skip { print }
  ' "$src" > "$dest"
}

inject_theme_and_config() {
  local file="$1" config_block="$2"
  local tmpfile
  tmpfile="$(mktemp)"

  local injected=false
  local theme_replaced=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Replace any existing ZSH_THEME= line (handles: export ZSH_THEME=, ZSH_THEME=, etc.)
    if [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?ZSH_THEME= ]]; then
      printf 'ZSH_THEME="catppuccin"\n' >> "$tmpfile"
      theme_replaced=true
      continue
    fi

    # Inject config block just before the oh-my-zsh source line
    if ! $injected && [[ "$line" =~ source[[:space:]].*oh-my-zsh\.sh ]]; then
      printf '%s\n\n' "$config_block" >> "$tmpfile"
      injected=true
    fi

    printf '%s\n' "$line" >> "$tmpfile"
  done < "$file"

  # If we never found a ZSH_THEME line, add one before the source line
  if ! $theme_replaced; then
    local tmpfile2
    tmpfile2="$(mktemp)"
    local added=false
    while IFS= read -r line || [[ -n "$line" ]]; do
      if ! $added && [[ "$line" =~ source[[:space:]].*oh-my-zsh\.sh ]]; then
        printf 'ZSH_THEME="catppuccin"\n' >> "$tmpfile2"
        added=true
      fi
      printf '%s\n' "$line" >> "$tmpfile2"
    done < "$tmpfile"
    rm -f "$tmpfile"
    tmpfile="$tmpfile2"
  fi

  # If we never found the source line, append the config block at the end
  if ! $injected; then
    printf '\n%s\n' "$config_block" >> "$tmpfile"
  fi

  mv "$tmpfile" "$file"
}

# ---------------------------------------------------------------------------
# Non-interactive config from environment
# ---------------------------------------------------------------------------

read_env_config() {
  CFG_FLAVOR="${CATPPUCCIN_FLAVOR:-mocha}"
  CFG_PRESET="${CATPPUCCIN_PRESET:-none}"

  # Validate flavor
  case "$CFG_FLAVOR" in
    mocha|frappe|macchiato|latte) ;;
    *) warn "Unknown flavor '$CFG_FLAVOR', using mocha."; CFG_FLAVOR="mocha" ;;
  esac

  # Validate preset
  case "$CFG_PRESET" in
    none|minimal|classic|powerline|rainbow|p10k) ;;
    *) warn "Unknown preset '$CFG_PRESET', using none."; CFG_PRESET="none" ;;
  esac

  # Support KEEP_ZSHRC from environment
  if [[ "${KEEP_ZSHRC:-}" == "yes" ]]; then
    KEEP_ZSHRC=true
  fi
}

# ---------------------------------------------------------------------------
# Uninstall
# ---------------------------------------------------------------------------

do_uninstall() {
  local zsh_custom="${ZSH_CUSTOM:-${ZSH:-}/custom}"
  THEME_DIR="${zsh_custom}/themes/catppuccin-oh-my-zsh"
  local symlink_path="${zsh_custom}/themes/catppuccin.zsh-theme"

  printf "\n"
  printf "${CLR_MAUVE}${CLR_BOLD}  Catppuccin for Oh My Zsh - Uninstaller${CLR_RESET}\n\n"

  if [[ ! -d "$THEME_DIR" && ! -L "$symlink_path" ]]; then
    warn "No installation found. Nothing to do."
    exit 0
  fi

  if ! $NON_INTERACTIVE; then
    printf "  ${CLR_TEXT}This will:${CLR_RESET}\n"
    [[ -d "$THEME_DIR" ]]  && printf "    ${CLR_RED}- Remove ${THEME_DIR}${CLR_RESET}\n"
    [[ -L "$symlink_path" ]] && printf "    ${CLR_RED}- Remove symlink ${symlink_path}${CLR_RESET}\n"
    [[ -f "$ZSHRC" ]] && printf "    ${CLR_RED}- Remove Catppuccin config from .zshrc${CLR_RESET}\n"
    [[ -f "$ZSHRC" ]] && printf "    ${CLR_YELLOW}- Reset ZSH_THEME to \"robbyrussell\"${CLR_RESET}\n"
    printf "\n"

    if ! ask_yn "Remove Catppuccin theme?" "n"; then
      warn "Aborted."
      exit 0
    fi
  fi

  uninstall_theme_files "$symlink_path"
  uninstall_patch_zshrc
  offer_backup_restore

  printf "\n"
  success "Catppuccin has been removed."
  info "Run: ${CLR_TEAL}source ~/.zshrc${CLR_RESET}"
}

uninstall_theme_files() {
  local symlink_path="$1"

  if [[ -d "$THEME_DIR" ]]; then
    info "Removing theme directory..."
    rm -rf "$THEME_DIR"
    success "Theme directory removed."
  fi

  if [[ -L "$symlink_path" ]]; then
    info "Removing symlink..."
    rm -f "$symlink_path"
    success "Symlink removed."
  fi
}

uninstall_patch_zshrc() {
  if [[ ! -f "$ZSHRC" ]]; then
    return 0
  fi

  local backup_path
  backup_path="${ZSHRC}.pre-catppuccin-uninstall.$(date +%Y%m%d_%H%M%S)"
  cp "$ZSHRC" "$backup_path"
  info "Backup saved: $backup_path"

  local tmpfile
  tmpfile="$(mktemp)"

  # Remove config block
  remove_old_config_block "$ZSHRC" "$tmpfile"

  # Reset ZSH_THEME
  local tmpfile2
  tmpfile2="$(mktemp)"
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?ZSH_THEME=\"catppuccin\" ]]; then
      printf 'ZSH_THEME="robbyrussell"\n' >> "$tmpfile2"
    else
      printf '%s\n' "$line" >> "$tmpfile2"
    fi
  done < "$tmpfile"
  rm -f "$tmpfile"

  mv "$tmpfile2" "$ZSHRC"
  success "ZSH_THEME reset to robbyrussell."
}

offer_backup_restore() {
  if $NON_INTERACTIVE; then
    return 0
  fi

  # Find the pre-catppuccin backup
  local latest_backup=""
  local candidate
  for candidate in "${ZSHRC}.pre-catppuccin"*; do
    [[ -f "$candidate" ]] && latest_backup="$candidate"
  done

  if [[ -z "$latest_backup" ]]; then
    return 0
  fi

  printf "\n"
  info "Found pre-installation backup: $latest_backup"
  if ask_yn "Restore .zshrc from this backup?" "n"; then
    cp "$latest_backup" "$ZSHRC"
    success "Restored .zshrc from backup."
  else
    info "Keeping current .zshrc."
  fi
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

print_summary() {
  printf "\n"
  printf "  ${CLR_GREEN}${CLR_BOLD}Installation complete!${CLR_RESET}\n"
  printf "\n"
  printf "    ${CLR_SUBTEXT}Flavor:${CLR_RESET}    ${CLR_TEXT}%s${CLR_RESET}\n" "$CFG_FLAVOR"
  if [[ "$CFG_PRESET" != "none" ]]; then
    printf "    ${CLR_SUBTEXT}Preset:${CLR_RESET}    ${CLR_TEXT}%s${CLR_RESET}\n" "$CFG_PRESET"
  fi
  printf "    ${CLR_SUBTEXT}Installed:${CLR_RESET} ${CLR_TEXT}%s${CLR_RESET}\n" "$THEME_DIR"

  if [[ -n "${BACKUP_PATH:-}" ]]; then
    printf "    ${CLR_SUBTEXT}Backup:${CLR_RESET}    ${CLR_TEXT}%s${CLR_RESET}\n" "$BACKUP_PATH"
  fi

  printf "\n"
  printf "  ${CLR_TEXT}To activate:${CLR_RESET}\n"
  printf "    ${CLR_TEAL}source ~/.zshrc${CLR_RESET}\n"
  printf "\n"

  if $KEEP_ZSHRC; then
    printf "  ${CLR_YELLOW}Remember to add to your .zshrc:${CLR_RESET}\n"
    printf "    ${CLR_TEAL}ZSH_THEME=\"catppuccin\"${CLR_RESET}\n"
    if [[ "$CFG_PRESET" != "none" ]]; then
      printf "    ${CLR_TEAL}CATPPUCCIN_PRESET=\"%s\"${CLR_RESET}\n" "$CFG_PRESET"
    fi
    printf "\n"
  fi

  printf "  ${CLR_SUBTEXT}Customize further:${CLR_RESET} ${CLR_TEXT}See README.md or edit .zshrc${CLR_RESET}\n"
  printf "  ${CLR_SUBTEXT}Uninstall:${CLR_RESET}         ${CLR_TEXT}bash %s --uninstall${CLR_RESET}\n" "$THEME_DIR/install.sh"
  printf "\n"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  setup_colors
  parse_args "$@"

  if $DO_HELP; then
    show_help
    exit 0
  fi

  if $DO_UNINSTALL; then
    preflight_uninstall
    do_uninstall
    exit 0
  fi

  preflight_checks

  if $NON_INTERACTIVE; then
    read_env_config
    info "Non-interactive install: flavor=$CFG_FLAVOR preset=$CFG_PRESET"
  else
    wizard_welcome
    wizard_flavor
    wizard_preset
    wizard_confirm
  fi

  do_install
  patch_zshrc
  print_summary
}

preflight_uninstall() {
  if [[ -z "${ZSH:-}" || ! -d "${ZSH:-}" ]]; then
    error "Oh My Zsh not found (\$ZSH is unset or directory missing)."
    exit 1
  fi
}

main "$@"
