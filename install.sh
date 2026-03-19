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
#
set -euo pipefail

# shellcheck disable=SC2059  # Color constants in printf format strings are intentional

INSTALLER_VERSION="1.0.0"
REPO_URL="https://github.com/Xerrion/catppuccin-oh-my-zsh.git"

# --- Catppuccin Mocha palette (ANSI true-color for installer UI) ---
readonly CLR_ROSEWATER='\033[38;2;245;224;220m'
readonly CLR_PINK='\033[38;2;245;194;231m'
readonly CLR_MAUVE='\033[38;2;203;166;247m'
readonly CLR_RED='\033[38;2;243;139;168m'
readonly CLR_PEACH='\033[38;2;250;179;135m'
readonly CLR_YELLOW='\033[38;2;249;226;175m'
readonly CLR_GREEN='\033[38;2;166;227;161m'
readonly CLR_TEAL='\033[38;2;148;226;213m'
readonly CLR_BLUE='\033[38;2;137;180;250m'
readonly CLR_SKY='\033[38;2;137;220;235m'
readonly CLR_LAVENDER='\033[38;2;180;190;254m'
readonly CLR_TEXT='\033[38;2;205;214;244m'
readonly CLR_SUBTEXT='\033[38;2;166;173;200m'
readonly CLR_OVERLAY='\033[38;2;108;112;134m'
readonly CLR_BOLD='\033[1m'
readonly CLR_DIM='\033[2m'
readonly CLR_RESET='\033[0m'

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

info() {
  printf "${CLR_SKY}  info${CLR_RESET}  %s\n" "$*"
}

warn() {
  printf "${CLR_PEACH}  warn${CLR_RESET}  %s\n" "$*"
}

error() {
  printf "${CLR_RED} error${CLR_RESET}  %s\n" "$*" >&2
}

success() {
  printf "${CLR_GREEN}    ok${CLR_RESET}  %s\n" "$*"
}

prompt() {
  local message="$1" default="${2:-}"
  if [[ -n "$default" ]]; then
    printf "${CLR_MAUVE}     > ${CLR_TEXT}%s ${CLR_SUBTEXT}[%s]:${CLR_RESET} " "$message" "$default"
  else
    printf "${CLR_MAUVE}     > ${CLR_TEXT}%s:${CLR_RESET} " "$message"
  fi
}

abort_handler() {
  printf "\n"
  warn "Installation cancelled."
  exit 130
}

trap abort_handler INT

# ---------------------------------------------------------------------------
# Globals (set by wizard or CLI flags)
# ---------------------------------------------------------------------------

NON_INTERACTIVE=false
DO_UNINSTALL=false
DO_HELP=false

# Config values - start with defaults
CFG_FLAVOR="mocha"
CFG_LAYOUT="oneline"
CFG_SEPARATOR="space"
CFG_SEPARATOR_CUSTOM=""
CFG_SHOW_TIME="false"
CFG_SHOW_VENV="true"
CFG_SHOW_PYTHON="false"
CFG_SHOW_NODE="false"
CFG_SHOW_RUST="false"
CFG_SHOW_GO="false"
CFG_SHOW_RUBY="false"
CFG_SHOW_JAVA="false"
CFG_SHOW_PHP="false"
CFG_SHOW_K8S="false"
CFG_SHOW_JOBS="false"
CFG_SHOW_EXEC_TIME="false"

# Resolved paths (set by preflight_checks)
THEME_DIR=""
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

# ---------------------------------------------------------------------------
# CLI argument parsing
# ---------------------------------------------------------------------------

parse_args() {
  for arg in "$@"; do
    case "$arg" in
      --non-interactive) NON_INTERACTIVE=true ;;
      --uninstall)       DO_UNINSTALL=true ;;
      --help|-h)         DO_HELP=true ;;
      *)                 error "Unknown flag: $arg"; show_help; exit 1 ;;
    esac
  done
}

