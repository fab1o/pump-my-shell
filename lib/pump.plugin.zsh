update_() {
  version=${1:-$PUMP_VERSION}

  release_tag="https://api.github.com/repos/fab1o/pump-my-shell/releases/latest"
  latest_version=$(curl -s $release_tag | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

  if [[ -n "$latest_version" && "$version" != "$latest_version" ]]; then
    echo " new version available for pump-my-shell:${yellow_cor} $version -> $latest_version ${clear_cor}"

    if [[ "$2" != "-f" ]]; then
      if ! confirm_from_ "do you want to install new version?"; then
        return 0;
      fi
    fi

    echo " if you encounter an error after installation, don't worry — simply restart your terminal"

    /bin/bash -c "$(curl -H "Cache-Control: no-cache" -fsSL https://raw.githubusercontent.com/fab1o/pump-my-shell/refs/heads/main/scripts/update.sh)"
    return 1;
  else
    if [[ "$2" == "-f" ]]; then
      echo " no update available for pump-my-shell:${yellow_cor} $version ${clear_cor}"
    fi
  fi
}
PUMP_VERSION="0.0.0"
_version_file_path="$(dirname "$0")/.version"
[[ -f "$_version_file_path" ]] && PUMP_VERSION=$(<"$_version_file_path")
update_

# General
alias cl="tput reset"
alias hg="history | grep" # $1
alias ll="ls -lAF"
alias nver="node -e 'console.log(process.version, process.arch, process.platform)'"
alias nlist="npm list --global --depth=0"
alias path="echo $PATH"

kill() {
  if [[ -z "$1" ]]; then
    echo "${yellow_cor} kill <port>${clear_cor} : to kill a port number"
    return 0;
  fi

  npx --yes kill-port $1
}

refresh() {
  if [[ -f "$HOME/.zshrc" ]]; then
    source "$HOME/.zshrc"
  fi
}

upgrade() {
  update_ -f;

  if command -v omz &>/dev/null; then
    omz update
  fi
  if command -v oh-my-posh &>/dev/null; then
    oh-my-posh upgrade
  fi
}

input_from_() {
  if command -v gum &>/dev/null; then
    _input=$(gum input --placeholder="$1")
  else
    stty -echoctl
    read "? " _input || { echo ""; echo ""; return 1 }
    stty echoctl
  fi

  echo "$_input"
}

confirm_from_() {
  if command -v gum &>/dev/null; then
    gum confirm ""confirm:$'\e[0m'" $1" --no-show-help
    result=$?

    if [[ $result -eq 130 ]]; then
      return 130;
    elif [[ $result -eq 0 ]]; then
      return 0;
    else
      return 1;
    fi
  else
    read -qs "?"$'\e[38;5;99m'confirm:$'\e[0m'" $1 (y/n) "
    result=$?

    if [[ $result -eq 130 ]]; then
      echo ""
      return 130;
    elif [[ $REPLY == [yY] ]]; then
      echo "y"
      return 0;
    else
      echo "n"
      return 1;
    fi
  fi
}

choose_multiple_branches_() {
  echo "$(gum choose --no-limit --height 20 --header=" $1" $(echo "$2" | tr ' ' '\n'))"
}

choose_one_() {
  if command -v gum &>/dev/null; then
    echo "$(gum choose --limit=1 --height 20 --header=" $1" ${@:2})"
    return 0;
  fi
  
  PS3=${1-"choose: "}
  select choice in "$@" "quit"; do
    case $choice in
      "quit")
        return 1
        ;;
      *)
        echo "$choice"
        return 0
        ;;
    esac
  done
}

choose_auto_one_() {
  if command -v gum &>/dev/null; then
    echo "$(gum choose --limit=1 --select-if-one --height 20 --header=" $1" ${@:2})"
    return 0;
  fi
  
  PS3=${1-"choose: "}
  select choice in "$@" "quit"; do
    case $choice in
      "quit")
        return 1
        ;;
      *)
        echo "$choice"
        return 0
        ;;
    esac
  done
}

get_folders_() {
  _pwd=$(pwd)
  if [[ -n "$1" ]]; then
    cd "$1"
  fi
  setopt null_glob
  ls -d */ | sed 's:/$::' | grep -v -E '^\.$|^revs$'
  unsetopt null_glob
  cd "$_pwd"
}

