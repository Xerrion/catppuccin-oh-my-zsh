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

INSTALLER_VERSION="2.2.0"
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

# Safe file replacement: copies tmpfile over target, preserving original permissions,
# then removes the tmpfile.
safe_replace() {
  local src="$1" dst="$2"
  if [[ -f "$dst" ]]; then
    # Preserve original permissions by copying content, then removing temp
    cp "$src" "$dst"
    rm -f "$src"
  else
    mv "$src" "$dst"
  fi
}

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

# Save incoming env vars before we overwrite them with script defaults
_ENV_KEEP_ZSHRC="${KEEP_ZSHRC:-}"

NON_INTERACTIVE=false
DO_UNINSTALL=false
DO_HELP=false
KEEP_ZSHRC=false

# Config values
CFG_FLAVOR="mocha"
CFG_MODE="preset"              # preset | custom
CFG_PRESET="none"
CFG_PL_SEPARATOR=""
# Custom mode values
CFG_STYLE=""
CFG_LAYOUT=""
CFG_SEGMENTS=""
CFG_RSEGMENTS=""
CFG_TRANSIENT=""

# Resolved paths (set by preflight_checks)
THEME_DIR=""
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
BACKUP_PATH=""

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
  printf "  CATPPUCCIN_FLAVOR            mocha|frappe|macchiato|latte   (default: mocha)\n"
  printf "  CATPPUCCIN_PRESET            none|minimal|classic|powerline|rainbow|p10k  (default: none)\n"
  printf "  CATPPUCCIN_PL_SEPARATOR      arrow|round|thin|slash|angly|flames|pixels|blocks  (default: arrow)\n"
  printf "  KEEP_ZSHRC                   yes  (skip .zshrc modification)\n\n"
  printf "Custom configuration (instead of preset):\n"
  printf "  CATPPUCCIN_STYLE             plain|powerline|rainbow\n"
  printf "  CATPPUCCIN_LAYOUT            oneline|twoline\n"
  printf "  CATPPUCCIN_SEGMENTS          Space-separated left segment names\n"
  printf "  CATPPUCCIN_RSEGMENTS         Space-separated right segment names\n"
  printf "  CATPPUCCIN_TRANSIENT_PROMPT  true|false\n\n"
  printf "  Setting any of STYLE/LAYOUT/SEGMENTS enables custom mode (PRESET is ignored).\n\n"
  printf "Examples:\n"
  printf "  # One-liner install with defaults\n"
  printf "  zsh -c \"\$(curl -fsSL https://raw.githubusercontent.com/Xerrion/catppuccin-oh-my-zsh/main/install.sh)\"\n\n"
  printf "  # Non-interactive with Frappe flavor and powerline preset\n"
  printf "  CATPPUCCIN_FLAVOR=frappe CATPPUCCIN_PRESET=powerline zsh install.sh --non-interactive\n\n"
  printf "  # Non-interactive with custom configuration\n"
  printf "  CATPPUCCIN_FLAVOR=mocha CATPPUCCIN_STYLE=powerline CATPPUCCIN_LAYOUT=twoline \\\\\n"
  printf "    CATPPUCCIN_SEGMENTS=\"os_icon cwd git\" CATPPUCCIN_RSEGMENTS=\"status time\" \\\\\n"
  printf "    CATPPUCCIN_TRANSIENT_PROMPT=true zsh install.sh --non-interactive\n"
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
  step "Step 1 - Choose a flavor"

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
# Wizard Step 2: Configuration mode
# ---------------------------------------------------------------------------

wizard_mode() {
  step "Step 2 - How do you want to configure?"

  printf "    %s1)%s  Choose from a preset %s(recommended)%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_DIM" "$CLR_RESET"
  printf "       %sPick a ready-made configuration. Quick and easy.%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  printf "\n"

  printf "    %s2)%s  Configure yourself%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
  printf "       %sWalk through style, layout, segments, and more.%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  printf "\n"

  ask_key "Mode" "12q"
  [[ "$ASK_RESULT" == "q" ]] && { warn "Aborted."; exit 0; }

  case "$ASK_RESULT" in
    1) CFG_MODE="preset" ;;
    2) CFG_MODE="custom" ;;
  esac

  success "Mode: $CFG_MODE"
}

# ---------------------------------------------------------------------------
# Wizard Step 2a (preset path): Preset
# ---------------------------------------------------------------------------