show_help() {
  printf "${CLR_TEXT}Catppuccin for Oh My Zsh - Installer v%s${CLR_RESET}\n\n" "$INSTALLER_VERSION"
  printf "Usage:\n"
  printf "  bash install.sh              Interactive wizard\n"
  printf "  bash install.sh --non-interactive\n"
  printf "                               Install with env-var config\n"
  printf "  bash install.sh --uninstall  Remove theme\n"
  printf "  bash install.sh --help       Show this message\n\n"
  printf "Environment variables (--non-interactive):\n"
  printf "  CATPPUCCIN_FLAVOR        mocha|frappe|macchiato|latte\n"
  printf "  CATPPUCCIN_LAYOUT        oneline|twoline\n"
  printf "  CATPPUCCIN_SEPARATOR     space|arrow|bar|dot|powerline|<custom>\n"
  printf "  CATPPUCCIN_SHOW_TIME     true|false\n"
  printf "  CATPPUCCIN_SHOW_VENV     true|false\n"
  printf "  CATPPUCCIN_SHOW_PYTHON   true|false\n"
  printf "  CATPPUCCIN_SHOW_NODE     true|false\n"
  printf "  CATPPUCCIN_SHOW_RUST     true|false\n"
  printf "  CATPPUCCIN_SHOW_GO       true|false\n"
  printf "  CATPPUCCIN_SHOW_RUBY     true|false\n"
  printf "  CATPPUCCIN_SHOW_JAVA     true|false\n"
  printf "  CATPPUCCIN_SHOW_PHP      true|false\n"
  printf "  CATPPUCCIN_SHOW_K8S      true|false\n"
  printf "  CATPPUCCIN_SHOW_JOBS     true|false\n"
  printf "  CATPPUCCIN_SHOW_EXEC_TIME true|false\n"
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
    error ".zshrc not found at $ZSHRC"
    exit 1
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
    return 0
  fi

  printf "${CLR_YELLOW}  What would you like to do?${CLR_RESET}\n"
  printf "    1) Update (git pull)\n"
  printf "    2) Reinstall (remove and re-clone)\n"
  printf "    3) Abort\n"
  prompt "Choice" "1"

  local choice
  read -r choice
  choice="${choice:-1}"

  case "$choice" in
    1)
      info "Updating via git pull..."
      git -C "$THEME_DIR" pull --ff-only || {
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
    3)
      warn "Aborted."
      exit 0
      ;;
    *)
      error "Invalid choice."
      exit 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Wizard: Welcome banner
# ---------------------------------------------------------------------------

wizard_welcome() {
  printf "\n"
  printf "${CLR_PINK}${CLR_BOLD}"
  printf "      /\\_/\\    ${CLR_ROSEWATER}Catppuccin for Oh My Zsh${CLR_PINK}\n"
  printf "     ( o.o )   ${CLR_LAVENDER}Soothing pastel theme${CLR_PINK}\n"
  printf "      > ^ <    ${CLR_MAUVE}v%s\n" "$INSTALLER_VERSION"
  printf "${CLR_RESET}"
  printf "${CLR_SUBTEXT}      -------   github.com/Xerrion/catppuccin-oh-my-zsh${CLR_RESET}\n"
  printf "\n"
}

# ---------------------------------------------------------------------------
# Wizard: Flavor
# ---------------------------------------------------------------------------

wizard_flavor() {
  printf "${CLR_TEXT}${CLR_BOLD}  Select a flavor:${CLR_RESET}\n"
  printf "    ${CLR_MAUVE}1)${CLR_TEXT} Mocha ${CLR_SUBTEXT}(default)${CLR_RESET}\n"
  printf "    ${CLR_MAUVE}2)${CLR_TEXT} Frappe${CLR_RESET}\n"
  printf "    ${CLR_MAUVE}3)${CLR_TEXT} Macchiato${CLR_RESET}\n"
  printf "    ${CLR_MAUVE}4)${CLR_TEXT} Latte${CLR_RESET}\n"
  prompt "Choice" "1"

  local choice
  read -r choice
  choice="${choice:-1}"

  case "$choice" in
    1) CFG_FLAVOR="mocha" ;;
    2) CFG_FLAVOR="frappe" ;;
    3) CFG_FLAVOR="macchiato" ;;
    4) CFG_FLAVOR="latte" ;;
    *) warn "Invalid choice, using mocha."; CFG_FLAVOR="mocha" ;;
  esac

  success "Flavor: $CFG_FLAVOR"
  printf "\n"
}