# Deleting a path
del() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} del${clear_cor} : to select folders in current folder to delete"
    echo "${yellow_cor} del -a${clear_cor} : to delete all folders at once in current folder"
    echo "${yellow_cor} del <path>${clear_cor} : to delete a folder or file"
    echo "${yellow_cor} del <path> -s${clear_cor} : to skip confirmation"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    echo " fatal: del requires gum"
    echo " install gum:${blue_cor} https://github.com/charmbracelet/gum ${clear_cor}"
    return 1;
  fi

  _pro=$(which_pro_pwd_)
  proj_folder=""
  pump_working_branch=""

  if [[ -n "$_pro" ]]; then
    for i in {1..10}; do
      if [[ "$_pro" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        proj_folder="${Z_PROJECT_FOLDER[$i]}"
        pump_working_branch="${PUMP_WORKING[$i]}"
        break
      fi
    done
  fi

  if [[ -z "$1" ]]; then
    if [[ -n ${(f)"$(get_folders_)"} ]]; then
      folders=($(get_folders_))
      selected_folders=($(gum choose --no-limit --height 20 --header=" choose folder to delete" "${folders[@]}"))

      delete_pump_workings_ "$pump_working_branch" "$_pro" "${selected_folders[@]}"

      for folder in "${selected_folders[@]}"; do
        gum spin --title "deleting... $folder" -- rm -rf "$folder"
        echo "${magenta_cor} deleted${blue_cor} $folder ${clear_cor}"
      done
      ls
    else
      echo " no folders"
    fi
    return 0;
  fi

  if [[ "$1" == "-a" ]]; then
    if ! confirm_from_ "delete all folders in "$'\e[94m'$(PWD)$'\e[0m'"?"; then
      return 0;
    fi

    setopt null_glob

    for i in */; do
      folder="${i%/}"

      delete_pump_working_ "$folder" "$pump_working_branch" "$_pro"
  
      gum spin --title "deleting... $folder" -- rm -rf "$folder"
      echo "${magenta_cor} deleted${blue_cor} $folder ${clear_cor}"
    done
    unsetopt null_glob
    
    return 0;
  fi

  setopt dot_glob null_glob
  # Capture all args (quoted or not) as a single pattern
  pattern="$*"
  # Expand the pattern — if it's a glob, this expands to matches
  files=(${(z)~pattern})

  # echo "1 ${files[1]}"
  # echo "pattern $pattern"
  # echo "qty ${#files[@]}"

  _count=0
  is_all=0
  dont_ask=0

  # Check if it's a glob pattern with multiple or changed matches
  if [[ ${#files[@]} -gt 1 || "$pattern" != "${files[1]}" ]]; then
    for f in $files; do
      if (( _count < 3 )); then
        confirm_from_ "delete "$'\e[94m'$f$'\e[0m'"?"
        _result=$?
        if [[ $_result -eq 130 ]]; then
          break;
        elif [[ $_result -eq 1 ]]; then
          continue;
        fi
      else
        if [[ dont_ask -eq 0 && is_all -eq 0 ]]; then
          maxlen=90
          split_pattern=""

          while [[ -n $pattern ]]; do
            line="${pattern[1,$maxlen]}"
            split_pattern+=""$'\e[94m'$line$'\n\e[0m'""
            pattern="${pattern[$((maxlen + 1)),-1]}"
          done
          split_pattern="${split_pattern%""$'\n\e[0m'""}"
          confirm_from_ "delete all remaining $split_pattern"$'\e[0m'"?"
          _result=$?
          if [[ $_result -eq 130 ]]; then
            break;
          elif [[ $_result -eq 1 ]]; then
            dont_ask=1
          else
            is_all=1
          fi
        fi
        if [[ is_all -eq 0 ]]; then
          confirm_from_ "delete "$'\e[94m'$f$'\e[0m'"?"
          _result=$?
          if [[ $_result -eq 130 ]]; then
            break;
          elif [[ $_result -eq 1 ]]; then
            continue;
          fi
        fi
      fi

      _count=$(( _count + 1 ))

      if [[ -d "$f" && -n "$pump_working_branch" && -n "$_pro" ]]; then
        folder=$(basename "$f")
        delete_pump_working_ "$folder" "$pump_working_branch" "$_pro"
      fi
      gum spin --title "deleting... $f" -- rm -rf "$f"
      echo "${magenta_cor} deleted${blue_cor} $f ${clear_cor}"
    done
    unsetopt dot_glob null_glob
    return 0;
  fi
  
  unsetopt dot_glob null_glob

  file_path=$(realpath "$1" 2>/dev/null) # also works: "${1/#\~/$HOME}"
  if [ $? -ne 0 ]; then return 1; fi

  if [[ -z "$file_path" || ! -e "$file_path" ]]; then
    return 1;
  fi

  confirm_msg=""
  folder_to_move=""

  if [[ "$file_path" == "$(PWD)" ]]; then
    folder_to_move="$(dirname "$file_path")"
    confirm_msg="delete current path "$'\e[94m'$PWD$'\e[0m'"?";
  else
    confirm_msg="delete "$'\e[94m'$file_path$'\e[0m'"?";
  fi

  if [[ "$2" != "-s" && ".DS_Store" != $(basename "$file_path") ]]; then 
    if [[ -d "$file_path" ]]; then
      if [[ -n "$(ls -A "$file_path")" ]]; then
        if ! confirm_from_ $confirm_msg; then
          return 0;
        fi
      fi
    else
      if ! confirm_from_ $confirm_msg; then
        return 0;
      fi
    fi
  fi

  file_path_log="$file_path"

  if [[ "$file_path" == "$(PWD)"* ]]; then # the file_path is inside the current path
    file_path_log=$(shorten_path_until_ "$file_path")
  elif [[ -n "$$proj_folder" ]]; then
    file_path_log=$(shorten_path_until_ "$file_path" $(basename "$proj_folder"))
  fi

  if [[ -d "$file_path" && -n "$pump_working_branch" && -n "$_pro" ]]; then
    folder=$(basename "$file_path")
    delete_pump_working_ "$folder" "$pump_working_branch" "$_pro"
  fi

  gum spin --title "deleting... $file_path" -- rm -rf "$file_path"
  echo "${magenta_cor} deleted${blue_cor} $file_path_log ${clear_cor}"

  if [[ -n "$folder_to_move" ]]; then
    cd "$folder_to_move"
  fi
}

_updated_config_key=""
update_config_() {
  local key=$1
  local value=$2

  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS (BSD sed) requires correct handling of patterns
    sed -i '' "s|^$key=[^[:space:]]*|$key=$value|" "$PUMP_CONFIG_FILE"
  else
    # Linux (GNU sed)
    sed -i "s|^$key=[^[:space:]]*|$key=$value|" "$PUMP_CONFIG_FILE"
  fi
  if [[ $? -eq 0 ]]; then
    _updated_config_key="$key"
  fi
  # if [[ $? -eq 0 ]]; then
  #   echo " ${gray_cor}updated $key in the config ${clear_cor}"
  # fi
}

input_name_() {
  qty=${1:-10}

  while true; do
    typed_value=$(gum input --no-show-help --placeholder="$2")
    if [[ $? -ne 0 ]]; then
      break
    fi

    if [[ "$typed_value" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ && ${#typed_value} -lt $qty ]]; then
      echo "${typed_value:l}"
      break
    fi
  done
}

input_path_() {
  while true; do
    typed_value=$(gum input --no-show-help --placeholder="$1")
    if [[ $? -ne 0 ]]; then
      break
    fi

    if [[ "$typed_value" =~ ^[a-zA-Z0-9/,._-]+$ ]]; then
      echo "$typed_value"
      break
    fi
  done
}

check_proj_name_valid_() {
  name=${1:-$Z_CURRENT_PROJECT_SHORT_NAME}

  invalid_proj_names=(
    "yarn" "npm" "pnpm" "bun" "back" "add" "new" "remove" "rm" "install" "cd" "uninstall" "update" "init" "pushd" "popd" "ls" "dir" "ll"
    "pro" "rev" "revs" "clone" "setup" "run" "test" "testw" "covc" "cov" "e2e" "e2eui" "recommit" "refix" "clear"
    "rdev" "dev" "stage" "prod" "gha" "pr" "push" "repush" "pushf" "add" "commit" "build" "i" "ig" "deploy" "fix" "format" "lint"
    "tsc" "start" "sbb" "sb" "renb" "co" "reseta" "clean" "delb" "prune" "discard" "restore"
    "st" "gconf" "fetch" "pull" "glog" "gll" "glr" "reset" "resetw" "reset1" "reset2" "reset3" "reset4" "reset5" "reset6"
    "dtag" "tag" "tags" "pop" "stash" "stashes" "rebase" "merge" "rc" "conti" "mc" "chp" "chc" "abort"
    "cl" "del" "help" "kill" "nver" "nlist" "path" "refresh" "pwd" "empty" "upgrade" "-h" "-q" "quiet" "skip" "-" "." ".."
  )

  if [[ " ${invalid_proj_names[@]} " =~ " $name " ]]; then
    if [[ "$2" != "-q" ]]; then
      echo " project name is invalid, choose another one"
    fi
    return 1
  fi
}

pause_output() {
  printf " "
  stty -echo

  IFS= read -r -k1 input

  if [[ $input == $'\e' ]]; then
      # Read the rest of the escape sequence (e.g. for arrow keys)
      IFS= read -r -k2 rest
      input+=$rest
      # Discard any remaining junk from the input buffer
      while IFS= read -r -t 0.01 -k1 junk; do :; done
  elif [[ $input != $'\n' ]]; then
      # Discard remaining characters if non-enter, non-escape key
      while IFS= read -r -t 0.01 -k1 junk; do :; done
  fi

  stty echo

  if [[ $input == "q" ]]; then
      clear
      return 1
  fi

  echo  # move to new line cleanly
}

help_line_() {
  word1=$1
  color=${2:-$gray_cor}
  total_width1=${3:-72}
  word2=$4
  total_width2=${5:-72}

  word_length1=${#word1}
  word_length2=${#word2}

  help_line_padding1=$(( ( total_width1 > word_length1 ? total_width1 - word_length1 - 2 : word_length1 - total_width1 - 2 ) / 2 ))
  help_line_line1="$(printf '%*s' "$help_line_padding1" '' | tr ' ' '─') $word1 $(printf '%*s' "$help_line_padding1" '' | tr ' ' '─')"

  if (( ${#help_line_line1} < total_width1 )); then
    help_line_pad_len1=$(( total_width1 - ${#help_line_line1} ))
    help_line_padding1=$(printf '%*s' $help_line_pad_len1 '' | tr ' ' '-')
    help_line_line1="${help_line_line1}${help_line_padding1}"
  fi
  
  help_line_line="$help_line_line1"

  if [[ $word_length2 -gt 0 ]]; then
    help_line_padding2=$(( ( total_width2 > word_length2 ? total_width2 - word_length2 - 2 : word_length2 - total_width2 - 2 ) / 2 ))
    help_line_line2="$(printf '%*s' "$help_line_padding2" '' | tr ' ' '─') $word2 $(printf '%*s' "$help_line_padding2" '' | tr ' ' '─')"

    if (( ${#help_line_line2} < total_width2 )); then
      help_line_pad_len2=$(( total_width2 - ${#help_line_line2} ))
      help_line_padding2=$(printf '%*s' $help_line_pad_len2 '' | tr ' ' '-')
      help_line_line2="${help_line_line2}${help_line_padding2}"
    fi

    help_line_line="$help_line_line1 | $help_line_line2"
  else
  fi

  echo "${color} $help_line_line ${clear_cor}"
}

save_project_() {
  if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
    echo "${red_cor} fatal: config file '$PUMP_CONFIG_FILE' does not exist, re-install pump-my-shell ${clear_cor}"
    return 1
  fi

  local i="$1"

  local folder="${Z_PROJECT_FOLDER[$i]}"
  local name="${2:-${Z_PROJECT_SHORT_NAME[$i]}}"
  local package_manager="${3:-${Z_PACKAGE_MANAGER[$i]}}"

  local typed_folder=""
  local typed_name=""
  local choose_pkg=""

  _updated_config_key=""

  if [[ -z "$name" ]]; then
    echo " type your project's abbreviated name (one short word):"
    typed_name=$(input_name_ 10 "${name:-pump}")

    # check for duplicates across other indices
    for j in {1..10}; do
      if [[ $j -ne $i && "${Z_PROJECT_SHORT_NAME[$j]}" == "$typed_name" ]]; then
        echo " project name already exists, please choose another one"
        return 1
      fi
    done

    if [[ -n "$typed_name" ]]; then
      check_proj_name_valid_ "$typed_name"
      if [[ $? -ne 0 ]]; then return 1; fi
      echo "  $typed_name"
    else
      return 1
    fi
  else
    typed_name="$name"
  fi

  if [[ -z "$folder" ]]; then
    echo ""
    echo " type your project's folder path:"
    typed_folder=$(input_path_ "${folder:-"$HOME/pump-my-shell"}")
    if [[ -n "$typed_folder" ]]; then
      check_prj_folder_ "$typed_folder"
      if [ $? -ne 0 ]; then
        Z_PROJECT_FOLDER[$i]=""
        return 1
      fi
      echo "  $typed_folder"
      update_config_ "Z_PROJECT_FOLDER_$i" "$typed_folder"
      Z_PROJECT_FOLDER[$i]="$typed_folder"
    else
      return 1
    fi
  fi

  if [[ -z "$package_manager" ]]; then
    echo ""
    choose_pkg=($(choose_one_ "choose package manager:" "npm" "yarn" "pnpm" "bun" "pip" "poetry" "poe"))
    if [[ -n "$choose_pkg" ]]; then
      echo "  $choose_pkg"
      update_config_ "Z_PACKAGE_MANAGER_$i" "$choose_pkg"
      Z_PACKAGE_MANAGER[$i]="$choose_pkg"
    else
      return 1
    fi
  fi

  if [[ -n "$typed_name" ]]; then
    update_config_ "Z_PROJECT_SHORT_NAME_$i" "$typed_name"
    Z_PROJECT_SHORT_NAME[$i]="$typed_name"
  fi

  if [[ -n "$_updated_config_key" ]]; then
    refresh
    if [[ -n "$typed_name" ]]; then
      echo " now run${yellow_cor} $typed_name ${clear_cor}"
    fi
  fi
}

help() {
  #tput reset

  if command -v gum &>/dev/null; then
    gum style --border=rounded --margin=0 --padding="1 16" --border-foreground=212 --width=69 \
      --align=center "welcome to $(gum style --foreground 212 "fab1o's pump my shell! v$PUMP_VERSION")"
  else
    help_line_ "fab1o's pump my shell!" "${purple_cor}"
    echo ""
  fi

  if [[ -n "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
    echo ""
    echo "  your project is set to:${solid_blue_cor} $Z_CURRENT_PROJECT_SHORT_NAME${clear_cor} with${solid_magenta_cor} $Z_CURRENT_PACKAGE_MANAGER ${clear_cor}"
  fi

  echo ""
  echo "  to learn more, visit:${blue_cor} https://github.com/fab1o/pump-my-shell/wiki ${clear_cor}"

  check_prj_ 1
  if [[ $? -ne 0 ]]; then
    echo ""
    echo " let's configure your first project!"
    
    save_project_ 1

    if [[ -z "${Z_PROJECT_FOLDER[1]}" || -z "${Z_PROJECT_SHORT_NAME[1]}" ]]; then
      echo " configure${solid_yellow_cor} $PUMP_CONFIG_FILE${clear_cor} as shown in the example below:"
      echo ""
      echo " Z_PROJECT_FOLDER_1=${Z_PROJECT_FOLDER[1]:-"$HOME/pump-my-shell"}"
      echo " Z_PROJECT_SHORT_NAME_1=${Z_PROJECT_SHORT_NAME[1]:-pump}"
      echo ""
      echo " then restart your terminal, then type${yellow_cor} help${clear_cor} again"
      echo ""
    else
      echo " then run${yellow_cor} help${clear_cor} again"
    fi

    return 0;
  fi
  
  echo ""
  help_line_ "get started" "${blue_cor}"
  echo ""
  echo "  1. to clone project, type:${blue_cor} clone ${clear_cor}"
  echo "  2. to setup project, type:${blue_cor} setup${clear_cor} or${blue_cor} setup -h${clear_cor} to see usage"
  echo "  3. to run a project, type:${blue_cor} run${clear_cor} or${blue_cor} run -h${clear_cor} to see usage"

  echo ""
  help_line_ "project selection" "${solid_blue_cor}"
  echo ""
  echo -e " ${solid_blue_cor} pro ${clear_cor}\t\t = set project"

  for i in {1..10}; do
    if [[ -n "${Z_PROJECT_FOLDER[$i]}" && -n "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
      local short="${Z_PROJECT_SHORT_NAME[$i]}"
      local folder="${Z_PROJECT_FOLDER[$i]}"
      local shortened_path=$(shorten_path_ "$folder" 1)
      local tab=$([[ ${#short} -lt 5 ]] && echo -e "\t\t" || echo -e "\t")
      echo " ${solid_blue_cor} $short ${clear_cor}${tab} = set project and cd $shortened_path"
    fi
  done

  echo ""
  help_line_ "project" "${blue_cor}"
  echo ""
  echo -e " ${blue_cor} clone ${clear_cor}\t = clone project or branch"
  
  _setup=${Z_CURRENT_SETUP:-$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")setup}

  max=53
  if (( ${#_setup} > $max )); then
    # echo -e " ${blue_cor} setup ${clear_cor}\t = ${_setup[1,$max]}"
    echo -e " ${blue_cor} setup ${clear_cor}\t = execute  Z_SETUP"
  else
    echo -e " ${blue_cor} setup ${clear_cor}\t = $_setup"
  fi
  if (( ${#Z_CURRENT_RUN} > $max )); then
    echo -e " ${blue_cor} run ${clear_cor}\t\t = execute  Z_RUN"
  else
    echo -e " ${blue_cor} run ${clear_cor}\t\t = $Z_CURRENT_RUN"
  fi
  if (( ${#Z_CURRENT_RUN_STAGE} > $max )); then
    echo -e " ${blue_cor} run stage ${clear_cor}\t = execute  Z_RUN_STAGE"
  else
    echo -e " ${blue_cor} run stage ${clear_cor}\t = $Z_CURRENT_RUN_STAGE"
  fi
  if (( ${#Z_CURRENT_RUN_PROD} > $max )); then
    echo -e " ${blue_cor} run prod ${clear_cor}\t = execute  Z_RUN_PROD"
  else
    echo -e " ${blue_cor} run prod ${clear_cor}\t = $Z_CURRENT_RUN_PROD"
  fi

  echo ""
  help_line_ "code review" "${cyan_cor}"
  echo ""
  echo -e " ${cyan_cor} rev ${clear_cor}\t\t = open a pull request for review"
  echo -e " ${cyan_cor} revs ${clear_cor}\t\t = list existing reviews"
  echo -e " ${cyan_cor} prune revs ${clear_cor}\t = delete merged reviews"

  pause_output  # Wait for user input to continue
  if [[ $? -ne 0 ]]; then
    return 0;
  fi

  help_line_ "$Z_CURRENT_PACKAGE_MANAGER" "${solid_magenta_cor}"
  echo ""
  echo -e " ${solid_magenta_cor} build ${clear_cor}\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")build"
  echo -e " ${solid_magenta_cor} deploy ${clear_cor}\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")deploy"
  echo -e " ${solid_magenta_cor} fix ${clear_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")format + lint"
  echo -e " ${solid_magenta_cor} format ${clear_cor}\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")format"
  echo -e " ${solid_magenta_cor} i ${clear_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")install"
  echo -e " ${solid_magenta_cor} ig ${clear_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")install global"
  echo -e " ${solid_magenta_cor} lint ${clear_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")lint"
  echo -e " ${solid_magenta_cor} rdev ${clear_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")dev"
  echo -e " ${solid_magenta_cor} sb ${clear_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook"
  echo -e " ${solid_magenta_cor} sbb ${clear_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook:build"
  echo -e " ${solid_magenta_cor} start ${clear_cor}\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")start"
  echo -e " ${solid_magenta_cor} tsc ${clear_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")tsc"
  
  echo ""
  help_line_ "test $Z_CURRENT_PROJECT_SHORT_NAME" "${magenta_cor}"
  echo ""
  if [[ "$Z_CURRENT_COV" != "$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage" ]]; then
    echo -e " ${solid_magenta_cor} ${Z_CURRENT_PACKAGE_MANAGER:0:1}cov ${clear_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage"
  fi
  if [[ "$Z_CURRENT_E2E" != "$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e" ]]; then
    echo -e " ${solid_magenta_cor} ${Z_CURRENT_PACKAGE_MANAGER:0:1}e2e ${clear_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e"
  fi
  if [[ "$Z_CURRENT_E2EUI" != "$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui" ]]; then
    echo -e " ${solid_magenta_cor} ${Z_CURRENT_PACKAGE_MANAGER:0:1}e2eui ${clear_cor}\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui"
  fi
  if [[ "$Z_CURRENT_TEST" != "$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test" ]]; then
    echo -e " ${solid_magenta_cor} ${Z_CURRENT_PACKAGE_MANAGER:0:1}test ${clear_cor}\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test"
  fi
  if [[ "$Z_CURRENT_TEST_WATCH" != "$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch" ]]; then
    echo -e " ${solid_magenta_cor} ${Z_CURRENT_PACKAGE_MANAGER:0:1}testw ${clear_cor}\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch"
  fi
  echo -e " ${magenta_cor} cov ${clear_cor}\t\t = $Z_CURRENT_COV"
  echo -e " ${magenta_cor} e2e ${clear_cor}\t\t = $Z_CURRENT_E2E"
  echo -e " ${magenta_cor} e2eui ${clear_cor}\t = $Z_CURRENT_E2EUI"
  echo -e " ${magenta_cor} test ${clear_cor}\t\t = $Z_CURRENT_TEST"
  echo -e " ${magenta_cor} testw ${clear_cor}\t = $Z_CURRENT_TEST_WATCH"

  echo ""
  help_line_ "git" "${solid_cyan_cor}"
  echo ""
  echo -e " ${solid_cyan_cor} gconf ${clear_cor}\t = git config"
  echo -e " ${solid_cyan_cor} gha ${clear_cor}\t\t = view last workflow run"
  echo -e " ${solid_cyan_cor} st ${clear_cor}\t\t = git status"
  
  pause_output  # Wait for user input to continue
  if [[ $? -ne 0 ]]; then
    return 0;
  fi

  help_line_ "git branch" "${solid_cyan_cor}"
  echo ""
  echo -e " ${solid_cyan_cor} back ${clear_cor}\t\t = go back to previous branch or folder"
  echo -e " ${solid_cyan_cor} co ${clear_cor}\t\t = switch branch"
  echo -e " ${solid_cyan_cor} co <b> <base> ${clear_cor} = create branch off of base branch"
  echo -e " ${solid_cyan_cor} dev ${clear_cor}\t\t = switch to develop or dev"
  echo -e " ${solid_cyan_cor} main ${clear_cor}\t\t = switch to master or main"
  echo -e " ${solid_cyan_cor} renb <b>${clear_cor}\t = rename branch"
  echo -e " ${solid_cyan_cor} stage ${clear_cor}\t = switch to staging or stage"

  echo ""
  help_line_ "git clean" "${solid_cyan_cor}"
  echo ""
  echo -e " ${solid_cyan_cor} clean${clear_cor}\t\t = clean + restore"
  echo -e " ${solid_cyan_cor} delb ${clear_cor}\t\t = delete branches"
  echo -e " ${solid_cyan_cor} discard ${clear_cor}\t = reset local changes"
  echo -e " ${solid_cyan_cor} prune ${clear_cor}\t = prune branches and tags"
  echo -e " ${solid_cyan_cor} reset1 ${clear_cor}\t = reset soft 1 commit"
  echo -e " ${solid_cyan_cor} reset2 ${clear_cor}\t = reset soft 2 commits"
  echo -e " ${solid_cyan_cor} reset3 ${clear_cor}\t = reset soft 3 commits"
  echo -e " ${solid_cyan_cor} reset4 ${clear_cor}\t = reset soft 4 commits"
  echo -e " ${solid_cyan_cor} reset5 ${clear_cor}\t = reset soft 5 commits"
  echo -e " ${solid_cyan_cor} reseta ${clear_cor}\t = reset hard origin + clean"
  echo -e " ${solid_cyan_cor} restore ${clear_cor}\t = undo edits since last commit"
  
  echo ""
  help_line_ "git log" "${solid_cyan_cor}"
  echo ""
  echo -e " ${solid_cyan_cor} glog ${clear_cor}\t\t = git log"
  echo -e " ${solid_cyan_cor} gll ${clear_cor}\t\t = list branches"
  echo -e " ${solid_cyan_cor} gll <b> ${clear_cor}\t = list branches matching branch"
  echo -e " ${solid_cyan_cor} glr ${clear_cor}\t\t = list remote branches"
  echo -e " ${solid_cyan_cor} glr <b> ${clear_cor}\t = list remote branches matching branch"

  pause_output  # Wait for user input to continue
  if [[ $? -ne 0 ]]; then
    return 0;
  fi

  help_line_ "git pull" "${solid_cyan_cor}"
  echo ""
  echo -e " ${solid_cyan_cor} fetch ${clear_cor}\t = fetch from origin"
  echo -e " ${solid_cyan_cor} pull ${clear_cor}\t\t = pull all branches from origin"
  echo -e " ${solid_cyan_cor} pull tags${clear_cor}\t = pull all tags from origin"

  echo ""
  help_line_ "git push" "${solid_cyan_cor}"
  echo ""
  echo -e " ${solid_cyan_cor} add ${clear_cor}\t\t = add files to index"
  echo -e " ${solid_cyan_cor} commit ${clear_cor}\t = open commit wizard"
  echo -e " ${solid_cyan_cor} commit <m>${clear_cor}\t = commit message"
  echo -e " ${solid_cyan_cor} pr ${clear_cor}\t\t = create pull request"
  echo -e " ${solid_cyan_cor} push ${clear_cor}\t\t = push all no-verify to origin"
  echo -e " ${solid_cyan_cor} pushf ${clear_cor}\t = push force all to origin"
  
  echo ""
  help_line_ "git rebase" "${solid_cyan_cor}"
  echo ""
  echo -e " ${solid_cyan_cor} abort${clear_cor}\t\t = abort rebase/merge/chp"
  echo -e " ${solid_cyan_cor} chc ${clear_cor}\t\t = continue cherry-pick"
  echo -e " ${solid_cyan_cor} chp ${clear_cor}\t\t = cherry-pick commit"
  echo -e " ${solid_cyan_cor} conti ${clear_cor}\t = continue rebase/merge/chp"
  echo -e " ${solid_cyan_cor} mc ${clear_cor}\t\t = continue merge"
  echo -e " ${solid_cyan_cor} merge ${clear_cor}\t = merge from $(git config --get init.defaultBranch) branch"
  echo -e " ${solid_cyan_cor} merge <b> ${clear_cor}\t = merge from branch"
  echo -e " ${solid_cyan_cor} rc ${clear_cor}\t\t = continue rebase"
  echo -e " ${solid_cyan_cor} rebase ${clear_cor}\t = rebase from $(git config --get init.defaultBranch) branch"
  echo -e " ${solid_cyan_cor} rebase <b> ${clear_cor}\t = rebase from branch"

  pause_output  # Wait for user input to continue
  if [[ $? -ne 0 ]]; then
    return 0;
  fi
  
  help_line_ "git stash" "${solid_cyan_cor}"
  echo ""
  echo -e " ${solid_cyan_cor} pop ${clear_cor}\t\t = stash pop index"
  echo -e " ${solid_cyan_cor} stash ${clear_cor}\t = stash unnamed"
  echo -e " ${solid_cyan_cor} stash <name> ${clear_cor}  = stash with name"
  echo -e " ${solid_cyan_cor} stashes ${clear_cor}\t = list all stashes"

  echo ""
  help_line_ "git tags" "${solid_cyan_cor}"
  echo ""
  echo -e " ${solid_cyan_cor} dtag ${clear_cor}\t\t = delete tag remotely"
  echo -e " ${solid_cyan_cor} tag ${clear_cor}\t\t = create tag remotely"
  echo -e " ${solid_cyan_cor} tags ${clear_cor}\t\t = list latest tags"
  echo -e " ${solid_cyan_cor} tags 1 ${clear_cor}\t = display latest tag"

  echo ""
  help_line_ "general" "${solid_cyan_cor}"
  echo ""
  echo -e " ${solid_yellow_cor} cl ${clear_cor}\t\t = clear"
  echo -e " ${solid_yellow_cor} del ${clear_cor}\t\t = delete utility"
  echo -e " ${solid_yellow_cor} help ${clear_cor}\t\t = display this help"
  echo -e " ${solid_yellow_cor} hg <text> ${clear_cor}\t = history | grep text"
  echo -e " ${solid_yellow_cor} kill <port> ${clear_cor}\t = kill port"
  echo -e " ${solid_yellow_cor} ll ${clear_cor}\t\t = ls -laF"
  echo -e " ${solid_yellow_cor} nver ${clear_cor}\t\t = node version"
  echo -e " ${solid_yellow_cor} nlist ${clear_cor}\t = npm list global"
  echo -e " ${solid_yellow_cor} path ${clear_cor}\t\t = echo \$PATH"
  echo -e " ${solid_yellow_cor} refresh ${clear_cor}\t = source .zshrc"
  echo -e " ${solid_yellow_cor} upgrade ${clear_cor}\t = upgrade pump + zsh + omp"
  echo ""
  help_line_ "multi-step task" "${pink_cor}"
  echo ""
  echo -e " ${pink_cor} cov <b> ${clear_cor}\t = compare test coverage with another branch"
  echo -e " ${pink_cor} refix ${clear_cor}\t = reset last commit, run fix then re-commit/push"
  echo -e " ${pink_cor} recommit ${clear_cor}\t = reset last commit then re-commit changes"
  echo -e " ${pink_cor} repush ${clear_cor}\t = reset last commit then re-push changes"
  echo -e " ${pink_cor} rev ${clear_cor}\t\t = open a pull request for review"
  echo ""
}

check_prj_folder_() {
  local _folder="$1"
  
  if [[ -n "$_folder" ]]; then
    edited_folder="${_folder/#\~/$HOME}"
    [[ -n "$edited_folder" ]] && _folder="$edited_folder"
  fi

  [[ -n "$_folder" ]] && _folder="${_folder%/}"
  [[ -n "$_folder" ]] && realfolder=$(realpath "$_folder" 2>/dev/null)

  [[ -z "$realfolder" ]] && mkdir -p "$_folder" &>/dev/null && realfolder=$(realpath "$_folder" 2>/dev/null)

  if [[ -z "$realfolder" ]]; then
    return 1
  fi

  return 0;
}

check_prj_() {
  local i="$1"
  local short_name="${Z_PROJECT_SHORT_NAME[$i]}"
  local folder="${Z_PROJECT_FOLDER[$i]}"

  if [[ -z "$folder" ]]; then
    return 1;
  fi

  check_prj_folder_ $folder
  if [ $? -ne 0 ]; then
    return 1;
  fi

  return 0;
}

clear_project_() {
  i="$1"

  $Z_PROJECT_SHORT_NAME[$i]=""
  $Z_PROJECT_FOLDER[$i]=""
  $Z_PROJECT_REPO[$i]=""
  $Z_PACKAGE_MANAGER[$i]=""
  $Z_CODE_EDITOR[$i]=""
  $Z_CLONE[$i]=""
  $Z_SETUP[$i]=""
  $Z_RUN[$i]=""
  $Z_RUN_STAGE[$i]=""
  $Z_RUN_PROD[$i]=""
  $Z_PRO[$i]=""
  $Z_TEST[$i]=""
  $Z_COV[$i]=""
  $Z_TEST_WATCH[$i]=""
  $Z_E2E[$i]=""
  $Z_E2EUI[$i]=""
  $Z_PR_TEMPLATE[$i]=""
  $Z_PR_REPLACE[$i]=""
  $Z_PR_APPEND[$i]=""
  $Z_PR_RUN_TEST[$i]=""
  $Z_GHA_INTERVAL[$i]=""
  $Z_COMMIT_ADD[$i]=""
  $Z_GHA_WORKFLOW[$i]=""
  $Z_CURRENT_PUSH_ON_REFIX=""
  $Z_DEFAULT_BRANCH[$i]=""
  $Z_PRINT_README[$i]=""
}

clear_current_project_() {
  Z_CURRENT_PROJECT_FOLDER=""
  Z_CURRENT_PROJECT_SHORT_NAME=""
  Z_CURRENT_PROJECT_REPO=""
  Z_CURRENT_PACKAGE_MANAGER=""
  Z_CURRENT_CODE_EDITOR=""
  Z_CURRENT_CLONE=""
  Z_CURRENT_SETUP=""
  Z_CURRENT_RUN=""
  Z_CURRENT_RUN_STAGE=""
  Z_CURRENT_RUN_PROD=""
  Z_CURRENT_PRO=""
  Z_CURRENT_TEST=""
  Z_CURRENT_COV=""
  Z_CURRENT_TEST_WATCH=""
  Z_CURRENT_E2E=""
  Z_CURRENT_E2EUI=""
  Z_CURRENT_PR_TEMPLATE=""
  Z_CURRENT_PR_REPLACE=""
  Z_CURRENT_PR_APPEND=""
  Z_CURRENT_PR_RUN_TEST=""
  Z_CURRENT_GHA_INTERVAL=""
  Z_CURRENT_COMMIT_ADD=""
  Z_CURRENT_GHA_WORKFLOW=""
  Z_CURRENT_PUSH_ON_REFIX=""
  Z_CURRENT_DEFAULT_BRANCH=""
  Z_CURRENT_PRINT_README=""
}

pro() {
  if [[ -z "$1" || "$1" == "-h" ]]; then
    echo "${yellow_cor} pro <pro>${clear_cor} : to set a project"
    echo "${yellow_cor} pro add ${solid_yellow_cor}[<pro>]${clear_cor} : to create a new project"
    echo "${yellow_cor} pro del <pro>${clear_cor} : to delete a project"
    echo "${yellow_cor} pro <pro> <branch/folder>${clear_cor} : to set to a project and branch if in 'single mode' or folder if in 'multi mode'"
    if [[ -n "${Z_PROJECT_SHORT_NAME[*]}" ]]; then
      echo ""
      echo -n " projects:"
      for i in {1..10}; do echo -n " ${Z_PROJECT_SHORT_NAME[$i]}"; done
    fi
    return 0;
  fi

  if [[ "$1" == "-q" ]]; then
    return 0;
  fi

  # Handle 'pwd' as a special case
  if [[ "$1" == "pwd" ]]; then
    _pro=$(which_pro_pwd_)
    if [[ -n "$_pro" ]]; then
      pro "$_pro" "$2"
      return $?
    fi
    return 0
  fi

  action_arg=""
  proj_arg=""
  folder_arg=""
  is_quiet=0
  
  if [[ -n "$3" ]]; then
    if [[ "$1" =~ ^(Z_PROJECT_SHORT_NAME_[1-9]|Z_PROJECT_SHORT_NAME_10)$ ]]; then
      proj_arg="$1"
      folder_arg="$2"
    else
      action_arg="$1"
      proj_arg="$2"
    fi
  elif [[ -n "$2" ]]; then
    if [[ "$1" =~ ^(Z_PROJECT_SHORT_NAME_[1-9]|Z_PROJECT_SHORT_NAME_10)$ ]]; then
      proj_arg="$1"
      if [[ "$2" != "-q" ]]; then folder_arg="$2"; else is_quiet=1; fi
    else
      action_arg="$1"
      if [[ "$2" != "-q" ]]; then proj_arg="$2"; else is_quiet=1; fi
    fi
  else
    if [[ "$1" =~ ^(Z_PROJECT_SHORT_NAME_[1-9]|Z_PROJECT_SHORT_NAME_10)$ ]]; then
      proj_arg="$1"
    else
      if [[ "$1" != "-q" ]]; then action_arg="$1"; else is_quiet=1; fi
    fi
  fi

  if [[ "$action_arg" == "add" ]]; then
    # Create a new project
    for i in {1..10}; do
      if [[ -z "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        save_project_ $i $proj_arg
        return 0;
      fi
    done
    if [[ $is_quiet -eq 0 ]]; then
      echo " no more slots available, please delete one to add a new one"
    fi
    return 1;
  elif [[ "$action_arg" == "del" ]]; then
    if [[ -z "$proj_arg" ]]; then
      if [[ $is_quiet -eq 0 ]]; then
        echo " please provide a project name to delete"
      fi
      return 1;
    fi

    # Delete a project
    for i in {1..10}; do
      if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        if [[ "$proj_arg" == "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
          clear_current_project_
        fi
        clear_project_ $i

        update_config_ "Z_PROJECT_SHORT_NAME_$i" ""
        update_config_ "Z_PROJECT_FOLDER_$i" ""
        update_config_ "Z_PROJECT_REPO_$i" ""
        update_config_ "Z_PACKAGE_MANAGER_$i" ""
        update_config_ "Z_CODE_EDITOR_$i" ""
        update_config_ "Z_CLONE_$i" ""
        update_config_ "Z_SETUP_$i" ""
        update_config_ "Z_RUN_$i" ""
        update_config_ "Z_RUN_STAGE_$i" ""
        update_config_ "Z_RUN_PROD_$i" ""
        update_config_ "Z_PRO_$i" ""
        update_config_ "Z_TEST_$i" ""
        update_config_ "Z_COV_$i" ""
        update_config_ "Z_TEST_WATCH_$i" ""
        update_config_ "Z_E2E_$i" ""
        update_config_ "Z_E2EUI_$i" ""
        update_config_ "Z_PR_TEMPLATE_$i" ""
        update_config_ "Z_PR_REPLACE_$i" ""
        update_config_ "Z_PR_APPEND_$i" ""
        update_config_ "Z_PR_RUN_TEST_$i" ""
        update_config_ "Z_GHA_INTERVAL_$i" ""
        update_config_ "Z_COMMIT_ADD_$i" ""
        update_config_ "Z_GHA_WORKFLOW_$i" ""
        update_config_ "Z_CURRENT_PUSH_ON_REFIX_$i" ""
        update_config_ "Z_DEFAULT_BRANCH_$i" ""
        update_config_ "Z_PRINT_README_$i" ""

        if [[ $? -eq 0 && $is_quiet -eq 0 ]]; then
          echo " project deleted: $proj_arg"
        fi
        return 0;
      fi
    done
    if [[ $is_quiet -eq 0 ]]; then
      echo " project not found: $proj_arg"
      if [[ -n "${Z_PROJECT_SHORT_NAME[*]}" ]]; then
        echo -n " valid project names are:"
        for i in {1..10}; do echo -n " ${Z_PROJECT_SHORT_NAME[$i]}"; done
      fi
    fi
    return 1;
  fi

  if [[ -z "$proj_arg" ]]; then
    if [[ $is_quiet -eq 0 ]]; then
      echo " please provide a project name to set"
      if [[ -n "${Z_PROJECT_SHORT_NAME[*]}" ]]; then
        echo -n " valid project names are:"
        for i in {1..10}; do echo -n " ${Z_PROJECT_SHORT_NAME[$i]}"; done
      fi
    fi
    return 1;
  fi

  # Check if the project name matches one of the configured projects
  for i in {1..10}; do
    if [[ "$1" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
      # set the current project
      Z_CURRENT_PROJECT_SHORT_NAME="${Z_PROJECT_SHORT_NAME[$i]}"
      Z_CURRENT_PROJECT_FOLDER="${Z_PROJECT_FOLDER[$i]}"
      Z_CURRENT_PROJECT_REPO="${Z_PROJECT_REPO[$i]}"
      Z_CURRENT_PACKAGE_MANAGER="${Z_PACKAGE_MANAGER[$i]}"
      Z_CURRENT_CODE_EDITOR="${Z_CODE_EDITOR[$i]}"
      Z_CURRENT_CLONE="${Z_CLONE[$i]}"
      Z_CURRENT_SETUP="${Z_SETUP[$i]}"
      Z_CURRENT_RUN="${Z_RUN[$i]}"
      Z_CURRENT_RUN_STAGE="${Z_RUN_STAGE[$i]}"
      Z_CURRENT_RUN_PROD="${Z_RUN_PROD[$i]}"
      Z_CURRENT_PRO="${Z_PRO[$i]}"
      Z_CURRENT_TEST="${Z_TEST[$i]}"
      Z_CURRENT_COV="${Z_COV[$i]}"
      Z_CURRENT_TEST_WATCH="${Z_TEST_WATCH[$i]}"
      Z_CURRENT_E2E="${Z_E2E[$i]}"
      Z_CURRENT_E2EUI="${Z_E2EUI[$i]}"
      Z_CURRENT_PR_TEMPLATE="${Z_PR_TEMPLATE[$i]}"
      Z_CURRENT_PR_REPLACE="${Z_PR_REPLACE[$i]}"
      Z_CURRENT_PR_APPEND="${Z_PR_APPEND[$i]}"
      Z_CURRENT_PR_RUN_TEST="${Z_PR_RUN_TEST[$i]}"
      Z_CURRENT_GHA_INTERVAL="${Z_GHA_INTERVAL[$i]}"
      Z_CURRENT_COMMIT_ADD="${Z_COMMIT_ADD[$i]}"
      Z_CURRENT_GHA_WORKFLOW="${Z_GHA_WORKFLOW[$i]}"
      Z_CURRENT_PUSH_ON_REFIX="${Z_PUSH_ON_REFIX[$i]}"
      Z_CURRENT_DEFAULT_BRANCH="${Z_DEFAULT_BRANCH[$i]}"
      Z_CURRENT_PRINT_README="${Z_PRINT_README[$i]}"

      check_prj_ $i
      if [ $? -ne 0 ]; then
        clear_current_project_
        return 1;
      fi
      break
    fi
  done

  if [[ -z "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
    if [[ $is_quiet -eq 0 ]]; then
      echo " project not found: $proj_arg"
      if [[ -n "${Z_PROJECT_SHORT_NAME[*]}" ]]; then
        echo -n " valid project names are:"
        for i in {1..10}; do echo -n " ${Z_PROJECT_SHORT_NAME[$i]}"; done
      fi
    fi
    return 1
  fi

  if [[ $is_quiet -eq 0 ]]; then
    echo " project set to: ${solid_blue_cor}$Z_CURRENT_PROJECT_SHORT_NAME${clear_cor} with ${solid_magenta_cor}$Z_CURRENT_PACKAGE_MANAGER${clear_cor}"
  fi

  echo "$Z_CURRENT_PROJECT_SHORT_NAME" > "$PUMP_PRO_FILE"
  export Z_CURRENT_PROJECT_SHORT_NAME="$Z_CURRENT_PROJECT_SHORT_NAME"

  if [[ $is_quiet -eq 0 ]]; then
  # If not in the correct directory, change to the project folder
    if [[ $(PWD) != $Z_CURRENT_PROJECT_FOLDER* ]]; then
      mkdir -p "$Z_CURRENT_PROJECT_FOLDER" &>/dev/null
      cd "$Z_CURRENT_PROJECT_FOLDER"
    fi

    refresh
  fi
}

which_pro_pwd_() {
  # Iterate over project indices (1 to 10)
  for i in {1..10}; do
    # Check if the project short name and folder are set in the associative arrays
    if [[ -n "${Z_PROJECT_SHORT_NAME[$i]}" && -n "${Z_PROJECT_FOLDER[$i]}" ]]; then
      # Check if the current working directory matches the project folder
      if [[ $(PWD) == "${Z_PROJECT_FOLDER[$i]}"* ]]; then
        echo "${Z_PROJECT_SHORT_NAME[$i]}"
        return 0
      fi
    fi
  done

  # Cannot determine project based on pwd
  return 1
}

check_any_pkg_() {
  check_any_pkg_silent_ "$1"
  if [ $? -ne 0 ]; then
    echo " not a project folder: ${1:-$PWD}"
    return 1;
  fi

  return 0;
}

check_pkg_() {
  check_pkg_silent_ "$1"
  if [ $? -ne 0 ]; then
    echo " not a project folder: ${1:-$PWD}"
    return 1;
  fi

  return 0;
}

check_any_pkg_silent_() {
  folder=""
  
  if [[ -n "$1" ]]; then
    folder_path="${1/#\~/$HOME}";
    folder="$(realpath "$folder_path" 2>/dev/null)"
  else
    folder="$(PWD)"
  fi

  if [[ -n "$folder" && -d "$folder" ]]; then
    if [[ -f "$folder/package.json" || -f "$folder/pyproject.toml" || -d "$folder/.git" ]]; then
      return 0
    fi

    while [[ "$folder" != "/" ]]; do
      if [[ -f "$folder/package.json" || -f "$folder/pyproject.toml" || -d "$folder/.git" ]]; then
        return 0
      fi
      folder="$(dirname "$folder")"
    done
  fi

  return 1
}

check_pkg_silent_() {
  folder=""
  
  if [[ -n "$1" ]]; then
    folder_path="${1/#\~/$HOME}";
    folder="$(realpath "$folder_path" 2>/dev/null)"
  else
    folder="$(PWD)"
  fi

  if [[ -n "$folder" && -d "$folder" ]]; then
    if [[ -f "$folder/package.json" ]]; then
      return 0
    fi

    while [[ "$folder" != "/" ]]; do
      if [[ -f "$folder/package.json" ]]; then
        return 0
      fi
      folder="$(dirname "$folder")"
    done
  fi

  return 1
}

check_git_silent_() {
  folder="${1:-$PWD}"

  if [[ ! -d "$folder" ]]; then
    return 1;
  fi

  _pwd=$(pwd)

  cd "$folder"
  git rev-parse --is-inside-work-tree &>/dev/null
  RET=$?

  cd "$_pwd"
  return $RET
}

check_git_() {
  check_git_silent_ "$1"
  if [ $? -eq 0 ]; then
    return 0;
  fi

  echo " fatal: not a git repository (or any of the parent directories): ${1:-$PWD}"
  return 1;
}

refix() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} refix${clear_cor} : to reset last commit then run fix then re-push"
    echo "${yellow_cor} refix -q${clear_cor} : suppress push output unless an error occurs"
    return 0;
  fi

  check_pkg_; if [ $? -ne 0 ]; then return 1; fi
  check_git_; if [ $? -ne 0 ]; then return 1; fi

  last_commit_msg=$(git log -1 --pretty=format:'%s' | xargs -0)
  
  if [[ "$last_commit_msg" == Merge* ]]; then
    echo " last commit is a merge commit, please rebase instead"
    return 1;
  fi

  git reset --soft HEAD~1 >/dev/null
  if [ $? -ne 0 ]; then return 1; fi

  unsetopt monitor
  unsetopt notify

  pipe_name=$(mktemp -u)
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title "refixing \"$last_commit_msg\"..." -- sh -c "read < $pipe_name" &
  spin_pid=$!

  $Z_CURRENT_PACKAGE_MANAGER run format &>/dev/null
  $Z_CURRENT_PACKAGE_MANAGER run lint &>/dev/null
  $Z_CURRENT_PACKAGE_MANAGER run format &>/dev/null

  echo "   refixing \"$last_commit_msg\"..."

  echo "done" > "$pipe_name" &>/dev/null
  rm "$pipe_name"
  wait $spin_pid &>/dev/null

  setopt notify
  setopt monitor

  git add .
  git commit -m "$last_commit_msg" "$@"

  if [[ -n "$Z_CURRENT_PUSH_ON_REFIX" && $Z_CURRENT_PUSH_ON_REFIX -eq 0 ]]; then
    return 0;
  fi

  if [[ "$1" != "-q" ]]; then
    if confirm_from_ "fix done, push now?"; then
      if confirm_from_ "save this preference and don't ask again?"; then
        for i in {1..10}; do
          if [[ "$Z_CURRENT_PROJECT_SHORT_NAME" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
            update_config_ "Z_PUSH_ON_REFIX_${i}" 1
            Z_CURRENT_PUSH_ON_REFIX=1
            break
          fi
        done
      fi
    else
      return 0;
    fi
  fi

  pushf "$@"
}

get_default_branch_folder_() {
  proj_folder="${1:-$PWD}"
  branch_folder=$(get_prj_for_git_ "$proj_folder")

  if [[ -z "$branch_folder" ]]; then
    return 1;
  fi

  _pwd=$(pwd)
  cd "$branch_folder"
  default_branch_folder=$(git config --get init.defaultBranch)
  cd "$_pwd"

  check_git_silent_ "$proj_folder/$default_branch_folder"
  if [ $? -eq 0 ]; then    
    echo "$proj_folder/$default_branch_folder"
  else
    echo "$branch_folder"
  fi
}

is_project_single_mode_() {
  proj="${1:-$Z_CURRENT_PROJECT_FOLDER}"

  check_any_pkg_silent_ "$proj"
  echo "$?"
}

covc() {
  if [[ -z "$1" || "$1" == "-h" ]]; then
    echo "${yellow_cor} covc <branch>${clear_cor} : to compare test coverage with another branch of the same project"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    echo " fatal: covc requires gum"
    echo " install gum:${blue_cor} https://github.com/charmbracelet/gum ${clear_cor}"
    return 1;
  fi

  if [[ -z "$Z_CURRENT_COV" && -z "$Z_CURRENT_SETUP" ]]; then
    echo " fatal: Z_COV and Z_SETUP are not set for${blue_cor} $Z_CURRENT_PROJECT_SHORT_NAME${clear_cor} - edit your pump.zshenv then run${yellow_cor} refresh ${clear_cor}"
    return 1;
  fi

  if [[ -z "$Z_CURRENT_COV" ]]; then
    echo " fatal: Z_COV is not set for${blue_cor} $Z_CURRENT_PROJECT_SHORT_NAME${clear_cor} - edit your pump.zshenv then run${yellow_cor} refresh ${clear_cor}"
    return 1;
  fi

  if [[ -z "$Z_CURRENT_SETUP" ]]; then
    echo " fatal: Z_SETUP is not set for${blue_cor} $Z_CURRENT_PROJECT_SHORT_NAME${clear_cor} - edit your pump.zshenv then run${yellow_cor} refresh ${clear_cor}"
    return 1;
  fi

  check_pkg_; if [ $? -ne 0 ]; then return 1; fi
  check_git_; if [ $? -ne 0 ]; then return 1; fi

  # git_status=$(git status --porcelain)
  # if [[ -n "$git_status" ]]; then
  #   echo " fatal: branch is not clean, cannot switch branches";
  #   return 1;
  # fi

  my_branch=$(git branch --show-current)

  if [[ "$1" == "$my_branch" ]]; then
    echo " fatal: trying to compare with the same branch";
    return 1;
  fi

  # default_branch=$(git config --get init.defaultBranch);
  # if [[ -n "$default_branch" ]]; then
  #   git fetch origin $default_branch --quiet
  #   read behind ahead < <(git rev-list --left-right --count origin/$default_branch...HEAD)
  #   if [[ $behind -ne 0 || $ahead -ne 0 ]]; then
  #     echo " warning: your branch is behind $default_branch by $behind commits and ahead by $ahead commits";
  #   fi
  # fi

  unsetopt monitor
  unsetopt notify

  pipe_name=$(mktemp -u)
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title "running test coverage on $1..." -- sh -c "read < $pipe_name" &
  spin_pid=$!

  is_single_mode=$(is_project_single_mode_)
  if [[ $is_single_mode -eq 0 ]]; then
    cov_folder=".$Z_CURRENT_PROJECT_FOLDER-coverage"
  else
    cov_folder="$Z_CURRENT_PROJECT_FOLDER/.coverage"
  fi

  _exit_code=1

  check_git_silent_ $cov_folder;
  if [[ $? -eq 0 ]]; then
    pushd "$cov_folder" &>/dev/null

    git reset --hard --quiet origin
    git fetch origin --quiet
    git switch "$1" --quiet &>/dev/null
    _exit_code=$?
  else
    rm -rf "$cov_folder" &>/dev/null
    git clone $Z_CURRENT_PROJECT_REPO "$cov_folder" --quiet
    if [ $? -ne 0 ]; then
      return 1;
    fi
    pushd "$cov_folder" &>/dev/null
    if [[ -n "$Z_CURRENT_CLONE" ]]; then
      eval "$Z_CURRENT_CLONE" &>/dev/null
    fi
    git switch "$1" --quiet &>/dev/null
    _exit_code=$?
  fi

  if [[ $_exit_code -eq 0 ]]; then
    git pull origin --quiet
    _exit_code=$?
  fi

  if [[ $_exit_code -ne 0 ]]; then
    echo "done" > "$pipe_name" &>/dev/null
    # kill $spin_pid &>/dev/null
    rm "$pipe_name"
    wait $spin_pid &>/dev/null
    setopt monitor
    setopt notify
    echo " fatal: did not match any branch known to git: $1"
    return 1;
  fi

  eval "$Z_CURRENT_SETUP" &>/dev/null

  is_delete_cov_folder=0;

  if [[ ! -d "coverage" ]]; then
    is_delete_cov_folder=1;
    mkdir -p coverage &>/dev/null
  fi

  eval "$Z_CURRENT_COV" --coverageReporters=text-summary > "coverage/coverage-summary.$1.txt" 2>&1
  if [[ $? -ne 0 ]]; then
    eval "$Z_CURRENT_COV" --coverageReporters=text-summary > "coverage/coverage-summary.$1.txt" 2>&1
  fi

  echo "   running test coverage on $1..."

  echo "done" > "$pipe_name" &>/dev/null
  # kill $spin_pid &>/dev/null
  rm "$pipe_name"
  wait $spin_pid &>/dev/null

  summary1=$(grep -A 4 "Coverage summary" "coverage/coverage-summary.$1.txt")

  # Extract each coverage percentage
  statements1=$(echo "$summary1" | grep "Statements" | awk '{print $3}' | tr -d '%')
  branches1=$(echo "$summary1" | grep "Branches" | awk '{print $3}' | tr -d '%')
  funcs1=$(echo "$summary1" | grep "Functions" | awk '{print $3}' | tr -d '%')
  lines1=$(echo "$summary1" | grep "Lines" | awk '{print $3}' | tr -d '%')

  if [[ $is_delete_cov_folder -eq 1 ]]; then
    rm -rf "coverage" &>/dev/null
  else
    rm -f "coverage/coverage-summary.$1.txt" &>/dev/null
    rm -f "coverage/coverage-summary.$my_branch.txt" &>/dev/null
  fi

  popd &>/dev/null

  is_delete_cov_folder=0;

  if [[ ! -d "coverage" ]]; then
    is_delete_cov_folder=1;
    mkdir -p coverage &>/dev/null
  fi

  pipe_name=$(mktemp -u)
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title "running test coverage on $my_branch..." -- sh -c "read < $pipe_name" &
  spin_pid=$!

  git switch "$my_branch" --quiet

  eval "$Z_CURRENT_COV" --coverageReporters=text-summary > "coverage/coverage-summary.$my_branch.txt" 2>&1
  if [[ $? -ne 0 ]]; then
    eval "$Z_CURRENT_COV" --coverageReporters=text-summary > "coverage/coverage-summary.$my_branch.txt" 2>&1
  fi

  echo "   running test coverage on $my_branch..."

  echo "done" > "$pipe_name" &>/dev/null
  # kill $spin_pid &>/dev/null
  rm "$pipe_name"
  wait $spin_pid &>/dev/null

  summary2=$(grep -A 4 "Coverage summary" "coverage/coverage-summary.$my_branch.txt")

  # Extract each coverage percentage
  statements2=$(echo "$summary2" | grep "Statements" | awk '{print $3}' | tr -d '%')
  branches2=$(echo "$summary2" | grep "Branches" | awk '{print $3}' | tr -d '%')
  funcs2=$(echo "$summary2" | grep "Functions" | awk '{print $3}' | tr -d '%')
  lines2=$(echo "$summary2" | grep "Lines" | awk '{print $3}' | tr -d '%')

  # echo "\033[32m on $1\033[0m"
  # echo "$summary1"
  # echo "\033[32m on $my_branch\033[0m"
  # echo "$summary2"

  # # Print the extracted values
  echo ""
  help_line_ "coverage" "${gray_cor}" 67
  help_line_ "${1:0:22}" "${gray_cor}" 32 "${my_branch:0:22}" 32
  echo ""

  color=$(if [[ $statements1 -gt $statements2 ]]; then echo "${red_cor}"; elif [[ $statements1 -lt $statements2 ]]; then echo "${green_cor}"; else echo ""; fi)
  echo " Statements\t\t: $(printf "%.2f" $statements1)%  |${color} Statements\t\t: $(printf "%.2f" $statements2)% ${clear_cor}"
  
  color=$(if [[ $branches1 -gt $branches2 ]]; then echo "${red_cor}"; elif [[ $branches1 -lt $branches2 ]]; then echo "${green_cor}"; else echo ""; fi)
  echo " Branches\t\t: $(printf "%.2f" $branches1)%  |${color} Branches\t\t: $(printf "%.2f" $branches2)% ${clear_cor}"
  
  color=$(if [[ $funcs1 -gt $funcs2 ]]; then echo "${red_cor}"; elif [[ $funcs1 -lt $funcs2 ]]; then echo "${green_cor}"; else echo ""; fi)
  echo " Functions\t\t: $(printf "%.2f" $funcs1)%  |${color} Functions\t\t: $(printf "%.2f" $funcs2)% ${clear_cor}"
  
  color=$(if [[ $lines1 -gt $lines2 ]]; then echo "${red_cor}"; elif [[ $lines1 -lt $lines2 ]]; then echo "${green_cor}"; else echo ""; fi)
  echo " Lines\t\t\t: $(printf "%.2f" $lines1)%  |${color} Lines\t\t: $(printf "%.2f" $lines2)% ${clear_cor}"
  echo ""

  if [[ $is_delete_cov_folder -eq 1 ]]; then
    rm -rf "coverage" &>/dev/null
  else
    rm -f "coverage/coverage-summary.$1.txt" &>/dev/null
    rm -f "coverage/coverage-summary.$my_branch.txt" &>/dev/null
  fi

  setopt monitor
  setopt notify
}

test() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} test${clear_cor} : to run Z_TEST"
    return 0;
  fi

  check_pkg_; if [ $? -ne 0 ]; then return 1; fi

  eval "$Z_CURRENT_TEST" "$@"
  if [ $? -ne 0 ]; then
    eval "$Z_CURRENT_TEST" "$@"
    if [ $? -ne 0 ]; then
      echo "\033[31m ❌ test failed\033[0m"
    else
      echo "\033[32m ✅ test passed on second run\033[0m"
    fi
  else
    echo "\033[32m ✅ test passed on first run\033[0m"
  fi
}

cov() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} cov${clear_cor} : to run Z_COV"
    return 0;
  fi

  check_pkg_; if [ $? -ne 0 ]; then return 1; fi

  if [[ $1 != -* ]]; then
    covc "$@"
    return $?;
  fi

  # check if folder is within project folder 

  if [[ -z "$Z_CURRENT_COV" ]]; then
    echo " fatal: Z_COV is not set for${blue_cor} $Z_CURRENT_PROJECT_SHORT_NAME${clear_cor} - edit your pump.zshenv then run${yellow_cor} refresh ${clear_cor}"
    return 1;
  fi
  
  eval "$Z_CURRENT_COV" "$@"
  if [ $? -ne 0 ]; then
    eval "$Z_CURRENT_COV" "$@"
    if [ $? -ne 0 ]; then
      echo "\033[31m ❌ test coverage failed\033[0m"
    else
      echo "\033[32m ✅ test coverage passed on second run\033[0m"
    fi
  else
    echo "\033[32m ✅ test coverage passed on first run\033[0m"
  fi
}

testw() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} testw${clear_cor} : to run Z_TEST_WATCH"
    return 0;
  fi

  check_pkg_; if [ $? -ne 0 ]; then return 1; fi

  eval "$Z_CURRENT_TEST_WATCH" "$@"
}

e2e() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} e2e${clear_cor} : to run Z_E2E"
    echo "${yellow_cor} e2e <e2e_project>${clear_cor} : to run Z_E2E --project <e2e_project>"
    return 0;
  fi

  check_pkg_; if [ $? -ne 0 ]; then return 1; fi

  if [[ -z "$1" ]]; then
    eval "$Z_CURRENT_E2E"
  else
    eval "$Z_CURRENT_E2E" --project="$1" "${@:2}"
  fi
}

e2eui() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} e2eui${clear_cor} : to run Z_E2EUI"
    echo "${yellow_cor} e2eui ${solid_yellow_cor}<project>${clear_cor} : to run Z_E2EUI --project"
    return 0;
  fi

  check_pkg_; if [ $? -ne 0 ]; then return 1; fi

  if [[ -z "$1" ]]; then
    eval "$Z_CURRENT_E2EUI"
  else
    eval "$Z_CURRENT_E2EUI" --project="$1" "${@:2}"
  fi
}

add() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} add${clear_cor} : to add all files to index"
    echo "${yellow_cor} add ${solid_yellow_cor}<files>${clear_cor} : to add files to index"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  if [[ -z "$1" ]]; then
    git add . "$@"
  else
    git add "$@"
  fi
}

# Creating PRs =============================================================
pr() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} pr${clear_cor} : to create a pull request"
    echo "${yellow_cor} pr -s${clear_cor} : to create a pull request, skip test"
    echo "${yellow_cor} pr <labels>${clear_cor} : to create a pull request with labels"
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    echo " fatal: pr requires gh"
    echo " install gh:${blue_cor} https://github.com/cli/cli ${clear_cor}"
    return 1;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  # Initialize an empty string to store the commit details
  commit_msgs=""
  pr_title=""

  # Get the current branch name
  # HEAD_COMMIT=$(git merge-base f-WMG1-247-performanceView HEAD)
  # my_branch=$(git branch --show-current)
  # OPTIONS="--abbrev-commit HEAD"

   git log $(git merge-base HEAD $(git config --get init.defaultBranch))..HEAD --no-merges --oneline --pretty=format:'%H | %s' | xargs -0 | while IFS= read -r line; do
    commit_hash=$(echo "$line" | cut -d'|' -f1 | xargs)
    commit_message=$(echo "$line" | cut -d'|' -f2- | xargs -0)

    # # Check if the commit belongs to the current branch
    # if ! git branch --contains "$commit_hash" | grep -q "\b$my_branch\b"; then
    #   break;
    # fi

    dirty_pr_title="$commit_message"
    pattern='.*\b(fix|feat|docs|refactor|test|chore|style|revert)(\s*\([^)]*\))?:\s*'
    if [[ "$dirty_pr_title" =~ $pattern ]]; then
      stripped="${dirty_pr_title/${match[0]}/}"
      pr_title="$stripped"
    else
      pr_title="$dirty_pr_title"
    fi

    pr_title="$dirty_pr_title"

    if [[ $dirty_pr_title =~ ([[:alnum:]]+-[[:digit:]]+) ]]; then
      ticket="${match[1]}"

      trimmed="${ticket#"${str%%[![:space:]]*}"}"
      trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"

      pr_title="$trimmed"
      
      if [[ $dirty_pr_title =~ [[:alnum:]]+-[[:digit:]]+(.*) ]]; then
        rest="${match[1]}"
        trimmed="${rest#"${str%%[![:space:]]*}"}"
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"

        pr_title="$pr_title$trimmed"
      fi
    fi

    # Add the commit hash and message to the list
    commit_msgs+="- $commit_hash - $commit_message"$'\n'

    # # Stop if the commit is the origin/HEAD commit
    # if [[ "$commit_hash" == "$HEAD_COMMIT" ]]; then
    #   break;
    # fi
  done

  if [[ ! -n "$commit_msgs" ]]; then
    echo " no commits found, try${yellow_cor} push${clear_cor} first.";
    return 0;
  fi

  pr_body="$commit_msgs"

  if [[ -f "$Z_CURRENT_PR_TEMPLATE" && -n "$Z_CURRENT_PR_REPLACE" ]]; then
    PR_TEMPLATE=$(cat $Z_CURRENT_PR_TEMPLATE)

    if [[ $Z_CURRENT_PR_APPEND -eq 1 ]]; then
      # Append commit msgs right after Z_CURRENT_PR_REPLACE in pr template
      pr_body=$(echo "$PR_TEMPLATE" | perl -pe "s/(\Q$Z_CURRENT_PR_REPLACE\E)/\1\n\n$commit_msgs\n/")
    else
      # Replace Z_CURRENT_PR_REPLACE with commit msgs in pr template
      pr_body=$(echo "$PR_TEMPLATE" | perl -pe "s/\Q$Z_CURRENT_PR_REPLACE\E/$commit_msgs/g")
    fi
  fi

  if [[ -z "$Z_CURRENT_PR_RUN_TEST" ]]; then
    if confirm_from_ "run tests before a pull request?"; then
      test
      if [ $? -ne 0 ]; then
        echo "${solid_red_cor} fatal: tests are not passing,${clear_cor} did not push";
        return 1;
      fi

      if confirm_from_ "save this preference and don't ask again?"; then
        for i in {1..10}; do
          if [[ "$Z_CURRENT_PROJECT_SHORT_NAME" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
            update_config_ "Z_PR_RUN_TEST_${i}" 1
            Z_CURRENT_PR_RUN_TEST=1
            break
          fi
        done
        echo ""
      fi
    fi
  elif [[ $Z_CURRENT_PR_RUN_TEST -eq 1 && "$1" != "-s" ]]; then
    git_status=$(git status --porcelain)
    if [[ -n "$git_status" ]]; then
      if ! confirm_from_ "skip test?"; then
        return 0;
      fi
    else
      test
      if [ $? -ne 0 ]; then
        echo "${solid_red_cor} fatal: tests are not passing,${clear_cor} did not push";
        return 1;
      fi
    fi
  fi

  ## debugging purposes
  # echo " pr_title:$pr_title"
  # echo ""
  # echo "$pr_body"
  # return 0;

  push

  my_branch=$(git branch --show-current);

  if [[ -z "$1" ]]; then
    gh pr create -a="@me" --title="$pr_title" --body="$pr_body" --web --head="$my_branch"
  else
    gh pr create -a="@me" --title="$pr_title" --body="$pr_body" --web --head="$my_branch" --label="$1"
  fi
}

run() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} run${clear_cor} : to run dev in current folder"
    echo " --"
    echo "${yellow_cor} run dev${clear_cor} : to run dev in current folder"
    echo "${yellow_cor} run stage${clear_cor} : to run stage in current folder"
    echo "${yellow_cor} run prod${clear_cor} : to run prod in current folder"
    echo " --"
    if [[ -n "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
      echo "${yellow_cor} run <folder>${clear_cor} : to run a folder on dev environment for $Z_CURRENT_PROJECT_SHORT_NAME"
      echo "${yellow_cor} run${solid_yellow_cor} [<folder>] [<env>]${clear_cor} : to run a folder on environment for $Z_CURRENT_PROJECT_SHORT_NAME"
      echo " --"
    fi
    echo "${yellow_cor} run <pro>${solid_yellow_cor} [<folder>] [<env>]${clear_cor} : to run a folder on environment for a project"
    return 0;
  fi

  if [[ $1 == -* ]]; then
    eval "run -h"
    return 0;
  fi

  proj_arg=""
  folder_arg=""
  _env="dev"

  if [[ -n "$3" ]]; then
    proj_arg="$1"
    _env="$3"
    folder_arg="$2"
  elif [[ -n "$2" ]]; then
    if [[ "$1" =~ ^(Z_PROJECT_SHORT_NAME_[1-9]|Z_PROJECT_SHORT_NAME_10)$ ]]; then
      proj_arg="${1:-$Z_CURRENT_PROJECT_SHORT_NAME}"
      if [[ "$2" == "dev" || "$2" == "stage" || "$2" == "prod" ]]; then
        for i in {1..10}; do
          if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
            check_any_pkg_silent_ "${Z_PROJECT_FOLDER[$i]}"
            if [[ $? -eq 0 ]]; then
              _env="$2"
            else
              folder_arg="$2"
            fi
            break
          fi
        done
      else
        folder_arg="$2"
      fi
    else
      folder_arg="$1"
      _env="$2"
    fi
  elif [[ -n "$1" ]]; then
    if [[ "$1" =~ ^(Z_PROJECT_SHORT_NAME_[1-9]|Z_PROJECT_SHORT_NAME_10)$ ]]; then
      proj_arg="$1"
    elif [[ "$1" == "dev" || "$1" == "stage" || "$1" == "prod" ]]; then
      _env="$1"
    else
      folder_arg="$1"
    fi
  fi

  # Validate environment
  if [[ "$_env" != "dev" && "$_env" != "stage" && "$_env" != "prod" ]]; then
    echo " fatal: env is incorrect, valid options: dev, stage or prod"
    echo " ${yellow_cor} run -h${clear_cor} to see usage"
    return 1;
  fi

  proj_folder=""
  _run="$Z_CURRENT_RUN"

  if [[ "$_env" == "stage" ]]; then
    _run="$Z_CURRENT_RUN_STAGE"
  elif [[ "$_env" == "prod" ]]; then
    _run="$Z_CURRENT_RUN_PROD"
  fi

  if [[ -n "$proj_arg" ]]; then
    for i in {1..10}; do
      if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        check_prj_ $i
        if [ $? -ne 0 ]; then return 1; fi

        proj_folder="${Z_PROJECT_FOLDER[$i]}"
        _run="${Z_RUN[$i]}"

        if [[ "$_env" == "stage" ]]; then
          _run="${Z_RUN_STAGE[$i]}"
        elif [[ "$_env" == "prod" ]]; then
          _run="${Z_RUN_PROD[$i]}"
        fi
        break
      fi
    done
  else
    proj_arg="$Z_CURRENT_PROJECT_SHORT_NAME"
  fi

  if [[ -z "$_run" ]]; then
    echo " no Z_RUN for${solid_blue_cor} $proj_arg${clear_cor} - edit your pump.zshenv config then run${yellow_cor} refresh ${clear_cor}"
    echo ""
    return 0;
  fi

  folder_to_run=""

  if [[ -n "$folder_arg" && -n "$proj_folder" ]]; then
    check_any_pkg_ "$proj_folder/$folder_arg"
    if [ $? -ne 0 ]; then return 1; fi
    folder_to_run="$proj_folder/$folder_arg"
  elif [[ -n "$proj_folder" ]]; then
    # check if proj_folder is a project
    check_any_pkg_silent_ "$proj_folder"
    if [ $? -eq 0 ]; then
      folder_to_run="$proj_folder"
    else
      if [[ -n ${(f)"$(get_folders_ "$proj_folder")"} ]]; then
        folders=($(get_folders_ "$proj_folder"))
        folder_to_run=($(choose_auto_one_ "choose folder to run:" "${folders[@]}"))
        if [[ -z "$folder_to_run" ]]; then
          return 0;
        fi
      fi
    fi
  elif [[ -n "$folder_arg" ]]; then
    check_any_pkg_ "$folder_arg"
    if [ $? -ne 0 ]; then return 1; fi
    folder_to_run="$folder_arg"
  else
    check_any_pkg_;
    if [ $? -ne 0 ]; then return 1; fi
    folder_to_run="."
  fi

  # debugging
  # echo "proj_arg=$proj_arg"
  # echo "folder_arg=$folder_arg"
  # echo "_env=$_env"
  # echo "folder_to_run=$folder_to_run"
  # echo " --------"

  pushd "$folder_to_run" &>/dev/null

  echo " run $_env on ${gray_cor}$(shorten_path_ "$folder_arg") ${clear_cor}:${pink_cor} $_run ${clear_cor}"
  eval "$_run"
}

setup() {
  if [[ "$1" == "-h" ]]; then
      echo "${yellow_cor} setup${clear_cor} : to setup current folder"
      if [[ -n "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
        echo "${yellow_cor} setup <folder>${clear_cor} : to setup a folder for $Z_CURRENT_PROJECT_SHORT_NAME"
      fi
      echo " --"
    echo "${yellow_cor} setup <pro>${solid_yellow_cor} [<folder>]${clear_cor} : to setup a folder for a project"
    return 0;
  fi

  if [[ $1 == -* ]]; then
    eval "setup -h"
    return 0;
  fi

  proj_arg=""
  folder_arg=""

  if [[ -n "$2" ]]; then
    proj_arg="$1"
    folder_arg="$2"
  elif [[ -n "$1" ]]; then
    if [[ "$1" =~ ^(Z_PROJECT_SHORT_NAME_[1-9]|Z_PROJECT_SHORT_NAME_10)$ ]]; then
      proj_arg="$1"
    else
      folder_arg="$1"
    fi
  fi

  proj_folder="";
  _setup=${Z_CURRENT_SETUP:-$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")setup}

  if [[ -n "$proj_arg" ]]; then
    for i in {1..10}; do
      if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        check_prj_ $i
        if [ $? -ne 0 ]; then return 1; fi

        proj_folder="${Z_PROJECT_FOLDER[$i]}"
        _setup="${Z_SETUP[$i]:-${Z_PACKAGE_MANAGER[$i]} $([[ ${Z_PACKAGE_MANAGER[$i]} == "yarn" ]] && echo "" || echo "run ")setup}"
        break
      fi
    done

    if [[ -z "$proj_folder" ]]; then
      echo " fatal: not a valid project: $proj_arg"
      echo " ${yellow_cor} setup -h${clear_cor} to see usage"
      return 1;
    fi
  fi

  if [[ -z "$_setup" ]]; then
    echo " no Z_SETUP for${solid_blue_cor} $proj_arg${clear_cor} - edit your pump.zshenv config then run${yellow_cor} refresh ${clear_cor}"
    echo ""
    return 0;
  fi

  folder_to_setup=""

  if [[ -n "$folder_arg" && -n "$proj_folder" ]]; then
    check_any_pkg_ "$proj_folder/$folder_arg"
    if [ $? -ne 0 ]; then return 1; fi
    folder_to_setup="$proj_folder/$folder_arg"
  elif [[ -n "$proj_folder" ]]; then
    # check if proj_folder is a project
    check_any_pkg_silent_ "$proj_folder"
    if [ $? -eq 0 ]; then
      folder_to_setup="$proj_folder"
    else
      if [[ -n ${(f)"$(get_folders_ "$proj_folder")"} ]]; then
        folders=($(get_folders_ "$proj_folder"))
        folder_to_setup=($(choose_auto_one_ "choose folder to setup:" "${folders[@]}"))
        if [[ -z "$folder_to_setup" ]]; then
          return 0;
        fi
      fi
    fi
  elif [[ -n "$folder_arg" ]]; then
    check_any_pkg_ "$folder_arg"
    if [ $? -ne 0 ]; then return 1; fi
    folder_to_setup="$folder_arg"
  else
    check_any_pkg_;
    if [ $? -ne 0 ]; then return 1; fi
    folder_to_setup="."
  fi

  # debugging
  # echo "proj_arg=$proj_arg"
  # echo "folder_arg=$folder_arg"
  # echo "folder_to_setup=$folder_to_setup"
  # echo " --------"

  pushd "$folder_to_setup" &>/dev/null

  echo " setup on ${gray_cor}$(shorten_path_) ${clear_cor}:${pink_cor} $_setup ${clear_cor}"
  eval "$_setup"
}

# Clone =====================================================================
# review branch
revs() {
  if [[ "$1" == "-h" ]]; then
    if [[ -n "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
      echo "${yellow_cor} revs${clear_cor} : to list reviews from $Z_CURRENT_PROJECT_SHORT_NAME"
    fi
    echo "${yellow_cor} revs <pro>${clear_cor} : to list reviews from project"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    echo " fatal: revs requires gum"
    echo " install gum:${blue_cor} https://github.com/charmbracelet/gum ${clear_cor}"
    return 1;
  fi
  
  proj_arg="$Z_CURRENT_PROJECT_SHORT_NAME"

  if [[ -n "$1" ]]; then
    valid_project=0
    for i in {1..10}; do
      if [[ "$1" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        proj_arg="${1:-$Z_CURRENT_PROJECT_SHORT_NAME}"
        valid_project=1
        break
      fi
    done

    if [[ $valid_project -eq 0 ]]; then
      echo " fatal: not a valid project: $1"
      echo " ${yellow_cor} pro${clear_cor} to see options"
      return 1
    fi
  fi

  proj_folder=""

  for i in {1..10}; do
    if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
      check_prj_ $i
      if [ $? -ne 0 ]; then return 1; fi

      proj_folder="${Z_PROJECT_FOLDER[$i]}"
      break
    fi
  done

  if [[ -z $proj_folder ]]; then
    echo " fatal: not a valid project: $proj_arg"
    echo " ${yellow_cor} revs -h${clear_cor} to see usage"
    return 1
  fi

  _pwd="$(PWD)";

  revs_folder="$proj_folder/revs"

  if [[ -d "$revs_folder" ]]; then
    cd "$revs_folder"
  else
    revs_folder=".$proj_folder-revs"
    if [[ -d "$revs_folder" ]]; then
      cd "$revs_folder"
    else
      echo " no revs for $proj_folder"
      echo " ${yellow_cor} rev${clear_cor} to open a review"
      return 1; 
    fi
  fi

  rev_choices=$(ls -d rev* | xargs -0 | sort -fu)

  if [[ -z "$rev_choices" ]]; then
    echo " no revs for $proj_folder"
    echo " ${yellow_cor} rev${clear_cor} to open a review"
    cd "$_pwd"
    return 1;
  fi

  choice=$(gum choose --limit=1 --header " choose review to open:" $(echo "$rev_choices" | tr ' ' '\n'))
  if [[ $? -eq 0 && -n "$choice" ]]; then
    rev "$proj_arg" "${choice//rev./}" -q
  fi

  cd "$_pwd"
  return 0;
}

rev() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} rev${clear_cor} : open a pull request for review"
    if [[ -n "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
      echo "${yellow_cor} rev${solid_yellow_cor} [<branch>]${clear_cor} : to open a review for $Z_CURRENT_PROJECT_SHORT_NAME"
    fi
    echo "${yellow_cor} rev <pro>${solid_yellow_cor} [<branch>]${clear_cor} : to open a review for a project"
    return 0;
  fi

  if [[ $1 == -* ]]; then
    rev -h
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    echo " fatal: rev requires gum"
    echo " install gum:${blue_cor} https://github.com/charmbracelet/gum ${clear_cor}"
    return 1;
  fi

  proj_arg="$Z_CURRENT_PROJECT_SHORT_NAME"
  branch_arg=""

  if [[ -n "$2" ]]; then
    proj_arg="$1"
    branch_arg="$2"
  elif [[ -n "$1" ]]; then
    if [[ "$1" =~ ^(Z_PROJECT_SHORT_NAME_[1-9]|Z_PROJECT_SHORT_NAME_10)$ ]]; then
      proj_arg="$1"
    else
      branch_arg="$1"
    fi
  fi

  proj_repo=""
  proj_folder=""
  _setup=""
  _clone=""
  code_editor="$Z_CURRENT_PROJECT_REPO"

  for i in {1..10}; do
    if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
      check_prj_ $i
      if [ $? -ne 0 ]; then return 1; fi
      
      # If the repository URI is not set, ask for it
      if [[ -z "${Z_PROJECT_REPO[$i]}" ]]; then
        echo " type the repository uri you use for${solid_blue_cor} ${Z_PROJECT_SHORT_NAME[$i]} ${clear_cor}"
        repo_value=$(gum input --placeholder="git@github.com:fab1o/pump-my-shell.git")
        if [[ -z "$repo_value" ]]; then
          return 1
        fi
        echo "  $repo_value"
        update_config_ "$project_repo_var" "$repo_value"
        echo ""
      fi

      proj_repo="${Z_PROJECT_REPO[$i]}"
      proj_folder="${Z_PROJECT_FOLDER[$i]}"
      _setup="${Z_SETUP[$i]}"
      _clone="${Z_CLONE[$i]}"
      code_editor="${Z_CODE_EDITOR[$i]}"
      break
    fi
  done

  # If no valid project was found
  if [[ -z "$proj_repo" ]]; then
    echo " fatal: not a valid project: $proj_arg"
    echo " ${yellow_cor} rev -h${clear_cor} to see usage"
    return 1
  fi

  if [[ -z "$proj_repo" || -z "$proj_folder" ]]; then
    echo " could not located repository uri or project folder, please check your config"
    echo "  run${yellow_cor} help${clear_cor} for more information"
    return 1;
  fi

  _pwd="$(PWD)";

  branch="";

  if [[ -z "$3" ]]; then # -q
    open_prj_for_git_ "$proj_folder"; if [ $? -ne 0 ]; then return 1; fi

    git fetch origin --quiet

    if [[ -z "$1" || -z "$branch_arg" ]]; then
      select_pr_;
      if [ $? -ne 0 ]; then
        cd "$_pwd"
        return 1;
      fi

      if [[ -n "$select_pr_choice" ]]; then
        rev "$proj_arg" "$select_pr_branch" -q
        # cd "$_pwd"
        return 0;
      fi

      echo " fatal: could not find a branch."
      cd "$_pwd"
      return 1;
    fi

    select_pr_ "$branch_arg";
    if [ $? -ne 0 ]; then
      cd "$_pwd"
      return 1;
    fi

    if [[ -n "$select_pr_choice" ]]; then
      rev "$proj_arg" "$select_pr_branch" -q
      # cd "$_pwd"
      return 0;
    fi

    echo " fatal: did not match any branch known to git: $branch_arg"
    cd "$_pwd"
    return 1;
  else
    branch="$branch_arg"
  fi

  branch_folder="${branch//\\/-}";
  branch_folder="${branch_folder//\//-}";

  revs_folder=""

  # check if using the proj_folder as single clone mode
  is_single_mode=$(check_any_pkg_silent_ "$proj_folder")
  if [[ $is_single_mode -eq 0 ]]; then
    revs_folder=".$proj_folder-revs"
  else
    revs_folder="$proj_folder/revs"
  fi

  full_rev_folder="$revs_folder/rev.$branch_folder"

  is_open_editor=0

  if [[ -d "$full_rev_folder" ]]; then
    echo " review already exist, opening${green_cor} $(shorten_path_ $full_rev_folder) ${clear_cor}"
    
    pushd "$full_rev_folder" &>/dev/null
    
    git_status=$(git status --porcelain)
    if [[ -n "$git_status" ]]; then
      if ! confirm_from_ "branch is not clean, reset?"; then
        return 0;
      fi
      echo " resetting..."
      reseta
    fi
    git checkout "$branch" --quiet
    echo " pulling latest changes..."
    git pull origin --quiet
    if [ $? -ne 0 ]; then
      is_open_editor=1
      echo ""
      echo "${yellow_cor} warn: could not pull latest changes, probably already merged ${clear_cor}"
      echo ""
    fi

    if [[ -n "$_setup" ]]; then
      echo "${pink_cor} $_setup ${clear_cor}"
      eval "$_setup"
      if [ $? -eq 0 ]; then
        if [ $is_open_editor -eq 0 ]; then
          eval $code_editor .
        fi
      fi
    fi

    return 0;
  fi

  echo " creating review for${green_cor} $select_pr_title${clear_cor}..."

  if command -v gum &>/dev/null; then
    gum spin --title "cloning... $proj_repo" -- git clone $proj_repo "$full_rev_folder" --quiet
  else
    echo " cloning... $proj_repo";
    git clone $proj_repo "$full_rev_folder" --quiet
  fi
  if [[ $? -ne 0 ]]; then
    return 1;
  fi

  pushd "$full_rev_folder" &>/dev/null

  if [[ -n "$_clone" ]]; then
    eval "$_clone" &>/dev/null
  fi

  error_msg=""
  git checkout "$branch" --quiet
  git pull origin --quiet
  if [[ $? -ne 0 ]]; then
    is_open_editor=1
    error_msg="${yellow_cor} warn: could not pull latest changes, probably already merged ${clear_cor}"
  fi

  if [[ -n "$_setup" ]]; then
    echo "${pink_cor} $_setup ${clear_cor}"
    eval "$_setup"
    if [ $? -eq 0 ]; then
      if [ $is_open_editor -eq 0 ]; then
        eval "$code_editor" .
      fi
    fi
  fi

  if [[ -n "$error_msg" ]]; then
    echo ""
    echo "$error_msg"
    echo ""
  fi
}

get_clone_default_branch_() { # $1 = repo uri # $2 = folder # $3 = branch to clone
  if [[ "$3" == "main" || "$3" == "master" ]]; then
    echo "$3"
    return 0;
  fi

  if command -v gum &>/dev/null; then
    gum spin --title "determining the default branch..." -- rm -rf "$2/.temp"
    gum spin --title "determining the default branch..." -- git clone "$1" "$2/.temp" --quiet
  else
    echo " determining the default branch...";
    rm -rf "$2/.temp" &>/dev/null
    git clone "$1" "$2/.temp" --quiet
  fi
  if [ $? -ne 0 ]; then
    return 1;
  fi  

  pushd "$2/.temp" &>/dev/null
  
  default_branch=$(git config --get init.defaultBranch)
  my_branch=$(git branch --show-current)

  popd &>/dev/null

  rm -rf "$2/.temp" &>/dev/null

  default_branch_folder="${default_branch//\\/-}"
  default_branch_folder="${default_branch_folder//\//-}"

  my_branch_folder="${my_branch//\\/-}"
  my_branch_folder="${my_branch_folder//\//-}"

  if [[ -z "$3" ]]; then
    if [[ -d "$2/$default_branch_folder" ]]; then
      default_branch=""
    fi

    if [[ -d "$2/$my_branch_folder" ]]; then
      my_branch=""
    fi
  fi

  default_branch_choice="";

  if [[ "$my_branch" != "$default_branch" && -n "$default_branch" && -n "$my_branch" ]]; then
    default_branch_choice=$(choose_auto_one_ "choose default branch:" "$default_branch" "$my_branch");
  elif [[ -n "$default_branch" ]]; then
    default_branch_choice="$default_branch";
  elif [[ -n "$my_branch" ]]; then
    default_branch_choice="$my_branch";
  fi

  if [[ -z "$default_branch_choice" ]]; then
    return 1;
  fi

  echo "$default_branch_choice"
  return 0;
}

# clone my project and checkout branch
clone() {
  if [[ "$1" == "-h" ]]; then
    if [[ -n "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
      echo "${yellow_cor} clone <branch>${clear_cor} : to clone $Z_CURRENT_PROJECT_SHORT_NAME branch"
      echo "${yellow_cor} clone $Z_CURRENT_PROJECT_SHORT_NAME${solid_yellow_cor} [<branch>]${clear_cor} : to clone $Z_CURRENT_PROJECT_SHORT_NAME branch"
    fi
      echo "${yellow_cor} clone <pro>${solid_yellow_cor} [<branch>]${clear_cor} : to clone another project"
    return 0;
  fi

  if [[ $1 == -* ]]; then
    clone -h
    return 0;
  fi

  proj_arg="$Z_CURRENT_PROJECT_SHORT_NAME"
  branch_arg=""

  if [[ -n "$2" ]]; then
    proj_arg="$1"
    branch_arg="$2"
  elif [[ -n "$1" ]]; then
    valid_project=0
    for i in {1..10}; do
      if [[ "$1" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        proj_arg="$1"
        valid_project=1
        break
      fi
    done
    if [[ $valid_project -eq 0 ]]; then
      branch_arg="$1"
    fi
  else
    pro_choices=()
    for i in {1..10}; do
      if [[ -n "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        pro_choices+=("${Z_PROJECT_SHORT_NAME[$i]}")
      fi
    done

    proj_arg=$(choose_auto_one_ "choose project to clone:" "${pro_choices[@]}")
    if [[ -z "$proj_arg" ]]; then
      return 1
    fi
  fi

  proj_repo=""
  proj_folder=""
  _clone=""
  default_branch=""
  print_readme=1

  if [[ -n "$proj_arg" ]]; then
    for i in {1..10}; do
      if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        if [[ -z "${Z_PROJECT_REPO[$i]}" ]]; then
          echo " type the repository uri you use for${solid_blue_cor} $proj_arg ${clear_cor}"
          Z_PROJECT_REPO[$i]=$(input_from_ "git@github.com:fab1o/pump-my-shell.git")
          if [[ -z "${Z_PROJECT_REPO[$i]}" ]]; then
            return 1
          fi
          echo "  ${Z_PROJECT_REPO[$i]}"
          update_config_ "Z_PROJECT_REPO_${i}" "${Z_PROJECT_REPO[$i]}"
          echo ""
        fi

        check_prj_ $i -q; if [ $? -ne 0 ]; then return 1; fi

        proj_repo="${Z_PROJECT_REPO[$i]}"
        proj_folder="${Z_PROJECT_FOLDER[$i]}"
        _clone="${Z_CLONE[$i]}"
        default_branch="${Z_DEFAULT_BRANCH[$i]}"
        print_readme="${Z_PRINT_README[$i]}"
        break
      fi
    done
  fi

  if [[ -z "$proj_repo" ]]; then
    echo " could not located repository uri, run${yellow_cor} help ${clear_cor}"
    return 1;
  fi

  if [[ -z "$proj_folder" ]]; then
    echo " could not located project folder, run${yellow_cor} help ${clear_cor}"
    return 1;
  fi

  work_mode=""

  if [[ -d "$proj_folder" ]]; then
    is_single_mode=$(is_project_single_mode_ "$proj_folder")
    if [ $is_single_mode -eq 0 ]; then             # SINGLE MODE
      echo "${solid_blue_cor} $proj_arg${clear_cor} already cloned in 'single mode': $proj_folder"
      echo ""
      echo " to clone a different branch, you must start over in 'multi mode':"
      echo "  1. either delete:${yellow_cor} del \"$proj_folder\" ${clear_cor}"
      echo "     or change the entry in your pump.zshenv then${yellow_cor} refresh${clear_cor}"
      echo "  2. clone again:${yellow_cor} clone $proj_arg $branch_arg ${clear_cor}"
      return 1;
    else
      if [[ -n "$(ls -A "$proj_folder")" ]]; then
        # is multi mode
        work_mode="m"
      fi
    fi
  fi

  branch_to_clone=""
  is_user_selected_mode=0;

  if [[ -z "$branch_arg" && -z "$work_mode" ]]; then
    # ask user if they want to single project mode, or multiple mode
    if command -v gum &>/dev/null; then
      gum confirm ""mode:$'\e[0m'" how do you prefer to manage $proj_arg? single or multiple repositories?" --affirmative="single" --negative="multiple"
      RET=$?
      if [[ $RET -eq 0 ]]; then
        work_mode="s"
      elif [[ $RET -eq 1 ]]; then
        work_mode="m"
      else
        return 0;
      fi
    else
    # no gum
      while true; do
        echo -n ""$'\e[38;5;99m'mode:$'\e[0m'" how do you prefer to manage $proj_arg? "$'\e[38;5;218m'single$'\e[0m'" or "$'\e[38;5;218m'multiple$'\e[0m'" repositories? [s/m]: "
        stty -echo                  # Turn off input echo
        read -k 1 mode              # Read one character
        stty echo                   # Turn echo back on
        case "$mode" in
          [sSmM]) break ;;          # Accept only s or m (case-insensitive)
          *) echo "" ;;
        esac
      done
      if [[ "$mode" == "s" || "$mode" == "S" ]]; then
        work_mode="s"
      elif [[ "$mode" == "m" || "$mode" == "M" ]]; then
        work_mode="m"
      else
        return 0;
      fi
    fi

    is_user_selected_mode=1;

    if [[ "$work_mode" == "s" ]]; then
      if [[ -d "$proj_folder" && -n "$(ls -A "$proj_folder")" ]]; then
        echo "  ${solid_yellow_cor}project folder '$proj_folder' is not empty, going with 'multi mode' ${clear_cor}"
      else
        default_branch_to_clone=$(get_clone_default_branch_ "$proj_repo" "$proj_folder");

        if [[ -z "$default_branch_to_clone" ]]; then
          return 0;
        fi

        if command -v gum &>/dev/null; then
          gum spin --title "cloning... $proj_repo on $default_branch_to_clone" -- git clone --quiet $proj_repo "$proj_folder"
          echo "   cloning... $proj_repo on $default_branch_to_clone"
        else
          echo "  cloning... $proj_repo on $default_branch_to_clone"
          git clone --quiet $proj_repo "$proj_folder"
        fi
        if [[ $? -ne 0 ]]; then
          echo "  could not clone"
          if [[ -d "$proj_folder" ]]; then
            echo "  project folder already exists: $proj_folder"
          fi
          return 1;
        fi        

        pushd "$proj_folder" &>/dev/null

        git config init.defaultBranch "$default_branch_to_clone"
        git checkout "$default_branch_to_clone" --quiet &>/dev/null

        save_pump_working_ "$proj_arg" "$(git branch --show-current)" "branch"

        #refresh >/dev/null 2>&1

        if [[ -n "$_clone" ]]; then
          echo "  ${pink_cor}$_clone ${clear_cor}"
          eval "$_clone"
        fi

        if [[ $print_readme -eq 1 ]] && command -v glow &>/dev/null; then
          # find readme file
          readme_file=$(find . -type f \( -iname "README*" -o -iname "readme*" \) | head -n 1);
          if [[ -n "$readme_file" ]]; then
            glow "$readme_file"
          fi
        fi

        echo ""
        echo "  default branch is${bright_green_cor} $(git config --get init.defaultBranch) ${clear_cor}"
        echo ""

        if [[ "$proj_arg" != "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
          pro $proj_arg
        fi
        return 0;
      fi
    fi
    # end of -z "$branch_arg" && -z "$work_mode"
  fi

  # multiple mode (requires passing a branch name)
  if [[ -n "$branch_arg" ]]; then
    branch_to_clone="$branch_arg"
  else
    if [[ $is_user_selected_mode -eq 0 ]]; then
      echo "${purple_cor} type a branch name: ${clear_cor}"
      branch_to_clone=$(input_name_ 50);
    else
      branch_to_clone=$(get_clone_default_branch_ "$proj_repo" "$proj_folder");
    fi

    if [[ -z "$branch_to_clone" ]]; then
      return 0;
    fi
  fi

  if [[ -z "$default_branch" ]]; then
    if [[ -n "$branch_arg" ]]; then
      default_branch=$(get_clone_default_branch_ "$proj_repo" "$proj_folder" "$branch_arg");

      if [[ -z "$default_branch" ]]; then
        return 0;
      fi
    else
      default_branch="$branch_to_clone"
    fi

    if confirm_from_ "save '$default_branch' as the default branch for $proj_arg and don't ask again?"; then
      for i in {1..10}; do
        if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
          update_config_ "Z_DEFAULT_BRANCH_${i}" "$default_branch"
          Z_DEFAULT_BRANCH[$i]="$default_branch"
          break
        fi
      done
      echo ""
    fi
  fi

  branch_to_clone="$branch_to_clone"

  branch_to_clone_folder="${branch_to_clone//\\/-}"
  branch_to_clone_folder="${branch_to_clone_folder//\//-}"

  if command -v gum &>/dev/null; then
    gum spin --title "cloning... $proj_repo on $branch_to_clone" -- git clone --quiet $proj_repo "$proj_folder/$branch_to_clone_folder"
    echo "   cloning... $proj_repo on $branch_to_clone"
  else
    echo "  cloning... $proj_repo on $branch_to_clone"
    git clone --quiet $proj_repo "$proj_folder/$branch_to_clone_folder"
  fi
  if [[ $? -ne 0 ]]; then
    echo "  could not clone"
    if [[ -d "$proj_folder/$branch_to_clone_folder" ]]; then
      echo "  project folder exists: $proj_folder/$branch_to_clone_folder"
    fi
    return 1;
  fi

  # multiple mode

  pushd "$proj_folder/$branch_to_clone_folder" &>/dev/null
  if [[ $? -eq 0 ]]; then
    save_pump_working_ "$proj_arg" "$(PWD)" "folder"
  fi
  
  git config init.defaultBranch $default_branch

  if [[ "$branch_to_clone" != "$(git branch --show-current)" ]]; then
    # check if branch exist
    remote_branch=$(git ls-remote --heads origin "$branch_to_clone")
    local_branch=$(git branch --list "$branch_to_clone" | head -n 1)

    if [[ -z "$remote_branch" && -z "$local_branch" ]]; then
      git checkout -b "$branch_to_clone" --quiet
    else
      git checkout "$branch_to_clone" --quiet
    fi
  fi

  # multiple mode

  if [[ -n "$_clone" ]]; then
    echo "  ${pink_cor}$_clone ${clear_cor}"
    eval "$_clone"
  fi

  if [[ $print_readme -eq 1 ]] && command -v glow &>/dev/null; then
    # find readme file
    readme_file=$(find . -type f \( -iname "README*" -o -iname "readme*" \) | head -n 1);
    if [[ -n "$readme_file" ]]; then
      glow "$readme_file"
    fi
  fi

  echo ""
  echo "  default branch is${bright_green_cor} $(git config --get init.defaultBranch) ${clear_cor}"
  echo ""

  if [[ "$proj_arg" != "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
    pro $proj_arg
  fi
}

abort() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} abort${clear_cor} : to abort any in progress rebase, merge and cherry-pick"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  GIT_EDITOR=true git rebase --abort &>/dev/null
  GIT_EDITOR=true git merge --abort  &>/dev/null
  GIT_EDITOR=true git cherry-pick --abort &>/dev/null
}

renb() {
  if [[ -z "$1" || "$1" == "-h" ]]; then
    echo "${yellow_cor} renb <branch>${clear_cor} : to rename a branch"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi
  
  git branch -m "$@"
}

chp() {
  if [[ -z "$1" || "$1" == "-h" ]]; then
    echo "${yellow_cor} chp <commit>${clear_cor} : to cherry-pick a commit"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi
  
  git cherry-pick "$@"
}

chc() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} chc${clear_cor} : to continue in progress cherry-pick"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  GIT_EDITOR=true git merge --continue &>/dev/null
}

mc() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} mc${clear_cor} : to continue in progress merge"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  git add .

  GIT_EDITOR=true git merge --continue &>/dev/null
}

rc() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} rc${clear_cor} : to continue in progress rebase"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  git add .

  GIT_EDITOR=true git rebase --continue &>/dev/null
}

conti() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} conti${clear_cor} : to continue any in progress rebase, merge or cherry-pick"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  git add .

  GIT_EDITOR=true git rebase --continue &>/dev/null
  GIT_EDITOR=true git merge --continue &>/dev/null
  GIT_EDITOR=true git cherry-pick --continue &>/dev/null
}

# Commits -----------------------------------------------------------------------
reset1() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} reset1${clear_cor} : to reset last commit"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  git log -1 --pretty=format:'%s' | xargs -0
  
  git reset --quiet --soft HEAD~1
}

reset2() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} reset2${clear_cor} : to reset 2 last commits"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  git log -2 --pretty=format:'%s' | xargs -0
  
  git reset --quiet --soft HEAD~2
}

reset3() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} reset3${clear_cor} : to reset 3 last commits"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  git log -3 --pretty=format:'%s' | xargs -0
  
  git reset --quiet --soft HEAD~3
}

reset4() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} reset4${clear_cor} : to reset 4 last commits"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  git log -4 --pretty=format:'%s' | xargs -0
  
  git reset --quiet --soft HEAD~4
}

reset5() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} reset5${clear_cor} : to reset 5 last commits"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  git log -5 --pretty=format:'%s' | xargs -0
  
  git reset --quiet --soft HEAD~5
}

repush() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} repush${clear_cor} : to reset last commit then re-push all changes"
    echo "${yellow_cor} repush -s${clear_cor} : to reset last commit then re-push only staged changes"
    echo "${yellow_cor} repush -q${clear_cor} : suppress output unless an error occurs"
    return 0;
  fi

  recommit "$@"
  if [ $? -ne 0 ]; then return 1; fi
  pushf "$@"
}

recommit() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} recommit${clear_cor} : to reset last commit then re-commit all changes"
    echo "${yellow_cor} recommit -s${clear_cor} : to reset last commit then re-commit only staged changes"
    echo "${yellow_cor} recommit -q${clear_cor} : suppress all output unless an error occurs"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  git_status=$(git status --porcelain)
  if [[ -z "$git_status" ]]; then
    if [[ "$1" != "-q" ]]; then
      echo " nothing to recommit, working tree clean"
    fi
    return 0;
  fi

  last_commit_msg=$(git log -1 --pretty=format:'%s' | xargs -0)
  
  if [[ "$last_commit_msg" == Merge* ]]; then
    echo " last commit is a merge commit, please rebase instead"
    return 1;
  fi

  if [[ "$1" != "-s" ]]; then
    git reset --quiet --soft HEAD~1 >/dev/null
    if [ $? -ne 0 ]; then return 1; fi

    if [[ -z "$Z_CURRENT_COMMIT_ADD" ]]; then
      if confirm_from_ "do you want to recommit all changes with '$last_commit_msg'?"; then
        git add .

        if confirm_from_ "save this preference and don't ask again?"; then
          for i in {1..10}; do
            if [[ "$Z_CURRENT_PROJECT_SHORT_NAME" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
              update_config_ "Z_COMMIT_ADD_${i}" 1
              Z_CURRENT_COMMIT_ADD=1
              break
            fi
          done

          echo ""
        fi
      fi
    elif [[ $Z_CURRENT_COMMIT_ADD -eq 1 ]]; then
      git add .
    fi
  else
    if git diff --cached --quiet; then
      echo " nothing to recommit, no staged changes"
      echo " run${yellow_cor} recommit${clear_cor} to re-commit all changes"
      return 1;
    fi
  fi

  git commit -m "$last_commit_msg" "$@"

  if [[ $? -eq 0 && "$1" != "-q" ]]; then
    echo ""
    git log -1 --pretty=format:'%H %s' | xargs -0
  fi
}

commit() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} commit${clear_cor} : to open commit wizard"
    echo "${yellow_cor} commit -a${clear_cor} : to add all files to index then open commit wizard"
    echo "${yellow_cor} commit <message>${clear_cor} : to create a commit with message"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  if [[ "$1" == "-a" ]]; then
    git add .
  elif [[ -z "$Z_CURRENT_COMMIT_ADD" ]]; then
    if confirm_from_ "do you want to commit all changes?"; then
      git add .

      if confirm_from_ "save this preference and don't ask again?"; then
        for i in {1..10}; do
          if [[ "$Z_CURRENT_PROJECT_SHORT_NAME" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
            update_config_ "Z_COMMIT_ADD_${i}" 1
            Z_CURRENT_COMMIT_ADD=1
            break
          fi
        done
        echo ""
      fi
    fi
  elif [[ $Z_CURRENT_COMMIT_ADD -eq 1 ]]; then
    git add .
  fi

  if [[ -z "$1" || "$1" == "-a" ]]; then
    if ! command -v gum &>/dev/null; then
      echo " fatal: commit requires gum"
      echo " install gum:${blue_cor} https://github.com/charmbracelet/gum ${clear_cor}"
      return 1;
    fi

    TYPE=$(gum choose "fix" "feat" "docs" "refactor" "test" "chore" "style" "revert")
    if [[ -z "$TYPE" ]]; then
      return 0;
    fi

    SCOPE=$(gum input --placeholder "scope")
    if [[ $? -ne 0 ]]; then
      return 0;
    fi
    
    # Since the scope is optional, wrap it in parentheses if it has a value.
    if [[ -n "$SCOPE" ]]; then
      SCOPE="($SCOPE)"
    fi

    SUMMARY=$(gum input --value "$TYPE$SCOPE: ")
    if [[ -z "$SUMMARY" ]]; then
      return 0;
    fi

    my_branch=$(git branch --show-current);
    
    if [[ $my_branch =~ ([[:alnum:]]+-[[:digit:]]+) ]]; then # [A-Z]+-[0-9]+
      TICKET="${match[1]} "
      SKIP_TICKET=0;

      git log -n 10 --pretty=format:"%h %s" | while read -r line; do
          commit_hash=$(echo "$line" | awk '{print $1}')
          message=$(echo "$line" | cut -d' ' -f2-)

          if [[ "$message" == "$TICKET"* ]]; then
            SKIP_TICKET=1;
            break;
          fi
      done
      if [[ $SKIP_TICKET -eq 0 ]]; then
        SUMMARY="$TICKET $SUMMARY"
      fi
    fi
    echo "$SUMMARY"
    git commit --no-verify --message "$SUMMARY";
  else
    git commit --no-verify --message "$1"
  fi
}

fetch() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} fetch${clear_cor} : to fetch all branches"
    echo "${yellow_cor} fetch <branch>${clear_cor} : to fetch branch"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  if [[ -z "$1" ]]; then
    git fetch origin --tags --prune-tags --prune
  elif [[ "$1" == -* ]]; then
    git fetch origin --tags --prune-tags --prune "$@"
  else
    git fetch origin $1:$1 --tags --prune-tags --prune ${@:2}
  fi
}

gconf() {
  echo "${solid_yellow_cor} Username:${clear_cor} $(git config --get user.name)"
  echo "${solid_yellow_cor} Email:${clear_cor} $(git config --get user.email)"
  echo "${solid_yellow_cor} Default branch:${clear_cor} $(git config --get init.defaultBranch)"
}

glog() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} glog <name>${clear_cor} : to log last 15 commits"
    return 0;
  fi

  _pwd="$(PWD)";

  open_prj_for_git_; if [ $? -ne 0 ]; then return 1; fi

  git --no-pager log --oneline -15 --graph --date=relative --decorate "$@"

  cd "$_pwd"
}

push() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} push${clear_cor} : to push no-verify to remote"
    echo "${yellow_cor} push tags${clear_cor} : to push tags to remote"
    echo "${yellow_cor} push -q${clear_cor} : suppress output unless an error occurs"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  fetch --quiet

  my_branch=$(git branch --show-current)

  if [[ "$1" == "tags" ]]; then
    git push --no-verify --tags --force "$@"
  else
    git push --no-verify --set-upstream origin $my_branch "$@"
  fi

  if [[ $? -eq 0 && "$1" != "-q" && "$1" != "tags" ]]; then
    echo ""
    git log -1 --pretty=format:'%H %s' | xargs -0
  fi
}

pushf() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} pushf${clear_cor} : to force push no-verify to remote"
    echo "${yellow_cor} pushf tags${clear_cor} : to force push tags to remote"
    echo "${yellow_cor} pushf -q${clear_cor} : to suppress output unless an error occurs"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  if [[ "$1" == "tags" ]]; then
    git push --no-verify --tags --force "$@"
  else
    git push --no-verify --force "$@"
  fi

  if [[ $? -eq 0 && "$1" != "-q" && "$1" != "tags" ]]; then
    echo ""
    git log -1 --pretty=format:'%H %s' | xargs -0
  fi
}

stash() {
  if [[ -z "$1" ]] || [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} stash ${clear_cor} : to stash all files unnamed"
    echo "${yellow_cor} stash <name>${clear_cor} : to stash all files with name"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  git stash push --include-untracked --message "${1:-.}"
}

dtag() {
  if [[ -z "$1" ]] || [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} dtag <name>${clear_cor} : to delete a tag"
    return 0;
  fi

  _pwd="$(PWD)";

  open_prj_for_git_; if [ $? -ne 0 ]; then return 1; fi
  
  git fetch --tags --prune-tags --quiet

  git tag -d $1

  if [ $? -ne 0 ]; then
    cd "$_pwd"
    return 1;
  fi

  git push origin --delete $1
  cd "$_pwd"
}

pull() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} pull${clear_cor} : to pull all branches"
    echo "${yellow_cor} pull tags${clear_cor} : to pull all tags"
    echo "${yellow_cor} pull -q${clear_cor} : to suppress output unless an error occurs"
    return 0;
  fi

  # let git command fail

  if [[ "$1" == "tags" ]] then
    git pull origin --tags "$@"
  else
    git pull origin "$@"
  fi

  if [[ $? -eq 0 && "$1" != "-q" && "$1" != "tags" ]]; then
    echo ""
    git log -1 --pretty=format:'%H %s' | xargs -0
  fi
}

tag() {
  if [[ -z "$1" ]] || [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} tag <name>${clear_cor} : to create a new tag"
    return 0;
  fi

  _pwd="$(PWD)";

  open_prj_for_git_; if [ $? -ne 0 ]; then return 1; fi
  
  prune

  git tag --annotate $1 --message $1
  if [ $? -ne 0 ]; then
    cd "$_pwd"
    return 1;
  fi

  git push --no-verify --tags
  cd "$_pwd"
}

tags() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} tags${clear_cor} : to list all tags"
    echo "${yellow_cor} tags -<x>${clear_cor} : to list x number of tags"
    return 0;
  fi

  _pwd="$(PWD)";

  open_prj_for_git_; if [ $? -ne 0 ]; then return 1; fi

  # prune

  TAG=""

  if [[ -z "$1" ]]; then
    TAG=$(git for-each-ref refs/tags --sort=-taggerdate --format='%(refname:short)')

    if [[ -z "$TAG" ]]; then
      TAG=$(git for-each-ref refs/tags --sort=-committerdate --format='%(refname:short)')
    fi
  else
    TAG=$(git for-each-ref refs/tags --sort=-taggerdate --format='%(refname:short)' --count="${1//[^0-9]/}")

    if [[ -z "$TAG" ]]; then
      TAG=$(git for-each-ref refs/tags --sort=-committerdate --format='%(refname:short)' --count="${1//[^0-9]/}")
    fi
  fi

  if [[ -z "$TAG" ]]; then
    echo " no tags found"
  else
    echo "$TAG"
  fi

  cd "$_pwd"
}

restore() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} restore${clear_cor} : to undo edits in tracked files"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  git restore -q .
}

clean() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} restore${clear_cor} : to delete all untracked files and directories and undo edits in tracked files"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi
  
  git clean -fd -q
  restore
}

discard() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} restore${clear_cor} : to undo everything that have not been committed"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  git reset --hard
  clean
}

reseta() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} reseta${clear_cor} : to erase everything and match HEAD to origin"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  # check if current branch exists in remote
  remote_branch=$(git ls-remote --heads origin "$(git branch --show-current)")

  if [[ -n "$remote_branch" ]]; then
    git reset --hard origin/$(git branch --show-current)
  else
    git reset --hard
  fi
  clean
}

open_prj_for_git_() {
  proj_folder="${1:-$PWD}"
  git_folder=$(get_prj_for_git_ "$proj_folder")

  if [[ -z "$git_folder" ]]; then
    if [[ -z "$2" ]]; then
      echo " fatal: not a git repository (or any of the parent directories): $proj_folder"
    fi
    return 1;
  fi

  cd "$git_folder"
}

get_prj_for_git_() {
  proj_folder="${1:-$PWD}"

  check_git_silent_ "$proj_folder"
  if [ $? -eq 0 ]; then
    echo "$proj_folder"
    return 0;
  fi

  if [[ ! -d "$proj_folder" ]]; then
    return 1;
  fi

  _pwd="$(PWD)"

  cd "$proj_folder"

  folder=""
  folders=("main" "master" "stage" "staging" "dev" "develop")

  # Loop through each folder name
  for defaultFolder in "${folders[@]}"; do
    if [[ -d "$defaultFolder" ]]; then
      check_git_silent_ "$defaultFolder"
      if [ $? -eq 0 ]; then
        folder="$proj_folder/$defaultFolder"
        break;
      fi
    fi
  done

  if [[ -z "$folder" ]]; then
    setopt null_glob
    for i in */; do
      check_git_silent_ "${i%/}"
      if [ $? -eq 0 ]; then
        folder="$proj_folder/${i%/}"
        break;
      fi
    done
    unsetopt null_glob
  fi

  cd "$_pwd"

  if [[ -z "$folder" ]]; then
    return 1;
  fi

  echo "$folder"
}

# List branches -----------------------------------------------------------------------
# list remote branches that contains an optional text and adds a link to the branch in github
glr() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} gll${clear_cor} : to list remote branches"
    echo "${yellow_cor} gll <branch>${clear_cor} : to list remote branches matching branch"
    return 0;
  fi

  _pwd="$(PWD)";

  open_prj_for_git_; if [ $? -ne 0 ]; then return 1; fi

  git fetch origin --quiet

  git branch -r --list "*$1*" --sort=authordate --format='%(authordate:format:%m-%d-%Y) %(align:17,left)%(authorname)%(end) %(refname:strip=3)' | sed \
    -e 's/\([0-9]*-[0-9]*-[0-9]*\)/\x1b[32m\1\x1b[0m/' \
    -e 's/\([^\ ]*\)$/\x1b[34m\x1b]8;;https:\/\/github.com\/wmgtech\/wmg2-one-app\/tree\/\1\x1b\\\1\x1b]8;;\x1b\\\x1b[0m/'

  cd "$_pwd"
}

