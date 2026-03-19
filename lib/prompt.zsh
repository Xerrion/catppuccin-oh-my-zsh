# Catppuccin for Oh My Zsh - Prompt Assembly
# Collects segment outputs, joins with separator, builds PROMPT and RPROMPT.
# Supports plain, powerline, and rainbow styles.

# Disable default virtualenv prompt (we handle it in segments)
export VIRTUAL_ENV_DISABLE_PROMPT=1

# --- Exec Time Hooks ---
if [[ "$CATPPUCCIN_SHOW_EXEC_TIME" == "true" ]]; then
  zmodload zsh/datetime 2>/dev/null  # provides $EPOCHSECONDS

  _ctp_preexec() {
    _CTP_CMD_START="$EPOCHSECONDS"
  }

  _ctp_precmd_exec_time() {
    if [[ -n "$_CTP_CMD_START" ]]; then
      _CTP_EXEC_DURATION=$(( EPOCHSECONDS - _CTP_CMD_START ))
      unset _CTP_CMD_START
    else
      unset _CTP_EXEC_DURATION
    fi
  }

  autoload -Uz add-zsh-hook
  add-zsh-hook preexec _ctp_preexec
  add-zsh-hook precmd _ctp_precmd_exec_time
fi

# --- Segment name to BG config key mapping ---
# Maps segment names to the uppercase key used for CATPPUCCIN_BG_*
typeset -gA _CTP_SEGMENT_BG_KEY=(
  [os_icon]="OS_ICON"
  [arrow]="ARROW"
  [status]="STATUS"
  [user]="USER"
  [host]="HOST"
  [cwd]="CWD"
  [git]="GIT"
  [time]="TIME"
  [venv]="VENV"
  [python]="PYTHON"
  [node]="NODE"
  [rust]="RUST"
  [go]="GO"
  [ruby]="RUBY"
  [java]="JAVA"
  [php]="PHP"
  [k8s]="K8S"
  [jobs]="JOBS"
  [exec_time]="EXEC_TIME"
)

# --- Prompt Templates (populated once at source time) ---
typeset -ga _CTP_LEFT_TEMPLATES=()
typeset -ga _CTP_LEFT_NAMES=()      # segment names parallel to templates
typeset -ga _CTP_RIGHT_TEMPLATES=()
typeset -ga _CTP_RIGHT_NAMES=()

# --- Build: collect segment templates (runs once) ---
_ctp_build_prompt() {
  _CTP_LEFT_TEMPLATES=()
  _CTP_LEFT_NAMES=()
  _CTP_RIGHT_TEMPLATES=()
  _CTP_RIGHT_NAMES=()

  local segment_names=(${(s: :)CATPPUCCIN_SEGMENTS})
  local name output

  for name in "${segment_names[@]}"; do
    # In twoline mode, skip arrow from left segments (prompt_char goes on line 2)
    if [[ "$CATPPUCCIN_LAYOUT" == "twoline" && "$name" == "arrow" ]]; then
      continue
    fi

    output="$(_ctp_segment_${name} 2>/dev/null)"
    if [[ -n "$output" ]]; then
      _CTP_LEFT_TEMPLATES+=("$output")
      _CTP_LEFT_NAMES+=("$name")
    fi
  done

  # Build right segments
  if [[ -n "$CATPPUCCIN_RSEGMENTS" ]]; then
    local rsegment_names=(${(s: :)CATPPUCCIN_RSEGMENTS})
    for name in "${rsegment_names[@]}"; do
      output="$(_ctp_segment_${name} 2>/dev/null)"
      if [[ -n "$output" ]]; then
        _CTP_RIGHT_TEMPLATES+=("$output")
        _CTP_RIGHT_NAMES+=("$name")
      fi
    done
  fi
}

# --- Plain Style: join segments with separator ---
_ctp_render_plain() {
  local -a templates=("${@}")
  local sep="$(_ctp_element_fg "SEPARATOR")$(_ctp_resolve_separator)%f"
  local segments=()
  local tpl rendered

  for tpl in "${templates[@]}"; do
    rendered="${(e)tpl}"
    if [[ -n "$rendered" ]]; then
      segments+=("$rendered")
    fi
  done

  echo "${(pj:$sep:)segments}"
}

# --- Powerline Style: segments with colored backgrounds and arrow separators ---

# Strip segment-level %F{...} and %f color codes so the powerline renderer
# can apply its own contrast foreground on the colored background.
_ctp_strip_fg() {
  setopt LOCAL_OPTIONS EXTENDED_GLOB
  local s="$1"
  # Remove %F{...} sequences (extended glob: [^\}]## = one-or-more non-})
  s="${s//\%F\{[^\}]##\}/}"
  # Remove standalone %f resets
  s="${s//\%f/}"
  echo "$s"
}

