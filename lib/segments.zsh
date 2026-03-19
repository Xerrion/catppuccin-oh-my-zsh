# Catppuccin for Oh My Zsh - Prompt Segments
# Each segment function outputs a formatted prompt string or empty if disabled.
# Segments use _ctp_element_fg/_ctp_element_color from colors.zsh for theming.

# --- Nerd Font Icons ---
# Defined via escape sequences so PUA characters survive any editor/tool.
# Powerline: U+E0A0-E0A2, U+E0B0-E0B3
# Devicons: U+E700-E8EF
# Font Awesome: U+ED00-F2FF
# Material Design: U+F0001-F1AF0
typeset -gr _CTP_ICON_GIT_BRANCH=$'\ue0a0'
typeset -gr _CTP_ICON_GIT_DIRTY=$'\uf00d'
typeset -gr _CTP_ICON_GIT_CLEAN=$'\uf00c'
typeset -gr _CTP_ICON_GIT_AHEAD=$'\uf062'
typeset -gr _CTP_ICON_GIT_BEHIND=$'\uf063'
typeset -gr _CTP_ICON_GIT_STASH=$'\uf01c'
typeset -gr _CTP_ICON_PYTHON=$'\ue73c'
typeset -gr _CTP_ICON_NODE=$'\ue718'
typeset -gr _CTP_ICON_RUST=$'\ue7a8'
typeset -gr _CTP_ICON_GO=$'\ue627'
typeset -gr _CTP_ICON_RUBY=$'\ue739'
typeset -gr _CTP_ICON_JAVA=$'\ue738'
typeset -gr _CTP_ICON_PHP=$'\ue73d'
typeset -gr _CTP_ICON_K8S=$'\U000f10fe'
typeset -gr _CTP_ICON_JOBS=$'\uf013'
typeset -gr _CTP_ICON_EXEC_TIME=$'\uf017'
typeset -gr _CTP_ICON_STATUS_OK=$'\uf00c'
typeset -gr _CTP_ICON_STATUS_ERR=$'\uf00d'
# Powerline separator glyphs
typeset -gr _CTP_ICON_PL_LEFT=$'\ue0b0'
typeset -gr _CTP_ICON_PL_LEFT_THIN=$'\ue0b1'
typeset -gr _CTP_ICON_PL_RIGHT=$'\ue0b2'
typeset -gr _CTP_ICON_PL_RIGHT_THIN=$'\ue0b3'
typeset -gr _CTP_ICON_PL_ROUND_LEFT=$'\ue0b4'
typeset -gr _CTP_ICON_PL_ROUND_RIGHT=$'\ue0b6'

# --- OS Icon detection ---
# Detects the running OS and returns the appropriate Nerd Font icon.
_ctp_detect_os_icon() {
  if [[ -f /etc/os-release ]]; then
    local id="$(source /etc/os-release 2>/dev/null && echo "$ID")"
    case "$id" in
      arch)    echo $'\uf303' ;;
      ubuntu)  echo $'\uf31b' ;;
      debian)  echo $'\uf306' ;;
      fedora)  echo $'\uf30a' ;;
      centos)  echo $'\uf304' ;;
      opensuse*|suse) echo $'\uf314' ;;
      manjaro) echo $'\uf312' ;;
      nixos)   echo $'\uf313' ;;
      gentoo)  echo $'\uf30d' ;;
      alpine)  echo $'\uf300' ;;
      void)    echo $'\uf32e' ;;
      *)       echo $'\uf17c' ;;  # generic linux
    esac
  elif [[ "$OSTYPE" == darwin* ]]; then
    echo $'\uf179'  # Apple
  elif [[ "$OSTYPE" == freebsd* ]]; then
    echo $'\uf30c'  # FreeBSD
  elif [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then
    echo $'\uf17a'  # Windows
  else
    echo $'\uf17c'  # generic linux fallback
  fi
}

# Cache the OS icon at source time (it won't change during a session)
typeset -gr _CTP_OS_ICON="$(_ctp_detect_os_icon)"