# list only branches that contains an optional text
gll() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} gll${clear_cor} : to list branches"
    echo "${yellow_cor} gll <branch>${clear_cor} : to list branches matching <branch>"
    return 0;
  fi

  _pwd="$(PWD)";

  open_prj_for_git_; if [ $? -ne 0 ]; then return 1; fi

  git branch --list "*$1*" --sort=authordate --format="%(authordate:format:%m-%d-%Y) %(align:17,left)%(authorname)%(end) %(refname:strip=2)" | sed \
    -e 's/\([0-9]*-[0-9]*-[0-9]*\)/\x1b[32m\1\x1b[0m/' \
    -e 's/\([^ ]*\)$/\x1b[34m\1\x1b[0m/'

  cd "$_pwd"
}

shorten_path_until_() {
  folder="${1:-$(PWD)}"
  target="${2:-$(basename $(PWD))}"

  # Remove trailing slash if present
  folder="${folder%/}"

  # Split path into array
  IFS='/' read -r -A PARTS <<< "$folder"

  # Find the index of the target folder
  for (( i=1; i<=${#PARTS[@]}; i++ )); do
    if [[ "${PARTS[i]}" == "$target" ]]; then
      # Print from target folder to the end
      echo ".../${(j:/:)PARTS[i,-1]}"
      return 0
    fi
  done

  # If folder not found, return full path
  echo "$folder"
}

shorten_path_() {
  folder="${1:-$(PWD)}"
  COUNT="${2:-2}"

  # Remove trailing slash if present
  folder="${folder%/}"

  # Split path into array
  IFS='/' read -r -A PARTS <<< "$folder"
  LEN=${#PARTS[@]}

  # Calculate start index
  START=$(( LEN - COUNT ))
  (( START < 0 )) && START=0

  # Print the last COUNT elements joined by /
  OUTPUT="${(j:/:)PARTS[@]:$START}"

  # Prepend ".../" if not returning the full path
  if (( COUNT < LEN )); then
    if [[ -z "$3" ]]; then
      echo ".../$OUTPUT"
      return 0;
    fi
  fi

  echo "$OUTPUT"
}

choose_branch_() {
  choice=$(choose_auto_one_ "$2" $(echo "$1" | tr ' ' '\n'))
  if [[ $? -ne 0 || -z "$choice" ]]; then
    echo ""
  else
    echo "$choice"
  fi
}

filter_branch_() {
  choice=$(echo "$1" | gum filter --height 25 --limit 1 --indicator ">" --placeholder " $2")
  if [[ $? -ne 0 || -z "$choice" ]]; then
    echo ""
  else
    echo "$choice"
  fi
}

select_branch_choice=""
# select_branch_ -a <search_text>
select_branch_() {
  # $1 are flag options
  # $2 is the search string
  branch_choices=$(git branch $1 --list --format="%(refname:strip=2)" | grep -i "$2" | sed 's/^[* ]*//g' | sed -e 's/HEAD//' | sed -e 's/remotes\///' | sed -e 's/HEAD -> origin\///' | sed -e 's/origin\///' | sort -fu)
  branch_choices_count=$(echo "$branch_choices" | wc -l)

  if [[ -n "$branch_choices" ]]; then
    if [ $branch_choices_count -gt 20 ]; then
      select_branch_choice=$(filter_branch_ "$branch_choices" "type branch name" ${@:3})
    else
      select_branch_choice=$(choose_branch_ "$branch_choices" "choose branch:" ${@:3})
    fi
    return 0;
  fi
  return 1;
}

select_pr_choice=""
select_pr_title=""
select_pr_branch=""

select_pr_() {
  pr_list=$(gh pr list | grep -i "$1" | awk -F'\t' '{print $1 "\t" $2 "\t" $3}');
  PRS_COUNT=$(echo "$pr_list" | wc -l);

  if [[ -n "$pr_list" ]]; then
    titles=$(echo "$pr_list" | cut -f2);

    if [ $PRS_COUNT -gt 20 ]; then
      echo "${purple_cor} choose pull request: ${clear_cor}"
      select_pr_title=$(echo "$titles" | gum filter --select-if-one --height 20 --placeholder " type pull request title");
    else
      select_pr_title=$(echo "$titles" | gum choose --select-if-one --height 20 --header " choose pull request:");
    fi

    select_pr_choice="$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $1}')"
    select_pr_branch="$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $3}')"

    if [[ -z "$select_pr_choice" || -z "$select_pr_branch" ]]; then
      return 1;
    fi
    return 0;
  else
    echo " no pull requests found"
  fi

  return 1;
}

gha_auto_() {
  wk_proj_folder="$1"
  workflow="$2"

  if [[ -z "$workflow" ]]; then
    echo " fatal: no workflow name provided"
    echo " ${yellow_cor} gha -h${clear_cor} to see usage"
    return 1;
  fi

  _pwd="$(PWD)";

  if [[ -n "$wk_proj_folder" ]]; then
    check_git_ "$wk_proj_folder";
    if [ $? -ne 0 ]; then
      return 1;
    fi
    
    cd "$wk_proj_folder"
  fi

  workflow_id="$(gh run list --workflow "$workflow" --limit 1 --json databaseId --jq '.[0].databaseId' &>/dev/null)"

  if [[ -z "$workflow_id" ]]; then
    echo "⚠️${yellow_cor} workflow not found ${clear_cor}"
    return 1;
  fi

  workflow_status="$(gh run list --workflow "$workflow" --limit 1 --json conclusion --jq '.[0].conclusion' &>/dev/null)"

  if [[ -z "$workflow_status" ]]; then
    echo " ⏳\e[90m workflow is still running ${clear_cor}"
    return 0
  fi

  # Output status with emoji
  if [[ "$workflow_status" == "success" ]]; then
    echo " ✅${green_cor} workflow passed: $workflow ${clear_cor}"
  else
    echo "\a ❌${red_cor} workflow failed (status: $workflow_status) ${clear_cor}"

    extracted_repo=""

    if [[ "$Z_CURRENT_PROJECT_REPO" == git@*:* ]]; then
      # SSH-style: git@host:user/repo.git
      if [[ "$Z_CURRENT_PROJECT_REPO" =~ '^[^@]+@[^:]+:([^[:space:]]+)(\.git)?$' ]]; then
        extracted_repo="${match[1]}"
      fi
    elif [[ "$Z_CURRENT_PROJECT_REPO" == http*://* ]]; then
      # HTTPS-style: https://host/user/repo(.git)
      if [[ "$Z_CURRENT_PROJECT_REPO" =~ '^https\?*://[^/]+/([^[:space:]]+)(\.git)?$' ]]; then
        extracted_repo="${match[1]}"
      fi
    fi

    if [[ -n "$extracted_repo" ]]; then
      extracted_repo="${extracted_repo%.git}"
      echo "  check out${blue_cor} https://github.com/$extracted_repo/actions/runs/$workflow_id ${clear_cor}"
    fi
    return 0
  fi

  cd "$_pwd"
}

gha() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} gha${solid_yellow_cor} [<workflow>]${clear_cor} : to check status of workflow in current project"
    echo "${yellow_cor} gha -a${clear_cor} : to run in auto mode"
    echo "${yellow_cor} gha <pro>${solid_yellow_cor} [<workflow>]${clear_cor} : to check status of a workflow for a project"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    echo " fatal: gha requires gum"
    echo " install gum:${blue_cor} https://github.com/charmbracelet/gum ${clear_cor}"
    return 1;
  fi

  workflow_arg=""
  proj_arg=""
  _mode=""

  # Parse arguments
  if [[ -n "$3" ]]; then
    if [[ "$1" == "-a" ]]; then
      _mode="$1"
      proj_arg="$2"
      workflow_arg="$3"
    elif [[ "$3" == "-a" ]]; then
      proj_arg="$1"
      workflow_arg="$2"
      _mode="$3"
    else
      echo " fatal: invalid arguments"
      echo " ${yellow_cor} gha -h${clear_cor} to see usage"
      return 1
    fi
  elif [[ -n "$2" ]]; then
    if [[ "$2" == "-a" ]]; then
      _mode="$2"
      for i in {1..10}; do
        if [[ "$1" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
          proj_arg="$1"
          break
        fi
      done
      [[ -z "$proj_arg" ]] && workflow_arg="$1"
    elif [[ "$1" == "-a" ]]; then
      _mode="$1"
      for i in {1..10}; do
        if [[ "$2" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
          proj_arg="$2"
          break
        fi
      done
      [[ -z "$proj_arg" ]] && workflow_arg="$2"
    else
      for i in {1..10}; do
        if [[ "$1" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
          proj_arg="$1"
          break
        fi
      done
      [[ -z "$proj_arg" ]] && workflow_arg="$2"
    fi
  elif [[ -n "$1" ]]; then
    if [[ "$1" == "-a" ]]; then
      _mode="$1"
    else
      for i in {1..10}; do
        if [[ "$1" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
          proj_arg="$1"
          break
        fi
      done
      [[ -z "$proj_arg" ]] && workflow_arg="$1"
    fi
  fi

  proj_folder="$(PWD)"  # default is current folder
  gha_interval=""
  gha_workflow=""

  # Set project parameters
  if [[ -n "$proj_arg" ]]; then
    found=0
    for i in {1..10}; do
      if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        found=1
        check_prj_ $i; if [ $? -ne 0 ]; then return 1; fi

        proj_folder="${Z_PROJECT_FOLDER[$i]}"
        gha_interval="${Z_GHA_INTERVAL[$i]}"
        gha_workflow="${Z_GHA_WORKFLOW[$i]}"
        break
      fi
    done

    if [[ "$found" -ne 1 ]]; then
      echo " invalid project name: $proj_arg"
      if [[ -n "${Z_PROJECT_SHORT_NAME[*]}" ]]; then
        echo -n " valid project names are:"
        for i in {1..10}; do echo -n " ${Z_PROJECT_SHORT_NAME[$i]}"; done
      fi
      return 1
    fi
  fi

  _pwd="$(PWD)";

  if [[ -n "$proj_folder" ]]; then
    open_prj_for_git_ "$proj_folder"; if [ $? -ne 0 ]; then return 1; fi
    proj_folder="$(PWD)";
  else
    echo " no project folder found"
    return 1;
  fi

  if [[ -z "$workflow_arg" && -z "$gha_workflow" ]]; then
    chosen_workflow=""
    workflow_choices=$(gh workflow list | cut -f1)
    if [[ -z "$workflow_choices" || "$workflow_choices" == "No workflows found" ]]; then
      echo " no workflows found"
      cd "$_pwd"
      return 1;
    fi
    
    chosen_workflow=$(gh workflow list | cut -f1 | gum choose --header " choose workflow:");
    if [[ $? -ne 0 || -z "$chosen_workflow" ]]; then
      cd "$_pwd"
      return 1;
    fi

    # ask to save the workflow
    if [[ -n "$proj_arg" ]]; then
      if confirm_from_ "would you like to save '$chosen_workflow' as the default workflow for this project?"; then
        for i in {1..10}; do
          if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
            Z_GHA_WORKFLOW[$i]="$chosen_workflow"
            update_config_ "Z_GHA_WORKFLOW_$i" "$chosen_workflow"
            break
          fi
        done
        echo ""
      fi
    fi

    gha_workflow="$chosen_workflow"

  elif [[ -n "$workflow_arg" ]]; then
    gha_workflow="$workflow_arg"
  fi

  if [[ "$_mode" == "-a" ]]; then
    if [[ -z "$gha_interval" ]]; then
      gha_interval=10
    fi

    echo " running every $gha_interval minutes, press cmd+c to stop"
    echo ""

    while true; do
      echo " checking workflow${purple_cor} $gha_workflow${clear_cor}..."
      gha_auto_ "$proj_folder" "$gha_workflow"
      
      if [[ $? -ne 0 ]]; then
        return 1;
      fi
      
      echo ""
      echo " sleeping $gha_interval minutes..."
      sleep $(($gha_interval * 60))
    done
  fi
  
  echo " checking workflow${purple_cor} $gha_workflow${clear_cor}..."
  gha_auto_ "$proj_folder" "$gha_workflow"
}

co() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} co${clear_cor} : to list branches to switch"
    echo "${yellow_cor} co pr${clear_cor} : to list PRs to check out"
    echo "${yellow_cor} co -r${clear_cor} : to list remote branches only"
    echo "${yellow_cor} co -a${clear_cor} : to list all branches"
    echo " --"
    echo "${yellow_cor} co <branch>${clear_cor} : to switch to an existing branch"
    echo "${yellow_cor} co -e <branch>${clear_cor} : to switch to exact branch"
    echo "${yellow_cor} co -b <branch>${clear_cor} : to create branch off of current HEAD"
    echo "${yellow_cor} co <branch> <base_branch>${clear_cor} : to create branch off of base branch"
    return 0;
  fi

  if [[ "$1" == "-" ]]; then
    co -h
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    echo " fatal: co requires gum"
    echo " install gum:${blue_cor} https://github.com/charmbracelet/gum ${clear_cor}"
    return 1;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  git fetch origin --quiet

  pump_past_branch="$(git branch --show-current)"

  # co (no arguments) branches
  if [[ -z "$1" ]]; then
    echo "${purple_cor} choose branch: ${clear_cor}"
    select_branch_ --list
    if [[ $? -ne 0 ]]; then return 0; fi

    if [[ -n "$select_branch_choice" ]]; then
      co -e $select_branch_choice
      if [ $? -eq 0 ]; then return 0; else return 1; fi
    fi
    return 0;
  fi

  # co pr
  if [[ "$1" == "pr" ]]; then
    select_pr_ "$2";
    if [[ $? -ne 0 ]]; then return 0; fi

    if [[ -n "$select_pr_choice" ]]; then
      echo " checking out PR: $select_pr_title"
      gh pr checkout $select_pr_choice
    fi
    return 0;
  fi

  # co -a all branches
  if [[ "$1" == "-a" || "$2" == "-a" ]]; then
    echo "${purple_cor} choose branch: ${clear_cor}"
    if [[ "$1" == "-a" ]]; then
      select_branch_ -a "$2";
    else
      select_branch_ -a "$1";
    fi
    
    if [ $? -ne 0 ]; then
      if [[ "$1" == "-a" ]]; then
        echo " did not match any branch known to git: $2";
      else
        echo echo " did not match any branch known to git: $1";
      fi
    fi

    if [[ -n "$select_branch_choice" ]]; then
      co -e $select_branch_choice
      if [ $? -eq 0 ]; then return 0; else return 1; fi
    fi
    return 0;
  fi

  # co -r remote branches
  if [[ "$1" == "-r" || "$2" == "-r" ]]; then
    echo "${purple_cor} choose remote branch: ${clear_cor}"
    if [[ "$1" == "-r" ]]; then
      select_branch_ -r "$2";
    else
      select_branch_ -r "$1";
    fi
    
    if [ $? -ne 0 ]; then
      if [[ "$1" == "-r" ]]; then
        echo " did not match any branch known to git: $2";
      else
        echo echo " did not match any branch known to git: $1";
      fi
    fi

    if [[ -n "$select_branch_choice" ]]; then
      co -e $select_branch_choice
      if [ $? -eq 0 ]; then return 0; else return 1; fi
    fi
    return 0;
  fi

  # co -b branch create branch
  if [[ "$1" == "-b" || "$2" == "-b" ]]; then
    if [[ -n "$1" && -n "$2" ]]; then
      pump_past_branch="$(git branch --show-current)"
      if [[ "$1" == "-b" ]]; then
        if [[ "$3" == "-q" ]]; then git checkout -b "$2" --quiet &>/dev/null; else git checkout -b "$2"; fi
      else
        if [[ "$3" == "-q" ]]; then git checkout -b "$1" --quiet &>/dev/null; else git checkout -b "$1"; fi
      fi
      if [[ $? -eq 0 ]]; then
        PUMP_PAST_="$pump_past_branch"
        PUMP_PAST_BRANCH_OR_FOLDER_="branch"
        return 0;
      fi
    else
      echo " fatal: branch is required"
      echo " ${yellow_cor} co -b <branch>${clear_cor} : to create branch off of current HEAD"
      echo " ${yellow_cor} co -h${clear_cor} to see usage"
    fi
    return 1;
  fi

  # co -e branch just checkout, do not create branch
  if [[ "$1" == "-e" || "$2" == "-e" ]]; then
    if [[ -n "$1" && -n "$2" ]]; then
      pump_past_branch="$(git branch --show-current)"
      if [[ "$1" == "-e" ]]; then
        if [[ "$3" == "-q" ]]; then git switch "$2" --quiet &>/dev/null; else git switch "$2" --quiet; fi
      else
        if [[ "$3" == "-q" ]]; then git switch "$1" --quiet &>/dev/null; else git switch "$1" --quiet; fi
      fi
      if [[ $? -eq 0 ]]; then
        PUMP_PAST_="$pump_past_branch"
        PUMP_PAST_BRANCH_OR_FOLDER_="branch"
        return 0;
      fi
    else
      echo " fatal: branch is required"
      echo " ${yellow_cor} co -e <branch>${clear_cor} : to switch to exact branch"
      echo " ${yellow_cor} co -h${clear_cor} to see usage"
    fi
    return 1;
  fi

  # co branch
  if [[ -z "$2" ]]; then
    select_branch_ -a "$1"

    if [[ $? -ne 0 ]]; then
      if [[ -n "$1" ]]; then
        echo " did not match any branch known to git: $1"
      fi
      return 1;
    fi
    if [[ -n "$select_branch_choice" ]]; then
      co -e "$select_branch_choice"
      if [ $? -eq 0 ]; then return 0; else return 1; fi
    fi
    return 0;
  fi

  branch="$1"

  # co branch BASE_BRANCH (creating branch)
  choices=$(git branch -a --list --format="%(refname:strip=2)" | grep -i "$2" | sed 's/^[* ]*//g' | sed -e 's/HEAD//' | sed -e 's/remotes\///' | sed -e 's/HEAD -> origin\///' | sed -e 's/origin\///' | sort -fu)
  if [[ $? -ne 0 || -z "$choices" ]]; then
    echo " did not match any branch known to git: $2"
    return 1;
  fi

  user_base_branch=$(choose_auto_one_ "search base branch:" $(echo "$choices" | tr ' ' '\n'))

  if [[ -z "$user_base_branch" ]]; then
    return 0;
  fi

  git switch $user_base_branch --quiet
  if [ $? -ne 0 ]; then return 1; fi

  pull --quiet
  git branch $branch $user_base_branch
  if [ $? -ne 0 ]; then return 1; fi

  git switch $branch
  if [ $? -ne 0 ]; then return 1; fi

  PUMP_PAST_="$pump_past_branch" # svae this for back() function
  PUMP_PAST_BRANCH_OR_FOLDER_="branch"


  if [[ -n "$Z_CURRENT_PROJECT_FOLDER" ]]; then
    is_single_mode=$(is_project_single_mode_ "$Z_CURRENT_PROJECT_FOLDER")
    if [[ $is_single_mode -eq 0 ]]; then
      if ! confirm_from_ "save '$branch' as working branch? running "$'\e[34m'$Z_CURRENT_PROJECT_SHORT_NAME$'\e[0m'" will take you back to this branch?"; then
        return 0;
      fi
    fi
    save_pump_working_ "$Z_CURRENT_PROJECT_SHORT_NAME" "$(git branch --show-current)" "$branch"
  fi
}

back() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} back${clear_cor} : to go back to previous branch (in single mode) or folder (in multi mode)"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  if [[ -z "$PUMP_PAST_" ]]; then
    return 0;
  fi

  if [[ "$PUMP_PAST_BRANCH_OR_FOLDER_" == "branch" ]]; then
    co -e "$PUMP_PAST_"
  else
    if [[ -d "$PUMP_PAST_" ]]; then
      cd "$PUMP_PAST_"
    fi
  fi
}

# checkout dev or develop branch
dev() {
  if [[ "$1" == "-h" ]]; then
      echo "${yellow_cor} dev${clear_cor} : to switch to dev or develop in current project"
      echo "${yellow_cor} dev <pro>${clear_cor} : to switch to dev or develop for a project"
    return 0;
  fi

  proj_folder="$(PWD)"

  if [[ -n "$1" ]]; then
    for i in {1..10}; do
      if [[ "$1" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        check_prj_ $i
        if [ $? -ne 0 ]; then return 1; fi

        proj_folder="${Z_PROJECT_FOLDER[$i]}"
        break
      fi
    done

    if [[ -z "$proj_folder" ]]; then
      echo " fatal: not a valid project: $1"
      echo " ${yellow_cor} dev -h${clear_cor} to see usage"
      return 1
    fi
  fi

  _pwd="$(PWD)"
  
  folder=""
  folders=("$proj_folder" "$proj_folder/dev" "$proj_folder/develop")

  # Loop through each folder name
  for defaultFolder in "${folders[@]}"; do
    if [[ -d "$defaultFolder" ]]; then
      check_git_silent_ "$defaultFolder"
      if [ $? -eq 0 ]; then
        folder="$defaultFolder"
        break;
      fi
    fi
  done

  if [[ -z "$folder" ]]; then
    cd "$_pwd"
    return 1;
  fi

  eval "$1"
  cd "$folder"

  if [[ -n "$(git branch -a --list | grep -w dev)" ]]; then
    co -e dev
  elif [[ -n "$(git branch -a --list | grep -w develop)" ]]; then
    co -e develop
  else
    echo " fatal: dev or develop branch is not known to git";
    cd "$_pwd"
    return 1;
  fi
}

# checkout main branch
main() {
  if [[ "$1" == "-h" ]]; then
      echo "${yellow_cor} main${clear_cor} : to switch to main in current project"
      echo "${yellow_cor} main <pro>${clear_cor}: to switch to main for a project"
    return 0;
  fi

  proj_folder="$(PWD)"

  if [[ -n "$1" ]]; then
    for i in {1..10}; do
      if [[ "$1" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        check_prj_ $i
        if [ $? -ne 0 ]; then return 1; fi

        proj_folder="${Z_PROJECT_FOLDER[$i]}"
        break
      fi
    done
  fi

  _pwd="$(PWD)"
  
  folder=""
  folders=("$proj_folder" "$proj_folder/main" "$proj_folder/master")

  # Loop through each folder name
  for defaultFolder in "${folders[@]}"; do
    if [[ -d "$defaultFolder" ]]; then
      check_git_silent_ "$defaultFolder"
      if [ $? -eq 0 ]; then
        folder="$defaultFolder"
        break;
      fi
    fi
  done

  if [[ -z "$folder" ]]; then
    cd "$_pwd"
    return 1;
  fi

  eval "$1"
  cd "$folder"

  if [[ -n "$(git branch -a --list | grep -w main)" ]]; then
    co -e main
  elif [[ -n "$(git branch -a --list | grep -w master)" ]]; then
    co -e master
  else
    echo " fatal: main or master branch is not known to git";
    cd "$_pwd"
    return 1;
  fi
}

# checkout stage branch
stage() {
  if [[ "$1" == "-h" ]]; then
      echo "${yellow_cor} stage${clear_cor} : to switch to stage or staging in current project"
      echo "${yellow_cor} stage <pro>${clear_cor}: to switch to stage or staging for a project"
    return 0;
  fi

  proj_folder="$(PWD)"

  if [[ -n "$1" ]]; then
    for i in {1..10}; do
      if [[ "$1" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        check_prj_ $i
        if [ $? -ne 0 ]; then return 1; fi

        proj_folder="${Z_PROJECT_FOLDER[$i]}"
        break
      fi
    done
  fi

  _pwd="$(PWD)"
  
  folder=""
  folders=("$proj_folder" "$proj_folder/stage" "$proj_folder/staging")

  # Loop through each folder name
  for defaultFolder in "${folders[@]}"; do
    if [[ -d "$defaultFolder" ]]; then
      check_git_silent_ "$defaultFolder"
      if [ $? -eq 0 ]; then
        folder="$defaultFolder"
        break;
      fi
    fi
  done

  if [[ -z "$folder" ]]; then
    cd "$_pwd"
    return 1;
  fi

  eval "$1"
  cd "$folder"

  if [[ -n "$(git branch -a --list | grep -w stage)" ]]; then
    co -e stage
  elif [[ -n "$(git branch -a --list | grep -w staging)" ]]; then
    co -e staging
  else
    echo " fatal: stage or staging branch is not known to git";
    cd "$_pwd"
    return 1;
  fi
}

# Merging & Rebasing -----------------------------------------------------------------------=
# rebase $1 or main
rebase() {
  check_git_; if [ $? -ne 0 ]; then return 1; fi

  my_branch=$(git branch --show-current)
  default_main_branch=$(git config --get init.defaultBranch)
  main_branch="${1:-$default_main_branch}"

  if [[ "$my_branch" == "$default_main_branch" ]]; then
    echo " fatal: cannot rebase, branches are the same";
    return 1;
  fi

  git fetch origin --quiet

  echo " rebase from branch${blue_cor} $main_branch ${clear_cor}"
  git rebase origin/$main_branch

  if [ $? -eq 0 ]; then
    if confirm_from_ "done. now git push?"; then
      git push --force-with-lease --no-verify --set-upstream origin $my_branch
    fi
  fi
}

# merge branch $1 or default branch
merge() {
  check_git_; if [ $? -ne 0 ]; then return 1; fi

  my_branch=$(git branch --show-current)
  default_main_branch=$(git config --get init.defaultBranch)
  main_branch="${1:-$default_main_branch}"

  if [[ "$my_branch" == "$default_main_branch" ]]; then
    echo " fatal: cannot merge, branches are the same";
    return 1;
  fi

  git fetch origin --quiet

  echo " merge from branch${blue_cor} $main_branch ${clear_cor}"
  git merge origin/$main_branch --no-edit

  if [[ $? -eq 0 ]]; then
    if confirm_from_ "done. now git push?"; then
      git push --no-verify --set-upstream origin $my_branch
    fi
  fi
}

# Delete branches ===========================================================
prune() {
  check_git_; if [ $? -ne 0 ]; then return 1; fi

  default_main_branch=$(git config --get init.defaultBranch)

  # delets all tags
  git tag -l | xargs git tag -d >/dev/null
  # fetch tags that exist in the remote
  git fetch origin --prune --prune-tags
  
  # lists all branches that have been merged into the currently checked-out branch
  # that can be safely deleted without losing any unmerged work and filters out the default branch
  git branch --merged | grep -v "^\*\\|$default_main_branch" | xargs -n 1 git branch -d
  git prune "$@"
}

# list branches and select one to delete or delete $1
delb() {
  if [[ "$1" == "-h" ]]; then
    if [[ -n "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then 
      echo "${yellow_cor} delb${solid_yellow_cor} [<branch>]${clear_cor} : to find branches to delete in $Z_CURRENT_PROJECT_SHORT_NAME"
    fi
    echo "${yellow_cor} delb -f${clear_cor} : to delete default braches too"
    echo "${yellow_cor} delb <pro>${solid_yellow_cor} [<branch>]${clear_cor} : to find branches to delete in a project"
    return 0;
  fi

  if [[ $1 == -* ]]; then
    eval "delb -h"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    echo " fatal: delb requires gum"
    echo " install gum:${blue_cor} https://github.com/charmbracelet/gum ${clear_cor}"
    return 1;
  fi

  proj_arg=""
  branch_arg=""

  if [[ -n "$2" ]]; then
    proj_arg="$1"
    branch_arg="$2"
  elif [[ -n "$1" && "$1" != "-1" ]]; then
    # Check if the first argument matches any of the project names dynamically
    for i in {1..10}; do
      if [[ "$1" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        proj_arg="$1"
        break
      fi
    done

    # If it's not a project name, treat it as a branch argument
    if [[ -z "$proj_arg" ]]; then
      branch_arg="$1"
    fi
  fi

  proj_folder="$(PWD)"
  pump_working_branch=""

  if [[ -n "$proj_arg" ]]; then
    # Loop through project numbers from 1 to 10
    for i in {1..10}; do
      # Check if the project name matches
      if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        check_prj_ $i
        if [ $? -ne 0 ]; then return 1; fi

        proj_folder="${Z_PROJECT_FOLDER[$i]}"
        pump_working_branch="${PUMP_WORKING[$i]}"
        break
      fi
    done
    
    # If no project matched, show an error
    if [[ -z "$proj_folder" ]]; then
      echo " invalid project name: $proj_arg"
      if [[ -n "${Z_PROJECT_SHORT_NAME[*]}" ]]; then
        echo -n " valid project names are:"
        for i in {1..10}; do echo -n " ${Z_PROJECT_SHORT_NAME[$i]}"; done
      fi
      return 1
    fi
  fi
  
  _pwd="$(PWD)";

  open_prj_for_git_ "$proj_folder"; if [ $? -ne 0 ]; then return 1; fi

  proj_folder="$(PWD)";

  is_deleted=1;
  selected_branches=""

  # delb (no arguments)
  if [[ -z "$branch_arg" ]] || [[ "$1" == "-f" ]]; then
    branches_to_choose="";
    if [[ "$1" == "-f" ]]; then
      branches_to_choose=$(git branch | grep -v '^\*' | cut -c 3- | sort -fu);
    else
      branches_to_choose=$(git branch | grep -v '^\*' | cut -c 3- | grep -vE '^(main|dev|stage|master|staging|develop)$' | sort -fu);
    fi
    if [[ -n "$branches_to_choose" ]]; then
      selected_branches=$(choose_multiple_branches_ "choose branches to delete" "$branches_to_choose")
      echo "$selected_branches" | xargs git branch -D
      is_deleted=$?
    else
      echo " no branches found to delete in \e[96m$(shorten_path_ $proj_folder) ${clear_cor}"
    fi
  else # delb branch
    branch_search="${branch_arg//\*/}"
    selected_branches=$(git branch | grep -w "$branch_search" | cut -c 3- | head -n 1)

    if [[ -z "$selected_branches" ]]; then
      echo " no branches matching in \e[96m$(shorten_path_ $proj_folder)${clear_cor}: $branch_search"
    else
      confirm_msg="delete "$'\e[94m'$selected_branches:$'\e[0m'" in "$'\e[94m'$(shorten_path_ $proj_folder)$'\e[0m'"?"
      
      if confirm_from_ $confirm_msg; then
        git branch -D $selected_branches
        is_deleted=$?
      fi
    fi
  fi

  if [[ $is_deleted -eq 0 ]]; then
    delete_pump_workings_ "$pump_working_branch" "$proj_arg" "$selected_branches"
  fi

  cd "$_pwd"
}

save_pump_working_(){
  proj_arg="$1"
  pump_working_branch="$2"
  type="$3"

  if [[ -z "$pump_working_branch" || -z "$proj_arg" ]]; then
    return 0;
  fi

  PUMP_PAST_="$pump_working_branch"
  PUMP_PAST_BRANCH_OR_FOLDER_=$type

  for i in {1..10}; do
    if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
      PUMP_WORKING[$i]="$pump_working_branch"
      echo "${PUMP_WORKING[$i]}" > "${PUMP_WORKING_FILE[$i]}"
      break
    fi
  done
}

delete_pump_working_(){
  item="$1"
  pump_working_branch="$2"
  proj_arg="$3"

  if [[ -z "$pump_working_branch" || -z "$proj_arg" ]]; then
    return 0;
  fi

  if [[ "$item" == "$pump_working_branch" ]]; then
    for i in {1..10}; do
      if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        rm -f "${PUMP_WORKING_FILE[$i]}"
        PUMP_WORKING[$i]=""
        break
      fi
    done
  fi
}

delete_pump_workings_(){
  pump_working_branch="$1"
  proj_arg="$2"
  selected_items="$3"

  if [[ -z "$pump_working_branch" || -z "$proj_arg" ]]; then
    return 0;
  fi

  for item in $selected_items; do
    delete_pump_working_ "$item" "$pump_working_branch" "$proj_arg"
  done
}

pop() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} pop${clear_cor} : to pop stash"
    echo "${yellow_cor} pop -a${clear_cor} : to pop all stashes"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  if [[ "$1" == "-a" ]]; then
    git stash list | awk '{print $1}' | xargs git stash pop --index
  else
    git stash pop --index
  fi
}

st() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} st${clear_cor} : to show git status"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  git status
}

stashes() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} stashes${clear_cor} : to show git stashes"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  git stash list
}

# projects linked list ===========================================================
typeset -A ll_next ll_prev node_type node_value
typeset -A project_heads project_folders
typeset -a project_names
typeset -gi node_counter=0
typeset -g head=""


clear_projects() {
  unset ll_next ll_prev node_type node_value head node_counter project_names
  typeset -A ll_next ll_prev node_type node_value
  typeset -A project_heads project_folders
  typeset -gi node_counter=0
  typeset -g head=""
  typeset -a project_names
}

create_project() {
  local name=$1
  local folder=$2

  project_names+=$name
  project_folders[$name]=$folder
  project_heads[$name]=""
}

add_project_node() {
  local project=$1
  local _type=$2
  local _value=$3

  local node_id="${project}_node$((++node_counter))"

  node_type[$node_id]=$_type
  node_value[$node_id]=$_value

  local head=${project_heads[$project]}
  if [[ -z $head ]]; then
    # First node
    ll_next[$node_id]=$node_id
    ll_prev[$node_id]=$node_id
    project_heads[$project]=$node_id
  else
    local tail=${ll_prev[$head]}
    ll_next[$tail]=$node_id
    ll_prev[$node_id]=$tail
    ll_next[$node_id]=$head
    ll_prev[$head]=$node_id
  fi
}

# Print the list forward
# print_list() {
#   local current=$head
#   if [[ -z $current ]]; then
#     echo "List is empty"
#     return
#   fi

#   echo "List contents:"
#   while true; do
#     echo "$current -> node_type=${node_type[$current]}, node_value=${node_value[$current]}"
#     current=${ll_next[$current]}
#     [[ $current == $head ]] && break
#   done
# }

# Remove node by matching node_type and node_value
# remove_node() {
#   local target_type=$1
#   local target_value=$2

#   local current=$head
#   [[ -z $current ]] && return

#   while true; do
#     if [[ "${node_type[$current]}" == "$target_type" && "${node_value[$current]}" == "$target_value" ]]; then
#       local p=${ll_prev[$current]}
#       local n=${ll_next[$current]}

#       # Remove from list
#       ll_next[$p]=$n
#       ll_prev[$n]=$p

#       # If head is being removed, update it
#       [[ $current == $head ]] && head=$n
#       # If it was the only node
#       [[ $current == $n ]] && head=""

#       # Delete node data
#       unset node_type[$current] node_value[$current] ll_next[$current] ll_prev[$current]
#       echo "Removed $current"
#       return
#     fi
#     current=${ll_next[$current]}
#     [[ $current == $head ]] && break
#   done
# }

traverse_project() {
  local project=$1
  local current=${project_heads[$project]}

  if [[ -z $current ]]; then
    return
  fi

  while true; do
    # Just print the node data; don't modify anything
    echo "$current -> type=${node_type[$current]}, value=${node_value[$current]}"
    current=${ll_next[$current]}
    
    # Stop when we circle back to the head (since it's circular)
    [[ $current == ${project_heads[$project]} ]] && break
  done
}

traverse_project_backward() {
  local project=$1
  local head=${project_heads[$project]}
  local tail=${ll_prev[$head]}

  if [[ -z $tail ]]; then
    return
  fi

  local current=$tail
  while true; do
    echo "$current -> type=${node_type[$current]}, value=${node_value[$current]}"
    current=${ll_prev[$current]}
    [[ $current == $tail ]] && break
  done
}

traverse_projects() {
  for project in $project_names; do
    local current=${project_heads[$project]}

    if [[ -z $current ]]; then
      continue
    fi

    while true; do
      echo "$current -> type=${node_type[$current]}, value=${node_value[$current]}"
      current=${ll_next[$current]}
      [[ $current == ${project_heads[$project]} ]] && break
    done
    echo ""
  done
}

# traverse_projects_backwards() {
#   for project in $project_names; do
#     local tail=${ll_prev[${project_heads[$project]}]}
#     if [[ -z $tail ]]; then
#       continue
#     fi

#     local current=$tail
#     while true; do
#       echo "$current -> type=${node_type[$current]}, value=${node_value[$current]}"
#       current=${ll_prev[$current]}
      
#       [[ $current == $tail ]] && break
#     done
#   done
# }

# traverse_forward() {
#   local current=$head
#   if [[ -z $current ]]; then
#     # List is empty
#     return 0;
#   fi

#   while true; do
#     echo "$current -> node_type=${node_type[$current]}, node_value=${node_value[$current]}"
#     current=${ll_next[$current]}
#     [[ $current == $head ]] && break
#   done
# }

# traverse_backward() {
#   local current=${ll_prev[$head]}
#   if [[ -z $current ]]; then
#     # List is empty
#     return 0;
#   fi

#   while true; do
#     echo "$current -> node_type=${node_type[$current]}, node_value=${node_value[$current]}"
#     current=${ll_prev[$current]}
#     [[ $current == ${ll_prev[$head]} ]] && break
#   done
# }

# save_linkedlist() {
#   echo "start"

#   local file="$1"
#   echo "" > "$file"  # clear file

#   echo "hey"

#   local current=$head
#   [[ -z $current ]] && return

#   echo "hey"

#   while true; do
#     echo "$current|${node_type[$current]}|${node_value[$current]}|${ll_next[$current]}|${ll_prev[$current]}" >> "$file"
#     echo "yo"
#     current=${ll_next[$current]}
#     [[ $current == $head ]] && break
#   done
# }

# restore_linkedlist() {
#   local file="$1"
#   [[ ! -f $file ]] && return

#   # Reset all structures
#   # unset ll_next ll_prev node_type node_value head
#   # typeset -A ll_next ll_prev node_type node_value
#   # typeset -g head=""
#   typeset -g node_counter=0

#   # Track highest node number for restoring counter
#   local highest_id=0

#   while IFS='|' read -r node_id node_type node_value node_next node_prev; do
#     # Validate node_id format (e.g., node1, node2)
#     if [[ $node_id =~ node([0-9]+) ]]; then
#       local id_num=${match[1]}
#       (( id_num > highest_id )) && highest_id=$id_num
#     fi

#     node_type[$node_id]=$node_type
#     node_value[$node_id]=$node_value
#     ll_next[$node_id]=$node_next
#     ll_prev[$node_id]=$node_prev

#     # First line -> set head
#     [[ -z $head ]] && head=$node_id
#   done < "$file"

#   node_counter=$highest_id

#   # Validate circularity
#   if [[ -n $head && $head == ${ll_next[${ll_prev[$head]}]} && $head == ${ll_prev[${ll_next[$head]}]} ]]; then
#     return 0
#   else
#     clear_linkedlist
#     return 1
#     #echo " warning: list restored but may not be circular or fully valid."
#   fi
# }

save_projects() {
  local file="$1"
  echo "" > "$file"

  if [[ ! -f $file ]]; then
    return 1
  fi

  for project in $project_names; do
    echo "PROJECT|$project|${project_folders[$project]}" >> "$file"
    local current=${project_heads[$project]}
    [[ -z $current ]] && continue

    while true; do
      echo "NODE|$current|${node_type[$current]}|${node_value[$current]}|${ll_next[$current]}|${ll_prev[$current]}" >> "$file"
      current=${ll_next[$current]}
      [[ $current == ${project_heads[$project]} ]] && break
    done
  done
}

restore_projects() {
  local file="$1"
  [[ ! -f $file ]] && return

  # Clear all existing data
  # unset project_names project_folders project_heads
  # unset ll_next ll_prev node_type node_value head node_counter
  # typeset -a project_names
  # typeset -A project_folders project_heads ll_next ll_prev node_type node_value
  # typeset -gi node_counter=0

  local current_project=""
  local highest_id=0

  while IFS='|' read -r kind arg1 arg2 arg3 arg4 arg5 arg6; do
    if [[ $kind == "PROJECT" ]]; then
      local name=$arg1
      local folder=$arg2
      project_names+=$name
      project_folders[$name]=$folder
    elif [[ $kind == "NODE" ]]; then
      local node_id=$arg1
      local _type=$arg2
      local _value=$arg3
      local _next=$arg4
      local _prev=$arg5

      node_type[$node_id]=$_type
      node_value[$node_id]=$_value
      ll_next[$node_id]=$_next
      ll_prev[$node_id]=$_prev

      [[ $node_id =~ node([0-9]+) ]] && (( match[1] > highest_id )) && node_counter=${match[1]}

      # Extract project name prefix from node ID
      local project_prefix=${node_id%%_node*}
      [[ -z ${project_heads[$project_prefix]} ]] && project_heads[$project_prefix]=$node_id
    fi
  done < "$file"
}

PUMP_DB_FILE="$(dirname "$0")/.db"
if [[ -f "$PUMP_DB_FILE" ]]; then
  restore_projects "$PUMP_DB_FILE"

  #traverse_projects

  # traverse_projects_backwards
  # traverse_project "music"
  # traverse_project "video"
  # traverse_project "photos"
else
  # Example usage
  create_project "music" "/projects/music"
  create_project "video" "/projects/video"
  create_project "photos" "/projects/photos"

  add_project_node "music" "artist" "Adele"
  add_project_node "music" "album" "25"
  add_project_node "music" "track" "Hello"

  add_project_node "video" "director" "Nolan"
  add_project_node "video" "film" "Inception"

  add_project_node "photos" "camera" "Nikon"
  add_project_node "photos" "location" "Iceland"

  save_projects "$PUMP_DB_FILE"
fi

# # Clear everything
# unset ll_next ll_prev node_type node_value head
# typeset -A ll_next ll_prev node_type node_value
# head=""

# # Restore
# restore_linkedlist "linkedlist.db"

# ==========================================================================
# &>/dev/null	                Hide both stdout and stderr outputs
# 2>/dev/null                 show stdout, hide stderr  
# 1>/dev/null or >/dev/null	  Hide stdout, show stderr

# ========================================================================
# Project configuration
PUMP_CONFIG_FILE="$(dirname "$0")/config/pump.zshenv"

if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
  echo "${red_cor} fatal: config file '$PUMP_CONFIG_FILE' does not exist, re-install pump-my-shell ${clear_cor}"
  return 1
fi

# ========================================================================
# PUMP_WORKING_FILE_3="$(dirname "$0")/.working_3"
# [[ -f "$PUMP_WORKING_FILE_3" ]] && PUMP_WORKING_3=$(<"$PUMP_WORKING_FILE_3")
# project 1 ==============================================================
# Declare associative arrays to hold project data
typeset -gA Z_PROJECT_SHORT_NAME
typeset -gA Z_PROJECT_FOLDER
typeset -gA Z_PROJECT_REPO
typeset -gA Z_PACKAGE_MANAGER
typeset -gA Z_CODE_EDITOR
typeset -gA Z_CLONE
typeset -gA Z_SETUP
typeset -gA Z_RUN
typeset -gA Z_RUN_STAGE
typeset -gA Z_RUN_PROD
typeset -gA Z_PRO
typeset -gA Z_TEST
typeset -gA Z_COV
typeset -gA Z_TEST_WATCH
typeset -gA Z_E2E
typeset -gA Z_E2EUI
typeset -gA Z_PR_TEMPLATE
typeset -gA Z_PR_REPLACE
typeset -gA Z_PR_APPEND
typeset -gA Z_PR_RUN_TEST
typeset -gA Z_GHA_INTERVAL
typeset -gA Z_COMMIT_ADD
typeset -gA Z_DEFAULT_BRANCH
typeset -gA Z_GHA_WORKFLOW
typeset -gA Z_PUSH_ON_REFIX
typeset -gA Z_PRINT_README
typeset -gA PUMP_WORKING
typeset -gA PUMP_WORKING_FILE
typeset -gA PUMP_WORKING_TYPE # "folder" | "branch"

Z_CURRENT_PROJECT_FOLDER=""
Z_CURRENT_PROJECT_SHORT_NAME=""
Z_CURRENT_PROJECT_REPO=""
Z_CURRENT_PACKAGE_MANAGER=""
Z_CURRENT_CODE_EDITOR=""
Z_CURRENT_CLONE=""
Z_CURRENT_SETUP=""
Z_CURRENT_RUN=""
Z_CURRENT_RUN_STAGE=""
Z_CURRENT_RUN_PROD=""
Z_CURRENT_PRO=""
Z_CURRENT_TEST=""
Z_CURRENT_COV=""
Z_CURRENT_TEST_WATCH=""
Z_CURRENT_E2E=""
Z_CURRENT_E2EUI=""
Z_CURRENT_PR_TEMPLATE=""
Z_CURRENT_PR_REPLACE=""
Z_CURRENT_PR_APPEND=""
Z_CURRENT_PR_RUN_TEST=""
Z_CURRENT_GHA_INTERVAL=""
Z_CURRENT_COMMIT_ADD=""
Z_CURRENT_GHA_WORKFLOW=""
Z_CURRENT_PUSH_ON_REFIX=""
Z_CURRENT_DEFAULT_BRANCH=""
Z_CURRENT_PRINT_README=""

PUMP_PAST_=""
PUMP_PAST_BRANCH_OR_FOLDER_=""

bright_green_cor="\e[1m\e[38;5;151m"
dark_gray_cor="\e[38;5;236m"

solid_blue_cor="\e[34m"
solid_cyan_cor="\e[36m"
solid_green_cor="\e[32m"
solid_yellow_cor="\e[33m"
solid_magenta_cor="\e[35m"
solid_red_cor="\e[31m"

gray_cor="\e[38;5;252m"
clear_cor="\e[0m"
blue_cor="\e[94m"
cyan_cor="\e[96m"
green_cor="\e[92m"
yellow_cor="\e[93m"
magenta_cor="\e[95m"
red_cor="\e[91m"
pink_cor="\e[0;95m"
purple_cor="\e[38;5;99m"

load_config_() {
  # Iterate over the first 10 project configurations
  for i in {1..10}; do
    short_name=$(sed -n "s/^Z_PROJECT_SHORT_NAME_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE")
    [[ -z "$short_name" ]] && continue  # Skip if not defined

    Z_PROJECT_SHORT_NAME[$i]=$short_name
    # echo "$i - key: Z_PROJECT_SHORT_NAME, value: $short_name"

    # Set project folder path
    _folder=$(sed -n "s/^Z_PROJECT_FOLDER_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE")
    if [[ -n "$_folder" ]]; then
      edited_folder="${_folder/#\~/$HOME}"
      [[ -n "$edited_folder" ]] && _folder="$edited_folder"
    fi
    
    [[ -n "$_folder" ]] && _folder="${_folder%/}"
    [[ -n "$_folder" ]] && realfolder=$(realpath "$_folder" 2>/dev/null)
    [[ -z "$realfolder" ]] && mkdir -p "$_folder" &>/dev/null && realfolder=$(realpath "$_folder" 2>/dev/null)

    Z_PROJECT_FOLDER[$i]=$realfolder
    # echo "$i - key: Z_PROJECT_FOLDER, value: $realfolder"

    keys=(
      Z_PROJECT_REPO
      Z_PACKAGE_MANAGER
      Z_CODE_EDITOR
      Z_CLONE
      Z_SETUP
      Z_RUN
      Z_RUN_STAGE
      Z_RUN_PROD
      Z_PRO
      Z_TEST
      Z_COV
      Z_TEST_WATCH
      Z_E2E
      Z_E2EUI
      Z_PR_TEMPLATE
      Z_PR_REPLACE
      Z_PR_APPEND
      Z_PR_RUN_TEST
      Z_GHA_INTERVAL
      Z_COMMIT_ADD
      Z_GHA_WORKFLOW
      Z_PUSH_ON_REFIX
      Z_DEFAULT_BRANCH
      Z_PRINT_README
    )

    for key in "${keys[@]}"; do
      value=$(sed -n "s/^${key}_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE")

      # If the value is not set, provide default values for specific keys
      if [[ -z "$value" ]]; then
        case "$key" in
          Z_PACKAGE_MANAGER)
            value="npm"
            ;;
          Z_CODE_EDITOR)
            value="code"
            ;;
          Z_RUN)
            value="${Z_PACKAGE_MANAGER[$i]} run dev"
            ;;
          Z_RUN_STAGE)
            value="${Z_PACKAGE_MANAGER[$i]} run stage"
            ;;
          Z_RUN_PROD)
            value="${Z_PACKAGE_MANAGER[$i]} run prod"
            ;;
          Z_TEST)
            value="${Z_PACKAGE_MANAGER[$i]} run test"
            ;;
          Z_COV)
            value="${Z_PACKAGE_MANAGER[$i]} run test:coverage"
            ;;
          Z_TEST_WATCH)
            value="${Z_PACKAGE_MANAGER[$i]} run test:watch"
            ;;
          Z_E2E)
            value="${Z_PACKAGE_MANAGER[$i]} run test:e2e"
            ;;
          Z_E2EUI)
            value="${Z_PACKAGE_MANAGER[$i]} run test:e2e-ui"
            ;;
          Z_PR_APPEND)
            value="0"
            ;;
          Z_GHA_INTERVAL)
            value="10"
            ;;
          Z_PRINT_README)
            value="0"
            ;;
          *)
            continue
            ;;
        esac
      fi

      # store the value
      case "$key" in
        Z_PROJECT_REPO)
          Z_PROJECT_REPO[$i]="$value"
          ;;
        Z_PACKAGE_MANAGER)
          Z_PACKAGE_MANAGER[$i]="$value"
          ;;
        Z_CODE_EDITOR)
          Z_CODE_EDITOR[$i]="$value"
          ;;
        Z_CLONE)
          Z_CLONE[$i]="$value"
          ;;
        Z_SETUP)
          Z_SETUP[$i]="$value"
          ;;
        Z_RUN)
          Z_RUN[$i]="$value"
          ;;
        Z_RUN_STAGE)
          Z_RUN_STAGE[$i]="$value"
          ;;
        Z_RUN_PROD)
          Z_RUN_PROD[$i]="$value"
          ;;
        Z_PRO)
          Z_PRO[$i]="$value"
          ;;
        Z_TEST)
          Z_TEST[$i]="$value"
          ;;
        Z_COV)
          Z_COV[$i]="$value"
          ;;
        Z_TEST_WATCH)
          Z_TEST_WATCH[$i]="$value"
          ;;
        Z_E2E)
          Z_E2E[$i]="$value"
          ;;
        Z_E2EUI)
          Z_E2EUI[$i]="$value"
          ;;
        Z_PR_TEMPLATE)
          Z_PR_TEMPLATE[$i]="$value"
          ;;
        Z_PR_REPLACE)
          Z_PR_REPLACE[$i]="$value"
          ;;
        Z_PR_APPEND)
          Z_PR_APPEND[$i]="$value"
          ;;
        Z_PR_RUN_TEST)
          Z_PR_RUN_TEST[$i]="$value"
          ;;
        Z_GHA_INTERVAL)
          Z_GHA_INTERVAL[$i]="$value"
          ;;
        Z_COMMIT_ADD)
          Z_COMMIT_ADD[$i]="$value"
          ;;
        Z_DEFAULT_BRANCH)
          Z_DEFAULT_BRANCH[$i]="$value"
          ;;
        Z_GHA_WORKFLOW)
          Z_GHA_WORKFLOW[$i]="$value"
          ;;
        Z_PUSH_ON_REFIX)
          Z_PUSH_ON_REFIX[$i]="$value"
          ;;
        Z_PRINT_README)
          Z_PRINT_README[$i]="$value"
          ;;
      esac
      # echo "$i - key: $key, value: $value"
    done
  done
}