wizard_preset() {
  step "Step 3 - Choose a preset"

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
# Wizard Step 2b: Separator shape (only for powerline/rainbow presets)
# ---------------------------------------------------------------------------

# Helper: returns true if the current config uses powerline/rainbow style
_uses_powerline_style() {
  if [[ "$CFG_MODE" == "preset" ]]; then
    case "$CFG_PRESET" in
      powerline|rainbow|p10k) return 0 ;;
      *)                      return 1 ;;
    esac
  else
    case "$CFG_STYLE" in
      powerline|rainbow) return 0 ;;
      *)                 return 1 ;;
    esac
  fi
}

# Helper: determine total wizard steps based on mode and style
_wizard_total_steps() {
  if [[ "$CFG_MODE" == "preset" ]]; then
    # Flavor, Mode, Preset, [Separator], Confirm
    if _uses_powerline_style; then
      echo "5"
    else
      echo "4"
    fi
  else
    # Flavor, Mode, Style, Layout, Segments, [Separator], Transient, Confirm
    if _uses_powerline_style; then
      echo "8"
    else
      echo "7"
    fi
  fi
}

# Nerd Font glyphs for separator previews
_SEP_ARROW_L=$'\ue0b0'
_SEP_ARROW_R=$'\ue0b2'
_SEP_ROUND_L=$'\ue0b4'
_SEP_ROUND_R=$'\ue0b6'
_SEP_THIN_L=$'\ue0b1'
_SEP_THIN_R=$'\ue0b3'
_SEP_SLASH_L=$'\ue0bc'
_SEP_SLASH_R=$'\ue0be'
_SEP_ANGLY_L=$'\ue0b8'
_SEP_ANGLY_R=$'\ue0ba'
_SEP_FLAMES_L=$'\ue0c0'
_SEP_FLAMES_R=$'\ue0c2'
_SEP_PIXELS_L=$'\ue0c6'
_SEP_PIXELS_R=$'\ue0c6'
_SEP_BLOCKS_L=$'\ue0ce'
_SEP_BLOCKS_R=$'\ue0d0'

# Preview a separator shape with colored mock segments
separator_preview() {
  local label="$1" sep_l="$2" sep_r="$3"
  printf "       "
  # Left side: [blue segment] separator [teal segment] closing
  printf "$(_bg 137 180 250)$(_fg 17 17 27) ~/dev $(_rs)"
  printf "$(_fg 137 180 250)$(_bg 148 226 213)${sep_l}$(_rs)"
  printf "$(_bg 148 226 213)$(_fg 17 17 27) ${_PV_GIT} main $(_rs)"
  printf "$(_fg 148 226 213)${sep_l}$(_rs)"
  # gap
  printf "  "
  # Right side: separator [yellow segment]
  printf "$(_fg 249 226 175)${sep_r}$(_rs)"
  printf "$(_bg 249 226 175)$(_fg 17 17 27) 12:34 $(_rs)"
  printf "\n"
}

wizard_separator() {
  local total="$(_wizard_total_steps)"
  local sep_step
  if [[ "$CFG_MODE" == "preset" ]]; then
    sep_step="4"
  else
    sep_step="6"
  fi
  step "Step ${sep_step}/${total} - Choose separator shape"

  printf "  %sControls the glyph between colored segments.%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  printf "  %sRequires a Nerd Font for proper display.%s\n\n" "$CLR_SUBTEXT" "$CLR_RESET"

  printf "    %s1)%s  Arrow %s(default)%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_DIM" "$CLR_RESET"
  separator_preview "arrow" "$_SEP_ARROW_L" "$_SEP_ARROW_R"
  printf "\n"

  printf "    %s2)%s  Round%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
  separator_preview "round" "$_SEP_ROUND_L" "$_SEP_ROUND_R"
  printf "\n"

  printf "    %s3)%s  Thin%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
  separator_preview "thin" "$_SEP_THIN_L" "$_SEP_THIN_R"
  printf "\n"

  printf "    %s4)%s  Slash%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
  separator_preview "slash" "$_SEP_SLASH_L" "$_SEP_SLASH_R"
  printf "\n"

  printf "    %s5)%s  Angly%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
  separator_preview "angly" "$_SEP_ANGLY_L" "$_SEP_ANGLY_R"
  printf "\n"

  printf "    %s6)%s  Flames%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
  separator_preview "flames" "$_SEP_FLAMES_L" "$_SEP_FLAMES_R"
  printf "\n"

  printf "    %s7)%s  Pixels%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
  separator_preview "pixels" "$_SEP_PIXELS_L" "$_SEP_PIXELS_R"
  printf "\n"

  printf "    %s8)%s  Blocks%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
  separator_preview "blocks" "$_SEP_BLOCKS_L" "$_SEP_BLOCKS_R"
  printf "\n"

  ask_key "Separator" "12345678q"
  [[ "$ASK_RESULT" == "q" ]] && { warn "Aborted."; exit 0; }

  case "$ASK_RESULT" in
    1) CFG_PL_SEPARATOR="arrow" ;;
    2) CFG_PL_SEPARATOR="round" ;;
    3) CFG_PL_SEPARATOR="thin" ;;
    4) CFG_PL_SEPARATOR="slash" ;;
    5) CFG_PL_SEPARATOR="angly" ;;
    6) CFG_PL_SEPARATOR="flames" ;;
    7) CFG_PL_SEPARATOR="pixels" ;;
    8) CFG_PL_SEPARATOR="blocks" ;;
  esac

  success "Separator: $CFG_PL_SEPARATOR"
}