# --- Arrow ---
# Green arrow on success, red on error. Uses ZSH conditional: %(?.true.false)
_ctp_segment_arrow() {
  [[ "$CATPPUCCIN_SHOW_ARROW" != "true" ]] && return
  echo "%(?.%F{$(_ctp_element_color "ARROW_OK")}.%F{$(_ctp_element_color "ARROW_ERR")})%1{➜%}%f"
}

# --- OS Icon ---
# Shows a Nerd Font icon for the detected operating system.
_ctp_segment_os_icon() {
  [[ "$CATPPUCCIN_SHOW_OS_ICON" != "true" ]] && return
  echo "$(_ctp_element_fg "OS_ICON")%1{${_CTP_OS_ICON}%}%f"
}

# --- Status ---
# Shows exit code on error or a check mark on success.
# Mode: icon (✓/✗), code (exit number on error), both
_ctp_segment_status() {
  [[ "$CATPPUCCIN_SHOW_STATUS" != "true" ]] && return
  local mode="${CATPPUCCIN_STATUS_MODE:-icon}"
  local ok_fg="%F{$(_ctp_element_color "STATUS_OK")}"
  local err_fg="%F{$(_ctp_element_color "STATUS_ERR")}"

  case "$mode" in
    icon)
      echo "%(?.${ok_fg}%1{${_CTP_ICON_STATUS_OK}%}%f.${err_fg}%1{${_CTP_ICON_STATUS_ERR}%}%f)"
      ;;
    code)
      # Only show on error: display the exit code
      echo "%(?.${ok_fg}%1{${_CTP_ICON_STATUS_OK}%}%f.${err_fg}%1{${_CTP_ICON_STATUS_ERR}%} %?%f)"
      ;;
    both)
      echo "%(?.${ok_fg}%1{${_CTP_ICON_STATUS_OK}%}%f.${err_fg}%1{${_CTP_ICON_STATUS_ERR}%} %?%f)"
      ;;
  esac
}

# --- Prompt Char ---
# A prompt character segment for twoline mode line 2.
# Changes color on success/error. Supports custom characters.
_ctp_segment_prompt_char() {
  [[ "$CATPPUCCIN_SHOW_PROMPT_CHAR" != "true" ]] && return
  local char="${CATPPUCCIN_PROMPT_CHAR:-❯}"
  echo "%(?.%F{$(_ctp_element_color "PROMPT_CHAR_OK")}.%F{$(_ctp_element_color "PROMPT_CHAR_ERR")})%1{${char}%}%f"
}

# --- User ---
_ctp_segment_user() {
  [[ "$CATPPUCCIN_SHOW_USER" != "true" ]] && return
  echo "$(_ctp_element_fg "USER")%n%f"
}

# --- Host ---
# Three modes: never (return empty), always (show always), ssh (show only in SSH)
_ctp_segment_host() {
  case "$CATPPUCCIN_SHOW_HOST" in
    never) return ;;
    always) echo "$(_ctp_element_fg "HOST")[%m]%f" ;;
    ssh)
      # SSH_CONNECTION is only set inside SSH sessions, so this check at
      # source time correctly reflects the session type for the shell lifetime.
      if [[ -n "$SSH_CONNECTION" ]]; then
        echo "$(_ctp_element_fg "HOST_SSH")[%m]%f"
      fi
      ;;
  esac
}

# --- CWD ---
# CATPPUCCIN_CWD_TRUNCATE controls depth: 0=full, 1=%1~ (tail), N=%N~
_ctp_segment_cwd() {
  [[ "$CATPPUCCIN_SHOW_CWD" != "true" ]] && return
  local truncate="${CATPPUCCIN_CWD_TRUNCATE}"
  local path_fmt
  if [[ "$truncate" == "0" ]]; then
    path_fmt="%~"  # full path with ~ substitution
  else
    path_fmt="%${truncate}~"  # show N trailing components
  fi
  echo "$(_ctp_element_fg "CWD")${path_fmt}%f"
}