# ---------------------------------------------------------------------------
# Wizard: Layout
# ---------------------------------------------------------------------------

wizard_layout() {
  printf "${CLR_TEXT}${CLR_BOLD}  Select prompt layout:${CLR_RESET}\n"
  printf "    ${CLR_MAUVE}1)${CLR_TEXT} Oneline ${CLR_SUBTEXT}(default)${CLR_RESET}\n"
  printf "    ${CLR_MAUVE}2)${CLR_TEXT} Twoline${CLR_RESET}\n"
  prompt "Choice" "1"

  local choice
  read -r choice
  choice="${choice:-1}"

  case "$choice" in
    1) CFG_LAYOUT="oneline" ;;
    2) CFG_LAYOUT="twoline" ;;
    *) warn "Invalid choice, using oneline."; CFG_LAYOUT="oneline" ;;
  esac

  success "Layout: $CFG_LAYOUT"
  printf "\n"
}

# ---------------------------------------------------------------------------
# Wizard: Separator
# ---------------------------------------------------------------------------

wizard_separator() {
  printf "${CLR_TEXT}${CLR_BOLD}  Select segment separator:${CLR_RESET}\n"
  printf "    ${CLR_MAUVE}1)${CLR_TEXT} Space ${CLR_SUBTEXT}(default)${CLR_RESET}\n"
  printf "    ${CLR_MAUVE}2)${CLR_TEAL} Arrow ${CLR_OVERLAY}(${CLR_TEAL} ❯ ${CLR_OVERLAY})${CLR_RESET}\n"
  printf "    ${CLR_MAUVE}3)${CLR_TEAL} Bar ${CLR_OVERLAY}(${CLR_TEAL} | ${CLR_OVERLAY})${CLR_RESET}\n"
  printf "    ${CLR_MAUVE}4)${CLR_TEAL} Dot ${CLR_OVERLAY}(${CLR_TEAL} · ${CLR_OVERLAY})${CLR_RESET}\n"
  printf "    ${CLR_MAUVE}5)${CLR_TEAL} Powerline ${CLR_OVERLAY}(${CLR_TEAL} ▸ ${CLR_OVERLAY})${CLR_RESET}\n"
  printf "    ${CLR_MAUVE}6)${CLR_TEXT} Custom${CLR_RESET}\n"
  prompt "Choice" "1"

  local choice
  read -r choice
  choice="${choice:-1}"

  case "$choice" in
    1) CFG_SEPARATOR="space" ;;
    2) CFG_SEPARATOR="arrow" ;;
    3) CFG_SEPARATOR="bar" ;;
    4) CFG_SEPARATOR="dot" ;;
    5) CFG_SEPARATOR="powerline" ;;
    6)
      prompt "Enter custom separator string" ""
      local custom_sep
      read -r custom_sep
      if [[ -z "$custom_sep" ]]; then
        warn "Empty input, using space."
        CFG_SEPARATOR="space"
      else
        CFG_SEPARATOR="$custom_sep"
        CFG_SEPARATOR_CUSTOM="$custom_sep"
      fi
      ;;
    *) warn "Invalid choice, using space."; CFG_SEPARATOR="space" ;;
  esac

  success "Separator: $CFG_SEPARATOR"
  printf "\n"
}

# ---------------------------------------------------------------------------
# Wizard: Optional segments
# ---------------------------------------------------------------------------

