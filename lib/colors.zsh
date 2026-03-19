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

# Resolve a CATPPUCCIN_BG_* variable to its hex color.
# Usage: _ctp_bg_color "CWD" -> "#89b4fa"
_ctp_bg_color() {
  local config_var="CATPPUCCIN_BG_${1}"
  local color_name="${(P)config_var}"
  _ctp_color "$color_name"
}

# Determine a high-contrast foreground for a given background color name.
# Light backgrounds get "crust" (dark), dark backgrounds get "crust" (dark) too
# since catppuccin accent colors are all light enough to need dark text.
# We use a simple luminance heuristic based on the palette position.
_ctp_contrast_fg() {
  local bg_name="$1"
  # Dark backgrounds: base, mantle, crust, surface0, surface1, surface2, overlay0, overlay1
  case "$bg_name" in
    base|mantle|crust|surface0|surface1|surface2|overlay0|overlay1)
      echo "$(_ctp_color "text")"
      ;;
    *)
      # Accent colors and light colors get dark foreground
      echo "$(_ctp_color "crust")"
      ;;
  esac
}