# --- Git ---
# Uses oh-my-zsh git_prompt_info. Configures ZSH_THEME_GIT_PROMPT_* vars.
# Also supports ahead/behind and stash indicators.
_ctp_segment_git() {
  [[ "$CATPPUCCIN_SHOW_GIT" != "true" ]] && return

  # Set oh-my-zsh git prompt variables using our color system
  ZSH_THEME_GIT_PROMPT_PREFIX="$(_ctp_element_fg "GIT_BRANCH")${_CTP_ICON_GIT_BRANCH} ("
  ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
  ZSH_THEME_GIT_PROMPT_DIRTY="$(_ctp_element_fg "GIT_BRANCH")) $(_ctp_element_fg "GIT_DIRTY")%1{${_CTP_ICON_GIT_DIRTY}%}%f"
  ZSH_THEME_GIT_PROMPT_CLEAN="$(_ctp_element_fg "GIT_BRANCH")) $(_ctp_element_fg "GIT_CLEAN")%1{${_CTP_ICON_GIT_CLEAN}%}%f"

  if [[ "$CATPPUCCIN_GIT_SHOW_AHEAD_BEHIND" == "true" ]]; then
    ZSH_THEME_GIT_PROMPT_AHEAD="%1{${_CTP_ICON_GIT_AHEAD}%}"
    ZSH_THEME_GIT_PROMPT_BEHIND="%1{${_CTP_ICON_GIT_BEHIND}%}"
  fi

  if [[ "$CATPPUCCIN_GIT_SHOW_STASH" == "true" ]]; then
    ZSH_THEME_GIT_PROMPT_STASHED="%1{${_CTP_ICON_GIT_STASH}%}"
  fi

  # git_prompt_info is evaluated at prompt render time via $()
  echo '$(git_prompt_info)'
}

# --- Time ---
_ctp_segment_time() {
  [[ "$CATPPUCCIN_SHOW_TIME" != "true" ]] && return
  local fmt
  if [[ "$CATPPUCCIN_TIME_FORMAT" == "HH:MM:SS" ]]; then
    fmt="%*"  # HH:MM:SS
  else
    fmt="%T"  # HH:MM
  fi
  echo "$(_ctp_element_fg "TIME")${fmt}%f"
}

# --- Python Virtualenv ---
_ctp_segment_venv() {
  [[ "$CATPPUCCIN_SHOW_VENV" != "true" ]] && return
  # VIRTUAL_ENV / CONDA_DEFAULT_ENV are evaluated at prompt render time
  echo '$(
    if [[ -n "$VIRTUAL_ENV" ]]; then
      echo "'"$(_ctp_element_fg "VENV")"'(${VIRTUAL_ENV:t})%f"
    elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
      echo "'"$(_ctp_element_fg "VENV")"'(${CONDA_DEFAULT_ENV})%f"
    fi
  )'
}

# --- Language version segments ---
# Each checks for project marker files before running the version command.
# They use $() prompt substitution for runtime evaluation.

_ctp_segment_python() {
  [[ "$CATPPUCCIN_SHOW_PYTHON" != "true" ]] && return
  echo '$(
    if [[ -f pyproject.toml || -f setup.py || -f setup.cfg || -f Pipfile || -f requirements.txt || -f .python-version ]]; then
      local ver="${$(python3 --version 2>/dev/null)#Python }"
      [[ -n "$ver" ]] && echo "'"$(_ctp_element_fg "PYTHON")${_CTP_ICON_PYTHON}"' ${ver}%f"
    fi
  )'
}

_ctp_segment_node() {
  [[ "$CATPPUCCIN_SHOW_NODE" != "true" ]] && return
  echo '$(
    if [[ -f package.json || -f .nvmrc || -f .node-version ]]; then
      local ver="${$(node --version 2>/dev/null)#v}"
      [[ -n "$ver" ]] && echo "'"$(_ctp_element_fg "NODE")${_CTP_ICON_NODE}"' ${ver}%f"
    fi
  )'
}

_ctp_segment_rust() {
  [[ "$CATPPUCCIN_SHOW_RUST" != "true" ]] && return
  echo '$(
    if [[ -f Cargo.toml || -f .rust-toolchain || -f .rust-toolchain.toml ]]; then
      local ver="${$(rustc --version 2>/dev/null)##rustc }"
      ver="${ver%% *}"
      [[ -n "$ver" ]] && echo "'"$(_ctp_element_fg "RUST")${_CTP_ICON_RUST}"' ${ver}%f"
    fi
  )'
}