wizard_segments() {
  # Parallel arrays: names, config variable suffixes, and current toggle state
  # Note: seg_labels and seg_state are read/written by render_segment_list and toggle_segments
  local -a seg_labels=( "Time display" "Python virtualenv" "Python version"
    "Node.js version" "Rust version" "Go version" "Ruby version" "Java version"
    "PHP version" "Kubernetes context" "Background jobs" "Execution time" )
  local -a seg_keys=( TIME VENV PYTHON NODE RUST GO RUBY JAVA PHP K8S JOBS EXEC_TIME )
  local -a seg_state=( "$CFG_SHOW_TIME" "$CFG_SHOW_VENV" "$CFG_SHOW_PYTHON"
    "$CFG_SHOW_NODE" "$CFG_SHOW_RUST" "$CFG_SHOW_GO" "$CFG_SHOW_RUBY"
    "$CFG_SHOW_JAVA" "$CFG_SHOW_PHP" "$CFG_SHOW_K8S" "$CFG_SHOW_JOBS"
    "$CFG_SHOW_EXEC_TIME" )

  printf "${CLR_TEXT}${CLR_BOLD}  Toggle optional segments ${CLR_SUBTEXT}(comma-separated numbers, Enter to keep defaults):${CLR_RESET}\n"
  render_segment_list

  prompt "Toggle" ""
  local input
  read -r input

  if [[ -n "$input" ]]; then
    toggle_segments "$input" "${#seg_keys[@]}"
  fi

  # Write back to CFG_ variables
  CFG_SHOW_TIME="${seg_state[0]}"
  CFG_SHOW_VENV="${seg_state[1]}"
  CFG_SHOW_PYTHON="${seg_state[2]}"
  CFG_SHOW_NODE="${seg_state[3]}"
  CFG_SHOW_RUST="${seg_state[4]}"
  CFG_SHOW_GO="${seg_state[5]}"
  CFG_SHOW_RUBY="${seg_state[6]}"
  CFG_SHOW_JAVA="${seg_state[7]}"
  CFG_SHOW_PHP="${seg_state[8]}"
  CFG_SHOW_K8S="${seg_state[9]}"
  CFG_SHOW_JOBS="${seg_state[10]}"
  CFG_SHOW_EXEC_TIME="${seg_state[11]}"

  success "Segments configured."
  printf "\n"
}

render_segment_list() {
  # Reads seg_labels and seg_state from the calling scope (wizard_segments)
  local i
  for i in "${!seg_labels[@]}"; do
    local marker=" "
    [[ "${seg_state[$i]}" == "true" ]] && marker="${CLR_GREEN}*${CLR_RESET}"
    printf "    [%b] ${CLR_MAUVE}%2d)${CLR_TEXT} %s${CLR_RESET}\n" "$marker" "$((i + 1))" "${seg_labels[$i]}"
  done
}

toggle_segments() {
  # Modifies seg_state in the calling scope (wizard_segments)
  local input="$1"
  local count="$2"

  IFS=',' read -ra nums <<< "$input"
  for num in "${nums[@]}"; do
    num="$(echo "$num" | tr -d '[:space:]')"
    if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= count )); then
      local idx=$((num - 1))
      if [[ "${seg_state[idx]}" == "true" ]]; then
        seg_state[idx]="false"
      else
        seg_state[idx]="true"
      fi
    else
      warn "Ignoring invalid number: $num"
    fi
  done
}

# ---------------------------------------------------------------------------
# Wizard: Confirmation
# ---------------------------------------------------------------------------

wizard_confirm() {
  printf "${CLR_TEXT}${CLR_BOLD}  Configuration Summary${CLR_RESET}\n"
  printf "${CLR_OVERLAY}  =====================${CLR_RESET}\n"
  printf "    ${CLR_SUBTEXT}Flavor:${CLR_RESET}    %s\n" "$CFG_FLAVOR"
  printf "    ${CLR_SUBTEXT}Layout:${CLR_RESET}    %s\n" "$CFG_LAYOUT"
  printf "    ${CLR_SUBTEXT}Separator:${CLR_RESET} %s\n" "$CFG_SEPARATOR"

  local enabled
  enabled="$(collect_enabled_segments)"
  if [[ -n "$enabled" ]]; then
    printf "    ${CLR_SUBTEXT}Segments:${CLR_RESET}  %s\n" "$enabled"
  fi

  printf "\n"
  printf "    ${CLR_BLUE}Theme dir:${CLR_RESET} %s\n" "$THEME_DIR"
  printf "    ${CLR_BLUE}zshrc:${CLR_RESET}     %s\n" "$ZSHRC"
  printf "\n"

  prompt "Proceed with installation? (Y/n)" "Y"
  local answer
  read -r answer
  answer="${answer:-Y}"

  case "$answer" in
    [Yy]*) return 0 ;;
    *)     warn "Aborted."; exit 0 ;;
  esac
}

