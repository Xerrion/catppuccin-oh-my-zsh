# Catppuccin for Oh My Zsh - Prompt Assembly
# Collects segment outputs, joins with separator, builds PROMPT.

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

# --- Prompt Builder ---
_ctp_build_prompt() {
  local sep="$(_ctp_element_fg "SEPARATOR")$(_ctp_resolve_separator)%f"
  local segments=()
  local segment_names=(${(s: :)CATPPUCCIN_SEGMENTS})
  local name output

  for name in "${segment_names[@]}"; do
    # In twoline mode, skip arrow from segments (it goes on line 2)
    if [[ "$CATPPUCCIN_LAYOUT" == "twoline" && "$name" == "arrow" ]]; then
      continue
    fi

    output="$(_ctp_segment_${name})"
    if [[ -n "$output" ]]; then
      segments+=("$output")
    fi
  done

  # Join segments with separator
  local joined="${(pj:$sep:)segments}"

  if [[ "$CATPPUCCIN_LAYOUT" == "twoline" ]]; then
    PROMPT="${joined}
%F{$(_ctp_element_color "ARROW_OK")}%1{❯%}%f "
  else
    PROMPT="${joined} "
  fi
}

_ctp_build_prompt
