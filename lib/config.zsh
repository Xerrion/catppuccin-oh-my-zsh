# Catppuccin for Oh My Zsh - Configuration Defaults
# All settings use ${VAR:=default} so user values set before sourcing are preserved.

# --- Preset ---
# Load a predefined configuration preset before applying user overrides.
# Options: none, minimal, classic, powerline, rainbow, p10k
# Set to "none" to use only your manual configuration.
: ${CATPPUCCIN_PRESET:="none"}

# Apply preset if requested (presets set defaults, user overrides still win)
local _ctp_config_dir="${0:A:h}"
if [[ "$CATPPUCCIN_PRESET" != "none" ]]; then
  local _ctp_preset_file="${_ctp_config_dir}/presets/${CATPPUCCIN_PRESET}.zsh"
  if [[ -f "$_ctp_preset_file" ]]; then
    source "$_ctp_preset_file"
  else
    echo "catppuccin: unknown preset '${CATPPUCCIN_PRESET}', ignoring" >&2
  fi
fi

# --- Flavor ---
# Options: mocha, frappe, macchiato, latte
: ${CATPPUCCIN_FLAVOR:="mocha"}

# --- Layout ---
# Options: oneline, twoline
: ${CATPPUCCIN_LAYOUT:="twoline"}

# --- Style ---
# Controls how segments are rendered.
# Options: plain, powerline, rainbow
#   plain     - Text segments with configurable separator (classic look)
#   powerline - Colored background segments with powerline arrow separators
#   rainbow   - Each segment gets a unique background color (like p10k rainbow)
: ${CATPPUCCIN_STYLE:="plain"}

# --- Separator (plain style) ---
# Preset names or any literal string.
# Preset names: arrow, bar, dot, space, powerline, chevron, round, slash
: ${CATPPUCCIN_SEPARATOR:="space"}

typeset -gA _CTP_SEPARATOR_PRESETS=(
  [arrow]=" ❯ "
  [bar]=" | "
  [dot]=" · "
  [space]=" "
  [powerline]=$' \ue0b0 '
  [chevron]=$' \ue0b1 '
  [round]=$' \ue0b5 '
  [slash]=$' \ue0bd '
)

_ctp_resolve_separator() {
  local preset="${CATPPUCCIN_SEPARATOR}"
  if [[ -n "${_CTP_SEPARATOR_PRESETS[$preset]+set}" ]]; then
    echo "${_CTP_SEPARATOR_PRESETS[$preset]}"
  else
    echo "${preset}"
  fi
}

# --- Separator (powerline/rainbow style) ---
# Controls the glyph shape used between segments.
# Preset names: arrow, round, thin, slash
# Or set CATPPUCCIN_PL_SEPARATOR_LEFT / _RIGHT directly for custom glyphs.
: ${CATPPUCCIN_PL_SEPARATOR:="arrow"}

typeset -gA _CTP_PL_SEP_LEFT=(
  [arrow]=$'\ue0b0'
  [round]=$'\ue0b4'
  [thin]=$'\ue0b1'
  [slash]=$'\ue0bc'
)
typeset -gA _CTP_PL_SEP_RIGHT=(
  [arrow]=$'\ue0b2'
  [round]=$'\ue0b6'
  [thin]=$'\ue0b3'
  [slash]=$'\ue0be'
)

_ctp_resolve_pl_separator() {
  local preset="${CATPPUCCIN_PL_SEPARATOR}"
  # Left glyph
  if [[ -n "${CATPPUCCIN_PL_SEPARATOR_LEFT:-}" ]]; then
    _CTP_PL_LEFT="${CATPPUCCIN_PL_SEPARATOR_LEFT}"
  elif [[ -n "${_CTP_PL_SEP_LEFT[$preset]+set}" ]]; then
    _CTP_PL_LEFT="${_CTP_PL_SEP_LEFT[$preset]}"
  else
    _CTP_PL_LEFT=$'\ue0b0'  # fallback to arrow
  fi
  # Right glyph
  if [[ -n "${CATPPUCCIN_PL_SEPARATOR_RIGHT:-}" ]]; then
    _CTP_PL_RIGHT="${CATPPUCCIN_PL_SEPARATOR_RIGHT}"
  elif [[ -n "${_CTP_PL_SEP_RIGHT[$preset]+set}" ]]; then
    _CTP_PL_RIGHT="${_CTP_PL_SEP_RIGHT[$preset]}"
  else
    _CTP_PL_RIGHT=$'\ue0b2'  # fallback to arrow
  fi
}

# Resolve once at source time
_ctp_resolve_pl_separator

# --- Segment Toggles ---
: ${CATPPUCCIN_SHOW_OS_ICON:="false"}
: ${CATPPUCCIN_SHOW_ARROW:="true"}
: ${CATPPUCCIN_SHOW_STATUS:="false"}
: ${CATPPUCCIN_SHOW_PROMPT_CHAR:="true"}
: ${CATPPUCCIN_SHOW_USER:="true"}
: ${CATPPUCCIN_SHOW_HOST:="ssh"}           # never, always, ssh
: ${CATPPUCCIN_SHOW_CWD:="true"}
: ${CATPPUCCIN_SHOW_GIT:="true"}
: ${CATPPUCCIN_SHOW_TIME:="false"}
: ${CATPPUCCIN_SHOW_VENV:="true"}
: ${CATPPUCCIN_SHOW_PYTHON:="false"}
: ${CATPPUCCIN_SHOW_NODE:="false"}
: ${CATPPUCCIN_SHOW_RUST:="false"}
: ${CATPPUCCIN_SHOW_GO:="false"}
: ${CATPPUCCIN_SHOW_RUBY:="false"}
: ${CATPPUCCIN_SHOW_JAVA:="false"}
: ${CATPPUCCIN_SHOW_PHP:="false"}
: ${CATPPUCCIN_SHOW_K8S:="false"}
: ${CATPPUCCIN_SHOW_JOBS:="false"}
: ${CATPPUCCIN_SHOW_EXEC_TIME:="false"}