# ---------------------------------------------------------------------------
# Custom path: Step 3 - Style
# ---------------------------------------------------------------------------

wizard_style() {
  local total="$(_wizard_total_steps)"
  step "Step 3/${total} - Choose a style"

  printf "  %sThis controls how segments are rendered.%s\n\n" "$CLR_SUBTEXT" "$CLR_RESET"

  printf "    %s1)%s  Plain%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
  printf "       %sText-only segments separated by characters.%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  # Plain preview
  printf "       "
  printf "%s>%s %s~/projects%s %s%s main %s*%s" \
    "$CLR_GREEN" "$CLR_RESET" "$CLR_BLUE" "$CLR_RESET" \
    "$CLR_TEAL" "$_PV_GIT" "$CLR_GREEN" "$CLR_RESET"
  printf "\n\n"

  printf "    %s2)%s  Powerline%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
  printf "       %sColored backgrounds with arrow separators. Needs a Nerd Font.%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  # Powerline preview
  printf "       "
  printf "$(_bg 137 180 250)$(_fg 17 17 27) ~/projects $(_rs)"
  printf "$(_fg 137 180 250)$(_bg 148 226 213)${_PV_PL}$(_rs)"
  printf "$(_bg 148 226 213)$(_fg 17 17 27) ${_PV_GIT} main $(_rs)"
  printf "$(_fg 148 226 213)${_PV_PL}$(_rs)"
  printf "\n\n"

  printf "    %s3)%s  Rainbow%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
  printf "       %sEvery segment has a unique vibrant background. Maximum flair.%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  # Rainbow preview
  printf "       "
  printf "$(_bg 137 180 250)$(_fg 17 17 27) ${_PV_LINUX} $(_rs)"
  printf "$(_fg 137 180 250)$(_bg 203 166 247)${_PV_PL}$(_rs)"
  printf "$(_bg 203 166 247)$(_fg 17 17 27) user $(_rs)"
  printf "$(_fg 203 166 247)$(_bg 116 199 236)${_PV_PL}$(_rs)"
  printf "$(_bg 116 199 236)$(_fg 17 17 27) ~/dev $(_rs)"
  printf "$(_fg 116 199 236)$(_bg 148 226 213)${_PV_PL}$(_rs)"
  printf "$(_bg 148 226 213)$(_fg 17 17 27) ${_PV_GIT} main $(_rs)"
  printf "$(_fg 148 226 213)${_PV_PL}$(_rs)"
  printf "\n\n"

  ask_key "Style" "123q"
  [[ "$ASK_RESULT" == "q" ]] && { warn "Aborted."; exit 0; }

  case "$ASK_RESULT" in
    1) CFG_STYLE="plain" ;;
    2) CFG_STYLE="powerline" ;;
    3) CFG_STYLE="rainbow" ;;
  esac

  success "Style: $CFG_STYLE"
}

# ---------------------------------------------------------------------------
# Custom path: Step 4 - Layout
# ---------------------------------------------------------------------------