_ctp_segment_go() {
  [[ "$CATPPUCCIN_SHOW_GO" != "true" ]] && return
  echo '$(
    if [[ -f go.mod || -f go.sum ]]; then
      local ver="${$(go version 2>/dev/null)##go version go}"
      ver="${ver%% *}"
      [[ -n "$ver" ]] && echo "'"$(_ctp_element_fg "GO")${_CTP_ICON_GO}"' ${ver}%f"
    fi
  )'
}

_ctp_segment_ruby() {
  [[ "$CATPPUCCIN_SHOW_RUBY" != "true" ]] && return
  echo '$(
    if [[ -f Gemfile || -f .ruby-version || -f Rakefile ]]; then
      local ver="${$(ruby --version 2>/dev/null)##ruby }"
      ver="${ver%% *}"
      [[ -n "$ver" ]] && echo "'"$(_ctp_element_fg "RUBY")${_CTP_ICON_RUBY}"' ${ver}%f"
    fi
  )'
}

_ctp_segment_java() {
  [[ "$CATPPUCCIN_SHOW_JAVA" != "true" ]] && return
  # Handles both old format (java -version -> "1.8.0_292") and
  # new format (java --version -> openjdk 17.0.1 ...)
  echo '$(
    if [[ -f pom.xml || -f build.gradle || -f build.gradle.kts || -f .java-version ]]; then
      local ver="$(java -version 2>&1 | head -1)"
      ver="${ver##*\"}"
      ver="${ver%%\"*}"
      # Fallback for newer java --version output (unquoted)
      if [[ -z "$ver" ]]; then
        ver="${$(java --version 2>/dev/null | head -1)##* }"
      fi
      [[ -n "$ver" ]] && echo "'"$(_ctp_element_fg "JAVA")${_CTP_ICON_JAVA}"' ${ver}%f"
    fi
  )'
}

_ctp_segment_php() {
  [[ "$CATPPUCCIN_SHOW_PHP" != "true" ]] && return
  echo '$(
    if [[ -f composer.json || -f .php-version || -f artisan ]]; then
      local ver="${$(php --version 2>/dev/null | head -1)##PHP }"
      ver="${ver%% *}"
      [[ -n "$ver" ]] && echo "'"$(_ctp_element_fg "PHP")${_CTP_ICON_PHP}"' ${ver}%f"
    fi
  )'
}

# --- Infrastructure ---

_ctp_segment_k8s() {
  [[ "$CATPPUCCIN_SHOW_K8S" != "true" ]] && return
  echo '$(
    local ctx="$(kubectl config current-context 2>/dev/null)"
    [[ -n "$ctx" ]] && echo "'"$(_ctp_element_fg "K8S")${_CTP_ICON_K8S}"' ${ctx}%f"
  )'
}

_ctp_segment_jobs() {
  [[ "$CATPPUCCIN_SHOW_JOBS" != "true" ]] && return
  # Use runtime evaluation so empty-check works in _ctp_render_prompt
  echo '$(
    local jcount=${#jobstates}
    (( jcount > 0 )) && echo "'"$(_ctp_element_fg "JOBS")"'%1{'"${_CTP_ICON_JOBS}"'%}${jcount}%f"
  )'
}

# --- Exec Time ---
# Requires preexec/precmd hooks (set up in prompt.zsh).
# This segment reads _CTP_EXEC_DURATION set by those hooks.
_ctp_segment_exec_time() {
  [[ "$CATPPUCCIN_SHOW_EXEC_TIME" != "true" ]] && return
  echo '$(
    if [[ -n "$_CTP_EXEC_DURATION" ]] && (( _CTP_EXEC_DURATION >= '"${CATPPUCCIN_EXEC_TIME_MIN}"' )); then
      local dur="$_CTP_EXEC_DURATION"
      local display=""
      if (( dur >= 3600 )); then
        display="$((dur / 3600))h$((dur % 3600 / 60))m"
      elif (( dur >= 60 )); then
        display="$((dur / 60))m$((dur % 60))s"
      else
        display="${dur}s"
      fi
      echo "'"$(_ctp_element_fg "EXEC_TIME")${_CTP_ICON_EXEC_TIME}"' ${display}%f"
    fi
  )'
}
