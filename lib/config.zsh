# Catppuccin for Oh My Zsh - Configuration Defaults
# All settings use ${VAR:=default} so user values set before sourcing are preserved.

# --- Flavor ---
# Options: mocha, frappe, macchiato, latte
: ${CATPPUCCIN_FLAVOR:="mocha"}

# --- Layout ---
# Options: oneline, twoline
: ${CATPPUCCIN_LAYOUT:="oneline"}

# --- Separator ---
# Preset names: arrow, bar, dot, space, powerline, chevron, round, slash
# Any other value is used as a literal separator string.
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

# --- Segment Toggles ---
: ${CATPPUCCIN_SHOW_ARROW:="true"}
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
# Override CATPPUCCIN_SEGMENTS to reorder, remove, or add segments.
: ${CATPPUCCIN_SEGMENTS:="arrow user host cwd git venv python node rust go ruby java php k8s jobs exec_time time"}

# --- Color Overrides ---
# Values are palette color NAMES (e.g. green, pink, mauve), not hex codes.
# Arrow
: ${CATPPUCCIN_COLOR_ARROW_OK:="green"}
: ${CATPPUCCIN_COLOR_ARROW_ERR:="red"}
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
# Separator
: ${CATPPUCCIN_COLOR_SEPARATOR:="overlay0"}

# --- Extra Options ---
: ${CATPPUCCIN_CWD_TRUNCATE:="1"}          # number of dirs to show (0=full path)
: ${CATPPUCCIN_TIME_FORMAT:="HH:MM"}       # HH:MM or HH:MM:SS
: ${CATPPUCCIN_EXEC_TIME_MIN:="2"}         # minimum seconds before showing exec time
: ${CATPPUCCIN_GIT_SHOW_STASH:="false"}
: ${CATPPUCCIN_GIT_SHOW_AHEAD_BEHIND:="true"}