wizard_layout() {
  local total="$(_wizard_total_steps)"
  step "Step 4/${total} - Choose a layout"

  printf "    %s1)%s  One line%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
  printf "       %sPrompt and input on the same line.%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  # Oneline preview
  printf "       "
  printf "%s>%s %s~/projects%s %s%s main%s %s\$ %s" \
    "$CLR_GREEN" "$CLR_RESET" "$CLR_BLUE" "$CLR_RESET" \
    "$CLR_TEAL" "$_PV_GIT" "$CLR_RESET" "$CLR_TEXT" "$CLR_RESET"
  printf "\n\n"

  printf "    %s2)%s  Two lines %s(recommended)%s\n" "$CLR_MAUVE" "$CLR_TEXT" "$CLR_DIM" "$CLR_RESET"
  printf "       %sInfo on line 1, input on line 2. More space for segments.%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  # Twoline preview
  printf "       "
  printf "%s>%s %s~/projects%s %s%s main%s\n" \
    "$CLR_GREEN" "$CLR_RESET" "$CLR_BLUE" "$CLR_RESET" \
    "$CLR_TEAL" "$_PV_GIT" "$CLR_RESET"
  printf "       %s❯%s " "$CLR_GREEN" "$CLR_RESET"
  printf "\n\n"

  ask_key "Layout" "12q"
  [[ "$ASK_RESULT" == "q" ]] && { warn "Aborted."; exit 0; }

  case "$ASK_RESULT" in
    1) CFG_LAYOUT="oneline" ;;
    2) CFG_LAYOUT="twoline" ;;
  esac

  success "Layout: $CFG_LAYOUT"
}

# ---------------------------------------------------------------------------
# Custom path: Step 5 - Segments
# ---------------------------------------------------------------------------

# Segment definitions: name, label, description, default on/off
# We group left and right segments separately
_SEGMENT_DEFS_LEFT=(
  "os_icon:OS Icon:Distro/OS icon:off"
  "arrow:Arrow:Colored arrow (status indicator):on"
  "user:User:Current username:on"
  "host:Host:Hostname (ssh-only by default):off"
  "cwd:Directory:Current working directory:on"
  "git:Git:Branch, dirty status, stash:on"
  "venv:Python venv:Active virtualenv name:on"
)

_SEGMENT_DEFS_RIGHT=(
  "status:Status:Exit code of last command:off"
  "exec_time:Exec Time:Duration of long-running commands:off"
  "python:Python:Python version:off"
  "node:Node.js:Node version:off"
  "rust:Rust:Rust version:off"
  "go:Go:Go version:off"
  "ruby:Ruby:Ruby version:off"
  "java:Java:Java version:off"
  "php:PHP:PHP version:off"
  "k8s:Kubernetes:Current k8s context:off"
  "jobs:Jobs:Background job count:off"
  "time:Time:Current time:off"
)

