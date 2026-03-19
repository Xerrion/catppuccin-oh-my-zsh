# Catppuccin Preset: powerline
# Powerline-style prompt with colored backgrounds and arrow separators.
# Two-line layout with OS icon, directory, git on line 1. Status and tools on the right.

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

: ${CATPPUCCIN_SEGMENTS:="os_icon cwd git venv"}
: ${CATPPUCCIN_RSEGMENTS:="status exec_time python node rust go jobs time"}

: ${CATPPUCCIN_TRANSIENT_PROMPT:="true"}
: ${CATPPUCCIN_CWD_TRUNCATE:="3"}
: ${CATPPUCCIN_STATUS_MODE:="code"}
: ${CATPPUCCIN_PROMPT_CHAR:="❯"}