# --- Segment Ordering ---
# Left prompt segments (line 1 in twoline mode)
: ${CATPPUCCIN_SEGMENTS:="arrow user host cwd git venv python node rust go ruby java php k8s jobs exec_time time"}

# Right prompt segments (RPROMPT). Set to "" to disable RPROMPT entirely.
: ${CATPPUCCIN_RSEGMENTS:=""}

# --- Status Mode ---
# How the status segment displays: icon, code, both
: ${CATPPUCCIN_STATUS_MODE:="icon"}

# --- Prompt Char ---
# Character(s) used for the prompt_char segment (twoline line 2)
: ${CATPPUCCIN_PROMPT_CHAR:="❯"}

# --- Transient Prompt ---
# Collapse previous prompts to a minimal form after command execution.
# Options: true, false
: ${CATPPUCCIN_TRANSIENT_PROMPT:="false"}

# --- Color Overrides ---
# Values are palette color NAMES (e.g. green, pink, mauve), not hex codes.
# Arrow
: ${CATPPUCCIN_COLOR_ARROW_OK:="green"}
: ${CATPPUCCIN_COLOR_ARROW_ERR:="red"}
# OS Icon
: ${CATPPUCCIN_COLOR_OS_ICON:="blue"}
# Status
: ${CATPPUCCIN_COLOR_STATUS_OK:="green"}
: ${CATPPUCCIN_COLOR_STATUS_ERR:="red"}
# Prompt Char
: ${CATPPUCCIN_COLOR_PROMPT_CHAR_OK:="green"}
: ${CATPPUCCIN_COLOR_PROMPT_CHAR_ERR:="red"}
# Identity
: ${CATPPUCCIN_COLOR_USER:="pink"}
: ${CATPPUCCIN_COLOR_HOST:="sky"}
: ${CATPPUCCIN_COLOR_HOST_SSH:="mauve"}
# Path
: ${CATPPUCCIN_COLOR_CWD:="blue"}
# Git
: ${CATPPUCCIN_COLOR_GIT_BRANCH:="teal"}
: ${CATPPUCCIN_COLOR_GIT_DIRTY:="yellow"}
: ${CATPPUCCIN_COLOR_GIT_CLEAN:="green"}
# Time
: ${CATPPUCCIN_COLOR_TIME:="mauve"}
# Language / Tool Environments
: ${CATPPUCCIN_COLOR_VENV:="peach"}
: ${CATPPUCCIN_COLOR_PYTHON:="yellow"}
: ${CATPPUCCIN_COLOR_NODE:="green"}
: ${CATPPUCCIN_COLOR_RUST:="peach"}
: ${CATPPUCCIN_COLOR_GO:="sapphire"}
: ${CATPPUCCIN_COLOR_RUBY:="red"}
: ${CATPPUCCIN_COLOR_JAVA:="maroon"}
: ${CATPPUCCIN_COLOR_PHP:="lavender"}
# Infrastructure
: ${CATPPUCCIN_COLOR_K8S:="blue"}
: ${CATPPUCCIN_COLOR_JOBS:="flamingo"}
: ${CATPPUCCIN_COLOR_EXEC_TIME:="yellow"}
# Separator (plain style)
: ${CATPPUCCIN_COLOR_SEPARATOR:="overlay0"}

# --- Powerline / Rainbow Background Colors ---
# These define the background color for each segment in powerline/rainbow style.
# The foreground is auto-selected for contrast (crust for light bg, text for dark bg).
: ${CATPPUCCIN_BG_OS_ICON:="blue"}
: ${CATPPUCCIN_BG_ARROW:="surface1"}
: ${CATPPUCCIN_BG_STATUS:="surface1"}
: ${CATPPUCCIN_BG_USER:="mauve"}
: ${CATPPUCCIN_BG_HOST:="sky"}
: ${CATPPUCCIN_BG_CWD:="blue"}
: ${CATPPUCCIN_BG_GIT:="teal"}
: ${CATPPUCCIN_BG_TIME:="lavender"}
: ${CATPPUCCIN_BG_VENV:="peach"}
: ${CATPPUCCIN_BG_PYTHON:="yellow"}
: ${CATPPUCCIN_BG_NODE:="green"}
: ${CATPPUCCIN_BG_RUST:="peach"}
: ${CATPPUCCIN_BG_GO:="sapphire"}
: ${CATPPUCCIN_BG_RUBY:="red"}
: ${CATPPUCCIN_BG_JAVA:="maroon"}
: ${CATPPUCCIN_BG_PHP:="lavender"}
: ${CATPPUCCIN_BG_K8S:="blue"}
: ${CATPPUCCIN_BG_JOBS:="flamingo"}
: ${CATPPUCCIN_BG_EXEC_TIME:="yellow"}

# --- Extra Options ---
: ${CATPPUCCIN_CWD_TRUNCATE:="1"}          # number of dirs to show (0=full path)
: ${CATPPUCCIN_TIME_FORMAT:="HH:MM"}       # HH:MM or HH:MM:SS
: ${CATPPUCCIN_EXEC_TIME_MIN:="2"}         # minimum seconds before showing exec time
: ${CATPPUCCIN_GIT_SHOW_STASH:="false"}
: ${CATPPUCCIN_GIT_SHOW_AHEAD_BEHIND:="true"}