collect_enabled_segments() {
  # Echoes space-separated list of enabled segment names
  local -a out=()
  [[ "$CFG_SHOW_TIME" == "true" ]]      && out+=("time")
  [[ "$CFG_SHOW_VENV" == "true" ]]      && out+=("venv")
  [[ "$CFG_SHOW_PYTHON" == "true" ]]    && out+=("python")
  [[ "$CFG_SHOW_NODE" == "true" ]]      && out+=("node")
  [[ "$CFG_SHOW_RUST" == "true" ]]      && out+=("rust")
  [[ "$CFG_SHOW_GO" == "true" ]]        && out+=("go")
  [[ "$CFG_SHOW_RUBY" == "true" ]]      && out+=("ruby")
  [[ "$CFG_SHOW_JAVA" == "true" ]]      && out+=("java")
  [[ "$CFG_SHOW_PHP" == "true" ]]       && out+=("php")
  [[ "$CFG_SHOW_K8S" == "true" ]]       && out+=("k8s")
  [[ "$CFG_SHOW_JOBS" == "true" ]]      && out+=("jobs")
  [[ "$CFG_SHOW_EXEC_TIME" == "true" ]] && out+=("exec_time")
  [[ ${#out[@]} -gt 0 ]] && echo "${out[*]}"
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
  local backup_path
  backup_path="${ZSHRC}.catppuccin-backup.$(date +%s)"

  info "Backing up .zshrc to $backup_path"
  cp "$ZSHRC" "$backup_path"

  local config_block
  config_block="$(build_config_block)"

  local tmpfile
  tmpfile="$(mktemp)"

  remove_old_config_block "$ZSHRC" "$tmpfile"
  inject_theme_and_config "$tmpfile" "$config_block"

  mv "$tmpfile" "$ZSHRC"
  success ".zshrc updated."

  # Store for summary
  BACKUP_PATH="$backup_path"
}

build_config_block() {
  local block="# --- Catppuccin Config ---"

  # Core - only non-defaults
  [[ "$CFG_FLAVOR" != "mocha" ]]       && block+=$'\n'"CATPPUCCIN_FLAVOR=\"$CFG_FLAVOR\""
  [[ "$CFG_LAYOUT" != "oneline" ]]     && block+=$'\n'"CATPPUCCIN_LAYOUT=\"$CFG_LAYOUT\""
  if [[ -n "$CFG_SEPARATOR_CUSTOM" ]]; then
    block+=$'\n'"CATPPUCCIN_SEPARATOR=\"$CFG_SEPARATOR_CUSTOM\""
  elif [[ "$CFG_SEPARATOR" != "space" ]]; then
    block+=$'\n'"CATPPUCCIN_SEPARATOR=\"$CFG_SEPARATOR\""
  fi

  # Segment toggles - only non-defaults
  [[ "$CFG_SHOW_TIME" != "false" ]]      && block+=$'\n'"CATPPUCCIN_SHOW_TIME=\"$CFG_SHOW_TIME\""
  [[ "$CFG_SHOW_VENV" != "true" ]]       && block+=$'\n'"CATPPUCCIN_SHOW_VENV=\"$CFG_SHOW_VENV\""
  [[ "$CFG_SHOW_PYTHON" != "false" ]]    && block+=$'\n'"CATPPUCCIN_SHOW_PYTHON=\"$CFG_SHOW_PYTHON\""
  [[ "$CFG_SHOW_NODE" != "false" ]]      && block+=$'\n'"CATPPUCCIN_SHOW_NODE=\"$CFG_SHOW_NODE\""
  [[ "$CFG_SHOW_RUST" != "false" ]]      && block+=$'\n'"CATPPUCCIN_SHOW_RUST=\"$CFG_SHOW_RUST\""
  [[ "$CFG_SHOW_GO" != "false" ]]        && block+=$'\n'"CATPPUCCIN_SHOW_GO=\"$CFG_SHOW_GO\""
  [[ "$CFG_SHOW_RUBY" != "false" ]]      && block+=$'\n'"CATPPUCCIN_SHOW_RUBY=\"$CFG_SHOW_RUBY\""
  [[ "$CFG_SHOW_JAVA" != "false" ]]      && block+=$'\n'"CATPPUCCIN_SHOW_JAVA=\"$CFG_SHOW_JAVA\""
  [[ "$CFG_SHOW_PHP" != "false" ]]       && block+=$'\n'"CATPPUCCIN_SHOW_PHP=\"$CFG_SHOW_PHP\""
  [[ "$CFG_SHOW_K8S" != "false" ]]       && block+=$'\n'"CATPPUCCIN_SHOW_K8S=\"$CFG_SHOW_K8S\""
  [[ "$CFG_SHOW_JOBS" != "false" ]]      && block+=$'\n'"CATPPUCCIN_SHOW_JOBS=\"$CFG_SHOW_JOBS\""
  [[ "$CFG_SHOW_EXEC_TIME" != "false" ]] && block+=$'\n'"CATPPUCCIN_SHOW_EXEC_TIME=\"$CFG_SHOW_EXEC_TIME\""

  block+=$'\n'"# --- End Catppuccin Config ---"
  printf '%s' "$block"
}

remove_old_config_block() {
  local src="$1" dest="$2"
  # Strip any existing config block (inclusive of markers)
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

  # Replace ZSH_THEME and inject config block before `source $ZSH/oh-my-zsh.sh`
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Replace any existing ZSH_THEME= line
    if [[ "$line" =~ ^[[:space:]]*ZSH_THEME= ]]; then
      printf '%s\n' 'ZSH_THEME="catppuccin"' >> "$tmpfile"
      continue
    fi

    # Inject config block just before the oh-my-zsh source line
    if ! $injected && [[ "$line" =~ source[[:space:]].*oh-my-zsh\.sh ]]; then
      printf '%s\n\n' "$config_block" >> "$tmpfile"
      injected=true
    fi

    printf '%s\n' "$line" >> "$tmpfile"
  done < "$file"

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
  CFG_LAYOUT="${CATPPUCCIN_LAYOUT:-oneline}"
  CFG_SEPARATOR="${CATPPUCCIN_SEPARATOR:-space}"

  # Detect custom separator (not a known preset)
  case "$CFG_SEPARATOR" in
    space|arrow|bar|dot|powerline) ;;
    *) CFG_SEPARATOR_CUSTOM="$CFG_SEPARATOR" ;;
  esac

  CFG_SHOW_TIME="${CATPPUCCIN_SHOW_TIME:-false}"
  CFG_SHOW_VENV="${CATPPUCCIN_SHOW_VENV:-true}"
  CFG_SHOW_PYTHON="${CATPPUCCIN_SHOW_PYTHON:-false}"
  CFG_SHOW_NODE="${CATPPUCCIN_SHOW_NODE:-false}"
  CFG_SHOW_RUST="${CATPPUCCIN_SHOW_RUST:-false}"
  CFG_SHOW_GO="${CATPPUCCIN_SHOW_GO:-false}"
  CFG_SHOW_RUBY="${CATPPUCCIN_SHOW_RUBY:-false}"
  CFG_SHOW_JAVA="${CATPPUCCIN_SHOW_JAVA:-false}"
  CFG_SHOW_PHP="${CATPPUCCIN_SHOW_PHP:-false}"
  CFG_SHOW_K8S="${CATPPUCCIN_SHOW_K8S:-false}"
  CFG_SHOW_JOBS="${CATPPUCCIN_SHOW_JOBS:-false}"
  CFG_SHOW_EXEC_TIME="${CATPPUCCIN_SHOW_EXEC_TIME:-false}"
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
    prompt "Remove Catppuccin theme? (y/N)" "N"
    local answer
    read -r answer
    case "${answer:-N}" in
      [Yy]*) ;;
      *)     warn "Aborted."; exit 0 ;;
    esac
  fi

  uninstall_theme_files "$symlink_path"
  uninstall_patch_zshrc
  offer_backup_restore

  printf "\n"
  success "Catppuccin has been removed."
  info "Run: source ~/.zshrc"
}

