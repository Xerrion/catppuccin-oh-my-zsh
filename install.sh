#!/usr/bin/env zsh
# Catppuccin for Oh My Zsh - Install / Configure / Uninstall
# https://github.com/Xerrion/catppuccin-oh-my-zsh
#
# Requires zsh (which is guaranteed since this installs an Oh My Zsh theme).
#
# Usage:
#   zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Xerrion/catppuccin-oh-my-zsh/main/install.sh)"
#   zsh install.sh --non-interactive
#   zsh install.sh --uninstall
#   zsh install.sh --keep-zshrc
#
setopt ERR_EXIT NO_UNSET PIPE_FAIL

INSTALLER_VERSION="2.1.0"
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
    CLR_ROSEWATER=$'\033[38;2;245;224;220m'
    CLR_FLAMINGO=$'\033[38;2;242;205;205m'
    CLR_PINK=$'\033[38;2;245;194;231m'
    CLR_MAUVE=$'\033[38;2;203;166;247m'
    CLR_RED=$'\033[38;2;243;139;168m'
    CLR_MAROON=$'\033[38;2;235;160;172m'
    CLR_PEACH=$'\033[38;2;250;179;135m'
    CLR_YELLOW=$'\033[38;2;249;226;175m'
    CLR_GREEN=$'\033[38;2;166;227;161m'
    CLR_TEAL=$'\033[38;2;148;226;213m'
    CLR_SKY=$'\033[38;2;137;220;235m'
    CLR_SAPPHIRE=$'\033[38;2;116;199;236m'
    CLR_BLUE=$'\033[38;2;137;180;250m'
    CLR_LAVENDER=$'\033[38;2;180;190;254m'
    CLR_TEXT=$'\033[38;2;205;214;244m'
    CLR_SUBTEXT=$'\033[38;2;166;173;200m'
    CLR_OVERLAY=$'\033[38;2;108;112;134m'
    CLR_SURFACE=$'\033[38;2;69;71;90m'
    CLR_BOLD=$'\033[1m'
    CLR_DIM=$'\033[2m'
    CLR_RESET=$'\033[0m'
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
  printf "%s  info%s  %s\n" "$CLR_BLUE" "$CLR_RESET" "$*"
}

warn() {
  printf "%s  warn%s  %s\n" "$CLR_YELLOW" "$CLR_RESET" "$*"
}

error() {
  printf "%s error%s  %s\n" "$CLR_RED" "$CLR_RESET" "$*" >&2
}

success() {
  printf "%s    ok%s  %s\n" "$CLR_GREEN" "$CLR_RESET" "$*"
}

