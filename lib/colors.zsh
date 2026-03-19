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
# In dark flavors, accent backgrounds get dark fg (crust), neutral backgrounds get light fg (text).
# In Latte (light flavor), the palette is inverted: crust is light and text is dark,
# so we swap the roles to maintain readable contrast.
_ctp_contrast_fg() {
  local bg_name="$1"
  local dark_fg light_fg
  if [[ "$CATPPUCCIN_FLAVOR" == "latte" ]]; then
    dark_fg="text"    # #4c4f69 — darkest in Latte
    light_fg="crust"  # #dce0e8 — lightest in Latte
  else
    dark_fg="crust"   # very dark in mocha/frappe/macchiato
    light_fg="text"   # light in mocha/frappe/macchiato
  fi
  # Dark backgrounds: base, mantle, crust, surface0, surface1, surface2, overlay0, overlay1
  case "$bg_name" in
    base|mantle|crust|surface0|surface1|surface2|overlay0|overlay1)
      echo "$(_ctp_color "$light_fg")"
      ;;
    *)
      # Accent colors get the contrasting dark foreground
      echo "$(_ctp_color "$dark_fg")"
      ;;
  esac
}