uninstall_theme_files() {
  local symlink_path="$1"

  if [[ -d "$THEME_DIR" ]]; then
    info "Removing theme directory: $THEME_DIR"
    rm -rf "$THEME_DIR"
    success "Theme directory removed."
  fi

  if [[ -L "$symlink_path" ]]; then
    info "Removing symlink: $symlink_path"
    rm -f "$symlink_path"
    success "Symlink removed."
  fi
}

uninstall_patch_zshrc() {
  if [[ ! -f "$ZSHRC" ]]; then
    return 0
  fi

  local backup_path
  backup_path="${ZSHRC}.catppuccin-uninstall.$(date +%s)"
  cp "$ZSHRC" "$backup_path"
  info "Backup saved: $backup_path"

  local tmpfile
  tmpfile="$(mktemp)"

  # Remove config block
  remove_old_config_block "$ZSHRC" "$tmpfile"

  # Reset ZSH_THEME to default
  local tmpfile2
  tmpfile2="$(mktemp)"
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^[[:space:]]*ZSH_THEME=\"catppuccin\" ]]; then
      printf '%s\n' 'ZSH_THEME="robbyrussell"' >> "$tmpfile2"
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

  # Find most recent catppuccin backup
  local latest_backup=""
  local candidate
  for candidate in "${ZSHRC}.catppuccin-backup."*; do
    [[ -f "$candidate" ]] && latest_backup="$candidate"
  done

  if [[ -z "$latest_backup" ]]; then
    return 0
  fi

  printf "\n"
  info "Found installation backup: $latest_backup"
  prompt "Restore .zshrc from this backup? (y/N)" "N"
  local answer
  read -r answer
  case "${answer:-N}" in
    [Yy]*)
      cp "$latest_backup" "$ZSHRC"
      success "Restored .zshrc from backup."
      ;;
    *) info "Keeping current .zshrc." ;;
  esac
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