load_config_

# clear project names if they are invalid
for i in {1..10}; do
  if [[ -n "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
    check_proj_name_valid_ "${Z_PROJECT_SHORT_NAME[$i]}" -q
    if [[ $? -ne 0 ]]; then
      clear_project_ $i
    fi
  fi
done

PUMP_PRO_FILE="$(dirname "$0")/.pump"

# auto pro ===============================================================
pro pwd -q
# get stored project and set project but do not change current directory
if [ $? -ne 0 ]; then
  # Read the current project short name from the PUMP_PRO_FILE if it exists
  [[ -f "$PUMP_PRO_FILE" ]] && pump_pro_file_value=$(<"$PUMP_PRO_FILE")

  if [[ -n "$pump_pro_file_value" ]]; then
    check_proj_name_valid_ "$pump_pro_file_value" -q
    if [ $? -ne 0 ]; then
      rm -f "$PUMP_PRO_FILE" &>/dev/null
      pump_pro_file_value=""
    fi
  fi

  # Create an array of project names to loop through
  project_names=("$pump_pro_file_value")
  
  # Loop through 1 to 10 to add additional project names to the array
  for i in {1..10}; do
    if [[ -n "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
      if [[ ! " ${project_names[@]} " =~ " ${Z_PROJECT_SHORT_NAME[$i]} " ]]; then
        project_names+=("${Z_PROJECT_SHORT_NAME[$i]}")
      fi
    fi
  done
  
  # Remove any empty values in the array (e.g., if $pump_pro_file_value is empty)
  project_names=("${project_names[@]/#/}")
  #echo "${project_names[@]}"

  # Loop over the projects to check and execute them
  for project in "${project_names[@]}"; do
    if [[ -n "$project" ]]; then
      pro "$project" -q
      if [[ $? -eq 0 ]]; then
        break  # Exit loop once a valid project is found and executed successfully
      fi
    fi
  done
fi

if [[ -n "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
  echo " your project is set to:${solid_blue_cor} $Z_CURRENT_PROJECT_SHORT_NAME${clear_cor} with${solid_magenta_cor} $Z_CURRENT_PACKAGE_MANAGER ${clear_cor}"
  echo ""
else
  return 0;
fi

if [[ -n "$Z_CURRENT_PRO" ]]; then
  eval "$Z_CURRENT_PRO"
fi
# ==========================================================================

alias i="$Z_CURRENT_PACKAGE_MANAGER install"
# Package manager aliases =========================================================
alias build="$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")build"
alias deploy="$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")deploy"
alias fix="$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")format && $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")lint"
alias format="$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")format"
alias ig="$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")install --global"
alias lint="$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")lint"
alias rdev="$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")dev"
alias tsc="$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")tsc"
alias sb="$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook"
alias sbb="$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook:build"
alias start="$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")start"