wizard_segments() {
  local total="$(_wizard_total_steps)"
  step "Step 5/${total} - Choose segments"

  printf "  %sToggle segments on/off. Press a key to toggle, Enter to confirm.%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  printf "  %sLeft segments appear in the prompt, right segments in RPROMPT.%s\n\n" "$CLR_SUBTEXT" "$CLR_RESET"

  # Initialize toggle arrays
  # Left segments
  local -A left_on
  local left_keys=()
  local idx=0
  local entry name label desc default_state
  for entry in "${_SEGMENT_DEFS_LEFT[@]}"; do
    name="${entry%%:*}"
    local rest="${entry#*:}"
    label="${rest%%:*}"
    rest="${rest#*:}"
    desc="${rest%%:*}"
    default_state="${rest##*:}"
    left_keys+=("$name")
    if [[ "$default_state" == "on" ]]; then
      left_on[$name]=1
    else
      left_on[$name]=0
    fi
  done

  # Right segments
  local -A right_on
  local right_keys=()
  for entry in "${_SEGMENT_DEFS_RIGHT[@]}"; do
    name="${entry%%:*}"
    local rest="${entry#*:}"
    label="${rest%%:*}"
    rest="${rest#*:}"
    desc="${rest%%:*}"
    default_state="${rest##*:}"
    right_keys+=("$name")
    if [[ "$default_state" == "on" ]]; then
      right_on[$name]=1
    else
      right_on[$name]=0
    fi
  done

  # Key mapping for toggles: a-g for left, h-s for right (skip q, used for quit)
  local all_keys="abcdefghijklmnoprstuvwx"
  local key_chars=(a b c d e f g h i j k l m n o p r s t)

  _draw_segments_ui() {
    # Clear: move up enough lines and redraw (simpler: just redraw each time)
    printf "\r"

    printf "  %s%sLeft prompt:%s\n" "$CLR_TEXT" "$CLR_BOLD" "$CLR_RESET"
    local i=0
    for entry in "${_SEGMENT_DEFS_LEFT[@]}"; do
      name="${entry%%:*}"
      local rest="${entry#*:}"
      label="${rest%%:*}"
      rest="${rest#*:}"
      desc="${rest%%:*}"
      local k="${key_chars[$((i+1))]}"
      local state_icon state_clr
      if (( left_on[$name] )); then
        state_icon="[x]"
        state_clr="$CLR_GREEN"
      else
        state_icon="[ ]"
        state_clr="$CLR_OVERLAY"
      fi
      printf "    %s%s)%s %s%s%s %-14s %s%s%s\n" \
        "$CLR_MAUVE" "$k" "$CLR_RESET" \
        "$state_clr" "$state_icon" "$CLR_RESET" \
        "$label" "$CLR_SUBTEXT" "$desc" "$CLR_RESET"
      (( i++ ))
    done

    printf "\n  %s%sRight prompt (RPROMPT):%s\n" "$CLR_TEXT" "$CLR_BOLD" "$CLR_RESET"
    for entry in "${_SEGMENT_DEFS_RIGHT[@]}"; do
      name="${entry%%:*}"
      local rest="${entry#*:}"
      label="${rest%%:*}"
      rest="${rest#*:}"
      desc="${rest%%:*}"
      local k="${key_chars[$((i+1))]}"
      local state_icon state_clr
      if (( right_on[$name] )); then
        state_icon="[x]"
        state_clr="$CLR_GREEN"
      else
        state_icon="[ ]"
        state_clr="$CLR_OVERLAY"
      fi
      printf "    %s%s)%s %s%s%s %-14s %s%s%s\n" \
        "$CLR_MAUVE" "$k" "$CLR_RESET" \
        "$state_clr" "$state_icon" "$CLR_RESET" \
        "$label" "$CLR_SUBTEXT" "$desc" "$CLR_RESET"
      (( i++ ))
    done
    printf "\n"
  }

  # Total lines: header(1) + left(7) + blank(1) + header(1) + right(12) + blank(1) = 23
  local ui_lines=$(( ${#_SEGMENT_DEFS_LEFT[@]} + ${#_SEGMENT_DEFS_RIGHT[@]} + 4 ))

  # Initial draw
  _draw_segments_ui

  # Toggle loop
  while true; do
    printf "%s  > %sPress a letter to toggle, Enter to confirm, q to quit:%s " "$CLR_MAUVE" "$CLR_TEXT" "$CLR_RESET"
    local key
    key="$(read_key)"
    key="${(L)key}"

    if [[ -z "$key" || "$key" == $'\n' || "$key" == $'\r' ]]; then
      # Validate: at least one left segment must be enabled
      local _any_left=false
      for name in "${left_keys[@]}"; do
        (( left_on[$name] )) && { _any_left=true; break; }
      done
      if ! $_any_left; then
        warn "  You must enable at least one left segment."
        printf "\033[1A\033[2K"  # clear the warning after next keypress
        continue
      fi
      break
    fi
    if [[ "$key" == "q" ]]; then
      warn "Aborted."
      exit 0
    fi

    # Find which segment this key maps to
    local ki=0
    local found=false
    for entry in "${_SEGMENT_DEFS_LEFT[@]}"; do
      if [[ "${key_chars[$((ki+1))]}" == "$key" ]]; then
        name="${entry%%:*}"
        if (( left_on[$name] )); then
          left_on[$name]=0
        else
          left_on[$name]=1
        fi
        found=true
        break
      fi
      (( ki++ ))
    done

    if ! $found; then
      for entry in "${_SEGMENT_DEFS_RIGHT[@]}"; do
        if [[ "${key_chars[$((ki+1))]}" == "$key" ]]; then
          name="${entry%%:*}"
          if (( right_on[$name] )); then
            right_on[$name]=0
          else
            right_on[$name]=1
          fi
          found=true
          break
        fi
        (( ki++ ))
      done
    fi

    if $found; then
      # Move cursor up to redraw
      printf "\033[${ui_lines}A"
      _draw_segments_ui
    fi
  done

  # Build segment strings from toggled state
  CFG_SEGMENTS=""
  for name in "${left_keys[@]}"; do
    if (( left_on[$name] )); then
      CFG_SEGMENTS+="${CFG_SEGMENTS:+ }${name}"
    fi
  done

  CFG_RSEGMENTS=""
  for name in "${right_keys[@]}"; do
    if (( right_on[$name] )); then
      CFG_RSEGMENTS+="${CFG_RSEGMENTS:+ }${name}"
    fi
  done

  success "Left:  ${CFG_SEGMENTS:-"(none)"}"
  success "Right: ${CFG_RSEGMENTS:-"(none)"}"
}

# ---------------------------------------------------------------------------
# Custom path: Step N-1 - Transient prompt
# ---------------------------------------------------------------------------

wizard_transient() {
  local total="$(_wizard_total_steps)"
  local trans_step
  if _uses_powerline_style; then
    trans_step="7"
  else
    trans_step="6"
  fi
  step "Step ${trans_step}/${total} - Transient prompt"

  printf "  %sWhen enabled, previous prompts collapse to a minimal arrow after%s\n" "$CLR_SUBTEXT" "$CLR_RESET"
  printf "  %syou run a command. Keeps your terminal clean.%s\n\n" "$CLR_SUBTEXT" "$CLR_RESET"

  printf "  %s%sWith transient prompt:%s\n" "$CLR_TEXT" "$CLR_BOLD" "$CLR_RESET"
  printf "    %s>%s ls\n" "$CLR_GREEN" "$CLR_RESET"
  printf "    %s>%s git status\n" "$CLR_GREEN" "$CLR_RESET"
  printf "    %s~/projects%s %s%s main%s\n" "$CLR_BLUE" "$CLR_RESET" "$CLR_TEAL" "$_PV_GIT" "$CLR_RESET"
  printf "    %s❯%s \n\n" "$CLR_GREEN" "$CLR_RESET"

  printf "  %s%sWithout transient prompt:%s\n" "$CLR_TEXT" "$CLR_BOLD" "$CLR_RESET"
  printf "    %s~/projects%s %s%s main%s\n" "$CLR_BLUE" "$CLR_RESET" "$CLR_TEAL" "$_PV_GIT" "$CLR_RESET"
  printf "    %s❯%s ls\n" "$CLR_GREEN" "$CLR_RESET"
  printf "    %s~/projects%s %s%s main%s\n" "$CLR_BLUE" "$CLR_RESET" "$CLR_TEAL" "$_PV_GIT" "$CLR_RESET"
  printf "    %s❯%s git status\n" "$CLR_GREEN" "$CLR_RESET"
  printf "    %s~/projects%s %s%s main%s\n" "$CLR_BLUE" "$CLR_RESET" "$CLR_TEAL" "$_PV_GIT" "$CLR_RESET"
  printf "    %s❯%s \n\n" "$CLR_GREEN" "$CLR_RESET"

  if ask_yn "Enable transient prompt?" "y"; then
    CFG_TRANSIENT="true"
  else
    CFG_TRANSIENT="false"
  fi

  success "Transient prompt: $CFG_TRANSIENT"
}

# ---------------------------------------------------------------------------
# Wizard: Confirmation with .zshrc preview
# ---------------------------------------------------------------------------

wizard_confirm() {
  local total="$(_wizard_total_steps)"
  step "Step ${total}/${total} - Review and confirm"

  local config_block
  config_block="$(build_config_block)"

  printf "  %s%sConfiguration:%s\n" "$CLR_TEXT" "$CLR_BOLD" "$CLR_RESET"
  printf "    %sFlavor:%s      %s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CFG_FLAVOR"
  if [[ "$CFG_MODE" == "preset" ]]; then
    printf "    %sPreset:%s      %s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CFG_PRESET"
    if [[ -n "$CFG_PL_SEPARATOR" ]] && _uses_powerline_style; then
      printf "    %sSeparator:%s   %s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CFG_PL_SEPARATOR"
    fi
  else
    printf "    %sStyle:%s       %s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CFG_STYLE"
    printf "    %sLayout:%s      %s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CFG_LAYOUT"
    printf "    %sLeft:%s        %s\n" "$CLR_SUBTEXT" "$CLR_RESET" "${CFG_SEGMENTS:-"(none)"}"
    printf "    %sRight:%s       %s\n" "$CLR_SUBTEXT" "$CLR_RESET" "${CFG_RSEGMENTS:-"(none)"}"
    if _uses_powerline_style && [[ -n "$CFG_PL_SEPARATOR" ]]; then
      printf "    %sSeparator:%s   %s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CFG_PL_SEPARATOR"
    fi
    printf "    %sTransient:%s   %s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CFG_TRANSIENT"
  fi
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

  if [[ "$CFG_MODE" == "preset" ]]; then
    # Preset mode: emit preset name
    [[ "$CFG_PRESET" != "none" ]] && block+=$'\n'"CATPPUCCIN_PRESET=\"$CFG_PRESET\""

    # Powerline separator (only when not default "arrow" and preset uses powerline)
    if [[ -n "$CFG_PL_SEPARATOR" && "$CFG_PL_SEPARATOR" != "arrow" ]]; then
      block+=$'\n'"CATPPUCCIN_PL_SEPARATOR=\"$CFG_PL_SEPARATOR\""
    fi
  else
    # Custom mode: emit individual settings
    [[ -n "$CFG_STYLE" && "$CFG_STYLE" != "plain" ]] && \
      block+=$'\n'"CATPPUCCIN_STYLE=\"$CFG_STYLE\""

    [[ -n "$CFG_LAYOUT" && "$CFG_LAYOUT" != "oneline" ]] && \
      block+=$'\n'"CATPPUCCIN_LAYOUT=\"$CFG_LAYOUT\""

    # Segments (always emit in custom mode to be explicit, even if empty)
    block+=$'\n'"CATPPUCCIN_SEGMENTS=\"$CFG_SEGMENTS\""
    block+=$'\n'"CATPPUCCIN_RSEGMENTS=\"$CFG_RSEGMENTS\""

    # Build CATPPUCCIN_SHOW_* toggles from segments
    local all_segs="os_icon arrow status prompt_char user host cwd git time venv python node rust go ruby java php k8s jobs exec_time"
    local enabled_segs=" ${CFG_SEGMENTS} ${CFG_RSEGMENTS} "
    local seg
    for seg in ${(z)all_segs}; do
      local show_val="false"
      if [[ "$enabled_segs" == *" ${seg} "* ]]; then
        show_val="true"
      fi
      local var_name="CATPPUCCIN_SHOW_${(U)seg}"
      # Only emit if different from default
      case "$seg" in
        arrow|prompt_char|user|cwd|git|venv)
          # These default to "true" (or "ssh" for host)
          [[ "$show_val" == "false" ]] && block+=$'\n'"${var_name}=\"false\""
          ;;
        host)
          # host defaults to "ssh", we simplify: if in segments list, set to "always"
          if [[ "$enabled_segs" == *" host "* ]]; then
            block+=$'\n'"CATPPUCCIN_SHOW_HOST=\"always\""
          fi
          ;;
        *)
          # Everything else defaults to "false"
          [[ "$show_val" == "true" ]] && block+=$'\n'"${var_name}=\"true\""
          ;;
      esac
    done

    # Powerline separator
    if [[ -n "$CFG_PL_SEPARATOR" && "$CFG_PL_SEPARATOR" != "arrow" ]]; then
      block+=$'\n'"CATPPUCCIN_PL_SEPARATOR=\"$CFG_PL_SEPARATOR\""
    fi

    # Transient prompt
    if [[ "$CFG_TRANSIENT" == "true" ]]; then
      block+=$'\n'"CATPPUCCIN_TRANSIENT_PROMPT=\"true\""
    fi
  fi

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
    done || {
      error "Failed to clone repository. Check your network connection and try again."
      exit 1
    }
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

  safe_replace "$tmpfile" "$ZSHRC"
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

  # If ZSH_THEME was never set (no existing line AND no source line to inject before),
  # prepend it to the config block area at the end of the file
  if ! $theme_replaced; then
    local tmpfile3
    tmpfile3="$(mktemp)"
    # Check if ZSH_THEME="catppuccin" was already added by the second pass
    if ! grep -q '^ZSH_THEME="catppuccin"' "$tmpfile" 2>/dev/null; then
      # Add it just before the config block sentinel or at the end
      local found_sentinel=false
      while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "# --- Catppuccin Theme Config ---" ]] && ! $found_sentinel; then
          printf 'ZSH_THEME="catppuccin"\n\n' >> "$tmpfile3"
          found_sentinel=true
        fi
        printf '%s\n' "$line" >> "$tmpfile3"
      done < "$tmpfile"
      if ! $found_sentinel; then
        printf '\nZSH_THEME="catppuccin"\n' >> "$tmpfile3"
      fi
      rm -f "$tmpfile"
      tmpfile="$tmpfile3"
    else
      rm -f "$tmpfile3"
    fi
  fi

  safe_replace "$tmpfile" "$file"
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

  # Determine mode: if style/layout/segments are set, use custom mode
  CFG_STYLE="${CATPPUCCIN_STYLE:-}"
  CFG_LAYOUT="${CATPPUCCIN_LAYOUT:-}"
  CFG_SEGMENTS="${CATPPUCCIN_SEGMENTS:-}"
  CFG_RSEGMENTS="${CATPPUCCIN_RSEGMENTS:-}"
  CFG_TRANSIENT="${CATPPUCCIN_TRANSIENT_PROMPT:-false}"

  if [[ -n "$CFG_STYLE" || -n "$CFG_LAYOUT" || -n "$CFG_SEGMENTS" ]]; then
    CFG_MODE="custom"
    # Apply defaults for custom mode when not specified
    : ${CFG_STYLE:="plain"}
    : ${CFG_LAYOUT:="oneline"}
    : ${CFG_SEGMENTS:="arrow user cwd git venv"}
    case "$CFG_STYLE" in
      plain|powerline|rainbow) ;;
      *) warn "Unknown style '$CFG_STYLE', using plain."; CFG_STYLE="plain" ;;
    esac
    case "$CFG_LAYOUT" in
      oneline|twoline) ;;
      *) warn "Unknown layout '$CFG_LAYOUT', using oneline."; CFG_LAYOUT="oneline" ;;
    esac
    case "$CFG_TRANSIENT" in
      true|false) ;;
      *) warn "Unknown transient value '$CFG_TRANSIENT', using false."; CFG_TRANSIENT="false" ;;
    esac
  else
    CFG_MODE="preset"
  fi

  # Powerline separator (relevant for powerline/rainbow)
  CFG_PL_SEPARATOR="${CATPPUCCIN_PL_SEPARATOR:-arrow}"
  case "$CFG_PL_SEPARATOR" in
    arrow|round|thin|slash|angly|flames|pixels|blocks) ;;
    *) warn "Unknown separator '$CFG_PL_SEPARATOR', using arrow."; CFG_PL_SEPARATOR="arrow" ;;
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

  safe_replace "$tmpfile2" "$ZSHRC"
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
    for candidate in "${ZSHRC}.pre-catppuccin"*(N); do
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
  if [[ "$CFG_MODE" == "preset" ]]; then
    if [[ "$CFG_PRESET" != "none" ]]; then
      printf "    %sPreset:%s    %s%s%s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CLR_TEXT" "$CFG_PRESET" "$CLR_RESET"
    fi
  else
    printf "    %sStyle:%s     %s%s%s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CLR_TEXT" "$CFG_STYLE" "$CLR_RESET"
    printf "    %sLayout:%s    %s%s%s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CLR_TEXT" "$CFG_LAYOUT" "$CLR_RESET"
  fi
  if [[ -n "$CFG_PL_SEPARATOR" && "$CFG_PL_SEPARATOR" != "arrow" ]]; then
    printf "    %sSeparator:%s %s%s%s\n" "$CLR_SUBTEXT" "$CLR_RESET" "$CLR_TEXT" "$CFG_PL_SEPARATOR" "$CLR_RESET"
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
    if [[ "$CFG_MODE" == "preset" && "$CFG_PRESET" != "none" ]]; then
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
    local _ni_msg="Non-interactive install: flavor=$CFG_FLAVOR"
    if [[ "$CFG_MODE" == "preset" ]]; then
      _ni_msg+=" preset=$CFG_PRESET"
    else
      _ni_msg+=" style=$CFG_STYLE layout=$CFG_LAYOUT"
    fi
    if [[ -n "$CFG_PL_SEPARATOR" && "$CFG_PL_SEPARATOR" != "arrow" ]]; then
      _ni_msg+=" separator=$CFG_PL_SEPARATOR"
    fi
    info "$_ni_msg"
  else
    wizard_welcome
    wizard_flavor
    wizard_mode

    if [[ "$CFG_MODE" == "preset" ]]; then
      # Preset path: Preset -> [Separator] -> Confirm
      wizard_preset
      if _uses_powerline_style; then
        wizard_separator
      fi
    else
      # Custom path: Style -> Layout -> Segments -> [Separator] -> Transient -> Confirm
      wizard_style
      wizard_layout
      wizard_segments
      if _uses_powerline_style; then
        wizard_separator
      fi
      wizard_transient
    fi

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
