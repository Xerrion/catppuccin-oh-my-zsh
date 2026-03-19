# Catppuccin for Oh My Zsh - Color System
# Loads flavor palette and provides color resolution functions.

# -- Load flavor palette --

local _ctp_root="${0:A:h:h}"
local _ctp_flavor_file="${_ctp_root}/catppuccin-flavors/catppuccin-${CATPPUCCIN_FLAVOR}.zsh"

if [[ -f "$_ctp_flavor_file" ]]; then
  source "$_ctp_flavor_file"
else
  echo "catppuccin: unknown flavor '${CATPPUCCIN_FLAVOR}', falling back to mocha" >&2
  source "${_ctp_root}/catppuccin-flavors/catppuccin-mocha.zsh"
fi

# -- Color resolution functions --

# Resolve a palette color name to its hex value.
# Usage: _ctp_color "pink" -> "#f5c2e7"
_ctp_color() {
  local varname="catppuccin_${1}"
  echo "${(P)varname}"
}

# Wrap a palette color name as a ZSH prompt foreground escape.
# Usage: _ctp_fg "pink" -> "%F{#f5c2e7}"
_ctp_fg() {
  echo "%F{$(_ctp_color "$1")}"
}

# Resolve a theme element config variable to its hex color.
# Bridges CATPPUCCIN_COLOR_* overrides (set in config.zsh) to hex values.
# Usage: _ctp_element_color "USER" -> resolves CATPPUCCIN_COLOR_USER -> "#f5c2e7"
_ctp_element_color() {
  local config_var="CATPPUCCIN_COLOR_${1}"
  local color_name="${(P)config_var}"
  _ctp_color "$color_name"
}

# Prompt-ready version of _ctp_element_color.
# Usage: _ctp_element_fg "USER" -> "%F{#f5c2e7}"
_ctp_element_fg() {
  echo "%F{$(_ctp_element_color "$1")}"
}