unalias ncov &>/dev/null
unalias ntest &>/dev/null
unalias ne2e &>/dev/null
unalias ne2eui &>/dev/null
unalias ntestw &>/dev/null

unalias ycov &>/dev/null
unalias ytest &>/dev/null
unalias ye2e &>/dev/null
unalias ye2eui &>/dev/null
unalias ytestw &>/dev/null

unalias pcov &>/dev/null
unalias ptest &>/dev/null
unalias pe2e &>/dev/null
unalias pe2eui &>/dev/null
unalias ptestw &>/dev/null

unalias bcov &>/dev/null
unalias btest &>/dev/null
unalias be2e &>/dev/null
unalias be2eui &>/dev/null
unalias btestw &>/dev/null 

if [[ "$Z_CURRENT_COV" != "$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage" ]]; then
  alias ${Z_CURRENT_PACKAGE_MANAGER:0:1}cov="$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage"
fi
if [[ "$Z_CURRENT_TEST" != "$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test" ]]; then
  alias ${Z_CURRENT_PACKAGE_MANAGER:0:1}test="$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test"
fi
if [[ "$Z_CURRENT_E2E" != "$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e" ]]; then
  alias ${Z_CURRENT_PACKAGE_MANAGER:0:1}e2e="$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e"
fi
if [[ "$Z_CURRENT_E2EUI" != "$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui" ]]; then
  alias ${Z_CURRENT_PACKAGE_MANAGER:0:1}e2eui="$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui"