_ctp_render_powerline_left() {
  local -a templates=("${@[@]:2}")  # templates from arg 2 onward
  local -a names=("${(s: :)1}")     # names from arg 1

  local segments=()
  local prev_bg=""
  local idx=0

  for tpl in "${templates[@]}"; do
    (( idx++ ))
    local rendered="${(e)tpl}"
    [[ -z "$rendered" ]] && continue

    local seg_name="${names[$idx]}"
    local bg_key="${_CTP_SEGMENT_BG_KEY[$seg_name]:-ARROW}"
    local bg_var="CATPPUCCIN_BG_${bg_key}"
    local bg_name="${(P)bg_var}"
    local bg_hex="$(_ctp_color "$bg_name")"
    local fg_hex="$(_ctp_contrast_fg "$bg_name")"

    # Strip segment's own fg colors — powerline uses contrast fg instead
    rendered="$(_ctp_strip_fg "$rendered")"

    local piece=""
    if [[ -n "$prev_bg" ]]; then
      # Transition separator: previous bg color as fg, new bg as bg
      piece+="%F{${prev_bg}}%K{${bg_hex}}%1{${_CTP_ICON_PL_LEFT}%}%f"
    else
      # First segment
      piece+="%K{${bg_hex}}"
    fi
    piece+="%F{${fg_hex}} ${rendered} %f"
    segments+=("$piece")
    prev_bg="$bg_hex"
  done

  # Closing separator after last segment
  local result="${(j::)segments}"
  if [[ -n "$prev_bg" ]]; then
    result+="%k%F{${prev_bg}}%1{${_CTP_ICON_PL_LEFT}%}%f"
  fi
  echo "$result"
}

_ctp_render_powerline_right() {
  local -a templates=("${@[@]:2}")
  local -a names=("${(s: :)1}")

  local segments=()
  local idx=0

  for tpl in "${templates[@]}"; do
    (( idx++ ))
    local rendered="${(e)tpl}"
    [[ -z "$rendered" ]] && continue

    local seg_name="${names[$idx]}"
    local bg_key="${_CTP_SEGMENT_BG_KEY[$seg_name]:-ARROW}"
    local bg_var="CATPPUCCIN_BG_${bg_key}"
    local bg_name="${(P)bg_var}"
    local bg_hex="$(_ctp_color "$bg_name")"
    local fg_hex="$(_ctp_contrast_fg "$bg_name")"

    # Strip segment's own fg colors — powerline uses contrast fg instead
    rendered="$(_ctp_strip_fg "$rendered")"

    # Right-side powerline: separator comes before the segment
    local piece="%F{${bg_hex}}%1{${_CTP_ICON_PL_RIGHT}%}%f"
    piece+="%K{${bg_hex}}%F{${fg_hex}} ${rendered} %f"
    segments+=("$piece")
  done

  local result="${(j::)segments}%k"
  echo "$result"
}

# --- Render: evaluate templates and assemble PROMPT/RPROMPT ---
_ctp_render_prompt() {
  local left_joined=""
  local right_joined=""

  case "$CATPPUCCIN_STYLE" in
    powerline|rainbow)
      left_joined="$(_ctp_render_powerline_left "${_CTP_LEFT_NAMES[*]}" "${_CTP_LEFT_TEMPLATES[@]}")"
      if (( ${#_CTP_RIGHT_TEMPLATES} > 0 )); then
        right_joined="$(_ctp_render_powerline_right "${_CTP_RIGHT_NAMES[*]}" "${_CTP_RIGHT_TEMPLATES[@]}")"
      fi
      ;;
    *)
      left_joined="$(_ctp_render_plain "${_CTP_LEFT_TEMPLATES[@]}")"
      if (( ${#_CTP_RIGHT_TEMPLATES} > 0 )); then
        right_joined="$(_ctp_render_plain "${_CTP_RIGHT_TEMPLATES[@]}")"
      fi
      ;;
  esac

  if [[ "$CATPPUCCIN_LAYOUT" == "twoline" ]]; then
    local line2=""
    if [[ "$CATPPUCCIN_SHOW_PROMPT_CHAR" == "true" ]]; then
      line2="$(_ctp_segment_prompt_char) "
    else
      # Fallback: simple colored arrow
      line2="%F{$(_ctp_element_color "ARROW_OK")}%1{❯%}%f "
    fi
    PROMPT="${left_joined}
${line2}"
  else
    PROMPT="${left_joined} "
  fi

  # Set RPROMPT
  if [[ -n "$right_joined" ]]; then
    RPROMPT="${right_joined}"
  else
    unset RPROMPT
  fi
}

# --- Transient Prompt ---
if [[ "$CATPPUCCIN_TRANSIENT_PROMPT" == "true" ]]; then
  # Hook into zle accept-line to trigger transient prompt
  _ctp_zle_accept_line() {
    _CTP_TRANSIENT_ACTIVE=1
    # Store the buffer before accepting
    local buf="$BUFFER"
    # Set transient prompt
    local char="${CATPPUCCIN_PROMPT_CHAR:-❯}"
    PROMPT="%F{$(_ctp_element_color "PROMPT_CHAR_OK")}%1{${char}%}%f "
    RPROMPT=""
    zle reset-prompt
    # Restore full prompt config (will be rendered by precmd for next prompt)
    PROMPT=""
    RPROMPT=""
    zle .accept-line
  }

  zle -N accept-line _ctp_zle_accept_line
fi

# Build templates once, then render on every prompt
_ctp_build_prompt

autoload -Uz add-zsh-hook
add-zsh-hook precmd _ctp_render_prompt
