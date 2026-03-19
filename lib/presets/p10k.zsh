# Catppuccin Preset: p10k
# Designed to closely match a Powerlevel10k setup with Catppuccin Mocha.
# Two-line powerline with os_icon + dir + vcs on line 1, prompt_char on line 2.
# Right side: status, exec_time, languages, jobs, time.
# Transient prompt enabled.

: ${CATPPUCCIN_LAYOUT:="twoline"}
: ${CATPPUCCIN_STYLE:="powerline"}
: ${CATPPUCCIN_SEPARATOR:="space"}

: ${CATPPUCCIN_SHOW_OS_ICON:="true"}
: ${CATPPUCCIN_SHOW_ARROW:="false"}
: ${CATPPUCCIN_SHOW_STATUS:="true"}
: ${CATPPUCCIN_SHOW_PROMPT_CHAR:="true"}
: ${CATPPUCCIN_SHOW_USER:="false"}
: ${CATPPUCCIN_SHOW_HOST:="ssh"}
: ${CATPPUCCIN_SHOW_CWD:="true"}
: ${CATPPUCCIN_SHOW_GIT:="true"}
: ${CATPPUCCIN_SHOW_TIME:="true"}
: ${CATPPUCCIN_SHOW_VENV:="true"}
: ${CATPPUCCIN_SHOW_PYTHON:="true"}
: ${CATPPUCCIN_SHOW_NODE:="true"}
: ${CATPPUCCIN_SHOW_RUST:="true"}
: ${CATPPUCCIN_SHOW_GO:="true"}
: ${CATPPUCCIN_SHOW_RUBY:="false"}
: ${CATPPUCCIN_SHOW_JAVA:="false"}
: ${CATPPUCCIN_SHOW_PHP:="false"}
: ${CATPPUCCIN_SHOW_K8S:="false"}
: ${CATPPUCCIN_SHOW_JOBS:="true"}
: ${CATPPUCCIN_SHOW_EXEC_TIME:="true"}

# Match p10k left: os_icon, dir, vcs
: ${CATPPUCCIN_SEGMENTS:="os_icon cwd git"}
# Match p10k right: status, exec_time, venv, languages, jobs, time
: ${CATPPUCCIN_RSEGMENTS:="status exec_time venv python node rust go jobs time"}

: ${CATPPUCCIN_TRANSIENT_PROMPT:="true"}
: ${CATPPUCCIN_CWD_TRUNCATE:="3"}
: ${CATPPUCCIN_STATUS_MODE:="code"}
: ${CATPPUCCIN_PROMPT_CHAR:="❯"}

# p10k-style background colors
: ${CATPPUCCIN_BG_OS_ICON:="blue"}
: ${CATPPUCCIN_BG_CWD:="blue"}
: ${CATPPUCCIN_BG_GIT:="teal"}
: ${CATPPUCCIN_BG_STATUS:="surface1"}
: ${CATPPUCCIN_BG_EXEC_TIME:="surface1"}
: ${CATPPUCCIN_BG_VENV:="surface1"}
: ${CATPPUCCIN_BG_PYTHON:="yellow"}
: ${CATPPUCCIN_BG_NODE:="green"}
: ${CATPPUCCIN_BG_RUST:="peach"}
: ${CATPPUCCIN_BG_GO:="sapphire"}
: ${CATPPUCCIN_BG_JOBS:="surface1"}
: ${CATPPUCCIN_BG_TIME:="surface1"}

# Prompt char colors (green on success, red on error like p10k)
: ${CATPPUCCIN_COLOR_PROMPT_CHAR_OK:="green"}
: ${CATPPUCCIN_COLOR_PROMPT_CHAR_ERR:="red"}