fi
if [[ "$Z_CURRENT_TEST_WATCH" != "$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch" ]]; then
  alias ${Z_CURRENT_PACKAGE_MANAGER:0:1}testw="$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch"
fi

# project functions =========================================================
z_project_handler() {
  local i="$1"
  local short_name="${Z_PROJECT_SHORT_NAME[$i]}"
  local folder="${Z_PROJECT_FOLDER[$i]}"
  local working="${PUMP_WORKING[$i]}"

  if [[ -z "$folder" ]]; then
    save_project_ $i
    return 1
  fi

  local is_single_mode=$(is_project_single_mode_ "$Z_CURRENT_PROJECT_FOLDER")

  if [[ "$2" == "-h" ]]; then
    echo "${yellow_cor} $short_name${clear_cor} : to cd into $short_name"
    if [[ $is_single_mode -eq 0 ]]; then
      echo "${yellow_cor} $short_name${solid_yellow_cor} [<branch>]${clear_cor} : to cd into $short_name and switch to branch"
    else
      echo "${yellow_cor} $short_name -l${clear_cor} : to list all $short_name's working folders"
      echo "${yellow_cor} $short_name${solid_yellow_cor} [<folder>]${clear_cor} : to cd into $short_name into a folder"
      echo "${yellow_cor} $short_name${solid_yellow_cor} [<folder>] [<branch>]${clear_cor} : to cd into $short_name into a folder and switch to branch"
    fi
    return 0
  fi

  if [[ "$2" == "-l" ]]; then
    if [[ $is_single_mode -eq 0 ]]; then
      echo " project is in 'single mode'"
      echo " ${yellow_cor} $short_name -h${clear_cor} to see usage"
      return 0
    fi

    folders=($(get_folders_ "$folder"))
    if [[ -n "${folders[*]}" ]]; then
      for folder in "${folders[@]}"; do
        echo "${pink_cor} $folder ${clear_cor}"
      done
    else
      echo " no folders yet"
    fi
    return 0
  fi

  if [[ -z "$2" && $is_single_mode -eq 1 ]]; then
    folders=($(get_folders_ "$folder"))
    if [[ -n "${folders[*]}" ]]; then
      selected_folder=($(choose_auto_one_ "choose work folder:" "${folders[@]}"))
      if [[ -z "$selected_folder" ]]; then
        return 1
      fi
      "$short_name" "$selected_folder"
      return 0
    fi
  fi

  local arg2=""
  if [[ "$short_name" == "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
    arg2="-q"
  fi

  pro "$short_name" $arg2
  cd "$folder" || return 1

  local folder_path=""
  local branch=""
  local is_working_branch=0

  if [[ $is_single_mode -eq 0 ]]; then
    branch="$2"
    if [[ -z "$branch" ]]; then
      is_working_branch=1
      branch=$(git branch | grep -w "$working" | cut -c 3- | head -n 1)
    fi
  else
    if [[ -z "$2" ]]; then
      is_working_branch=1
      folder_path="$working"
      if [[ -z "$folder_path" || ! -d "$folder_path" ]]; then
        folder_path=$(get_default_branch_folder_ "$folder")
      fi
    else
      folder_path="$2"
    fi
    branch="$3"
  fi

  if [[ -n "$folder_path" ]]; then
    if [[ $is_working_branch -eq 1 ]]; then check_any_pkg_silent_ "$folder_path"; else check_any_pkg_ "$folder_path"; fi
    if [[ $? -eq 0 ]]; then
      _path=$(realpath "$folder_path" 2>/dev/null)
      if [[ -n "$_path" ]]; then
        PUMP_FUTURE_="$_path"
        PUMP_FUTURE_BRANCH_OR_FOLDER_="folder"
      fi
      pushd "$folder_path" &>/dev/null
    fi
  fi

  if [[ -n "$branch" ]]; then
    if [[ $is_working_branch -eq 1 ]]; then
      co -e "$branch" -q
    else
      co -e "$branch"
    fi
    st
  fi
}

for i in {1..10}; do
  short_name="${Z_PROJECT_SHORT_NAME[$i]}"
  if [[ -n "$short_name" ]]; then
    eval "
      $short_name() {
        z_project_handler $i \"\$@\"
      }
    "
  fi
done