step() {
  printf "\n%s%s  %s%s\n\n" "$CLR_MAUVE" "$CLR_BOLD" "$*" "$CLR_RESET"
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
read_key() {
  local key=""
  if is_tty; then
    # zsh native single-character read (no stty hack needed)
    read -k 1 key 2>/dev/null || true
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
    printf "%s  > %s%s [%s%s%s]:%s " "$CLR_MAUVE" "$CLR_TEXT" "$prompt_text" "$CLR_SUBTEXT" "$valid_chars" "$CLR_TEXT" "$CLR_RESET"
    local key
    key="$(read_key)"
    key="${(L)key}"

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

  printf "%s  > %s%s %s[%s]:%s " "$CLR_MAUVE" "$CLR_TEXT" "$prompt_text" "$CLR_SUBTEXT" "$hint" "$CLR_RESET"
  local key
  key="$(read_key)"
  key="${(L)key}"

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

# Save incoming env vars before we overwrite them with script defaults
_ENV_KEEP_ZSHRC="${KEEP_ZSHRC:-}"

# ---------------------------------------------------------------------------
# CLI argument parsing
# ---------------------------------------------------------------------------

parse_args() {
  local arg
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
  printf "%sCatppuccin for Oh My Zsh - Installer v%s%s\n\n" "$CLR_TEXT" "$INSTALLER_VERSION" "$CLR_RESET"
  printf "Usage:\n"
  printf "  zsh install.sh                    Interactive wizard\n"
  printf "  zsh install.sh --non-interactive  Install with env-var config\n"
  printf "  zsh install.sh --uninstall        Remove theme\n"
  printf "  zsh install.sh --keep-zshrc       Install files but don't modify .zshrc\n"
  printf "  zsh install.sh --help             Show this message\n\n"
  printf "Environment variables (--non-interactive):\n"
  printf "  CATPPUCCIN_FLAVOR   mocha|frappe|macchiato|latte   (default: mocha)\n"
  printf "  CATPPUCCIN_PRESET   none|minimal|classic|powerline|rainbow|p10k  (default: none)\n"
  printf "  KEEP_ZSHRC          yes  (skip .zshrc modification)\n\n"
  printf "Examples:\n"
  printf "  # One-liner install with defaults\n"
  printf "  zsh -c \"\$(curl -fsSL https://raw.githubusercontent.com/Xerrion/catppuccin-oh-my-zsh/main/install.sh)\"\n\n"
  printf "  # Non-interactive with Frappe flavor and powerline preset\n"
  printf "  CATPPUCCIN_FLAVOR=frappe CATPPUCCIN_PRESET=powerline zsh install.sh --non-interactive\n"
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
      printf "    %s%s%s\n" "$CLR_DIM" "$line" "$CLR_RESET"
    done || {
      warn "git pull failed, will remove and re-clone."
      rm -rf "$THEME_DIR"
    }
    return 0
  fi

  printf "  %sWhat would you like to do?%s\n" "$CLR_TEXT" "$CLR_RESET"
  printf "    %s1)%s Update %s(git pull)%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_SUBTEXT" "$CLR_RESET"
  printf "    %s2)%s Reinstall %s(remove and re-clone)%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_SUBTEXT" "$CLR_RESET"
  printf "    %sq)%s Quit%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"

  ask_key "Choice" "12q"

  case "$ASK_RESULT" in
    1)
      info "Updating via git pull..."
      git -C "$THEME_DIR" pull --ff-only 2>&1 | while IFS= read -r line; do
        printf "    %s%s%s\n" "$CLR_DIM" "$line" "$CLR_RESET"
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
  printf "%s%s" "$CLR_LAVENDER" "$CLR_BOLD"
  printf "      /\\_/\\ \n"
  printf "     ( o.o )  %sCatppuccin for Oh My Zsh%s\n" "$CLR_ROSEWATER" "$CLR_LAVENDER"
  printf "      > ^ <   %sv%s%s\n" "$CLR_SUBTEXT" "$INSTALLER_VERSION" "$CLR_LAVENDER"
  printf "%s" "$CLR_RESET"
  printf "%s      -------%s\n" "$CLR_OVERLAY" "$CLR_RESET"
  printf "\n"
  printf "  %sThis wizard will guide you through installation.%s\n" "$CLR_TEXT" "$CLR_RESET"
  printf "  %sPress%s q %sat any prompt to quit.%s\n" "$CLR_SUBTEXT" "$CLR_TEXT" "$CLR_SUBTEXT" "$CLR_RESET"
}

# ---------------------------------------------------------------------------
# Wizard Step 1: Flavor
# ---------------------------------------------------------------------------

wizard_flavor() {
  step "Step 1/3 - Choose a flavor"

  # Show flavor options with color swatches
  printf "    %s1)%s  " "$CLR_MAUVE" "$CLR_RESET"
  printf "\033[38;2;220;224;232m Latte \033[0m"
  printf "      %sLight background%s\n" "$CLR_SUBTEXT" "$CLR_RESET"

  printf "    %s2)%s  " "$CLR_MAUVE" "$CLR_RESET"
  printf "\033[38;2;198;208;245m Frappe \033[0m"
  printf "     %sMedium-dark%s\n" "$CLR_SUBTEXT" "$CLR_RESET"

  printf "    %s3)%s  " "$CLR_MAUVE" "$CLR_RESET"
  printf "\033[38;2;202;211;245m Macchiato \033[0m"
  printf "  %sDark%s\n" "$CLR_SUBTEXT" "$CLR_RESET"

  printf "    %s4)%s  " "$CLR_MAUVE" "$CLR_RESET"
  printf "\033[38;2;205;214;244m Mocha \033[0m"
  printf "      %sDarkest %s(default)%s\n" "$CLR_SUBTEXT" "$CLR_DIM" "$CLR_RESET"

  printf "\n"

  # Show a prompt preview in each flavor
  printf "  %sPreview:%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  flavor_preview "latte"     "\033[38;2;64;160;43m"  "\033[38;2;30;102;245m"  "\033[38;2;23;146;153m"
  flavor_preview "frappe"    "\033[38;2;166;209;137m" "\033[38;2;140;170;238m" "\033[38;2;129;200;190m"
  flavor_preview "macchiato" "\033[38;2;166;218;149m" "\033[38;2;138;173;244m" "\033[38;2;139;213;202m"
  flavor_preview "mocha"     "\033[38;2;166;227;161m" "\033[38;2;137;180;250m" "\033[38;2;148;226;213m"
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
  local name="$1" green="$2" blue="$3" teal="$4"
  local git_icon=$'\ue0a0'
  printf "    %s%-10s%s " "$CLR_DIM" "$name" "$CLR_RESET"
  printf "${green}>${CLR_RESET} ${blue}~/projects${CLR_RESET} ${teal}${git_icon} main${CLR_RESET}\n"
}

# ---------------------------------------------------------------------------
# Wizard Step 2: Preset
# ---------------------------------------------------------------------------

wizard_preset() {
  step "Step 2/3 - Choose a preset"

  printf "  %sPresets configure layout, style, segments, and more in one step.%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  printf "  %sYou can customize individual settings later in .zshrc.%s\n\n" "$CLR_SUBTEXT" "$CLR_RESET"

  # Preset options with inline previews
  printf "    %s1)%s  Minimal%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
  printf "       %sOne-line, clean. Just the essentials.%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  preset_preview_minimal
  printf "\n"

  printf "    %s2)%s  Classic%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
  printf "       %sTwo-line with user, host, directory, git. Traditional feel.%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  preset_preview_classic
  printf "\n"

  printf "    %s3)%s  Powerline %s(recommended)%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_DIM" "$CLR_RESET"
  printf "       %sColored backgrounds with powerline arrows. Transient prompt.%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  preset_preview_powerline
  printf "\n"

  printf "    %s4)%s  Rainbow%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
  printf "       %sEvery segment has a unique color. Maximum flair.%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  preset_preview_rainbow
  printf "\n"

  printf "    %s5)%s  p10k%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
  printf "       %sClosest match to Powerlevel10k. Great for p10k migrants.%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  preset_preview_p10k
  printf "\n"

  printf "    %s6)%s  None %s(defaults only, configure manually)%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_SUBTEXT" "$CLR_RESET"
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
#
# Color reference (Mocha RGB):
#   crust:    17,17,27     blue:     137,180,250   teal:     148,226,213
#   surface1: 69,71,90     text:     205,214,244   green:    166,227,161
#   mauve:    203,166,247  sapphire: 116,199,236   yellow:   249,226,175
#   pink:     245,194,231  peach:    250,179,135   lavender: 180,190,254

# Nerd Font glyphs
_PV_PL=$'\ue0b0'       # powerline left separator
_PV_PLR=$'\ue0b2'      # powerline right separator
_PV_GIT=$'\ue0a0'      # git branch icon
_PV_LINUX=$'\uf17c'    # linux penguin (os_icon)
_PV_PYTHON=$'\ue73c'   # python icon
_PV_CHECK=$'\uf00c'    # check mark
_PV_CLOCK=$'\uf017'    # clock / exec_time

# ANSI helpers - fg=38;2, bg=48;2 (truecolor)
_fg() { printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3"; }
_bg() { printf '\033[48;2;%s;%s;%sm' "$1" "$2" "$3"; }
_rs() { printf '\033[0m'; }

preset_preview_minimal() {
  printf "       %s>%s %s~/projects%s %s%s main %s*%s\n" \
    "$CLR_GREEN" "$CLR_RESET" "$CLR_BLUE" "$CLR_RESET" "$CLR_TEAL" "$_PV_GIT" "$CLR_GREEN" "$CLR_RESET"
}

preset_preview_classic() {
  printf "       %suser%s %s%s %s~/projects%s %s%s %s%s main %s*%s    %s|%s %s%s%s %s%s 2s%s %s12:34%s\n" \
    "$CLR_PINK" "$CLR_RESET" "$CLR_OVERLAY" "·" "$CLR_BLUE" "$CLR_RESET" "$CLR_OVERLAY" "·" \
    "$CLR_TEAL" "$_PV_GIT" "$CLR_GREEN" "$CLR_RESET" "$CLR_OVERLAY" "$CLR_RESET" \
    "$CLR_GREEN" "$_PV_CHECK" "$CLR_RESET" "$CLR_YELLOW" "$_PV_CLOCK" "$CLR_RESET" "$CLR_MAUVE" "$CLR_RESET"
  printf "       %s>%s \n" "$CLR_GREEN" "$CLR_RESET"
}

preset_preview_powerline() {
  # Left: [os_icon on blue][cwd on blue][git on teal]
  printf "       "
  # os_icon segment (blue bg, dark text)
  printf "$(_bg 137 180 250)$(_fg 17 17 27) ${_PV_LINUX} $(_rs)"
  # transition: same bg for os_icon->cwd (both blue) — separator invisible
  printf "$(_fg 137 180 250)$(_bg 137 180 250)${_PV_PL}$(_fg 17 17 27) ~/projects $(_rs)"
  # transition: blue->teal
  printf "$(_fg 137 180 250)$(_bg 148 226 213)${_PV_PL}$(_rs)"
  # git segment (teal bg, dark text)
  printf "$(_bg 148 226 213)$(_fg 17 17 27) ${_PV_GIT} main * $(_rs)"
  # closing separator (teal on default)
  printf "$(_fg 148 226 213)${_PV_PL}$(_rs)"
  # gap
  printf "       "
  # Right: [status on surface1][time on lavender]
  # first right segment — separator fg=segment bg, no bg (default)
  printf "$(_fg 69 71 90)${_PV_PLR}$(_rs)"
  printf "$(_bg 69 71 90)$(_fg 205 214 244) ${_PV_CHECK} $(_rs)"
  # transition: surface1->lavender — separator fg=lavender, bg=surface1
  printf "$(_fg 180 190 254)$(_bg 69 71 90)${_PV_PLR}$(_rs)"
  printf "$(_bg 180 190 254)$(_fg 17 17 27) 12:34 $(_rs)"
  printf "\n"
  printf "       %s>%s \n" "$CLR_GREEN" "$CLR_RESET"
}

preset_preview_rainbow() {
  # Left: [os_icon on blue][user on mauve][cwd on sapphire][git on teal]
  printf "       "
  printf "$(_bg 137 180 250)$(_fg 17 17 27) ${_PV_LINUX} $(_rs)"
  printf "$(_fg 137 180 250)$(_bg 203 166 247)${_PV_PL}$(_rs)"
  printf "$(_bg 203 166 247)$(_fg 17 17 27) user $(_rs)"
  printf "$(_fg 203 166 247)$(_bg 116 199 236)${_PV_PL}$(_rs)"
  printf "$(_bg 116 199 236)$(_fg 17 17 27) ~/dev $(_rs)"
  printf "$(_fg 116 199 236)$(_bg 148 226 213)${_PV_PL}$(_rs)"
  printf "$(_bg 148 226 213)$(_fg 17 17 27) ${_PV_GIT} main $(_rs)"
  printf "$(_fg 148 226 213)${_PV_PL}$(_rs)"
  # gap
  printf "  "
  # Right: [python on yellow][exec_time on green]
  # first right segment
  printf "$(_fg 249 226 175)${_PV_PLR}$(_rs)"
  printf "$(_bg 249 226 175)$(_fg 17 17 27) ${_PV_PYTHON} 3.12 $(_rs)"
  # transition: yellow->green
  printf "$(_fg 166 227 161)$(_bg 249 226 175)${_PV_PLR}$(_rs)"
  printf "$(_bg 166 227 161)$(_fg 17 17 27) ${_PV_CLOCK} 4s $(_rs)"
  printf "\n"
  printf "       %s>%s \n" "$CLR_GREEN" "$CLR_RESET"
}

preset_preview_p10k() {
  # Left: [os_icon on blue][cwd on blue][git on teal]
  printf "       "
  printf "$(_bg 137 180 250)$(_fg 17 17 27) ${_PV_LINUX} $(_rs)"
  printf "$(_fg 137 180 250)$(_bg 137 180 250)${_PV_PL}$(_fg 17 17 27) ~/projects $(_rs)"
  printf "$(_fg 137 180 250)$(_bg 148 226 213)${_PV_PL}$(_rs)"
  printf "$(_bg 148 226 213)$(_fg 17 17 27) ${_PV_GIT} main * $(_rs)"
  printf "$(_fg 148 226 213)${_PV_PL}$(_rs)"
  # gap
  printf "     "
  # Right: [status on surface1][python on yellow][time on surface1]
  # first right segment
  printf "$(_fg 69 71 90)${_PV_PLR}$(_rs)"
  printf "$(_bg 69 71 90)$(_fg 205 214 244) ${_PV_CHECK} $(_rs)"
  # transition: surface1->yellow
  printf "$(_fg 249 226 175)$(_bg 69 71 90)${_PV_PLR}$(_rs)"
  printf "$(_bg 249 226 175)$(_fg 17 17 27) ${_PV_PYTHON} 3.12 $(_rs)"
  # transition: yellow->surface1
  printf "$(_fg 69 71 90)$(_bg 249 226 175)${_PV_PLR}$(_rs)"
  printf "$(_bg 69 71 90)$(_fg 205 214 244) 12:34 $(_rs)"
  printf "\n"
  printf "       %s>%s \n" "$CLR_GREEN" "$CLR_RESET"
}

# ---------------------------------------------------------------------------
# Wizard Step 3: Confirmation with .zshrc preview
# ---------------------------------------------------------------------------

wizard_confirm() {
  step "Step 3/3 - Review and confirm"

  local config_block
  config_block="$(build_config_block)"

  printf "  %s%sConfiguration:%s\n" "$CLR_TEXT" "$CLR_BOLD" "$CLR_RESET"
  printf "    %sFlavor:%s  %s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CFG_FLAVOR"
  printf "    %sPreset:%s  %s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CFG_PRESET"
  printf "\n"

  printf "  %s%sFiles:%s\n" "$CLR_TEXT" "$CLR_BOLD" "$CLR_RESET"
  printf "    %sTheme:%s   %s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$THEME_DIR"
  printf "    %sConfig:%s  %s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$ZSHRC"
  printf "\n"

  if ! $KEEP_ZSHRC && [[ -f "$ZSHRC" ]]; then
    # Detect current theme
    local current_theme
    current_theme="$(detect_current_theme)"
    if [[ -n "$current_theme" && "$current_theme" != "catppuccin" ]]; then
      printf "  %s%sChanges to .zshrc:%s\n" "$CLR_TEXT" "$CLR_BOLD" "$CLR_RESET"
      printf "    %s- ZSH_THEME=\"%s\"%s\n" "$CLR_RED" "$current_theme" "$CLR_RESET"
      printf "    %s+ ZSH_THEME=\"catppuccin\"%s\n" "$CLR_GREEN" "$CLR_RESET"
      printf "\n"
    fi

    printf "  %s%sConfig block to add:%s\n" "$CLR_TEXT" "$CLR_BOLD" "$CLR_RESET"
    local cline
    while IFS= read -r cline; do
      printf "    %s+ %s%s\n" "$CLR_GREEN" "$cline" "$CLR_RESET"
    done <<< "$config_block"
    printf "\n"

    printf "  %sA backup of .zshrc will be created before any changes.%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
    printf "\n"
  elif $KEEP_ZSHRC; then
    printf "  %s.zshrc will not be modified (--keep-zshrc).%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
    printf "  %sYou will need to set ZSH_THEME=\"catppuccin\" manually.%s\n\n" "$CLR_SUBTEXT" "$CLR_RESET"
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
      printf "    %s%s%s\n" "$CLR_DIM" "$line" "$CLR_RESET"
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

  # Support KEEP_ZSHRC=yes from environment (saved before parse_args ran)
  if [[ "$_ENV_KEEP_ZSHRC" == "yes" ]]; then
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
  printf "%s%s  Catppuccin for Oh My Zsh - Uninstaller%s\n\n" "$CLR_MAUVE" "$CLR_BOLD" "$CLR_RESET"

  if [[ ! -d "$THEME_DIR" && ! -L "$symlink_path" ]]; then
    warn "No installation found. Nothing to do."
    exit 0
  fi

  if ! $NON_INTERACTIVE; then
    printf "  %sThis will:%s\n" "$CLR_TEXT" "$CLR_RESET"
    [[ -d "$THEME_DIR" ]]   && printf "    %s- Remove %s%s\n" "$CLR_RED" "$THEME_DIR" "$CLR_RESET"
    [[ -L "$symlink_path" ]] && printf "    %s- Remove symlink %s%s\n" "$CLR_RED" "$symlink_path" "$CLR_RESET"
    [[ -f "$ZSHRC" ]]       && printf "    %s- Remove Catppuccin config from .zshrc%s\n" "$CLR_RED" "$CLR_RESET"
    [[ -f "$ZSHRC" ]]       && printf "    %s- Reset ZSH_THEME to \"robbyrussell\"%s\n" "$CLR_YELLOW" "$CLR_RESET"
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

  # Find the original pre-catppuccin backup (prefer the one without timestamp)
  local best_backup=""
  local candidate
  if [[ -f "${ZSHRC}.pre-catppuccin" ]]; then
    best_backup="${ZSHRC}.pre-catppuccin"
  else
    for candidate in "${ZSHRC}.pre-catppuccin"*; do
      [[ -f "$candidate" ]] && best_backup="$candidate"
    done
  fi

  if [[ -z "$best_backup" ]]; then
    return 0
  fi

  printf "\n"
  info "Found pre-installation backup: $best_backup"
  if ask_yn "Restore .zshrc from this backup?" "n"; then
    cp "$best_backup" "$ZSHRC"
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
  printf "  %s%sInstallation complete!%s\n" "$CLR_GREEN" "$CLR_BOLD" "$CLR_RESET"
  printf "\n"
  printf "    %sFlavor:%s    %s%s%s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CLR_TEXT" "$CFG_FLAVOR" "$CLR_RESET"
  if [[ "$CFG_PRESET" != "none" ]]; then
    printf "    %sPreset:%s    %s%s%s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CLR_TEXT" "$CFG_PRESET" "$CLR_RESET"
  fi
  printf "    %sInstalled:%s %s%s%s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CLR_TEXT" "$THEME_DIR" "$CLR_RESET"

  if [[ -n "${BACKUP_PATH:-}" ]]; then
    printf "    %sBackup:%s    %s%s%s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CLR_TEXT" "$BACKUP_PATH" "$CLR_RESET"
  fi

  printf "\n"
  printf "  %sTo activate:%s\n" "$CLR_TEXT" "$CLR_RESET"
  printf "    %ssource ~/.zshrc%s\n" "$CLR_TEAL" "$CLR_RESET"
  printf "\n"

  if $KEEP_ZSHRC; then
    printf "  %sRemember to add to your .zshrc:%s\n" "$CLR_YELLOW" "$CLR_RESET"
    printf "    %sZSH_THEME=\"catppuccin\"%s\n" "$CLR_TEAL" "$CLR_RESET"
    if [[ "$CFG_PRESET" != "none" ]]; then
      printf "    %sCATPPUCCIN_PRESET=\"%s\"%s\n" "$CLR_TEAL" "$CFG_PRESET" "$CLR_RESET"

    fi
    printf "\n"
  fi

  printf "  %sCustomize further:%s %sSee README.md or edit .zshrc%s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CLR_TEXT" "$CLR_RESET"
  printf "  %sUninstall:%s         %szsh %s --uninstall%s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CLR_TEXT" "$THEME_DIR/install.sh" "$CLR_RESET"
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