print_summary() {
  printf "\n"
  printf "${CLR_GREEN}${CLR_BOLD}"
  printf "  Installation complete!\n"
  printf "${CLR_RESET}\n"

  printf "    ${CLR_SUBTEXT}Theme:${CLR_RESET}     catppuccin (%s)\n" "$CFG_FLAVOR"
  printf "    ${CLR_SUBTEXT}Layout:${CLR_RESET}    %s\n" "$CFG_LAYOUT"
  printf "    ${CLR_SUBTEXT}Separator:${CLR_RESET} %s\n" "$CFG_SEPARATOR"
  printf "    ${CLR_SUBTEXT}Installed:${CLR_RESET} %s\n" "$THEME_DIR"

  if [[ -n "${BACKUP_PATH:-}" ]]; then
    printf "    ${CLR_SUBTEXT}Backup:${CLR_RESET}    %s\n" "$BACKUP_PATH"
  fi

  printf "\n"
  printf "  ${CLR_TEXT}To activate, run:${CLR_RESET}\n"
  printf "    ${CLR_TEAL}source ~/.zshrc${CLR_RESET}\n"
  printf "\n"
  printf "  ${CLR_TEXT}To uninstall later:${CLR_RESET}\n"
  printf "    ${CLR_TEAL}bash %s --uninstall${CLR_RESET}\n" "$THEME_DIR/install.sh"
  printf "  ${CLR_DIM}or${CLR_RESET}\n"
  printf "    ${CLR_TEAL}sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/Xerrion/catppuccin-oh-my-zsh/main/install.sh)\" -- --uninstall${CLR_RESET}\n"
  printf "\n"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
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
    info "Non-interactive install with flavor=$CFG_FLAVOR layout=$CFG_LAYOUT separator=$CFG_SEPARATOR"
  else
    wizard_welcome
    wizard_flavor
    wizard_layout
    wizard_separator
    wizard_segments
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
