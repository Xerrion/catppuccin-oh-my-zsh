# Catppuccin for Oh My Zsh
# https://github.com/Xerrion/catppuccin-oh-my-zsh
#
# Soothing pastel theme for Oh My Zsh.
# See README.md for configuration options.

local _ctp_dir="${0:A:h}"

# Load configuration defaults (preserves user-set values)
source "${_ctp_dir}/lib/config.zsh"

# Load color system and flavor palette
source "${_ctp_dir}/lib/colors.zsh"

# Load segment functions
source "${_ctp_dir}/lib/segments.zsh"

# Build and set PROMPT
source "${_ctp_dir}/lib/prompt.zsh"
