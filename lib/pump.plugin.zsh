typeset -g is_d=0 # (debug flag) when -d is on, it will be shared across all subsequent function calls

typeset -gA Z_PROJECT_SHORT_NAME
typeset -gA Z_PROJECT_FOLDER
typeset -gA Z_PROJECT_REPO
typeset -gA Z_PROJECT_SINGLE_MODE
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

typeset -g PUMP_VERSION="0.0.0"

typeset -g PUMP_VERSION_FILE="$(dirname "$0")/.version"
typeset -g PUMP_WORKING_FILE="$(dirname "$0")/.working"
typeset -g PUMP_CONFIG_FILE="$(dirname "$0")/config/pump.zshenv"

[[ -f "$PUMP_VERSION_FILE" ]] && PUMP_VERSION=$(<"$PUMP_VERSION_FILE")

if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
  cp "$(dirname "$0")/config/pump.zshenv.default" "$PUMP_CONFIG_FILE" &>/dev/null
  if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
    print "${red_cor} config file '$PUMP_CONFIG_FILE' does not exist, re-install pump-my-shell ${reset_cor}"
    return 1;
  fi
fi

# ========================================================================
Z_CURRENT_PROJECT_FOLDER=""
Z_CURRENT_PROJECT_SHORT_NAME=""
Z_CURRENT_PROJECT_REPO=""
Z_CURRENT_PROJECT_SINGLE_MODE=""
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

PUMP_PAST_FOLDER=""
PUMP_PAST_BRANCH=""

bright_green_cor="\e[1m\e[38;5;151m"
dark_gray_cor="\e[38;5;236m"

solid_blue_cor="\e[34m"
solid_cyan_cor="\e[36m"
solid_green_cor="\e[32m"
solid_yellow_cor="\e[33m"
solid_magenta_cor="\e[35m"
solid_red_cor="\e[31m"

gray_cor="\e[38;5;252m"
reset_cor="\e[0m"
blue_cor="\e[94m"
cyan_cor="\e[96m"
green_cor="\e[92m"
yellow_cor="\e[93m"
magenta_cor="\e[95m"
red_cor="\e[91m"
pink_cor="\e[0;95m"
purple_cor="\e[38;5;99m"
# ========================================================================

function cl() {
  typeset -g is_d=0
  tput reset
}

function parse_flags_() {
  if [[ -z "$1" ]]; then
    print "${red_cor} fatal: parse_flags_ requires a prefix${reset_cor}" >&2
    return 1;
  fi

  local prefix="$1"
  local valid_flags="d${2}h"
  shift 2

  local OPTIND=1 opt
  local -A flags
  
  for opt in {a..z}; do
    flags[$opt]=0
    echo "${prefix}is_$opt=0"
  done

  while getopts ":abcdefghijklmnopqrstuvwxyz" opt; do
    case "$opt" in
      \?) break ;;
      *)
        if [[ $valid_flags != *$opt* ]]; then
          print "${red_cor} invalid option: -$opt${reset_cor}\n" >&2
          flags[h]=1
        fi
        flags[$opt]=1
        ;;
    esac
  done

  for opt in ${(k)flags}; do
    echo "${prefix}is_$opt=${flags[$opt]}"
    if [[ "$opt" == "d" ]]; then
      if (( flags[$opt] || is_d )); then
        echo "is_d=1" # keep is_d on
      fi
    fi
  done

  if (( OPTIND > 1 )); then
    shift $((OPTIND - 1))
  fi
  echo "set -- ${(q+)@}"
}

typeset -Ag node_folder node_branch node_project
typeset -Ag ll_next ll_prev
typeset -gi node_counter=0
typeset -g head=""

function ll_add_node_() {
  local project="$1"
  local folder="$(PWD)"
  local branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"

  if [[ -z "$project" ]]; then
    project=$(which_pro_pwd_)
  fi

  node_project[$id]="$i"
  node_folder[$id]="$folder"
  node_branch[$id]="$branch"

  print_debug_ "ll_add_node_ $project - $folder - $branch"

  local id="node$((++node_counter))"

  node_project[$id]="$i"
  node_folder[$id]="$folder"
  node_branch[$id]="$branch"

  if [[ -z "$head" ]]; then
    ll_next[$id]="$id"
    ll_prev[$id]="$id"
    head="$id"
  else
    local tail="${ll_prev[$head]}"
    ll_next[$tail]="$id"
    ll_prev[$id]="$tail"
    ll_next[$id]="$head"
    ll_prev[$head]="$id"
  fi
}

function ll_remove_node_() {
  local folder="$1" branch="$2" project="$3"

  if [[ -z "$head" ]]; then
    return 1
  fi

  local id="$head"

  while true; do
    if [[ "${node_folder[$id]}" == "$folder" &&
          "${node_branch[$id]}" == "$branch" &&
          "${node_project[$id]}" == "$project" ]]; then
  
      local prev="${ll_prev[$id]}"
      local next="${ll_next[$id]}"

      if [[ "$id" == "$prev" ]]; then
        # Single node
        unset node_folder[$id] node_branch[$id] node_project[$id]
        unset ll_prev[$id] ll_next[$id]
        head=""
      else
        ll_next[$prev]="$next"
        ll_prev[$next]="$prev"
        [[ "$id" == "$head" ]] && head="$next"
        unset node_folder[$id] node_branch[$id] node_project[$id]
        unset ll_prev[$id] ll_next[$id]
      fi

      return 0
    fi

    id="${ll_next[$id]}"
    [[ "$id" == "$head" ]] && break
  done

  return 1
}

function ll_traverse_() {
  if [[ -z "$head" ]]; then
    return
  fi

  local id="$head"

  while true; do
    print "pro=${Z_PROJECT_SHORT_NAME[${node_project[$id]}]}, folder=${node_folder[$id]}, branch=${node_branch[$id]}"
    id="${ll_next[$id]}"
    [[ "$id" == "$head" ]] && break
  done
}

function ll_save_() {
  local file="${1:-$PUMP_WORKING_FILE}"

  echo "" > "$file"

  if [[ -z "$head" ]]; then return; fi

  local id="$head"
  while true; do
    echo "${node_project[$id]}|${node_folder[$id]}|${node_branch[$id]}" >> "$file"
    id="${ll_next[$id]}"
    [[ "$id" == "$head" ]] && break
  done
}

function ll_restore_() {
  local file="${1:-$PUMP_WORKING_FILE}"

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  # Clear everything
  node_folder=()
  node_branch=()
  node_project=()
  ll_next=()
  ll_prev=()
  head=""

  while IFS='|' read -r project folder branch; do
    ll_add_node_ "$project" "$folder" "$branch"
  done < "$file"
}

function confirm_between_() {
  local question="$1"
  local option1="$2"
  local option2="$3"
  local opt1="${option1[1]}"
  local opt2="${option2[1]}"
  local is_echod="${4:-0}"

  local chosen_mode=""

  if command -v gum &>/dev/null; then
    gum confirm ""mode:$'\e[0m'" $1" --no-show-help --affirmative="$option1" --negative="$option2"
    RET=$?
    if (( RET == 130 )); then
      return 130;
    fi
    if (( RET == 0 )); then
      chosen_mode="$opt1"
    elif (( RET == 1 )); then
      chosen_mode="$opt2"
    fi
  else
    while true; do
      echo -n ""$'\e[38;5;99m'mode:$'\e[0m'" $1? "$'\e[38;5;218m'$option1$'\e[0m'" or "$'\e[38;5;218m'$option2$'\e[0m'" repositories? [${opt1:l}/${opt2:l}]: "
      stty -echo                  # Turn off input echo
      read -k 1 mode              # Read one character
      stty echo                   # Turn echo back on
      case "$mode" in
        [sSmM]) break ;;          # Accept only s or m (case-insensitive)
        *) echo "" ;;
      esac
    done
    if [[ "$mode" == "${opt1:l}" || "$mode" == "${opt1:u}" ]]; then
      chosen_mode="$opt1"
      RET=0
    elif [[ "$mode" == "${opt2:l}" || "$mode" == "${opt2:u}" ]]; then
      chosen_mode="$opt2"
      RET=1
    else
      return 130;
    fi
  fi

  if (( is_echod )); then
    echo $chosen_mode
  fi

  return $RET;
}

function confirm_from_() {
  #trap 'echo ""; return 130' INT

  if command -v gum &>/dev/null; then
    gum confirm ""confirm:$'\e[0m'" $1" --no-show-help
    return $?
  fi

  read -qs "?"$'\e[38;5;99m'confirm:$'\e[0m'" $1 (y/n) "
  RET=$?

  if (( RET == 130 )); then
    return 130;
  fi
  
  if [[ $REPLY == [yY] ]]; then
    print "y" >&2
    return 0;
  fi
  
  if [[ $REPLY == [nN] ]]; then
    print "n" >&2
    return 1;
  fi
  
  print $REPLY >&2
  return 130;
}

function update_() {
  eval "$(parse_flags_ "update_" "f" "$@")"

  local release_tag="https://api.github.com/repos/fab1o/pump-my-shell/releases/latest"
  local latest_version=$(curl -s $release_tag | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

  if [[ -n "$latest_version" && "$PUMP_VERSION" != "$latest_version" ]]; then
    print " new version available for pump-my-shell:${yellow_cor} $PUMP_VERSION -> $latest_version ${reset_cor}"

    if (( ! update_is_f )); then
      if ! confirm_from_ "do you want to install new version?"; then
        return 0;
      fi
    fi

    print " if you encounter an error after installation, don't worry — simply restart your terminal"

    /bin/bash -c "$(curl -H "Cache-Control: no-cache" -fsSL https://raw.githubusercontent.com/fab1o/pump-my-shell/refs/heads/main/scripts/update.sh)"
    return 1;
  else
    print " no update available for pump-my-shell:${yellow_cor} $PUMP_VERSION ${reset_cor}" >&2
  fi
}

update_ 2>/dev/null

# General
alias hg="history | grep" # $1
alias ll="ls -lAF"
alias nver="node -e 'console.log(process.version, process.arch, process.platform)'"
alias nlist="npm list --global --depth=0"
alias path="echo $PATH"

function kill() {
  if [[ -z "$1" ]]; then
    print "${yellow_cor} kill <port>${reset_cor} : to kill a port number"
    return 0;
  fi

  npx --yes kill-port $1
}

function refresh() {
  if [[ -f "$HOME/.zshrc" ]]; then
    source "$HOME/.zshrc"
  fi
}

function upgrade() {
  update_ -f

  if command -v omz &>/dev/null; then
    omz update
  fi
  if command -v oh-my-posh &>/dev/null; then
    oh-my-posh upgrade
  fi
}

function input_from_() {
  trap 'echo ""; return 130' INT

  if command -v gum &>/dev/null; then
    _input=$(gum input --placeholder="$1")
    if (( $? != 0 )); then
      #clear_last_line_
      return 1;
    fi
  else
    stty -echoctl
    read "?> " _input || { echo ""; echo ""; return 1; }
    stty echoctl
  fi

  echo "$_input"
}

function choose_multiple_() {
  local purple=$'\e[38;5;99m'
  local cor=$'\e[38;2;167;139;250m'
  local reset=$'\e[0m'

  if command -v gum &>/dev/null; then
    echo "$(gum choose --no-limit --height 20 --header="${purple} $1 ${cor}(use spacebar)${purple}:${reset}" "${@:2}")"
    return 0;
  fi

  trap 'echo ""; return 130' INT
  PS3="${purple}$1: ${reset}"
  select choice in "${@:2}" "quit"; do
    case $choice in
      "quit")
        return 1;
        ;;
      *)
        echo "$choice"
        return 0;
        ;;
    esac
  done
}
function choose_one_() {
  local purple=$'\e[38;5;99m'
  local reset=$'\e[0m'

  if command -v gum &>/dev/null; then
    echo "$(gum choose --limit=1 --height="$2" --header="${purple} $1:${reset}" "${@:3}")"
    return 0;
  fi
  
  PS3="${purple}$1: ${reset}"
  select choice in "${@:3}" "quit"; do
    case $choice in
      "quit")
        return 1;
        ;;
      *)
        echo "$choice"
        return 0;
        ;;
    esac
  done
}

function choose_auto_one_by_filtering_() {
  if command -v gum &>/dev/null; then
    print "${purple_cor} $1: ${reset_cor}" >&2
    echo "$(gum filter --height 20 --limit 1 --indicator=">" --placeholder=" $2" "${@:3}")"
  else
    choose_auto_one_ "$2" "$3"
  fi
}

function choose_auto_one_() {
  local purple=$'\e[38;5;99m'
  local reset=$'\e[0m'

  if command -v gum &>/dev/null; then
    local choice="$(gum choose --limit=1 --select-if-one --height 20 --header="${purple} $1:${reset}" "${@:2}")"
    if [[ -z "$choice" ]]; then
      return 1;
    fi
    echo "$choice"
    return 0;
  fi
  
  PS3="${purple}$1: ${reset}"
  select choice in "${@:2}" "quit"; do
    case $choice in
      "quit")
        return 1;
        ;;
      *)
        echo "$choice"
        return 0;
        ;;
    esac
  done
}

function get_files_() {
  local _pwd=$(pwd)

  if [[ -n "$1" ]]; then
    cd "$1"
  fi

  setopt null_glob
  ls -d * | sed 's:/$::' | grep -v -E '^\.$|^revs$'
  unsetopt null_glob

  cd "$_pwd"
}

function get_folders_() {
  local _pwd=$(pwd)

  if [[ -n "$1" ]]; then
    cd "$1"
  fi

  setopt null_glob
  ls -d */ | sed 's:/$::' | grep -v -E '^\.$|^revs$'
  unsetopt null_glob

  cd "$_pwd"
}

# Deleting a path
function del() {
  eval "$(parse_flags_ "del_" "s" "$@")"

  if (( del_is_h )); then
    print "${yellow_cor} del ${reset_cor} : to delete in current directory"
    print "${yellow_cor} del <glob>${reset_cor} : to delete files (or folders)"
    print "${yellow_cor} del -s ${solid_yellow_cor}[<glob>]${reset_cor} : without confirmation"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " del requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi

  # local _pro="$Z_PROJECT_SHORT_NAME"
  # local proj_folder=""
  # local pump_working_branch=""

  # if [[ -n "$_pro" ]]; then
  #   for i in {1..9}; do
  #     if [[ "$_pro" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
  #       proj_folder="${Z_PROJECT_FOLDER[$i]}"
  #       pump_working_branch="${PUMP_WORKING[$i]}"
  #       break
  #     fi
  #   done
  # fi

  if [[ -z "$1" ]]; then
    if [[ -n ${(f)"$(get_files_)"} ]]; then
      local folders=($(get_files_))
      local selected_folders=$(choose_multiple_ "choose what to delete" "${folders[@]}")
      if [[ -z "$selected_folders" ]]; then
        return 1;
      fi

      # delete_pump_workings_ "$pump_working_branch" "$_pro" "${selected_folders[@]}"

      for folder in "${selected_folders[@]}"; do
        gum spin --title "deleting... $folder" -- rm -rf "$folder"
        print "${magenta_cor} deleted${blue_cor} $folder ${reset_cor}"
      done
      ls
    else
      print " no folders"
    fi
    return 0;
  fi

  setopt dot_glob null_glob
  # Capture all args (quoted or not) as a single pattern
  local pattern="$*"
  # Expand the pattern — if it's a glob, this expands to matches
  local files=(${(z)~pattern})

  # print "1 ${files[1]}"
  # print "pattern $pattern"
  # print "qty ${#files[@]}"

  local _count=0
  local is_all=$del_is_s
  local dont_ask=$del_is_s

  # Check if it's a glob pattern with multiple or changed matches
  if [[ ${#files[@]} -gt 1 || "$pattern" != "${files[1]}" ]]; then
    for f in $files; do
      if (( ! del_is_s && _count < 3 )); then
        confirm_from_ "delete "$'\e[94m'$f$'\e[0m'"?"
        RET=$?
        if (( RET == 130 )); then
          break;
        elif (( RET == 1 )); then
          continue;
        fi
      else
        if (( is_all == 0 && dont_ask == 0 )); then
          maxlen=90
          split_pattern=""

          while [[ -n $pattern ]]; do
            line="${pattern[1,$maxlen]}"
            split_pattern+=""$'\e[94m'$line$'\n\e[0m'""
            pattern="${pattern[$((maxlen + 1)),-1]}"
          done
          split_pattern="${split_pattern%""$'\n\e[0m'""}"
          confirm_from_ "delete all remaining $split_pattern"$'\e[0m'"?"
          RET=$?
          if (( RET == 130 )); then
            break;
          elif (( RET == 1 )); then
            dont_ask=1
          else
            is_all=1
          fi
        fi
        if (( is_all == 0 )); then
          confirm_from_ "delete "$'\e[94m'$f$'\e[0m'"?"
          RET=$?
          if (( RET == 130 )); then
            break;
          elif (( RET == 1 )); then
            continue;
          fi
        fi
      fi

      _count=$(( _count + 1 ))

      # if [[ -d "$f" && -n "$pump_working_branch" && -n "$_pro" ]]; then
      #   delete_pump_working_ $(basename "$f") "$pump_working_branch" "$_pro"
      # fi

      gum spin --title "deleting... $f" -- rm -rf "$f"
      print "${magenta_cor} deleted${blue_cor} $f ${reset_cor}"

    done

    unsetopt dot_glob null_glob
    return 0;
  fi
  
  unsetopt dot_glob null_glob

  local file_path=$(realpath "$1" 2>/dev/null) # also works: "${1/#\~/$HOME}"
  if (( $? != 0 )); then return 1; fi

  if [[ -z "$file_path" || ! -e "$file_path" ]]; then
    return 1;
  fi

  local confirm_msg=""
  local folder_to_move=""

  if [[ "$file_path" == "$(PWD)" ]]; then
    folder_to_move="$(dirname "$file_path")"
    confirm_msg="delete current path "$'\e[94m'$PWD$'\e[0m'"?";
  else
    confirm_msg="delete "$'\e[94m'$file_path$'\e[0m'"?";
  fi

  if (( ! del_is_s )) && [[ ".DS_Store" != $(basename "$file_path") ]]; then 
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

  local file_path_log=""

  if [[ "$file_path" == "$(PWD)"* ]]; then # the file_path is inside the current path
    file_path_log=$(shorten_path_until_ "$file_path")
  elif [[ -n "$Z_CURRENT_PROJECT_FOLDER" ]]; then
    file_path_log=$(shorten_path_until_ "$file_path" $(basename "$Z_CURRENT_PROJECT_FOLDER"))
  fi

  # if [[ -d "$file_path" && -n "$pump_working_branch" && -n "$_pro" ]]; then
  #   delete_pump_working_ "$(basename "$file_path")" "$pump_working_branch" "$_pro"
  # fi

  gum spin --title "deleting... $file_path" -- rm -rf "$file_path"

  if [[ -z "$file_path_log" ]]; then
    file_path_log="$file_path"
  fi

  print "${magenta_cor} deleted${blue_cor} $file_path_log ${reset_cor}"

  if [[ -n "$folder_to_move" ]]; then
    cd "$folder_to_move"
  fi
}

function check_config_file_() {
  local config_file="${1:-$PUMP_CONFIG_FILE}"
  local config_dir=$(dirname "$config_file")
  local config_name=$(basename "$config_file")

  if [[ ! -d "$config_dir" ]]; then
    mkdir -p "$config_dir"
  fi

  if [[ ! -f "$config_file" ]]; then
    touch "$config_file"
    chmod 644 "$config_file"
  fi

  PUMP_CONFIG_FILE="$config_file"
}

function update_config_() {
  check_config_file_
  
  if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
    return 1;
  fi

  local i=$1
  local key="$2"
  local value="$3"

  key="${key:u}_${i}"

  print_debug_ "update_config_ $key=$value"

  if [[ "$(uname)" == "Darwin" ]]; then
    if grep -q "^${key}=" "$PUMP_CONFIG_FILE"; then
      sed -i '' "s|^${key}=.*|${key}=${value}|" "$PUMP_CONFIG_FILE"
    else
      echo "${key}=${value}" >> "$PUMP_CONFIG_FILE"
    fi
    RET=$?
  else
    if grep -q "^${key}=" "$PUMP_CONFIG_FILE"; then
      sed -i "s|^${key}=.*|${key}=${value}|" "$PUMP_CONFIG_FILE"
    else
      echo "${key}=${value}" >> "$PUMP_CONFIG_FILE"
    fi
    RET=$?
  fi

  if (( RET != 0 )); then
    return 1;
  fi

  return 0;
}

function input_name_() {
  print "${purple_cor} $1:${reset_cor}" >&2

  while true; do
    local typed_value=""
    typed_value="$(input_from_ "$2")"
    if (( $? != 0 )); then
      return 1;
    fi
    if [[ -z "$typed_value" ]]; then
      if command -v gum &>/dev/null; then
        echo "$2"
        return 0;
      fi
      return 1;
    fi

    local qty=${3:-10}
    if [[ "$typed_value" =~ ^[a-z0-9][a-z0-9-]*$ && ${#typed_value} -le $qty ]]; then
      echo "${typed_value:l}"
      break;
    else
      print " invalid name: lowercase, no special characters, $qty max" >&2
    fi
  done
}

function choose_prj_folder_() {
  if !command -v gum &>/dev/null; then
    echo "$(input_path_ "$2")"
    return $?
  fi

  local i="$1"
  local header="$2"
  local repo="$3"
  local folder_path=""

  print " ${purple_cor} ${header}:${reset_cor}" >&2

  cd "${HOME:-/}"

  while true; do
    if [[ -n "$folder_path" ]]; then
      confirm_between_ "do you want to use: "$'\e[94m'${folder_path}$'\e[0m'" or keep browsing?" "browse" "use"
      RET=$?
      if (( RET == 130 )); then
        return 130;
      fi
      
      if (( RET == 0 )); then
        cd "$folder_path"
      else
        local found=0
        for j in {1..10}; do
          if [[ $j -ne $i && "${Z_PROJECT_FOLDER[$j]}" == "$folder_path" && -n "${Z_PROJECT_SHORT_NAME[$j]}"  ]]; then
            found=1
            clear_last_line_
            print "  project folder already in use, choose another one" >&2
            cd "$HOME"
          fi
        done

        if (( found == 0 )); then
          clear_last_line_
          echo "$folder_path"
          return 0;
        fi
      fi
    fi

    folder_path=""
    
    if [[ -z ${(f)"$(get_folders_)"} ]]; then
      cd "${HOME:-/}"
    fi

    local folder=""
    folder="$(gum file --directory --height 14)"
    if (( $? == 130 )); then
        return 130;
    fi

    if [[ -n "$folder" ]]; then
      folder_path="$folder"
    else
      return 1;
    fi
  done

  return 1;
}

function input_path_() {
  local header="$1"

  print "${purple_cor} ${header}:${reset_cor}" >&2

  while true; do
    local typed_value=""
    typed_value="$(input_from_)"
    if (( $? != 0 )); then
      return 1;
    fi
    if [[ -z "$typed_value" ]]; then
      return 1;
    fi

    if [[ "$typed_value" =~ ^[a-zA-Z0-9/,._-]+$ ]]; then
      echo "$typed_value"
      break;
    fi
  done
}

function input_repo_() {
  if command -v gh &>/dev/null; then
    confirm_from_ "do you want to access your Github account to choose from a list of repositories?"
    RET=$?
    if (( RET == 130 )); then
      return 130;
    fi

    if (( RET == 0 )); then
      local gh_owner=""
      gh_owner=$(input_from_ "type the github owner account (user or organization)")
      if [[ -n "$gh_owner" ]]; then
        repos=("${(@f)$(gh repo list $gh_owner --limit 100 --json nameWithOwner -q '.[].nameWithOwner')}")
        if (( $? == 0 && ${#repos[@]} > 0 )); then
          local selected_repo=$(choose_one_ "choose repository" 30 "${repos[@]}")
          if [[ -n "$selected_repo" ]]; then
            local mode=""
            mode=$(confirm_between_ "ssh or https?" "ssh" "https" 1)
            if (( $? == 130 )); then
              return 130;
            fi
            local repo_uri=""
            if [[ "$mode" == "s" ]]; then
              repo_uri="git@github.com:${selected_repo}.git"
            else
              repo_uri="https://github.com/${selected_repo}.git"
            fi
            echo "$repo_uri"
            return 0;
          fi
        fi
      fi
    fi
  fi
  
  print "${purple_cor} type $1:${reset_cor}" >&2
  # setopt rematch_pcre

  while true; do
    local typed_repo=""
    typed_repo="$(input_from_ "$2")"
    if (( $? != 0 )); then
      return 1;
    fi
    if [[ -z "$typed_repo" ]]; then
      if command -v gum &>/dev/null; then
        echo "$2"
        return 0;
      fi
      return 1;
    fi
    #                      '^(git@[^:]+:[^/]+/[^/]+(\.git)?|https://[^/]+/[^/]+/[^/]+(\.git)?)$'
    if [[ "$typed_repo" =~ '^((git@[a-zA-Z0-9._-]+:[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?)|(https://[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?))$' ]]; then
       echo "$typed_repo"
       break;
    else
      clear_last_line_
      print "  repository must be a valid ssh or https uri" >&2
    fi
  done
}

function pause_output() {
  printf " "
  stty -echo

  IFS= read -r -k1 input

  if [[ $input == $'\e' ]]; then
      # read the rest of the escape sequence (e.g. for arrow keys)
      IFS= read -r -k2 rest
      input+=$rest
      # discard any remaining junk from the input buffer
      while IFS= read -r -t 0.01 -k1 junk; do :; done
  elif [[ $input != $'\n' ]]; then
      # discard remaining characters if non-enter, non-escape key
      while IFS= read -r -t 0.01 -k1 junk; do :; done
  fi

  stty echo

  if [[ $input == "q" ]]; then
      clear
      return 1;
  fi

  echo  # move to new line cleanly
}

function help_line_() {
  local word1="$1"
  local color=${2:-$gray_cor}
  local total_width1=${3:-72}
  local word2="$4"
  local total_width2=${5:-72}

  local help_line_padding=$(( total_width1 - 2 ))
  local help_line_line="$(printf '%*s' "$help_line_padding" '' | tr ' ' '─')"

  if [[ -n "$word1" ]]; then
    local word_length1=${#word1}

    local help_line_padding1=$(( ( total_width1 > word_length1 ? total_width1 - word_length1 - 2 : word_length1 - total_width1 - 2 ) / 2 ))
    local help_line_line1="$(printf '%*s' "$help_line_padding1" '' | tr ' ' '─') $word1 $(printf '%*s' "$help_line_padding1" '' | tr ' ' '─')"

    if (( ${#help_line_line1} < total_width1 )); then
      local help_line_pad_len1=$(( total_width1 - ${#help_line_line1} ))
      help_line_padding1=$(printf '%*s' $help_line_pad_len1 '' | tr ' ' '-')
      help_line_line1="${help_line_line1}${help_line_padding1}"
    fi
    
    help_line_line="$help_line_line1"
  fi

  if [[ -n "$word2" ]]; then
    local word_length2=${#word2}

    local help_line_padding2=$(( ( total_width2 > word_length2 ? total_width2 - word_length2 - 2 : word_length2 - total_width2 - 2 ) / 2 ))
    local help_line_line2="$(printf '%*s' "$help_line_padding2" '' | tr ' ' '─') $word2 $(printf '%*s' "$help_line_padding2" '' | tr ' ' '─')"

    if (( ${#help_line_line2} < total_width2 )); then
      local help_line_pad_len2=$(( total_width2 - ${#help_line_line2} ))
      help_line_padding2=$(printf '%*s' $help_line_pad_len2 '' | tr ' ' '-')
      help_line_line2="${help_line_line2}${help_line_padding2}"
    fi

    help_line_line="$help_line_line1 | $help_line_line2"
  fi

  print "${color} $help_line_line ${reset_cor}"
}

function help() {
  trap 'echo ""; return 130' INT

  #tput reset
  if command -v gum &>/dev/null; then
    gum style --border=rounded --margin=0 --padding="1 16" --border-foreground=212 --width=69 \
      --align=center "welcome to $(gum style --foreground 212 "fab1o's pump my shell! v$PUMP_VERSION")"
  else
    help_line_ "fab1o's pump my shell!" "${purple_cor}"
    print ""
  fi

  if [[ -n "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
    print ""
    print "  your project is set to:${solid_blue_cor} $Z_CURRENT_PROJECT_SHORT_NAME${reset_cor} with${solid_magenta_cor} $Z_CURRENT_PACKAGE_MANAGER ${reset_cor}"
  fi

  print ""
  print "  to learn more, visit:${blue_cor} https://github.com/fab1o/pump-my-shell/wiki ${reset_cor}"

  if [[ -z "$Z_CURRENT_PROJECT_FOLDER" || -z "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
    print ""
    save_prj_ -a 1

    if [[ -z "$Z_CURRENT_PROJECT_FOLDER" || -z "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
      print ""
      print " configure${solid_yellow_cor} $PUMP_CONFIG_FILE${reset_cor} as shown in the example below:"
      print ""
      print " Z_PROJECT_SHORT_NAME_1=${Z_PROJECT_SHORT_NAME[1]:-pump}"
      print " Z_PROJECT_FOLDER_1=${Z_PROJECT_FOLDER[1]:-"$HOME/pump-my-shell"}"
      print ""
      print " then restart your terminal, then type${yellow_cor} help${reset_cor} again"
      print ""
    else
      refresh
      print " now run${yellow_cor} help${reset_cor} again"
    fi
    return 0;
  fi
  
  print ""
  help_line_ "get started" "${blue_cor}"
  print ""
  print "  1. to clone project, type:${blue_cor} clone ${reset_cor}"
  print "  2. to setup project, type:${blue_cor} setup${reset_cor} or${blue_cor} setup -h${reset_cor} to see usage"
  print "  3. to run a project, type:${blue_cor} run${reset_cor} or${blue_cor} run -h${reset_cor} to see usage"

  print ""
  help_line_ "project selection" "${solid_blue_cor}"
  print ""
  print " ${solid_blue_cor} pro ${reset_cor}\t\t = set project"

  local i=0
  for i in {1..9}; do
    if [[ -n "${Z_PROJECT_FOLDER[$i]}" && -n "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
      local short="${Z_PROJECT_SHORT_NAME[$i]}"
      local folder="${Z_PROJECT_FOLDER[$i]}"
      local shortened_path=$(shorten_path_ "$folder" 1)
      local tab=$([[ ${#short} -lt 5 ]] && echo -e "\t\t" || echo -e "\t")
      
      print " ${solid_blue_cor} $short ${reset_cor}${tab} = set project and cd $shortened_path"
    fi
  done

  print ""
  help_line_ "project" "${blue_cor}"
  print ""
  print " ${blue_cor} clone ${reset_cor}\t = clone project or branch"
  
  local _setup=${Z_CURRENT_SETUP:-$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")setup}

  max=53
  if (( ${#_setup} > $max )); then
    # print " ${blue_cor} setup ${reset_cor}\t = ${_setup[1,$max]}"
    print " ${blue_cor} setup ${reset_cor}\t = execute  Z_SETUP"
  else
    print " ${blue_cor} setup ${reset_cor}\t = $_setup"
  fi
  if (( ${#Z_CURRENT_RUN} > $max )); then
    print " ${blue_cor} run ${reset_cor}\t\t = execute  Z_RUN"
  else
    print " ${blue_cor} run ${reset_cor}\t\t = $Z_CURRENT_RUN"
  fi
  if (( ${#Z_CURRENT_RUN_STAGE} > $max )); then
    print " ${blue_cor} run stage ${reset_cor}\t = execute  Z_RUN_STAGE"
  else
    print " ${blue_cor} run stage ${reset_cor}\t = $Z_CURRENT_RUN_STAGE"
  fi
  if (( ${#Z_CURRENT_RUN_PROD} > $max )); then
    print " ${blue_cor} run prod ${reset_cor}\t = execute  Z_RUN_PROD"
  else
    print " ${blue_cor} run prod ${reset_cor}\t = $Z_CURRENT_RUN_PROD"
  fi

  print ""
  help_line_ "code review" "${cyan_cor}"
  print ""
  print " ${cyan_cor} rev ${reset_cor}\t\t = open a pull request for review"
  print " ${cyan_cor} revs ${reset_cor}\t\t = list existing reviews"
  print " ${cyan_cor} prune revs ${reset_cor}\t = delete merged reviews"

  pause_output  # Wait for user input to continue
  if (( $? != 0 )); then
    return 0;
  fi

  help_line_ "$Z_CURRENT_PACKAGE_MANAGER" "${solid_magenta_cor}"
  print ""
  print " ${solid_magenta_cor} build ${reset_cor}\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")build"
  print " ${solid_magenta_cor} deploy ${reset_cor}\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")deploy"
  print " ${solid_magenta_cor} fix ${reset_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")format + lint"
  print " ${solid_magenta_cor} format ${reset_cor}\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")format"
  print " ${solid_magenta_cor} i ${reset_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")install"
  print " ${solid_magenta_cor} ig ${reset_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")install global"
  print " ${solid_magenta_cor} lint ${reset_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")lint"
  print " ${solid_magenta_cor} rdev ${reset_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")dev"
  print " ${solid_magenta_cor} sb ${reset_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook"
  print " ${solid_magenta_cor} sbb ${reset_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook:build"
  print " ${solid_magenta_cor} start ${reset_cor}\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")start"
  print " ${solid_magenta_cor} tsc ${reset_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")tsc"
  
  print ""
  help_line_ "test $Z_CURRENT_PROJECT_SHORT_NAME" "${magenta_cor}"
  print ""
  if [[ "$Z_CURRENT_COV" != "$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage" ]]; then
    print " ${solid_magenta_cor} ${Z_CURRENT_PACKAGE_MANAGER:0:1}cov ${reset_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage"
  fi
  if [[ "$Z_CURRENT_E2E" != "$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e" ]]; then
    print " ${solid_magenta_cor} ${Z_CURRENT_PACKAGE_MANAGER:0:1}e2e ${reset_cor}\t\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e"
  fi
  if [[ "$Z_CURRENT_E2EUI" != "$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui" ]]; then
    print " ${solid_magenta_cor} ${Z_CURRENT_PACKAGE_MANAGER:0:1}e2eui ${reset_cor}\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui"
  fi
  if [[ "$Z_CURRENT_TEST" != "$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test" ]]; then
    print " ${solid_magenta_cor} ${Z_CURRENT_PACKAGE_MANAGER:0:1}test ${reset_cor}\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test"
  fi
  if [[ "$Z_CURRENT_TEST_WATCH" != "$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch" ]]; then
    print " ${solid_magenta_cor} ${Z_CURRENT_PACKAGE_MANAGER:0:1}testw ${reset_cor}\t = $Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch"
  fi
  print " ${magenta_cor} cov ${reset_cor}\t\t = $Z_CURRENT_COV"
  print " ${magenta_cor} e2e ${reset_cor}\t\t = $Z_CURRENT_E2E"
  print " ${magenta_cor} e2eui ${reset_cor}\t = $Z_CURRENT_E2EUI"
  print " ${magenta_cor} test ${reset_cor}\t\t = $Z_CURRENT_TEST"
  print " ${magenta_cor} testw ${reset_cor}\t = $Z_CURRENT_TEST_WATCH"

  print ""
  help_line_ "git" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} gconf ${reset_cor}\t = git config"
  print " ${solid_cyan_cor} gha ${reset_cor}\t\t = view last workflow run"
  print " ${solid_cyan_cor} st ${reset_cor}\t\t = git status"
  
  pause_output  # Wait for user input to continue
  if (( $? != 0 )); then
    return 0;
  fi

  help_line_ "git branch" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} co ${reset_cor}\t\t = switch branch"
  print " ${solid_cyan_cor} co <b> <base> ${reset_cor} = create branch off of base branch"
  print " ${solid_cyan_cor} dev ${reset_cor}\t\t = switch to develop or dev"
  print " ${solid_cyan_cor} main ${reset_cor}\t\t = switch to master or main"
  print " ${solid_cyan_cor} next ${reset_cor}\t\t = go to the next working folder/branch"
  print " ${solid_cyan_cor} prev ${reset_cor}\t\t = go to the previous working folder/branch"
  print " ${solid_cyan_cor} renb <b>${reset_cor}\t = rename branch"
  print " ${solid_cyan_cor} stage ${reset_cor}\t = switch to staging or stage"

  print ""
  help_line_ "git clean" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} clean${reset_cor}\t\t = clean + restore"
  print " ${solid_cyan_cor} delb ${reset_cor}\t\t = delete branches"
  print " ${solid_cyan_cor} discard ${reset_cor}\t = reset local changes"
  print " ${solid_cyan_cor} prune ${reset_cor}\t = prune branches and tags"
  print " ${solid_cyan_cor} reset1 ${reset_cor}\t = reset soft 1 commit"
  print " ${solid_cyan_cor} reset2 ${reset_cor}\t = reset soft 2 commits"
  print " ${solid_cyan_cor} reset3 ${reset_cor}\t = reset soft 3 commits"
  print " ${solid_cyan_cor} reset4 ${reset_cor}\t = reset soft 4 commits"
  print " ${solid_cyan_cor} reset5 ${reset_cor}\t = reset soft 5 commits"
  print " ${solid_cyan_cor} reseta ${reset_cor}\t = reset hard origin + clean"
  print " ${solid_cyan_cor} restore ${reset_cor}\t = undo edits since last commit"
  
  print ""
  help_line_ "git log" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} glog ${reset_cor}\t\t = git log"
  print " ${solid_cyan_cor} gll ${reset_cor}\t\t = list branches"
  print " ${solid_cyan_cor} gll <b> ${reset_cor}\t = list branches matching branch"
  print " ${solid_cyan_cor} glr ${reset_cor}\t\t = list remote branches"
  print " ${solid_cyan_cor} glr <b> ${reset_cor}\t = list remote branches matching branch"

  pause_output  # Wait for user input to continue
  if (( $? != 0 )); then
    return 0;
  fi

  help_line_ "git pull" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} fetch ${reset_cor}\t = fetch from origin"
  print " ${solid_cyan_cor} pull ${reset_cor}\t\t = pull all branches from origin"
  print " ${solid_cyan_cor} pull tags${reset_cor}\t = pull all tags from origin"

  print ""
  help_line_ "git push" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} add ${reset_cor}\t\t = add files to index"
  print " ${solid_cyan_cor} commit ${reset_cor}\t = open commit wizard"
  print " ${solid_cyan_cor} commit <m>${reset_cor}\t = commit message"
  print " ${solid_cyan_cor} pr ${reset_cor}\t\t = create pull request"
  print " ${solid_cyan_cor} push ${reset_cor}\t\t = push all no-verify to origin"
  print " ${solid_cyan_cor} pushf ${reset_cor}\t = push force all to origin"
  
  print ""
  help_line_ "git rebase" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} abort${reset_cor}\t\t = abort rebase/merge/chp"
  print " ${solid_cyan_cor} chc ${reset_cor}\t\t = continue cherry-pick"
  print " ${solid_cyan_cor} chp ${reset_cor}\t\t = cherry-pick commit"
  print " ${solid_cyan_cor} conti ${reset_cor}\t = continue rebase/merge/chp"
  print " ${solid_cyan_cor} mc ${reset_cor}\t\t = continue merge"
  print " ${solid_cyan_cor} merge ${reset_cor}\t = merge from $(git config --get init.defaultBranch)"
  print " ${solid_cyan_cor} merge <b> ${reset_cor}\t = merge from branch"
  print " ${solid_cyan_cor} rc ${reset_cor}\t\t = continue rebase"
  print " ${solid_cyan_cor} rebase ${reset_cor}\t = rebase from $(git config --get init.defaultBranch)"
  print " ${solid_cyan_cor} rebase <b> ${reset_cor}\t = rebase from branch"

  pause_output  # Wait for user input to continue
  if (( $? != 0 )); then
    return 0;
  fi
  
  help_line_ "git stash" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} pop ${reset_cor}\t\t = stash pop index"
  print " ${solid_cyan_cor} stash ${reset_cor}\t = stash unnamed"
  print " ${solid_cyan_cor} stash <name> ${reset_cor}  = stash with name"
  print " ${solid_cyan_cor} stashes ${reset_cor}\t = list all stashes"

  print ""
  help_line_ "git tags" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} dtag ${reset_cor}\t\t = delete tag remotely"
  print " ${solid_cyan_cor} tag ${reset_cor}\t\t = create tag remotely"
  print " ${solid_cyan_cor} tags ${reset_cor}\t\t = list latest tags"
  print " ${solid_cyan_cor} tags 1 ${reset_cor}\t = display latest tag"

  print ""
  help_line_ "general" "${solid_cyan_cor}"
  print ""
  print " ${solid_yellow_cor} cl ${reset_cor}\t\t = clear"
  print " ${solid_yellow_cor} del ${reset_cor}\t\t = delete utility"
  print " ${solid_yellow_cor} help ${reset_cor}\t\t = display this help"
  print " ${solid_yellow_cor} hg <text> ${reset_cor}\t = history | grep text"
  print " ${solid_yellow_cor} kill <port> ${reset_cor}\t = kill port"
  print " ${solid_yellow_cor} ll ${reset_cor}\t\t = ls -laF"
  print " ${solid_yellow_cor} nver ${reset_cor}\t\t = node version"
  print " ${solid_yellow_cor} nlist ${reset_cor}\t = npm list global"
  print " ${solid_yellow_cor} path ${reset_cor}\t\t = print \$PATH"
  print " ${solid_yellow_cor} refresh ${reset_cor}\t = source .zshrc"
  print " ${solid_yellow_cor} upgrade ${reset_cor}\t = upgrade pump + zsh + omp"
  print ""
  help_line_ "multi-step task" "${pink_cor}"
  print ""
  print " ${pink_cor} cov <b> ${reset_cor}\t = compare test coverage with another branch"
  print " ${pink_cor} refix ${reset_cor}\t = reset last commit, run fix then re-commit/push"
  print " ${pink_cor} recommit ${reset_cor}\t = reset last commit then re-commit changes"
  print " ${pink_cor} repush ${reset_cor}\t = reset last commit then re-push changes"
  print " ${pink_cor} rev ${reset_cor}\t\t = open a pull request for review"
  print ""
}

# data checkers =========================================================
function check_prj_name_() {
  eval "$(parse_flags_ "check_prj_name_" "s" "$@")"

  local i="$1"
  local name="${2:-$Z_PROJECT_SHORT_NAME[$i]}"

  print_debug_ "check_prj_name_ index: $i - name: $name - is_s: $check_prj_name_is_s"

  local error_msg=""

  if [[ -z "$name" ]]; then
    error_msg="project name is missing"
  else
    local invalid_proj_names=(
      "yarn" "npm" "pnpm" "bun" "back" "add" "new" "remove" "rm" "install" "cd" "uninstall" "update" "init" "pushd" "popd" "ls" "dir" "ll"
      "pro" "rev" "revs" "clone" "setup" "run" "test" "testw" "covc" "cov" "e2e" "e2eui" "recommit" "refix" "clear"
      "rdev" "dev" "stage" "prod" "gha" "pr" "push" "repush" "pushf" "add" "commit" "build" "i" "ig" "deploy" "fix" "format" "lint"
      "tsc" "start" "sbb" "sb" "renb" "co" "reseta" "clean" "delb" "prune" "discard" "restore"
      "st" "gconf" "fetch" "pull" "glog" "gll" "glr" "reset" "resetw" "reset1" "reset2" "reset3" "reset4" "reset5" "reset6"
      "dtag" "tag" "tags" "pop" "stash" "stashes" "rebase" "merge" "rc" "conti" "mc" "chp" "chc" "abort"
      "cl" "del" "help" "kill" "nver" "nlist" "path" "refresh" "pwd" "empty" "upgrade" "quiet" "skip" "." ".."
    )

    if [[ " ${invalid_proj_names[@]} " =~ " $name " || "$name" == -* ]]; then
      error_msg="project name is invalid: $name"
    else
      # check for duplicates across other indices
      for j in {1..10}; do
        if [[ $j -ne $i && "${Z_PROJECT_SHORT_NAME[$j]}" == "$name" ]]; then
          error_msg="project name already in use"
          error_msg+="\n ${yellow_cor}pro -e $name${reset_cor} to edit the project"
          break;
        fi
      done
    fi
  fi

  if [[ -n "$error_msg" ]]; then
    print " $error_msg" >&2

    if (( check_prj_name_is_s )); then
      save_prj_name_ $i "$name"
      if (( $? == 0 )); then
        return 0;
      fi
    fi
    return 1;
  fi

  return 0;
}

function get_prj_repo_() {
  eval "$(parse_flags_ "get_prj_repo_" "s" "$@")"

  local i="$1"
  local repo="${2:-$Z_PROJECT_REPO[$i]}"

  local error_msg=""
  local warn_msg=""

  if [[ -z "$repo" ]]; then
    error_msg="project repository is missing"
  else
    # check for duplicates across other indices
    if ! [[ "$repo" =~ '^((git@[a-zA-Z0-9._-]+:[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?)|(https://[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?))$' ]]; then
      error_msg="project repository is invalid: $repo"
    fi
  fi
  
  if [[ -n "$warn_msg" ]]; then
    print " $warn_msg" >&2
  fi

  print_debug_ "get_prj_repo_ index: $i - repo: $repo - is_s: $get_prj_repo_is_s"

  if [[ -n "$error_msg" ]]; then
    repo=""
    clear_last_line_
    print "  $error_msg" >&2

    if (( get_prj_repo_is_s )); then
      save_prj_repo_ $i

      if (( $? == 0 )); then
        if (( i > 0 )); then
          repo="$Z_PROJECT_REPO[$i]"
        else
          repo="$Z_CURRENT_PROJECT_REPO"
        fi
      fi

    fi
  fi

  if [[ -n "$repo" ]]; then
    if command -v gum &>/dev/null; then
      gum spin --timeout=8s --title "checking repository uri..." -- git ls-remote "$repo"
    fi
    print_debug_ "get_prj_repo_: $repo"
    echo "$repo"
    return 0;
  fi

  return 1;
}

function get_prj_folder_() {
  eval "$(parse_flags_ "get_prj_folder_" "s" "$@")"

  local i="$1"
  local folder="${2:-$Z_PROJECT_FOLDER[$i]}"

  print_debug_ "get_prj_folder_ index: $i - folder: $folder - is_s: $get_prj_folder_is_s"

  local error_msg=""

  if [[ -z "$folder" ]]; then
    error_msg="project folder is missing"
  else
    for j in {1..10}; do
      if [[ $j -ne $i && "${Z_PROJECT_FOLDER[$j]}" == "$folder" && -n "${Z_PROJECT_SHORT_NAME[$j]}" ]]; then
        error_msg="project folder already in use, choose another one"
        break;
      fi
    done
  fi

  if [[ -n "$error_msg" ]]; then
    folder=""
    clear_last_line_
    print "  $error_msg" >&2

    if (( get_prj_folder_is_s )); then
      save_prj_folder_ $i
      if (( $? == 0 )); then
        print_debug_ "get_prj_folder_ Z_PROJECT_FOLDER_$i: $Z_PROJECT_FOLDER[$i]"
        if (( i > 0 )); then
          folder="$Z_PROJECT_FOLDER[$i]"
        else
          folder="$Z_CURRENT_PROJECT_FOLDER"
        fi
      fi
    fi
  fi

  if [[ -n "$folder" ]]; then
    if [[ ! -d "$folder" ]]; then
      mkdir -p "$folder" &>/dev/null
    fi
    print_debug_ "get_prj_folder_: $folder"
    echo "$folder"
    return 0;
  fi

  return 1;
}

function check_prj_pkg_manager_() {
  eval "$(parse_flags_ "check_prj_pkg_manager_" "s" "$@")"

  local i="$1"
  local pkg_manager="${2:-$Z_PACKAGE_MANAGER[$i]}"

  print_debug_ "check_prj_pkg_manager_ index: $i - folder: $folder - is_s: $check_prj_pkg_manager_is_s"

  local error_msg=""

  if [[ -z "$pkg_manager" ]]; then
    error_msg="package manager is missing"
  else
    local valid_pkg_managers=(
      "npm" "yarn" "pnpm" "bun" "pip" "poetry" "poe"
    )

    if ! [[ " ${valid_pkg_managers[@]} " =~ " $pkg_manager " ]]; then
      error_msg="package manager is invalid: $pkg_manager"
    fi
  fi

  if [[ -n "$error_msg" ]]; then
    clear_last_line_
    print " $error_msg" >&2

    if (( check_prj_pkg_manager_is_s )); then
      save_pkg_manager_ $i "$pkg_manager"
      if (( $? == 0 )); then
        return 0;
      fi
    fi
    return 1;
  fi

  return 0;
}

function check_prj_() {
  eval "$(parse_flags_ "check_prj_" "s" "$@")"

  local i="$1"

  if [[ -z "$i" || $i -lt 1 || $i -gt 9 ]]; then
    print " fatal: check_prj_ project index is invalid: $i"
    return 1;
  fi

  local name="${Z_PROJECT_SHORT_NAME[$i]}"

  if (( check_prj_is_s )); then
    check_prj_name_ -s $i "$name"
  else
    check_prj_name_ $i "$name"
  fi
  if (( $? != 0 )); then
    return 1;
  fi

  local folder="${Z_PROJECT_FOLDER[$i]}"

  if (( check_prj_is_s )); then
    get_prj_folder_ -s $i "$folder" >/dev/null
  else
    get_prj_folder_ $i "$folder" >/dev/null
  fi
  if (( $? != 0 )); then
    return 1;
  fi

  local pkg_manager="${Z_PACKAGE_MANAGER[$i]}"

  if (( check_prj_is_s )); then
    check_prj_pkg_manager_ -s $i "$pkg_manager"
  else
    check_prj_pkg_manager_ $i "$pkg_manager"
  fi
  if (( $? != 0 )); then
    return 1;
  fi
  
  # local repo="${Z_PROJECT_REPO[$i]}"
  # repo is no necessary here, only for clone and rev
  # if (( check_prj_is_s )); then
  #   get_prj_repo_ -s $i "$repo" >/dev/null
  # else
  #   get_prj_repo_ $i "$repo" >/dev/null
  # fi
  # if (( $? != 0 )); then
  #   return 1;
  # fi

  # now it's time to save the project name
  save_prj_name_really_ $i

  return 0;
}
# end of data checkers =========================================================

clear_last_line_() {
  print -n "\033[1A\033[2K" >&2
}

# save project data to config file =========================================
function save_prj_name_really_() {
  local i="$1"
  local name="${2:-$SAVE_PRJ_NAME_TEMP}"

  if [[ -z "$name" ]]; then
    print_debug_ "save_prj_name_really_ name is empty"
    return 0;
  fi

  print_debug_ "save_prj_name_really_ index: $i - name: $name"

  if (( i > 0 )); then
    if [[ -n "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
      unset -f "${Z_PROJECT_SHORT_NAME[$i]}" &>/dev/null
    fi
    
    update_config_ $i "Z_PROJECT_SHORT_NAME" "$name"

    Z_PROJECT_SHORT_NAME[$i]="$name"
  else
    if [[ -n "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
      unset -f "$Z_CURRENT_PROJECT_SHORT_NAME" &>/dev/null
    fi

    Z_CURRENT_PROJECT_SHORT_NAME="$name"
  fi

  eval "
    function ${name}() {
      z_project_handler_ $i \"\$@\"
    }
  "

  SAVE_PRJ_NAME_TEMP=""
}

function save_prj_name_() {
  eval "$(parse_flags_ "save_prj_name_" "ae" "$@")"

  local i="$1"
  local name="${2:-${Z_PROJECT_SHORT_NAME[$i]}}"

  local typed_name=""

  typed_name=$(input_name_ "type your project short name" "$name" 10)
  clear_last_line_

  print_debug_ "save_prj_name_ index: $i - name: $name - typed_name: "$typed_name" - is_a: $save_prj_name_is_a - is_e: $save_prj_name_is_e"
  
  if [[ -n "$typed_name" ]]; then
    check_prj_name_ $i "$typed_name"
    if (( $? == 0 )); then
      # save the project name after all other answers
      SAVE_PRJ_NAME_TEMP="$typed_name"
      print "  project name: $typed_name" >&2
      return 0; # ok if it didn't save to config
    fi
  fi

  return 1;
}

function choose_mode_() {
  local name="${1:-it}"

  confirm_between_ "how do you prefer to manage $name: multiple or single mode?" "multiple" "single" $2
}

function save_prj_mode_() {
  eval "$(parse_flags_ "save_prj_mode_" "ae" "$@")"

  local i="$1"
  local name="${2:-${Z_PROJECT_SHORT_NAME[$i]}}"

  choose_mode_ "$name"
  RET=$?
  if (( RET == 130 )); then
    return 130;
  fi

  local single_mode="$RET"

  print_debug_ "save_prj_mode_ index: $i - name: $name - single_mode: $single_mode"

  if (( i > 0 )); then
    update_config_ $i "Z_PROJECT_SINGLE_MODE" "$single_mode"
    Z_PROJECT_SINGLE_MODE[$i]="$single_mode"
  else
    Z_CURRENT_PROJECT_SINGLE_MODE="$single_mode"
  fi
  
  if (( single_mode )); then
    print "  project mode: single" >&2
  else
    print "  project mode: multiple" >&2
  fi

  return 0;
}

function save_prj_folder_() {
  eval "$(parse_flags_ "save_prj_folder_" "arse" "$@")"

  local i="$1"
  local folder="${2:-$Z_PROJECT_FOLDER[$i]}"

  local repo="$Z_PROJECT_REPO[$i]"
  local single_mode="$Z_PROJECT_SINGLE_MODE[$i]"

  print_debug_ "save_prj_folder_ index: $i - folder: "$folder" - is_s: $save_prj_folder_is_s - is_r: $save_prj_folder_is_r"

  local chose_folder=""

  # local parent_folder="$(dirname "$folder")"

  local handle_folder_processing=0

  if [[ -n "$folder" ]]; then
    if (( ! save_prj_folder_is_r && ! save_prj_folder_is_s )); then
      confirm_from_ "use exiting project folder: "$'\e[94m'${folder}$'\e[0m'"?"
      RET=$?
      if (( RET == 130 )); then
        return 130;
      fi
      if (( RET == 0 )); then
        # if multiple mode, we need to process the folder
        if (( ! single_mode )); then
          if [[ -d "$folder" && -n "$(ls -A "$folder" 2>/dev/null)" ]]; then
            mv -f "$folder" "${folder}_$(date +"%Y%m%d%H%M%S")" &>/dev/null
            mkdir -p "$folder" &>/dev/null
          fi
          single_mode=1 # prevent processing again
        fi
        chose_folder="$folder"
      fi
    elif (( save_prj_folder_is_s )); then
      single_mode=1 # prevent processing again
      chose_folder="$folder"
    fi
  fi

  local header=""
  if (( single_mode )) && (( save_prj_folder_is_r || save_prj_folder_is_s )); then
    header="select the folder where your project was cloned"
  else
    handle_folder_processing=1
    header="choose a parent folder in which to git clone from (project will be a subfolder)"
  fi

  if [[ -z "$chose_folder" ]]; then
    chose_folder=$(choose_prj_folder_ $i "$header")
    #clear_last_line_
  fi

  print_debug_ "save_prj_folder_ chose_folder: $chose_folder"
  print_debug_ "save_prj_folder_ handle_folder_processing: $handle_folder_processing - single_mode: $single_mode"


  if [[ -n "$chose_folder" ]]; then
    local proj_folder="$chose_folder"

    if (( handle_folder_processing )); then
      proj_folder="${repo%.git}"
      proj_folder="${proj_folder##*[:/]}"
      proj_folder="${chose_folder}/${proj_folder}"
    fi

    proj_folder=$(get_prj_folder_ $i "$proj_folder")

    if [[ -n "$proj_folder" ]]; then
      if (( handle_folder_processing )); then
        if [[ -d "$proj_folder" && -n "$(ls -A "$proj_folder" 2>/dev/null)" ]]; then
          mv -f "$proj_folder" "${proj_folder}_$(date +"%Y%m%d%H%M%S")" &>/dev/null
          mkdir -p "$proj_folder" &>/dev/null
        fi
      fi

      if (( i > 0 )); then
        update_config_ $i "Z_PROJECT_FOLDER" "$proj_folder"
        Z_PROJECT_FOLDER[$i]="$proj_folder"
      else
        Z_CURRENT_PROJECT_FOLDER="$proj_folder"
      fi

      if (( ! save_prj_folder_is_s )); then
        if (( handle_folder_processing )); then
          print "  parent folder: $chose_folder" >&2
          print "  project folder: $proj_folder" >&2
        else
          print "  project folder: $proj_folder" >&2
        fi
      fi
      return 0; # ok if it didn't save to config
    fi
  fi

  return 1;
}

function save_prj_repo_() {
  eval "$(parse_flags_ "save_prj_repo_" "ae" "$@")"

  local i="$1"
  local repo="${2:-$Z_PROJECT_REPO[$i]}"
  local single_mode="${2:-$Z_PROJECT_SINGLE_MODE[$i]}"

  print_debug_ "save_prj_repo_ index: $i - repo: $repo - is_a: $save_prj_repo_is_a - is_e: $save_prj_repo_is_e"

  local typed_repo=""

  if [[ -n "$repo" ]]; then
    confirm_from_ "use repository uri: "$'\e[94m'${repo}$'\e[0m'"?"
    RET=$?
    if (( RET == 130 )); then
      return 130;
    fi
    if (( RET == 0 )); then
      typed_repo="$repo"
    fi
  fi

  if [[ -z "$typed_repo" ]] && (( single_mode )); then
    confirm_from_ "have you already cloned the project?"
    RET=$?
    if (( RET == 130 )); then
      return 130;
    fi
    if (( RET == 0 )); then # yes
      while true; do
        save_prj_folder_ -r $i
        if (( $? != 0 )); then return 1; fi
        local folder=""
        if (( i > 0 )); then
          folder=${Z_PROJECT_FOLDER[$i]}
        else
          folder=$Z_CURRENT_PROJECT_FOLDER
        fi
        typed_repo="$(cd "$folder" && git remote get-url origin 2>/dev/null)"
        # if (( $? != 0 )) || [[ -z "$typed_repo" ]]; then
        #   print "  not able to check for the repository uri" >&2
        # fi
        break;
      done
    fi
  fi

  if [[ -z "$typed_repo" ]]; then
    typed_repo=$(input_repo_ "the repository uri (ssh or https)" "$repo")
    clear_last_line_
  fi
  
  if [[ -n "$typed_repo" ]]; then
    get_prj_repo_ $i "$typed_repo" 1>/dev/null
    if (( $? == 0 )); then
      if (( i > 0 )); then
        update_config_ $i "Z_PROJECT_REPO" "$typed_repo"
        Z_PROJECT_REPO[$i]="$typed_repo"
      else
        Z_CURRENT_PROJECT_REPO="$typed_repo"
      fi
      print "  project repository: $typed_repo" >&2
      return 0; # ok if it didn't save to config
    fi
  fi

  return 1;
}

function save_pkg_manager_() {
  local i="$1"

  local choose_pkg=($(choose_one_ "choose package manager" 15 "npm" "yarn" "pnpm" "bun" "pip" "poetry" "poe"))

  if [[ -n "$choose_pkg" ]]; then
    check_prj_pkg_manager_ $i "$choose_pkg"
    if (( $? == 0 )); then
      if (( i > 0 )); then
        update_config_ $i "Z_PACKAGE_MANAGER" "$choose_pkg"
        Z_PACKAGE_MANAGER[$i]="$choose_pkg"
      else
        Z_CURRENT_PACKAGE_MANAGER="$choose_pkg"
      fi
      print "  package manager: $choose_pkg" >&2
      return 0;
    fi
  fi

  return 1;
}

function save_prj_() {
  eval "$(parse_flags_ "save_prj_" "ae" "$@")"

  local i="$1"

  if [[ -z "$i" || $i -lt 1 || $i -gt 9 ]]; then
    print " fatal: save_prj_ project index is invalid: $i"
    return 1;
  fi

  # local p="${i}th"

  # case $i in
  #   1) p="1st" ;;
  #   2) p="2nd" ;;
  #   3) p="3rd" ;;
  # esac

  if (( save_prj_is_e )); then
    help_line_ "editing project: $Z_PROJECT_SHORT_NAME[$i]" "${solid_magenta_cor}"
  else
    help_line_ "adding a new project" "${solid_magenta_cor}"
  fi

  save_prj_name_ $i "$2"
  if (( $? != 0 )); then
    return 1;
  fi

  save_prj_mode_ $i "$2"
  if (( $? != 0 )); then
    return 1;
  fi

  save_prj_repo_ $i
  if (( $? != 0 )); then
    return 1;
  fi

  save_prj_folder_ -s $i
  if (( $? != 0 )); then
    return 1;
  fi

  save_pkg_manager_ $i
  if (( $? != 0 )); then
    return 1;
  fi

  # now it's time to save the project name
  save_prj_name_really_ $i

  help_line_ "" "${solid_magenta_cor}"
  print "  project saved!" >&2
  print "  try running: ${yellow_cor}${Z_PROJECT_SHORT_NAME[$i]}${reset_cor}" >&2

  return 0;
}

# end of save project data to config file =========================================

unset_aliases_() {
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

  unset -f i &>/dev/null
  unset -f build &>/dev/null
  unset -f deploy &>/dev/null
  unset -f fix &>/dev/null
  unset -f format &>/dev/null
  unset -f ig &>/dev/null
  unset -f lint &>/dev/null
  unset -f rdev &>/dev/null
  unset -f tsc &>/dev/null
  unset -f sb &>/dev/null
  unset -f sbb &>/dev/null
  unset -f start &>/dev/null
}

set_aliases_() {
  check_prj_pkg_manager_ -s 0 "$Z_CURRENT_PACKAGE_MANAGER"
  if [[ -z "$Z_CURRENT_PACKAGE_MANAGER" ]]; then
    return 1;
  fi

  # Reset all aliases
  #unalias -a &>/dev/null
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
}

function remove_prj_() {
  i="$1"

  unset_aliases_
  unset -f "$proj_arg" &>/dev/null

  Z_PROJECT_SHORT_NAME[$i]=""
  Z_PROJECT_FOLDER[$i]=""
  Z_PROJECT_REPO[$i]=""
  Z_PROJECT_SINGLE_MODE[$i]=""
  Z_PACKAGE_MANAGER[$i]=""
  Z_CODE_EDITOR[$i]=""
  Z_CLONE[$i]=""
  Z_SETUP[$i]=""
  Z_RUN[$i]=""
  Z_RUN_STAGE[$i]=""
  Z_RUN_PROD[$i]=""
  Z_PRO[$i]=""
  Z_TEST[$i]=""
  Z_COV[$i]=""
  Z_TEST_WATCH[$i]=""
  Z_E2E[$i]=""
  Z_E2EUI[$i]=""
  Z_PR_TEMPLATE[$i]=""
  Z_PR_REPLACE[$i]=""
  Z_PR_APPEND[$i]=""
  Z_PR_RUN_TEST[$i]=""
  Z_GHA_INTERVAL[$i]=""
  Z_COMMIT_ADD[$i]=""
  Z_GHA_WORKFLOW[$i]=""
  Z_CURRENT_PUSH_ON_REFIX=""
  Z_DEFAULT_BRANCH[$i]=""
  Z_PRINT_README[$i]=""

  update_config_ $i "Z_PROJECT_SHORT_NAME" ""
  update_config_ $i "Z_PROJECT_FOLDER" "" >/dev/null
  update_config_ $i "Z_PROJECT_REPO" "" >/dev/null
  update_config_ $i "Z_PROJECT_SINGLE_MODE" "" >/dev/null
  update_config_ $i "Z_PACKAGE_MANAGER" "" >/dev/null
  update_config_ $i "Z_CODE_EDITOR" "" >/dev/null
  update_config_ $i "Z_CLONE" "" >/dev/null
  update_config_ $i "Z_SETUP" "" >/dev/null
  update_config_ $i "Z_RUN" "" >/dev/null
  update_config_ $i "Z_RUN_STAGE" "" >/dev/null
  update_config_ $i "Z_RUN_PROD" "" >/dev/null
  update_config_ $i "Z_PRO" "" >/dev/null
  update_config_ $i "Z_TEST" "" >/dev/null
  update_config_ $i "Z_COV" "" >/dev/null
  update_config_ $i "Z_TEST_WATCH" "" >/dev/null
  update_config_ $i "Z_E2E" "" >/dev/null
  update_config_ $i "Z_E2EUI" "" >/dev/null
  update_config_ $i "Z_PR_TEMPLATE" "" >/dev/null
  update_config_ $i "Z_PR_REPLACE" "" >/dev/null
  update_config_ $i "Z_PR_APPEND" "" >/dev/null
  update_config_ $i "Z_PR_RUN_TEST" "" >/dev/null
  update_config_ $i "Z_GHA_INTERVAL" "" >/dev/null
  update_config_ $i "Z_COMMIT_ADD" "" >/dev/null
  update_config_ $i "Z_GHA_WORKFLOW" "" >/dev/null
  update_config_ $i "Z_CURRENT_PUSH_ON_REFIX" "" >/dev/null
  update_config_ $i "Z_DEFAULT_BRANCH" "" >/dev/null
  update_config_ $i "Z_PRINT_README" "" >/dev/null
}

function save_current_proj_() {
  local i=$1

  Z_CURRENT_PROJECT_SHORT_NAME="${Z_PROJECT_SHORT_NAME[$i]}"
  Z_CURRENT_PROJECT_FOLDER="${Z_PROJECT_FOLDER[$i]}"
  Z_CURRENT_PROJECT_REPO="${Z_PROJECT_REPO[$i]}"
  Z_CURRENT_PROJECT_SINGLE_MODE="${Z_PROJECT_SINGLE_MODE[$i]}"
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
}

function clear_curr_prj_() {
  load_config_entry_
  
  save_current_proj_ 0
}

function get_prj_index_() {
  local proj_arg="$1"

  if [[ -z "$proj_arg" ]]; then
    return 1;
  fi

  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
      echo "$i"
      return 0;
    fi
  done

  return 1;
}

function is_project_() {
  local proj_arg="$1"

  get_prj_index_ "$proj_arg" >/dev/null
  if (( $? != 0 )); then return 1; fi
}

function print_current_proj() {
  local i="$1"

  print ""
  print " Z_PROJECT_SHORT_NAME_$i: ${Z_PROJECT_SHORT_NAME[$i]}"
  print " Z_PROJECT_FOLDER_$i: ${Z_PROJECT_FOLDER[$i]}"
  print " Z_PROJECT_REPO_$i: ${Z_PROJECT_REPO[$i]}"
  print " Z_PROJECT_MODE_$i: ${Z_PROJECT_SINGLE_MODE[$i]}"
  print " Z_PROJECT_SINGLE_MODE_$i: ${Z_PROJECT_SINGLE_SINGLE_MODE[$i]}"
  print " Z_PACKAGE_MANAGER_$i: ${Z_PACKAGE_MANAGER[$i]}"
  print " Z_RUN_$i: ${Z_RUN[$i]}"
  print " Z_RUN_STAGE_$i: ${Z_RUN_STAGE[$i]}"
  print " Z_RUN_PROD_$i: ${Z_RUN_PROD[$i]}"
  print " Z_COV_$i: ${Z_COV[$i]}"
  print " Z_E2E_$i: ${Z_E2E[$i]}"
  print " Z_E2EUI_$i: ${Z_E2EUI[$i]}"
  print " Z_TEST_$i: ${Z_TEST[$i]}"
  print " Z_TEST_WATCH_$i: ${Z_TEST_WATCH[$i]}"
  print " Z_SETUP_$i: ${Z_SETUP[$i]}"
  print " Z_CLONE_$i: ${Z_CLONE[$i]}"
  print " Z_PRO_$i: ${Z_PRO[$i]}"
  print ""
  print " Z_CURRENT_PROJECT_SHORT_NAME: $Z_CURRENT_PROJECT_SHORT_NAME"
  print " Z_CURRENT_PROJECT_FOLDER: $Z_CURRENT_PROJECT_FOLDER"
  print " Z_CURRENT_PROJECT_REPO: $Z_CURRENT_PROJECT_REPO"
  print " Z_CURRENT_PROJECT_SINGLE_MODE: $Z_CURRENT_PROJECT_SINGLE_MODE"
  print " Z_CURRENT_PACKAGE_MANAGER: $Z_CURRENT_PACKAGE_MANAGER"
  print " Z_CURRENT_RUN: $Z_CURRENT_RUN"
  print " Z_CURRENT_RUN_STAGE: $Z_CURRENT_RUN_STAGE"
  print " Z_CURRENT_RUN_PROD: $Z_CURRENT_RUN_PROD"
  print " Z_CURRENT_COV: $Z_CURRENT_COV"
  print " Z_CURRENT_E2E: $Z_CURRENT_E2E"
  print " Z_CURRENT_E2EUI: $Z_CURRENT_E2EUI"
  print " Z_CURRENT_TEST: $Z_CURRENT_TEST"
  print " Z_CURRENT_TEST_WATCH: $Z_CURRENT_TEST_WATCH"
  print " Z_CURRENT_SETUP: $Z_CURRENT_SETUP"
  print " Z_CURRENT_CLONE: $Z_CURRENT_CLONE"
  print " Z_CURRENT_PRO: $Z_CURRENT_PRO"
  print ""
}

function which_pro_index_pwd_() {
  local i=0
  for i in {1..9}; do
    if [[ -n "${Z_PROJECT_SHORT_NAME[$i]}" && -n "${Z_PROJECT_FOLDER[$i]}" ]]; then
      if [[ $(PWD) == $Z_PROJECT_FOLDER[$i]* ]]; then
        echo "$i"
        return 0;
      fi
    fi
  done

  echo "0"
  return 1;
}

function which_pro_pwd_() {
  local i=0
  for i in {1..9}; do
    if [[ -n "${Z_PROJECT_SHORT_NAME[$i]}" && -n "${Z_PROJECT_FOLDER[$i]}" ]]; then
      if [[ $(PWD) == $Z_PROJECT_FOLDER[$i]* ]]; then
        echo "${Z_PROJECT_SHORT_NAME[$i]}"
        return 0;
      fi
    fi
  done

  # Cannot determine project based on pwd
  return 1;
}

function check_any_pkg_() {
  check_any_pkg_silent_ "$1"
  if (( $? != 0 )); then
    print " not a project folder: ${1:-$PWD}" >&2
    return 1;
  fi

  return 0;
}

function check_pkg_() {
  check_pkg_silent_ "$1"
  if (( $? != 0 )); then
    print " not a project folder: ${1:-$PWD}" >&2
    return 1;
  fi

  return 0;
}

function check_any_pkg_silent_() {
  local folder="${1:-$PWD}"

  if [[ -n "$folder" && -d "$folder" ]]; then
    if [[ -f "$folder/package.json" || -f "$folder/pyproject.toml" || -d "$folder/.git" ]]; then
      return 0;
    fi

    while [[ "$folder" != "/" ]]; do
      if [[ -f "$folder/package.json" || -f "$folder/pyproject.toml" || -d "$folder/.git" ]]; then
        return 0;
      fi
      folder="$(dirname "$folder")"
    done
  fi

  return 1;
}

function check_pkg_silent_() {
  local folder="${1:-$PWD}"

  if [[ -n "$folder" && -d "$folder" ]]; then
    if [[ -f "$folder/package.json" ]]; then
      return 0;
    fi

    while [[ "$folder" != "/" ]]; do
      if [[ -f "$folder/package.json" ]]; then
        return 0;
      fi
      folder="$(dirname "$folder")"
    done
  fi

  return 1;
}

function is_git_repo_() {
  local folder="${1:-$PWD}"

  if [[ ! -d "$folder" ]]; then
    return 1;
  fi

  if [[ -d "$folder/.git" ]]; then
    return 0;
  fi

  ( git -C "$folder" rev-parse --is-inside-work-tree &>/dev/null )
}

function check_git_() {
  if is_git_repo_ "$1"; then
    return 0;
  fi

  print " not a git repository (or any of the parent directories): ${1:-$PWD}" >&2 
  return 1;
}

function get_default_folder_() {
  local proj_folder="${1:-$PWD}"
  local folder=$(get_prj_for_git_ "$proj_folder")

  if [[ -z "$folder" ]]; then
    return 1;
  fi

  local _pwd=$(pwd)
  cd "$folder"
  local default_folder=$(git config --get init.defaultBranch)
  cd "$_pwd"

  if is_git_repo_ "$proj_folder/$default_folder"; then    
    echo "$proj_folder/$default_folder"
  else
    echo "$folder"
  fi
}

function is_project_single_mode_() {
  local i=$1

  local proj_folder=""
  local single_mode=""

  if (( i > 0 )); then
    proj_folder="${Z_PROJECT_FOLDER[$i]}"
    single_mode="${Z_PROJECT_SINGLE_MODE[$i]}"
  else
    proj_folder="$Z_CURRENT_PROJECT_FOLDER"
    single_mode="$Z_CURRENT_PROJECT_SINGLE_MODE"
  fi

  print_debug_ "is_project_single_mode_ index: $i - proj_folder: $proj_folder - single_mode: $single_mode"

  if [[ -n "$proj_folder" && -d "$proj_folder" ]]; then
    if is_git_repo_ "$proj_folder" || [[ -f "$proj_folder/package.json" || -f "$proj_folder/pyproject.toml" ]]; then
      echo 1;
      return 0;
    fi
  fi

  if (( single_mode )); then
    echo 1;
    return 0;
  fi

  echo 0;
}

function pro() {
  eval "$(parse_flags_ "pro_" "aerupf" "$@")"

  if (( pro_is_h )); then
    print "${yellow_cor} pro <pro>${reset_cor} : to set a project"
    print "${yellow_cor} pro -a <pro>${reset_cor} : to add a new project"
    print "${yellow_cor} pro -e <pro>${reset_cor} : to edit a project"
    print "${yellow_cor} pro -r <pro>${reset_cor} : to remove a project"
    print "${yellow_cor} pro -u <pro>${reset_cor} : to unset project"
    print "${yellow_cor} pro -p <pro>${reset_cor} : to print project info"
    if [[ -n "${Z_PROJECT_SHORT_NAME[*]}" ]]; then
      print ""
      print -n " projects: ${blue_cor} "
      local i=0
      for i in {1..9}; do
        if [[ -n "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
          print -n "${Z_PROJECT_SHORT_NAME[$i]}"
          local j=$(( i + 1 ))
          if [[ -n "${Z_PROJECT_SHORT_NAME[$j]}" ]]; then
            print -n ", "
          fi
        fi
      done
      print "${reset_cor}"
    fi
    return 0;
  fi

  local proj_arg="$1"

  if (( pro_is_p )); then
    # print project
    if [[ -z "$proj_arg" ]]; then
      print " please provide a project name to print" >&2
      print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        print_current_proj $i
        return 0;
      fi
    done

    print " project not found: $proj_arg" >&2
    print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
    return 1;
  fi

  # CRUD operations
  if (( pro_is_e )); then
    # edit project
    if [[ -z "$proj_arg" ]]; then
      print " please provide a project name to edit" >&2
      print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        save_prj_ -e $i $proj_arg
        return 0;
      fi
    done
    
    print " project not found: $proj_arg" >&2
    print " ${yellow_cor} pro -a $proj_arg${reset_cor} to add project" >&2
    return 1;
  fi
  
  if (( pro_is_a )); then
    # add project
    local i=0
    for i in {1..9}; do
      if [[ -z "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        save_prj_ -a $i $proj_arg

        return 0;
      fi
    done

    print " no more slots available, please remove one to add a new one" >&2
    print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
    
    return 1;
  fi

  if (( pro_is_r )); then
    # remove project
    if [[ -z "$proj_arg" ]]; then
      print " please provide a project name to delete" >&2
      print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        remove_prj_ $i
        if (( $? == 0 )); then
          print " project deleted: $proj_arg"
        fi
        
        if [[ "$proj_arg" == "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
          clear_curr_prj_
          activate_pro_
        fi
        return 0;
      fi
    done

    print " project not found: $proj_arg" >&2
    print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
    return 1;
  fi # end of delete

  if (( pro_is_u )); then
    # unset project
    if [[ -z "$proj_arg" ]]; then
      print " please provide a project name to unset" >&2
      print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        # unset aliases
        clear_curr_prj_
        return 0;
      fi
    done

    print " project not found: $proj_arg" >&2
    print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if [[ -z "$proj_arg" ]]; then
    pro -h
    return 0;
  fi

  if [[ "$proj_arg" == "pwd" ]]; then
    proj_arg=$(which_pro_pwd_); print_debug_ "which_pro_pwd_: $proj_arg"
    
    if [[ -z "$proj_arg" ]]; then
      return 1;
    fi
  fi

  print_debug_ "pro proj_arg: $proj_arg"

  local found=0
  # Check if the project name matches one of the configured projects
  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
      found=$i
      break;
    fi
  done

  if (( ! found )); then
    print " project not found: $proj_arg" >&2
    print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( ! pro_is_f && ! pro_is_d )); then
    check_prj_ -s $found
  fi
  if (( $? != 0 )); then
    return 1;
  fi

  local is_refresh=1

  if [[ "$proj_arg" == "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
    is_refresh=0
  fi

  print_debug_ "project found $i: $proj_arg"

  # set the current project
  save_current_proj_ $i

  (( is_d )) && print_current_proj $i

  if (( is_refresh )); then
    print " project set to: ${solid_blue_cor}$Z_CURRENT_PROJECT_SHORT_NAME${reset_cor} with ${solid_magenta_cor}$Z_CURRENT_PACKAGE_MANAGER${reset_cor}"

    echo "$Z_CURRENT_PROJECT_SHORT_NAME" > "$PUMP_PRO_FILE"
    
    export Z_CURRENT_PROJECT_SHORT_NAME="$Z_CURRENT_PROJECT_SHORT_NAME"

    if [[ -n "$Z_CURRENT_PRO" ]]; then
      eval "$Z_CURRENT_PRO"
    fi

    unset_aliases_
    set_aliases_
  fi

  return 0;
}

function refix() {
  eval "$(parse_flags_ "refix_" "" "$@")"

  if (( refix_is_h )); then
    print "${yellow_cor} refix${reset_cor} : to reset last commit then run fix then re-push"
    return 0;
  fi

  check_pkg_; if (( $? != 0 )); then return 1; fi
  check_git_; if (( $? != 0 )); then return 1; fi

  last_commit_msg=$(git log -1 --pretty=format:'%s' | xargs -0)
  
  if [[ "$last_commit_msg" == Merge* ]]; then
    print " last commit is a merge commit, please rebase instead" >&2 
    return 1;
  fi

  git reset --soft HEAD~1 >/dev/null
  if (( $? != 0 )); then return 1; fi

  unsetopt monitor
  unsetopt notify

  pipe_name=$(mktemp -u)
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title "refixing \"$last_commit_msg\"..." -- sh -c "read < $pipe_name" &
  spin_pid=$!

  $Z_CURRENT_PACKAGE_MANAGER run format &>/dev/null
  $Z_CURRENT_PACKAGE_MANAGER run lint &>/dev/null
  $Z_CURRENT_PACKAGE_MANAGER run format &>/dev/null

  print "   refixing \"$last_commit_msg\"..."

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

  if confirm_from_ "fix done, push now?"; then
    if confirm_from_ "save this preference and don't ask again?"; then
      local i=0
      for i in {1..9}; do
        if [[ "$Z_CURRENT_PROJECT_SHORT_NAME" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
          update_config_ $i "Z_PUSH_ON_REFIX" 1
          Z_CURRENT_PUSH_ON_REFIX=1
          break
        fi
      done
    fi
  else
    return 0;
  fi

  pushf "$@"
}

function covc() {
  eval "$(parse_flags_ "covc_" "" "$@")"

  if (( covc_is_h )); then
    print "${yellow_cor} covc <branch>${reset_cor} : to compare test coverage with another branch of the same project"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " covc requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi

  check_pkg_; if (( $? != 0 )); then return 1; fi
  check_git_; if (( $? != 0 )); then return 1; fi

  # local git_status=$(git status --porcelain)
  # if [[ -n "$git_status" ]]; then
  #   print " branch is not clean, cannot switch branches";
  #   return 1;
  # fi

  local proj_name="$Z_CURRENT_PROJECT_SHORT_NAME"
  local proj_folder="$Z_CURRENT_PROJECT_FOLDER"
  local _setup="$Z_CURRENT_SETUP"
  local _clone="$Z_CURRENT_CLONE"
  local _cov="$Z_CURRENT_COV"

  if [[ -z "$_cov" || -z "$_setup" ]]; then
    print " Z_COV or Z_SETUP is missing for ${blue_cor}${proj_name}${reset_cor} - edit your pump.zshenv then run${yellow_cor} refresh ${reset_cor}" >&2
    return 1;
  fi

  print_debug_ "covc proj_folder: i: $i - proj_folder: $proj_folder proj_name: $proj_name"

  local branch="$1"

  if [[ -z "$branch" ]]; then
    covc -h
    return 0;
  fi

  local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

  if [[ "$branch" == "$my_branch" ]]; then
    print " trying to compare with the same branch"; >&2
    return 1;
  fi

  # default_branch=$(git config --get init.defaultBranch);
  # if [[ -n "$default_branch" ]]; then
  #   git fetch origin $default_branch --quiet
  #   read behind ahead < <(git rev-list --left-right --count origin/$default_branch...HEAD)
  #   if [[ $behind -ne 0 || $ahead -ne 0 ]]; then
  #     print " warning: your branch is behind $default_branch by $behind commits and ahead by $ahead commits";
  #   fi
  # fi

  local is_single_mode=$(is_project_single_mode_ 0)

  if (( is_single_mode )); then
    cov_folder=".$proj_folder-coverage"
  else
    cov_folder="$proj_folder/.coverage"
  fi

  RET=1

  if is_git_repo_ "$cov_folder"; then
    pushd "$cov_folder" &>/dev/null

    git reset --hard --quiet origin
    git fetch origin --quiet
    git switch "$branch" --quiet &>/dev/null
    RET=$?
  else
    local proj_repo="$(get_prj_repo_ $i "$Z_PROJECT_REPO[$i]")"
    if [[ -z "$proj_repo" ]]; then
      return 1;
    fi

    rm -rf "$cov_folder" &>/dev/null
    
    gum spin --title "running test coverage on $branch..." -- git clone $proj_repo "$cov_folder" --quiet
    if (( $? == 0 )); then
      pushd "$cov_folder" &>/dev/null

      if [[ -n "$_clone" ]]; then
        eval "$_clone" &>/dev/null
      fi

      git switch "$branch" --quiet &>/dev/null
      RET=$?
    else
      RET=1
    fi
  fi

  if (( RET == 0 )); then
    git pull origin --quiet
    RET=$?
  fi

  if (( RET != 0 )); then
    print " did not match any branch known to git: $branch" >&2

    return 1;
  fi

  unsetopt monitor
  unsetopt notify

  pipe_name=$(mktemp -u)
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title "running test coverage on $branch..." -- sh -c "read < $pipe_name" &
  spin_pid=$!

  eval "$_setup" &>/dev/null

  is_delete_cov_folder=0;

  if [[ ! -d "coverage" ]]; then
    is_delete_cov_folder=1;
    mkdir -p coverage &>/dev/null
  fi

  eval "$_cov" --coverageReporters=text-summary > "coverage/coverage-summary.$branch.txt" 2>&1
  if (( $? != 0 )); then
    eval "$_cov" --coverageReporters=text-summary > "coverage/coverage-summary.$branch.txt" 2>&1
  fi

  echo "   running test coverage on $branch..."

  echo "done" > "$pipe_name" &>/dev/null
  # kill $spin_pid &>/dev/null
  rm "$pipe_name"
  wait $spin_pid &>/dev/null

  summary1=$(grep -A 4 "Coverage summary" "coverage/coverage-summary.$branch.txt")

  # Extract each coverage percentage
  statements1=$(echo "$summary1" | grep "Statements" | awk '{print $3}' | tr -d '%')
  branches1=$(echo "$summary1" | grep "Branches" | awk '{print $3}' | tr -d '%')
  funcs1=$(echo "$summary1" | grep "Functions" | awk '{print $3}' | tr -d '%')
  lines1=$(echo "$summary1" | grep "Lines" | awk '{print $3}' | tr -d '%')

  if (( is_delete_cov_folder )); then
    rm -rf "coverage" &>/dev/null
  else
    rm -f "coverage/coverage-summary.$branch.txt" &>/dev/null
    rm -f "coverage/coverage-summary.$my_branch.txt" &>/dev/null
  fi

  popd &>/dev/null

  is_delete_cov_folder=0;

  if [[ ! -d "coverage" ]]; then
    is_delete_cov_folder=1;
    mkdir -p coverage &>/dev/null
  fi

  git switch "$my_branch" --quiet
  if (( $? != 0 )); then
    print " did not match any branch known to git: $branch" >&2
    return 1;
  fi

  pipe_name=$(mktemp -u)
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title "running test coverage on $my_branch..." -- sh -c "read < $pipe_name" &
  spin_pid=$!

  eval "$_cov" --coverageReporters=text-summary > "coverage/coverage-summary.$my_branch.txt" 2>&1
  if (( $? != 0 )); then
    eval "$_cov" --coverageReporters=text-summary > "coverage/coverage-summary.$my_branch.txt" 2>&1
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

  # print "\033[32m on $branch\033[0m"
  # print "$summary1"
  # print "\033[32m on $my_branch\033[0m"
  # print "$summary2"

  # # Print the extracted values
  print ""
  help_line_ "coverage" "${gray_cor}" 67
  help_line_ "${1:0:22}" "${gray_cor}" 32 "${my_branch:0:22}" 32
  print ""

  color=$(if [[ $statements1 -gt $statements2 ]]; then echo "${red_cor}"; elif [[ $statements1 -lt $statements2 ]]; then echo "${green_cor}"; else echo ""; fi)
  print " Statements\t\t: $(printf "%.2f" $statements1)%  |${color} Statements\t\t: $(printf "%.2f" $statements2)% ${reset_cor}"
  
  color=$(if [[ $branches1 -gt $branches2 ]]; then echo "${red_cor}"; elif [[ $branches1 -lt $branches2 ]]; then echo "${green_cor}"; else echo ""; fi)
  print " Branches\t\t: $(printf "%.2f" $branches1)%  |${color} Branches\t\t: $(printf "%.2f" $branches2)% ${reset_cor}"
  
  color=$(if [[ $funcs1 -gt $funcs2 ]]; then echo "${red_cor}"; elif [[ $funcs1 -lt $funcs2 ]]; then echo "${green_cor}"; else echo ""; fi)
  print " Functions\t\t: $(printf "%.2f" $funcs1)%  |${color} Functions\t\t: $(printf "%.2f" $funcs2)% ${reset_cor}"
  
  color=$(if [[ $lines1 -gt $lines2 ]]; then echo "${red_cor}"; elif [[ $lines1 -lt $lines2 ]]; then echo "${green_cor}"; else echo ""; fi)
  print " Lines\t\t\t: $(printf "%.2f" $lines1)%  |${color} Lines\t\t: $(printf "%.2f" $lines2)% ${reset_cor}"
  print ""

  if (( is_delete_cov_folder )); then
    rm -rf "coverage" &>/dev/null
  else
    rm -f "coverage/coverage-summary.$branch.txt" &>/dev/null
    rm -f "coverage/coverage-summary.$my_branch.txt" &>/dev/null
  fi

  print ""
  print "#### Coverage"
  print "| \`$1\` | \`${my_branch}\` |"
  print "| --- | --- |"
  print "| Statements: $(printf "%.2f" $statements1)% | Statements: $(printf "%.2f" $statements2)% |"
  print "| Branches: $(printf "%.2f" $branches1)% | Branches: $(printf "%.2f" $branches2)% |"
  print "| Functions: $(printf "%.2f" $funcs1)% | Functions: $(printf "%.2f" $funcs2)% |"
  print "| Lines: $(printf "%.2f" $lines1)% | Lines: $(printf "%.2f" $lines2)% |"
  print ""

  setopt monitor
  setopt notify
}

function test() {
  eval "$(parse_flags_ "test_" "" "$@")"

  if (( test_is_h )); then
    print "${yellow_cor} test${reset_cor} : to run Z_TEST"
    return 0;
  fi

  check_pkg_; if (( $? != 0 )); then return 1; fi

  eval "$Z_CURRENT_TEST" "$@"
  if (( $? != 0 )); then
    eval "$Z_CURRENT_TEST" "$@"
    if (( $? != 0 )); then
      print "\033[31m ❌ test failed\033[0m"
    else
      print "\033[32m ✅ test passed on second run\033[0m"
    fi
  else
    print "\033[32m ✅ test passed on first run\033[0m"
  fi
}

function cov() {
  eval "$(parse_flags_ "cov_" "" "$@")"

  if (( cov_is_h )); then
    print "${yellow_cor} cov${reset_cor} : to run Z_COV"
    print "${yellow_cor} cov <branch>${reset_cor} : to compare test coverage with another branch of the same project"
    return 0;
  fi

  check_pkg_; if (( $? != 0 )); then return 1; fi

  if [[ -n "$1" && $1 != -* ]]; then
    covc "$@"
    return $?;
  fi

  # check if folder is within project folder 

  if [[ -z "$Z_CURRENT_COV" ]]; then
    print " Z_COV is not set for${blue_cor} $Z_CURRENT_PROJECT_SHORT_NAME${reset_cor} - edit your pump.zshenv then run${yellow_cor} refresh ${reset_cor}"
    return 1;
  fi
  
  eval "$Z_CURRENT_COV" "$@"
  if (( $? != 0 )); then
    eval "$Z_CURRENT_COV" "$@"
    if (( $? != 0 )); then
      print "\033[31m ❌ test coverage failed\033[0m"
    else
      print "\033[32m ✅ test coverage passed on second run\033[0m"
    fi
  else
    print "\033[32m ✅ test coverage passed on first run\033[0m"
  fi
}

function testw() {
  eval "$(parse_flags_ "testw_" "" "$@")"

  if (( testw_is_h )); then
    print "${yellow_cor} testw${reset_cor} : to run Z_TEST_WATCH"
    return 0;
  fi

  check_pkg_; if (( $? != 0 )); then return 1; fi

  eval "$Z_CURRENT_TEST_WATCH" "$@"
}

function e2e() {
  eval "$(parse_flags_ "e2e_" "" "$@")"

  if (( e2e_is_h )); then
    print "${yellow_cor} e2e${reset_cor} : to run Z_E2E"
    print "${yellow_cor} e2e <e2e_project>${reset_cor} : to run Z_E2E --project <e2e_project>"
    return 0;
  fi

  check_pkg_; if (( $? != 0 )); then return 1; fi

  if [[ -z "$1" ]]; then
    eval "$Z_CURRENT_E2E"
  else
    eval "$Z_CURRENT_E2E" --project="$1" "${@:2}"
  fi
}

function e2eui() {
  eval "$(parse_flags_ "e2eui_" "" "$@")"

  if (( e2eui_is_h )); then
    print "${yellow_cor} e2eui${reset_cor} : to run Z_E2EUI"
    print "${yellow_cor} e2eui ${solid_yellow_cor}<project>${reset_cor} : to run Z_E2EUI --project"
    return 0;
  fi

  check_pkg_; if (( $? != 0 )); then return 1; fi

  if [[ -z "$1" ]]; then
    eval "$Z_CURRENT_E2EUI"
  else
    eval "$Z_CURRENT_E2EUI" --project="$1" "${@:2}"
  fi
}

function add() {
  eval "$(parse_flags_ "add_" "" "$@")"

  if (( add_is_h )); then
    print "${yellow_cor} add${reset_cor} : to add all files to index"
    print "${yellow_cor} add <glob>${reset_cor} : to add files to index"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  if [[ -z "$1" ]]; then
    git add . "$@"
  else
    git add "$@"
  fi
}

# Creating PRs =============================================================
function pr() {
  eval "$(parse_flags_ "pr_" "t" "$@")"

  if (( pr_is_h )); then
    print "${yellow_cor} pr${reset_cor} : to create a pull request"
    print "${yellow_cor} pr -t${reset_cor} : only if tests pass"
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " pr requires gh" >&2
    print " install gh:${blue_cor} https://github.com/cli/cli ${reset_cor}" >&2
    return 1;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  # Initialize an empty string to store the commit details
  local commit_msgs=""
  local pr_title=""

  # Get the current branch name
  # HEAD_COMMIT=$(git merge-base f-WMG1-247-performanceView HEAD)
  # my_branch=$(git branch --show-current)
  # OPTIONS="--abbrev-commit HEAD"

   git log $(git merge-base HEAD $(git config --get init.defaultBranch))..HEAD --no-merges --oneline --pretty=format:'%H | %s' | xargs -0 | while IFS= read -r line; do
    local commit_hash=$(echo "$line" | cut -d'|' -f1 | xargs)
    local commit_message=$(echo "$line" | cut -d'|' -f2- | xargs -0)

    # # Check if the commit belongs to the current branch
    # if ! git branch --contains "$commit_hash" | grep -q "\b$my_branch\b"; then
    #   break;
    # fi

    local dirty_pr_title="$commit_message"
    local pattern='.*\b(fix|feat|docs|refactor|test|chore|style|revert)(\s*\([^)]*\))?:\s*'
    if [[ "$dirty_pr_title" =~ $pattern ]]; then
      pr_title="${dirty_pr_title/${match[0]}/}"
    else
      pr_title="$dirty_pr_title"
    fi

    pr_title="$dirty_pr_title"

    if [[ $dirty_pr_title =~ ([[:alnum:]]+-[[:digit:]]+) ]]; then
      local ticket="${match[1]}"

      local trimmed="${ticket#"${str%%[![:space:]]*}"}"
      trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"

      pr_title="$trimmed"
      
      if [[ $dirty_pr_title =~ [[:alnum:]]+-[[:digit:]]+(.*) ]]; then
        local rest="${match[1]}"
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
    print " no commits found, try${yellow_cor} push${reset_cor} first.";
    return 0;
  fi

  local pr_body="$commit_msgs"

  if [[ -f "$Z_CURRENT_PR_TEMPLATE" && -n "$Z_CURRENT_PR_REPLACE" ]]; then
    local pr_template=$(cat $Z_CURRENT_PR_TEMPLATE)

    if [[ $Z_CURRENT_PR_APPEND -eq 1 ]]; then
      # Append commit msgs right after Z_CURRENT_PR_REPLACE in pr template
      pr_body=$(echo "$pr_template" | perl -pe "s/(\Q$Z_CURRENT_PR_REPLACE\E)/\1\n\n$commit_msgs\n/")
    else
      # Replace Z_CURRENT_PR_REPLACE with commit msgs in pr template
      pr_body=$(echo "$pr_template" | perl -pe "s/\Q$Z_CURRENT_PR_REPLACE\E/$commit_msgs/g")
    fi
  fi

  if [[ -z "$Z_CURRENT_PR_RUN_TEST" ]]; then
    if confirm_from_ "run tests before a pull request?"; then
      test
      if (( $? != 0 )); then
        print "${solid_red_cor} tests are not passing,${reset_cor} did not push" >&2
        return 1;
      fi

      if confirm_from_ "save this preference and don't ask again?"; then
        local i=0
        for i in {1..9}; do
          if [[ "$Z_CURRENT_PROJECT_SHORT_NAME" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
            update_config_ $i "Z_PR_RUN_TEST" 1
            Z_CURRENT_PR_RUN_TEST=1
            break
          fi
        done
        print ""
      fi
    fi
  elif (( $Z_CURRENT_PR_RUN_TEST || pr_is_t )); then
    local git_status=$(git status --porcelain)
    if [[ -n "$git_status" ]]; then
      if ! confirm_from_ "skip test?"; then
        return 0;
      fi
    else
      test
      if (( $? != 0 )); then
        print "${solid_red_cor} tests are not passing,${reset_cor} did not push" >&2
        return 1;
      fi
    fi
  fi

  ## debugging purposes
  # print " pr_title:$pr_title"
  # print ""
  # print "$pr_body"
  # return 0;

  push $2

  local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

  if [[ -n "$Z_CURRENT_PROJECT_REPO" ]]; then
    if [[ -z "$Z_CURRENT_LABEL_PR" || "$Z_CURRENT_LABEL_PR" -eq 0 ]]; then
      local labels=("none" "${(@f)$(gh label list --repo "$Z_CURRENT_PROJECT_REPO" --limit 25 | awk '{print $1}')}")
      local choose_labels=$(choose_multiple_ "choose labels" "${labels[@]}")
      if [[ -z "$choose_labels" ]]; then
        return 1;
      fi

      if [[ "$choose_labels" == "none" ]]; then
        gh pr create -a="@me" --title="$pr_title" --body="$pr_body" --web --head="$my_branch"
      else
        local choose_labels_comma="${(j:,:)${(f)choose_labels}}"
        gh pr create -a="@me" --title="$pr_title" --body="$pr_body" --web --head="$my_branch" --label="$choose_labels_comma"
      fi
      return 0;
    fi
  fi

  gh pr create -a="@me" --title="$pr_title" --body="$pr_body" --web --head="$my_branch"
}

function run() {
  eval "$(parse_flags_ "run_" "" "$@")"

  if (( run_is_h )); then
    print "${yellow_cor} run${reset_cor} : to run dev in current folder"
    print " --"
    print "${yellow_cor} run dev${reset_cor} : to run dev in current folder"
    print "${yellow_cor} run stage${reset_cor} : to run stage in current folder"
    print "${yellow_cor} run prod${reset_cor} : to run prod in current folder"
    print " --"
    if [[ -n "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
      print "${yellow_cor} run <folder>${reset_cor} : to run a folder on dev environment for $Z_CURRENT_PROJECT_SHORT_NAME"
      print "${yellow_cor} run${solid_yellow_cor} [<folder>] [<env>]${reset_cor} : to run a folder on environment for $Z_CURRENT_PROJECT_SHORT_NAME"
      print " --"
    fi
    print "${yellow_cor} run <pro>${solid_yellow_cor} [<folder>] [<env>]${reset_cor} : to run a folder on environment for a project"
    return 0;
  fi

  local proj_arg=""
  local folder_arg=""
  local _env="dev"

  if [[ -n "$3" ]]; then
    proj_arg="$1"
    _env="$3"
    folder_arg="$2"
  elif [[ -n "$2" ]]; then
    local i=$(get_prj_index_ $1)
    if [[ -n $i ]]; then
      proj_arg="${1:-$Z_CURRENT_PROJECT_SHORT_NAME}"
      if [[ "$2" == "dev" || "$2" == "stage" || "$2" == "prod" ]]; then
        local single_mode=$(is_project_single_mode_ $i)

        if (( single_mode )); then
          _env="$2";
        else
          folder_arg="$2";
        fi
      else
        folder_arg="$2"
      fi
    else
      folder_arg="$1"
      _env="$2"
    fi
  elif [[ -n "$1" ]]; then
    if is_project_ $1; then
      proj_arg="$1"
    elif [[ "$1" == "dev" || "$1" == "stage" || "$1" == "prod" ]]; then
      _env="$1"
    else
      folder_arg="$1"
    fi
  fi

  # Validate environment
  if [[ "$_env" != "dev" && "$_env" != "stage" && "$_env" != "prod" ]]; then
    print " env is incorrect, valid options: dev, stage or prod" >&2
    print " ${yellow_cor} run -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local proj_folder=""
  local _run="$Z_CURRENT_RUN"

  if [[ "$_env" == "stage" ]]; then
    _run="$Z_CURRENT_RUN_STAGE"
  elif [[ "$_env" == "prod" ]]; then
    _run="$Z_CURRENT_RUN_PROD"
  fi

  if [[ -n "$proj_arg" ]]; then
    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        proj_folder=$(get_prj_folder_ -s $i "$Z_PROJECT_FOLDER[$i]")
        if [ -z "$proj_folder" ]; then return 1; fi

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
    print " no Z_RUN for${solid_blue_cor} $proj_arg${reset_cor} - edit your pump.zshenv config then run${yellow_cor} refresh ${reset_cor}" >&2
    return 1;
  fi

  local folder_to_run=""

  if [[ -n "$folder_arg" && -n "$proj_folder" ]]; then
    check_any_pkg_ "$proj_folder/$folder_arg"
    if (( $? != 0 )); then return 1; fi
    folder_to_run="$proj_folder/$folder_arg"
  elif [[ -n "$proj_folder" ]]; then
    # check if proj_folder is a project
    check_any_pkg_silent_ "$proj_folder"
    if (( $? == 0 )); then
      folder_to_run="$proj_folder"
    else
      if [[ -n ${(f)"$(get_folders_ "$proj_folder")"} ]]; then
        local folders=($(get_folders_ "$proj_folder"))
        folder_to_run=($(choose_auto_one_ "choose folder to run" "${folders[@]}"))
        if [[ -z "$folder_to_run" ]]; then
          return 0;
        fi
      fi
    fi
  elif [[ -n "$folder_arg" ]]; then
    check_any_pkg_ "$folder_arg"
    if (( $? != 0 )); then return 1; fi
    folder_to_run="$folder_arg"
  else
    check_any_pkg_;
    if (( $? != 0 )); then return 1; fi
    folder_to_run="."
  fi

  # debugging
  # print "proj_arg=$proj_arg"
  # print "folder_arg=$folder_arg"
  # print "_env=$_env"
  # print "folder_to_run=$folder_to_run"
  # print " --------"

  pushd "$folder_to_run" &>/dev/null

  print " run $_env on ${gray_cor}$(shorten_path_ "$folder_arg") ${reset_cor}:${pink_cor} $_run ${reset_cor}"
  eval "$_run"
}

function setup() {
  eval "$(parse_flags_ "setup_" "" "$@")"

  if (( setup_is_h )); then
      print "${yellow_cor} setup${reset_cor} : to setup current folder"
      if [[ -n "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
        print "${yellow_cor} setup <folder>${reset_cor} : to setup a folder for $Z_CURRENT_PROJECT_SHORT_NAME"
      fi
      print " --"
    print "${yellow_cor} setup <pro>${solid_yellow_cor} [<folder>]${reset_cor} : to setup a folder for a project"
    return 0;
  fi

  local proj_arg=""
  local folder_arg=""

  if [[ -n "$2" ]]; then
    proj_arg="$1"
    folder_arg="$2"
  elif [[ -n "$1" ]]; then
    if is_project_ $1; then
      proj_arg="$1"
    else
      folder_arg="$1"
    fi
  fi

  local proj_folder="";
  local _setup=${Z_CURRENT_SETUP:-$Z_CURRENT_PACKAGE_MANAGER $([[ $Z_CURRENT_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")setup}

  if [[ -n "$proj_arg" ]]; then
    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        proj_folder=$(get_prj_folder_ -s $i "$Z_PROJECT_FOLDER[$i]")
        if [ -z "$proj_folder" ]; then return 1; fi

        _setup="${Z_SETUP[$i]:-${Z_PACKAGE_MANAGER[$i]} $([[ ${Z_PACKAGE_MANAGER[$i]} == "yarn" ]] && echo "" || echo "run ")setup}"
        break
      fi
    done

    if [[ -z "$proj_folder" ]]; then
      print " not a valid project: $proj_arg" >&2
      print " ${yellow_cor} setup -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  if [[ -z "$_setup" ]]; then
    print " no Z_SETUP for${solid_blue_cor} $proj_arg${reset_cor} - edit your pump.zshenv config then run${yellow_cor} refresh ${reset_cor}" >&2
    return 1;
  fi

  local folder_to_setup=""

  if [[ -n "$folder_arg" && -n "$proj_folder" ]]; then
    check_any_pkg_ "$proj_folder/$folder_arg"
    if (( $? != 0 )); then return 1; fi
    folder_to_setup="$proj_folder/$folder_arg"
  elif [[ -n "$proj_folder" ]]; then
    # check if proj_folder is a project
    check_any_pkg_silent_ "$proj_folder"
    if (( $? == 0 )); then
      folder_to_setup="$proj_folder"
    else
      if [[ -n ${(f)"$(get_folders_ "$proj_folder")"} ]]; then
        folders=($(get_folders_ "$proj_folder"))
        folder_to_setup=($(choose_auto_one_ "choose folder to setup" "${folders[@]}"))
        if [[ -z "$folder_to_setup" ]]; then
          return 0;
        fi
      fi
    fi
  elif [[ -n "$folder_arg" ]]; then
    check_any_pkg_ "$folder_arg"
    if (( $? != 0 )); then return 1; fi
    folder_to_setup="$folder_arg"
  else
    check_any_pkg_;
    if (( $? != 0 )); then return 1; fi
    folder_to_setup="."
  fi

  # debugging
  # print "proj_arg=$proj_arg"
  # print "folder_arg=$folder_arg"
  # print "folder_to_setup=$folder_to_setup"
  # print " --------"

  pushd "$folder_to_setup" &>/dev/null

  print " setup on ${gray_cor}$(shorten_path_) ${reset_cor}:${pink_cor} $_setup ${reset_cor}"
  eval "$_setup"
}

# Clone =====================================================================
# review branch
function revs() {
  eval "$(parse_flags_ "revs_" "" "$@")"

  if (( revs_is_h )); then
    if [[ -n "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
      print "${yellow_cor} revs${reset_cor} : to list reviews from $Z_CURRENT_PROJECT_SHORT_NAME"
    fi
    print "${yellow_cor} revs <pro>${reset_cor} : to list reviews from project"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " revs requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi
  
  local proj_arg="$Z_CURRENT_PROJECT_SHORT_NAME"

  if [[ -n "$1" ]]; then
    local valid_project=0
    local i=0
    for i in {1..9}; do
      if [[ "$1" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        proj_arg="${1:-$Z_CURRENT_PROJECT_SHORT_NAME}"
        valid_project=1
        break
      fi
    done

    if (( valid_project == 0 )); then
      print " not a valid project: $1" >&2
      print " ${yellow_cor} pro${reset_cor} to see options" >&2
      return 1;
    fi
  fi

  local proj_folder=""
  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
      proj_folder=$(get_prj_folder_ -s $i "$Z_PROJECT_FOLDER[$i]")
      if [ -z "$proj_folder" ]; then return 1; fi
      break
    fi
  done

  if [[ -z $proj_folder ]]; then
    print " not a valid project: $proj_arg" >&2
    print " ${yellow_cor} revs -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local _pwd="$(PWD)";
  local revs_folder="$proj_folder/revs"

  if [[ -d "$revs_folder" ]]; then
    cd "$revs_folder"
  else
    revs_folder=".$proj_folder-revs"
    if [[ -d "$revs_folder" ]]; then
      cd "$revs_folder"
    else
      print " no revs for $proj_folder" >&2
      print " ${yellow_cor} rev${reset_cor} to open a review" >&2
      return 1; 
    fi
  fi

  local rev_choices=$(ls -d rev* | xargs -0 | sort -fu)

  if [[ -z "$rev_choices" ]]; then
    cd "$_pwd"
    print " no revs for $proj_folder" >&2
    print " ${yellow_cor} rev${reset_cor} to open a review" >&2
    return 1;
  fi

  local choice=$(gum choose --limit=1 --header " choose review to open:" $(echo "$rev_choices" | tr ' ' '\n'))

  if [[ -n "$choice" ]]; then
    rev "$proj_arg" "${choice//rev./}" >/dev/null
  fi

  cd "$_pwd"

  return 0;
}

function rev() {
  eval "$(parse_flags_ "rev_" "" "$@")"

  if (( rev_is_h )); then
    print "${yellow_cor} rev${reset_cor} : open a pull request for review"
    if [[ -n "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
      print "${yellow_cor} rev${solid_yellow_cor} [<branch>]${reset_cor} : to open a review for $Z_CURRENT_PROJECT_SHORT_NAME"
    fi
    print "${yellow_cor} rev <pro>${solid_yellow_cor} [<branch>]${reset_cor} : to open a review for a project"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " rev requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi

  local proj_arg="$Z_CURRENT_PROJECT_SHORT_NAME"
  local branch_arg=""

  if [[ -n "$2" ]]; then
    proj_arg="$1"
    branch_arg="$2"
  elif [[ -n "$1" ]]; then
    if is_project_ $1; then
      proj_arg="$1"
    else
      branch_arg="$1"
    fi
  fi

  local proj_repo=""
  local proj_folder=""
  local _setup=""
  local _clone=""
  local code_editor="$Z_CURRENT_PROJECT_REPO"
  local single_mode=""

  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
      proj_repo="$(get_prj_repo_ -s $i)"
      if [ -z "$proj_repo" ]; then return 1; fi
      
      proj_folder="$(get_prj_folder_ -s $i)"
      if [ -z "$proj_folder" ]; then return 1; fi

      _setup="${Z_SETUP[$i]}"
      _clone="${Z_CLONE[$i]}"
      code_editor="${Z_CODE_EDITOR[$i]}"
      single_mode=$(is_project_single_mode_ $i)
      break
    fi
  done

  if [[ -z "$proj_repo" ]]; then
    print " could not locate repository uri: $proj_arg" >&2
    return 1;
  fi

  if [[ -z "$proj_folder" ]]; then
    print " could not locate project folder: $proj_arg" >&2
    return 1;
  fi

  local _pwd="$(PWD)";
  local branch="";

  if [[ -z "$3" ]]; then # -q
    open_prj_for_git_ "$proj_folder"
    if (( $? != 0 )); then return 1; fi

    git fetch origin --quiet

    if [[ -z "$1" || -z "$branch_arg" ]]; then
      select_pr_;
      if (( $? != 0 )); then
        cd "$_pwd"
        return 1;
      fi

      if [[ -n "$select_pr_choice" ]]; then
        rev "$proj_arg" "$select_pr_branch" >/dev/null
        # cd "$_pwd"
        return 0;
      fi

      print " could not find a branch."
      cd "$_pwd"
      return 1;
    fi

    select_pr_ "$branch_arg";
    if (( $? != 0 )); then
      cd "$_pwd"
      return 1;
    fi

    if [[ -n "$select_pr_choice" ]]; then
      rev "$proj_arg" "$select_pr_branch" >/dev/null
      # cd "$_pwd"
      return 0;
    fi

    cd "$_pwd"
    print " did not match any branch known to git: $branch_arg" >&2
    return 1;
  else
    branch="$branch_arg"
  fi

  local branch_folder="${branch//\\/-}";
  branch_folder="${branch_folder//\//-}";

  local revs_folder=""

  # check if using the proj_folder as single clone mode
  if (( single_mode )); then
    revs_folder=".$proj_folder-revs"
  else
    revs_folder="$proj_folder/revs"
  fi

  local full_rev_folder="$revs_folder/rev.$branch_folder"

  if [[ -d "$full_rev_folder" ]]; then
    print " review already exist, opening${green_cor} $(shorten_path_ $full_rev_folder) ${reset_cor} and pulling latest changes..."
  else
    print " creating review for${green_cor} $select_pr_title${reset_cor}..."

    if command -v gum &>/dev/null; then
      gum spin --title "cloning... $proj_repo" -- git clone $proj_repo "$full_rev_folder" --quiet
    else
      print " cloning... $proj_repo";
      git clone $proj_repo "$full_rev_folder" --quiet
    fi

    if (( $? != 0 )); then
      return 1;
    fi
  fi

  pushd "$full_rev_folder" &>/dev/null
  
  local git_status=$(git status --porcelain)
  if [[ -n "$git_status" ]]; then
    if ! confirm_from_ "branch is not clean, reset?"; then
      return 0;
    fi
    print " resetting via reseta..."
    reseta
  fi
  
  local warn_msg=""

  git checkout "$branch" --quiet
  git pull origin --quiet

  local is_open_editor=0

  if (( $? != 0 )); then
    is_open_editor=1
    warn_msg="${yellow_cor} warn: could not pull latest changes, probably already merged ${reset_cor}"
  fi

  if [[ -n "$_setup" ]]; then
    print "${pink_cor} $_setup ${reset_cor}"
    eval "$_setup"
    if (( $? == 0 )); then
      if (( is_open_editor )); then
        eval $code_editor .
      fi
    fi
  fi

  if [[ -n "$warn_msg" ]]; then
    print ""
    print "$warn_msg"
    print ""
  fi

  return 0;
}

function get_clone_default_branch_() { # $1 = repo uri # $2 = folder # $3 = branch to clone
  if [[ "$3" == "main" || "$3" == "master" ]]; then
    echo "$3"
    return 0;
  fi

  if command -v gum &>/dev/null; then
    gum spin --title "determining the default branch..." -- rm -rf "$2/.temp"
    gum spin --title "determining the default branch..." -- git clone "$1" "$2/.temp" --quiet
  else
    print " determining the default branch..."
    rm -rf "$2/.temp" &>/dev/null
    git clone "$1" "$2/.temp" --quiet
  fi
  if (( $? != 0 )); then
    return 1;
  fi  

  pushd "$2/.temp" &>/dev/null
  
  local default_branch="$(git config --get init.defaultBranch)"
  local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

  popd &>/dev/null

  rm -rf "$2/.temp" &>/dev/null

  local default_branch_folder="${default_branch//\\/-}"
  default_branch_folder="${default_branch_folder//\//-}"

  local my_branch_folder="${my_branch//\\/-}"
  my_branch_folder="${my_branch_folder//\//-}"

  if [[ -z "$3" ]]; then
    if [[ -d "$2/$default_branch_folder" ]]; then
      default_branch=""
    fi

    if [[ -d "$2/$my_branch_folder" ]]; then
      my_branch=""
    fi
  fi

  local default_branch_choice="";

  if [[ "$my_branch" != "$default_branch" && -n "$default_branch" && -n "$my_branch" ]]; then
    default_branch_choice=$(choose_auto_one_ "choose default branch" "$default_branch" "$my_branch");
  elif [[ -n "$default_branch" ]]; then
    default_branch_choice="$default_branch";
  elif [[ -n "$my_branch" ]]; then
    default_branch_choice="$my_branch";
  fi

  if [[ -z "$default_branch_choice" ]]; then
    return 1;
  fi

  echo "$default_branch_choice"
}

# clone my project and checkout branch
function clone() {
  eval "$(parse_flags_ "clone_" "" "$@")"

  if (( clone_is_h )); then
    if [[ -n "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
      print "${yellow_cor} clone <branch>${reset_cor} : to clone $Z_CURRENT_PROJECT_SHORT_NAME branch"
      print "${yellow_cor} clone $Z_CURRENT_PROJECT_SHORT_NAME${solid_yellow_cor} [<branch>]${reset_cor} : to clone $Z_CURRENT_PROJECT_SHORT_NAME branch"
    fi
      print "${yellow_cor} clone <pro>${solid_yellow_cor} [<branch>]${reset_cor} : to clone another project"
    return 0;
  fi

  if [[ $1 == -* ]]; then
    clone -h
    return 0;
  fi

  local proj_arg="$Z_CURRENT_PROJECT_SHORT_NAME"
  local branch_arg=""

  if [[ -n "$2" ]]; then
    proj_arg="$1"
    branch_arg="$2"
  elif [[ -n "$1" ]]; then
    valid_project=0
    local i=0
    for i in {1..9}; do
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
    local i=0
    for i in {1..9}; do
      if [[ -n "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        pro_choices+=("${Z_PROJECT_SHORT_NAME[$i]}")
      fi
    done

    proj_arg=$(choose_auto_one_ "choose project to clone" "${pro_choices[@]}")
    if [[ -z "$proj_arg" ]]; then
      return 1;
    fi
  fi

  local proj_repo=""
  local proj_folder=""
  local _clone=""
  local default_branch=""
  local print_readme=1
  local single_mode=""

  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
      proj_repo="$(get_prj_repo_ -s $i)"
      if [ -z "$proj_repo" ]; then return 1; fi

      proj_folder="$(get_prj_folder_ -s $i)"
      if [ -z "$proj_folder" ]; then return 1; fi

      _clone="${Z_CLONE[$i]}"
      default_branch="${Z_DEFAULT_BRANCH[$i]}"
      print_readme="${Z_PRINT_README[$i]}"
      single_mode=$(is_project_single_mode_ $i)
      break
    fi
  done

  if [[ -z "$proj_repo" ]]; then
    print " could not locate repository uri: $proj_arg" >&2
    return 1;
  fi

  if [[ -z "$proj_folder" ]]; then
    print " could not locate project folder: $proj_arg" >&2
    return 1;
  fi

  if (( single_mode )); then
    print "${solid_blue_cor} $proj_arg${reset_cor} already cloned in 'single mode': $proj_folder" >&2
    print "" >&2
    print " to clone a different branch, edit the project to 'multiple mode':" >&2
    print "  1. ${yellow_cor}pro -e ${proj_arg}${reset_cor}" >&2
    print "  2. then choose 'multiple' and save project" >&2
    return 1;
  fi

  local user_selected_mode=0;

  if [[ -z "$branch_arg" && -z "$single_mode" ]]; then
    # ask user if they want to single project mode, or multiple mode
    single_mode=$(choose_mode_ $proj_arg 1)
    if (( $? == 130 )); then
      return 130;
    fi

    user_selected_mode=1;

    if (( single_mode )); then
      if [[ -d "$proj_folder" && -n "$(ls -A "$proj_folder")" ]]; then
        print "  ${solid_yellow_cor}project folder '$proj_folder' is not empty, going with 'multi mode' ${reset_cor}"
      else
        local default_branch_to_clone=$(get_clone_default_branch_ "$proj_repo" "$proj_folder");

        if [[ -z "$default_branch_to_clone" ]]; then
          return 0;
        fi

        if command -v gum &>/dev/null; then
          gum spin --title "cloning... $proj_repo on $default_branch_to_clone" -- git clone $proj_repo "$proj_folder" --quiet
          echo "   cloning... $proj_repo on $default_branch_to_clone"
        else
          print "  cloning... $proj_repo on $default_branch_to_clone"
          git clone --quiet $proj_repo "$proj_folder"
        fi
        if (( $? != 0 )); then
          print "  could not clone" >&2
          if [[ -d "$proj_folder" ]]; then
            print "  project folder already exists: $proj_folder" >&2
          fi
          return 1;
        fi        

        pushd "$proj_folder" &>/dev/null

        git config init.defaultBranch "$default_branch_to_clone"
        git checkout "$default_branch_to_clone" --quiet &>/dev/null

        save_pump_working_ "$proj_arg"

        #refresh >/dev/null 2>&1

        if [[ -n "$_clone" ]]; then
          print "  ${pink_cor}$_clone ${reset_cor}"
          eval "$_clone"
        fi

        if [[ $print_readme -eq 1 ]] && command -v glow &>/dev/null; then
          # find readme file
          local readme_file=$(find . -type f \( -iname "README*" -o -iname "readme*" \) | head -n 1);
          if [[ -n "$readme_file" ]]; then
            glow "$readme_file"
          fi
        fi

        print ""
        print "  default branch is${bright_green_cor} $(git config --get init.defaultBranch) ${reset_cor}"
        print ""

        if [[ "$proj_arg" != "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
          pro $proj_arg
        fi
        return 0;
      fi
    fi
    # end of (( single_mode ))
  fi

  # multiple mode (requires passing a branch name)

  local branch_to_clone=""
  
  if [[ -n "$branch_arg" ]]; then
    branch_to_clone="$branch_arg"
  else
    if (( user_selected_mode )); then # first time user is cloning
      branch_to_clone=$(get_clone_default_branch_ "$proj_repo" "$proj_folder");
    else
      branch_to_clone=$(input_name_ "type the branch name" "" 50);
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
      local i=0
      for i in {1..9}; do
        if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
          update_config_ $i "Z_DEFAULT_BRANCH" "$default_branch"
          Z_DEFAULT_BRANCH[$i]="$default_branch"
          break
        fi
      done
      print ""
    fi
  fi

  local branch_to_clone_folder="${branch_to_clone//\\/-}"
  branch_to_clone_folder="${branch_to_clone_folder//\//-}"

  if command -v gum &>/dev/null; then
    gum spin --title "cloning... $proj_repo on $branch_to_clone" -- git clone $proj_repo "$proj_folder/$branch_to_clone_folder" --quiet
    echo "   cloning... $proj_repo on $branch_to_clone"
  else
    print "  cloning... $proj_repo on $branch_to_clone"
    git clone --quiet $proj_repo "$proj_folder/$branch_to_clone_folder"
  fi
  if (( $? != 0 )); then
    print "  could not clone" >&2
    if [[ -d "$proj_folder/$branch_to_clone_folder" ]]; then
      print "  project folder exists: $proj_folder/$branch_to_clone_folder" >&2
    fi
    return 1;
  fi

  # multiple mode

  local past_folder="$(PWD)"

  pushd "$proj_folder/$branch_to_clone_folder" &>/dev/null
  if (( $? == 0 )); then
    PUMP_PAST_FOLDER="$past_folder"
    save_pump_working_ "$proj_arg"
  fi
  
  git config init.defaultBranch $default_branch

  if [[ "$branch_to_clone" != "$(git symbolic-ref --short HEAD 2>/dev/null)" ]]; then
    # check if branch exist
    local remote_branch=$(git ls-remote --heads origin "$branch_to_clone")
    local local_branch=$(git branch --list "$branch_to_clone" | head -n 1)

    if [[ -z "$remote_branch" && -z "$local_branch" ]]; then
      git checkout -b "$branch_to_clone" --quiet
    else
      git checkout "$branch_to_clone" --quiet
    fi
  fi

  # multiple mode

  if [[ -n "$_clone" ]]; then
    print "  ${pink_cor}$_clone ${reset_cor}"
    eval "$_clone"
  fi

  if [[ $print_readme -eq 1 ]] && command -v glow &>/dev/null; then
    # find readme file
    local readme_file=$(find . -type f \( -iname "README*" -o -iname "readme*" \) | head -n 1);
    if [[ -n "$readme_file" ]]; then
      glow "$readme_file"
    fi
  fi

  print ""
  print "  default branch is${bright_green_cor} $(git config --get init.defaultBranch) ${reset_cor}"
  print ""

  if [[ "$proj_arg" != "$Z_CURRENT_PROJECT_SHORT_NAME" ]]; then
    pro $proj_arg
  fi
}

function abort() {
  eval "$(parse_flags_ "abort_" "" "$@")"

  if (( abort_is_h )); then
    print "${yellow_cor} abort${reset_cor} : to abort any in progress rebase, merge and cherry-pick"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  GIT_EDITOR=true git rebase --abort &>/dev/null
  GIT_EDITOR=true git merge --abort  &>/dev/null
  GIT_EDITOR=true git cherry-pick --abort &>/dev/null
}

function renb() {
  eval "$(parse_flags_ "renb_" "" "$@")"

  if (( renb_is_h )); then
    print "${yellow_cor} renb <branch>${reset_cor} : to rename a branch"
    return 0;
  fi

  if [[ -z "$1" ]]; then
    renb -h
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  local old_name="$(git symbolic-ref --short HEAD 2>/dev/null)"

  git config branch."$1".gh-merge-base "$(git config --get branch."$old_name".gh-merge-base)" &>/dev/null
  
  git branch -m "$@"
}

function chp() {
  eval "$(parse_flags_ "chp_" "" "$@")"

  if (( chp_is_h )); then
    print "${yellow_cor} chp <commit>${reset_cor} : to cherry-pick a commit"
    return 0;
  fi

  if [[ -z "$1" ]]; then
    chp -h
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi
  
  git cherry-pick "$@"
}

function chc() {
  eval "$(parse_flags_ "chc_" "" "$@")"

  if (( chc_is_h )); then
    print "${yellow_cor} chc${reset_cor} : to continue in progress cherry-pick"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  GIT_EDITOR=true git merge --continue &>/dev/null
}

function mc() {
  eval "$(parse_flags_ "mc_" "" "$@")"

  if (( mc_is_h )); then
    print "${yellow_cor} mc${reset_cor} : to continue in progress merge"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  git add .

  GIT_EDITOR=true git merge --continue &>/dev/null
}

function rc() {
  eval "$(parse_flags_ "rc_" "" "$@")"

  if (( rc_is_h )); then
    print "${yellow_cor} rc${reset_cor} : to continue in progress rebase"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  git add .

  GIT_EDITOR=true git rebase --continue &>/dev/null
}

function conti() {
  eval "$(parse_flags_ "conti_" "" "$@")"

  if (( conti_is_h )); then
    print "${yellow_cor} conti${reset_cor} : to continue any in progress rebase, merge or cherry-pick"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  git add .

  GIT_EDITOR=true git rebase --continue &>/dev/null
  GIT_EDITOR=true git merge --continue &>/dev/null
  GIT_EDITOR=true git cherry-pick --continue &>/dev/null
}

# Commits -----------------------------------------------------------------------
function reset1() {
  eval "$(parse_flags_ "reset1_" "" "$@")"

  if (( reset1_is_h )); then
    print "${yellow_cor} reset1${reset_cor} : to reset last commit"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  git log -1 --pretty=format:'%s' | xargs -0
  
  git reset --quiet --soft HEAD~1
}

function reset2() {
  eval "$(parse_flags_ "reset2_" "" "$@")"

  if (( reset2_is_h )); then
    print "${yellow_cor} reset2${reset_cor} : to reset 2 last commits"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  git log -2 --pretty=format:'%s' | xargs -0
  
  git reset --quiet --soft HEAD~2
}

function reset3() {
  eval "$(parse_flags_ "reset3_" "" "$@")"

  if (( reset3_is_h )); then
    print "${yellow_cor} reset3${reset_cor} : to reset 3 last commits"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  git log -3 --pretty=format:'%s' | xargs -0
  
  git reset --quiet --soft HEAD~3
}

function reset4() {
  eval "$(parse_flags_ "reset4_" "" "$@")"

  if (( reset4_is_h )); then
    print "${yellow_cor} reset4${reset_cor} : to reset 4 last commits"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  git log -4 --pretty=format:'%s' | xargs -0
  
  git reset --quiet --soft HEAD~4
}

function reset5() {
  eval "$(parse_flags_ "reset5_" "" "$@")"

  if (( reset5_is_h )); then
    print "${yellow_cor} reset5${reset_cor} : to reset 5 last commits"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  git log -5 --pretty=format:'%s' | xargs -0
  
  git reset --quiet --soft HEAD~5
}

function repush() {
  eval "$(parse_flags_ "repush_" "s" "$@")"

  if (( repush_is_h )); then
    print "${yellow_cor} repush${reset_cor} : to reset last commit then re-push all changes"
    print "${yellow_cor} repush -s${reset_cor} : only staged changes"
    return 0;
  fi

  if (( repush_is_s )); then
    recommit -s $@
  else
    recommit $@
  fi

  if (( $? != 0 )); then return 1; fi
  
  pushf $@
}

function recommit() {
  eval "$(parse_flags_ "recommit_" "s" "$@")"

  if (( recommit_is_h )); then
    print "${yellow_cor} recommit${reset_cor} : to reset last commit then re-commit all changes"
    print "${yellow_cor} recommit -s${reset_cor} : only staged changes"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  local git_status=$(git status --porcelain)
  if [[ -z "$git_status" ]]; then
    print " nothing to recommit, working tree clean"
    return 0;
  fi

  local last_commit_msg=$(git log -1 --pretty=format:'%s' | xargs -0)
  
  if [[ "$last_commit_msg" == Merge* ]]; then
    print " last commit is a merge commit, please rebase instead" >&2
    return 1;
  fi

  if (( ! recommit_is_s )); then
    git reset --quiet --soft HEAD~1 >/dev/null
    if (( $? != 0 )); then return 1; fi

    if [[ -z "$Z_CURRENT_COMMIT_ADD" ]]; then
      if confirm_from_ "do you want to recommit all changes with '$last_commit_msg'?"; then
        git add .

        if confirm_from_ "save this preference and don't ask again?"; then
          local i=0
          for i in {1..9}; do
            if [[ "$Z_CURRENT_PROJECT_SHORT_NAME" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
              update_config_ $i "Z_COMMIT_ADD" 1
              Z_CURRENT_COMMIT_ADD=1
              break
            fi
          done

          print ""
        fi
      fi
    elif [[ $Z_CURRENT_COMMIT_ADD -eq 1 ]]; then
      git add .
    fi
  else
    if git diff --cached --quiet; then
      print " nothing to recommit, no staged changes" >&2
      print " run${yellow_cor} recommit${reset_cor} to re-commit all changes" >&2
      return 1;
    fi
  fi

  git commit -m "$last_commit_msg" $@

  if (( $? == 0 )); then
    print ""
    git log -1 --pretty=format:'%h %s' | xargs -0
  fi
}

function commit() {
  eval "$(parse_flags_ "commit_" "a" "$@")"

  if (( commit_is_h )); then
    print "${yellow_cor} commit${reset_cor} : to open commit wizard"
    print "${yellow_cor} commit -a${reset_cor} : to open wizard and commit all files"
    print "${yellow_cor} commit <message>${reset_cor} : to commit with message"
    print "${yellow_cor} commit -a <message>${reset_cor} : to commit all files with message"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  local msg_arg=""

  if (( commit_is_a )); then
    git add .
    msg_arg="$2"
  else
    msg_arg="$1"
    if [[ -z "$Z_CURRENT_COMMIT_ADD" ]]; then
      if confirm_from_ "do you want to commit all changes?"; then
        git add .

        if confirm_from_ "save this preference and don't ask again?"; then
          local i=0
          for i in {1..9}; do
            if [[ "$Z_CURRENT_PROJECT_SHORT_NAME" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
              update_config_ $i "Z_COMMIT_ADD" 1
              Z_CURRENT_COMMIT_ADD=1
              break
            fi
          done
          print ""
        fi
      fi
    elif [[ $Z_CURRENT_COMMIT_ADD -eq 1 ]]; then
      git add .
    fi
  fi

  if [[ -z "$msg_arg" ]]; then
    if ! command -v gum &>/dev/null; then
      print " commit wizard requires gum" >&2
      print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
      print " or ${yellow_cor}commit <message>${reset_cor} : to create a commit with message" >&2
      return 1;
    fi

    local type_commit=$(gum choose "fix" "feat" "docs" "refactor" "test" "chore" "style" "revert")
    if [[ -z "$type_commit" ]]; then
      return 0;
    fi

    # scope is optional
    scope_commit=$(gum input --placeholder "scope")
    if (( $? != 0 )); then
      return 0;
    fi
    if [[ -n "$scope_commit" ]]; then
      scope_commit="($scope_commit)"
    fi

    msg_arg=$(gum input --value "${type_commit}${scope_commit}: ")
    if (( $? != 0 )); then
      return 0;
    fi

    local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
    
    if [[ $my_branch =~ ([[:alnum:]]+-[[:digit:]]+) ]]; then # [A-Z]+-[0-9]+
      local ticket="${match[1]} "
      local skip=0;

      git log -n 10 --pretty=format:"%h %s" | while read -r line; do
        commit_hash=$(echo "$line" | awk '{print $1}')
        message=$(echo "$line" | cut -d' ' -f2-)

        if [[ "$message" == "$ticket"* ]]; then
          skip=1;
          break;
        fi
      done

      if [[ $skip -eq 0 ]]; then
        msg_arg="$ticket $commit_msg"
      fi
    fi
    
    print "$msg_arg"
  fi

  if (( commit_is_a )); then
    git commit --no-verify --message "$msg_arg" ${@:3}
  else
    git commit --no-verify --message "$msg_arg" ${@:2}
  fi
}

function fetch() {
  eval "$(parse_flags_ "fetch_" "" "$@")"

  if (( fetch_is_h )); then
    print "${yellow_cor} fetch${reset_cor} : to fetch all branches"
    print "${yellow_cor} fetch <branch>${reset_cor} : to fetch a branch"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  git fetch --tags --prune-tags --force

  if [[ -n "$1" ]]; then
    git fetch --prune origin "$1" ${@:2}
  else
    git fetch --prune --all $@
  fi

  local current_branches=$(git branch --format '%(refname:short)')

  for config in $(git config --get-regexp "^branch\." | awk '{print $1}'); do
    local branch_name="${config#branch.}"

    if ! echo "$current_branches" | grep -q "^$branch_name$"; then
      git config --remove-section "branch."$branch_name"" &>/dev/null
    fi
  done

  return 0
}

function gconf() {
  print "${solid_yellow_cor} Username:${reset_cor} $(git config --get user.name)"
  print "${solid_yellow_cor} Email:${reset_cor} $(git config --get user.email)"
  print "${solid_yellow_cor} Default branch:${reset_cor} $(git config --get init.defaultBranch)"
}

function glog() {
  eval "$(parse_flags_ "glog_" "" "$@")"

  if (( glog_is_h )); then
    print "${yellow_cor} glog ${solid_yellow_cor}[x]${reset_cor} : to log last x commits, default is 15"
    return 0;
  fi

  local _pwd="$(PWD)";

  open_prj_for_git_
  if (( $? != 0 )); then return 1; fi

  local x=${1:-15}

  if [[ "$x" =~ ^-?[0-9]+$ ]]; then
    x=${x#-}
  else
    x=15
  fi

  git --no-pager log --oneline -n ${x} --graph --date=relative --decorate

  cd "$_pwd"
}

function push() {
  eval "$(parse_flags_ "push_" "" "$@")"

  if (( push_is_h )); then
    print "${yellow_cor} push${reset_cor} : to push with no-verify"
    print " ${yellow_cor} -fl${reset_cor} : force with lease"
    print " ${yellow_cor}  -t${reset_cor} : push tags"
    print " ${yellow_cor}  -f${reset_cor} : force"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  fetch --quiet

  local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

  if (( push_is_t && push_is_f )); then
    git push --no-verify --tags --force $@
  elif (( push_is_t )); then
    git push --no-verify --tags $@
  elif (( push_is_f && push_is_l )); then
    git push --no-verify --force-with-lease --set-upstream origin $my_branch $@
  elif (( push_is_f )); then
    git push --no-verify --force --set-upstream origin $my_branch $@
  else
    git push --no-verify --set-upstream origin $my_branch $@
  fi

  if (( ! $? && ! push_is_t )); then
    print ""
    git log -1 --pretty=format:'%h %s' | xargs -0
  fi
}

function pushf() {
  eval "$(parse_flags_ "pf_" "" "$@")"

  if (( is_h )); then
    print "${yellow_cor} pushf${reset_cor} : to force push no-verify"
    print "${yellow_cor}    -t${reset_cor} : to force push tags"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  if (( is_t )); then
    git push --no-verify --tags --force $@
  else
    git push --no-verify --force $@
  fi

  if (( $? == 0 && ! is_t && ! is_q )); then
    print ""
    git log -1 --pretty=format:'%h %s' | xargs -0
  fi
}

function stash() {
  eval "$(parse_flags_ "stash_" "" "$@")"

  if (( stash_is_h )); then
    print "${yellow_cor} stash ${reset_cor} : to stash all files unnamed"
    print "${yellow_cor} stash <name>${reset_cor} : to stash all files with name"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  if [[ -z "$1" ]]; then
    git stash push --include-untracked --message "$(date +%Y-%m-%d_%H:%M:%S)" ${@:2}
    return 0;
  fi

  git stash push --include-untracked --message $@
}

function dtag() {
  eval "$(parse_flags_ "dtag_" "" "$@")"

  if (( dtag_is_h )); then
    print "${yellow_cor} dtag <name>${reset_cor} : to delete a tag"
    return 0;
  fi
  if [[ -z "$1" ]]; then
    dtag -h
    return 0;
  fi

  local _pwd="$(PWD)";

  open_prj_for_git_
  if (( $? != 0 )); then return 1; fi
  
  fetch --quiet

  git tag -d "$1" ${@:2}

  if (( $? != 0 )); then
    cd "$_pwd"
    return 1;
  fi

  git push origin --delete "$1" ${@:2}

  cd "$_pwd"
}

function print_debug_() {
  if (( is_d )); then
    print "debug: $1" >&2
  fi
}

function exec_() {
  print_debug_ "$1" >&2

  if (( is_d )); then
    return 0;
  fi

  local command="$1"
  shift
  eval "$command $@"
}

function pull() {
  eval "$(parse_flags_ "pull_" "" "$@")"

  if (( pull_is_h )); then
    print "${yellow_cor} pull ${solid_yellow_cor}[<origin_branch>]${reset_cor} : to pull from origin branch"
    print " ${yellow_cor}  -t${reset_cor} : to pull tags"
    return 0;
  fi

  local branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

  if (( pull_is_t )); then
    git pull origin --tags $@
  else
    git pull --rebase --autostash $@ origin "$branch"
  fi

  if (( ! $? && ! pull_is_t && ! pull_is_q )); then
    print ""
    git log -1 --pretty=format:'%h %s' | xargs -0
  fi
}

function tag() {
  eval "$(parse_flags_ "tag_" "" "$@")"

  if (( tag_is_h )); then
    print "${yellow_cor} tag <name>${reset_cor} : to create a new tag"
    return 0;
  fi
  if [[ -z "$1" ]]; then
    tah -h
    return 0;
  fi

  local _pwd="$(PWD)";

  open_prj_for_git_
  if (( $? != 0 )); then return 1; fi
  
  prune &>/dev/null

  git tag --annotate "$1" --message "$1" ${@:2}
  if (( $? == 0 )); then
    git push --no-verify --tags
  fi

  cd "$_pwd"
}

function tags() {
  eval "$(parse_flags_ "tags_" "" "$@")"

  if (( tags_is_h )); then
    print "${yellow_cor} tags${reset_cor} : to list all tags"
    print "${yellow_cor} tags <x>${reset_cor} : to list x number of tags"
    return 0;
  fi

  local _pwd="$(PWD)";

  open_prj_for_git_
  if (( $? != 0 )); then return 1; fi

  prune >/dev/null

  local tag=""

  if [[ -z "$1" ]]; then
    tag=$(git for-each-ref refs/tags --sort=-taggerdate --format='%(refname:short)')

    if [[ -z "$tag" ]]; then
      tag=$(git for-each-ref refs/tags --sort=-committerdate --format='%(refname:short)')
    fi
  else
    tag=$(git for-each-ref refs/tags --sort=-taggerdate --format='%(refname:short)' --count="${1//[^0-9]/}")

    if [[ -z "$tag" ]]; then
      tag=$(git for-each-ref refs/tags --sort=-committerdate --format='%(refname:short)' --count="${1//[^0-9]/}")
    fi
  fi

  if [[ -z "$tag" ]]; then
    print " no tags found"
  else
    print "$tag"
  fi

  cd "$_pwd"
}

function restore() {
  eval "$(parse_flags_ "restore_" "" "$@")"

  if (( restore_is_h )); then
    print "${yellow_cor} restore${reset_cor} : to undo edits in tracked files"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  git restore -q .
}

function clean() {
  eval "$(parse_flags_ "clean_" "" "$@")"

  if (( clean_is_h )); then
    print "${yellow_cor} clean${reset_cor} : to delete all untracked files and directories and undo edits in tracked files"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi
  
  git clean -fd -q
  restore
}

function discard() {
  eval "$(parse_flags_ "discard_" "" "$@")"

  if (( discard_is_h )); then
    print "${yellow_cor} discard${reset_cor} : to undo everything that have not been committed"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  git reset --hard
  clean
}

function reseta() {
  eval "$(parse_flags_ "reseta_" "" "$@")"

  if (( reseta_is_h )); then
    print "${yellow_cor} reseta${reset_cor} : to erase everything and match HEAD to origin"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  # check if current branch exists in remote
  local remote_branch=$(git ls-remote --heads origin "$(git symbolic-ref --short HEAD 2>/dev/null)")

  if [[ -n "$remote_branch" ]]; then
    git reset --hard origin/"$(git symbolic-ref --short HEAD 2>/dev/null)"
  else
    git reset --hard
  fi

  clean
}

function open_prj_for_git_() {
  local proj_folder="${1:-$PWD}"
  local git_folder=$(get_prj_for_git_ "$proj_folder")

  if [[ -z "$git_folder" ]]; then
    print " not a git repository (or any of the parent directories): $proj_folder" >&2
    return 1;
  fi

  cd "$git_folder"
}

function get_prj_for_git_() {
  local proj_folder="${1:-$PWD}"

  if is_git_repo_ "$proj_folder"; then
    print "$proj_folder"
    return 0;
  fi

  if [[ ! -d "$proj_folder" ]]; then
    return 1;
  fi

  local _pwd="$(PWD)"

  cd "$proj_folder"

  local folder=""
  local folders=("main" "master" "stage" "staging" "dev" "develop")

  # Loop through each folder name
  for defaultFolder in "${folders[@]}"; do
    if [[ -d "$defaultFolder" ]]; then
      if is_git_repo_ "$defaultFolder"; then
        folder="$proj_folder/$defaultFolder"
        break;
      fi
    fi
  done

  if [[ -z "$folder" ]]; then
    setopt null_glob
    local i=0
    for i in */; do
      if is_git_repo_ "${i%/}"; then
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

  print "$folder"
}

# List branches -----------------------------------------------------------------------
# list remote branches that contains an optional text and adds a link to the branch in github
function glr() {
  eval "$(parse_flags_ "glr_" "" "$@")"

  if (( glr_is_h )); then
    print "${yellow_cor} gll${reset_cor} : to list remote branches"
    print "${yellow_cor} gll <branch>${reset_cor} : to list remote branches matching branch"
    return 0;
  fi

  local _pwd="$(PWD)";

  open_prj_for_git_
  if (( $? != 0 )); then return 1; fi

  fetch --quiet

  git branch -r --list "*$1*" --sort=authordate --format='%(authordate:format:%m-%d-%Y) %(align:17,left)%(authorname)%(end) %(refname:strip=3)' | sed \
    -e 's/\([0-9]*-[0-9]*-[0-9]*\)/\x1b[32m\1\x1b[0m/' \
    -e 's/\([^\ ]*\)$/\x1b[34m\x1b]8;;https:\/\/github.com\/wmgtech\/wmg2-one-app\/tree\/\1\x1b\\\1\x1b]8;;\x1b\\\x1b[0m/'

  cd "$_pwd"
}

# list only branches that contains an optional text
function gll() {
  eval "$(parse_flags_ "gll_" "" "$@")"

  if (( gll_is_h )); then
    print "${yellow_cor} gll${reset_cor} : to list branches"
    print "${yellow_cor} gll <branch>${reset_cor} : to list branches matching <branch>"
    return 0;
  fi

  local _pwd="$(PWD)";

  open_prj_for_git_
  if (( $? != 0 )); then return 1; fi

  git branch --list "*$1*" --sort=authordate --format="%(authordate:format:%m-%d-%Y) %(align:17,left)%(authorname)%(end) %(refname:strip=2)" | sed \
    -e 's/\([0-9]*-[0-9]*-[0-9]*\)/\x1b[32m\1\x1b[0m/' \
    -e 's/\([^ ]*\)$/\x1b[34m\1\x1b[0m/'

  cd "$_pwd"
}

function shorten_path_until_() {
  local folder="${1:-$(PWD)}"
  local target="${2:-$(basename $(PWD))}"

  # Remove trailing slash if present
  local folder="${folder%/}"

  # Split path into array
  IFS='/' read -r -A PARTS <<< "$folder"

  # Find the index of the target folder
  for (( i=1; i<=${#PARTS[@]}; i++ )); do
    if [[ "${PARTS[i]}" == "$target" ]]; then
      # Print from target folder to the end
      echo ".../${(j:/:)PARTS[i,-1]}"
      return 0;
    fi
  done

  # If folder not found, return full path
  echo "$folder"
}

function shorten_path_() {
  local folder="${1:-$(PWD)}"
  local count="${2:-2}"

  # Remove trailing slash if present
  local folder="${folder%/}"

  # Split path into array
  IFS='/' read -r -A parts <<< "$folder"
  local len=${#parts[@]}

  # Calculate start index
  local start=$(( len - count ))

  (( start < 0 )) && start=0

  # Print the last COUNT elements joined by /
  local output="${(j:/:)parts[@]:$start}"

  # Prepend ".../" if not returning the full path
  if (( count < len )); then
    if [[ -z "$3" ]]; then
      echo ".../$output"
      return 0;
    fi
  fi

  echo "$output"
}

# select_branch_ -a <search_text>
function select_branch_() {
  local multiple=${3:-0}

  # $1 are flag options
  # $2 is the search string
  print_debug_ "select_branch_ : git branch $1 | grep -i "$2""

  local branch_choices=$(git branch $1 --format="%(refname:strip=2)" | grep -i "$2" | sed -e 's/^[* ]*//g' | sed -e 's/HEAD//' | sed -e 's/remotes\///' | sed -e 's/HEAD -> origin\///' | sed -e 's/origin\///' | sort -fu)
  
  if [[ -z "$branch_choices" ]]; then
    print " did not match any branch known to git: $2" >&2
    return 1;
  fi

  #$branch_choices=$(echo "$branch_choices" | sed -e 's/^[* ]*//g' | sed -e 's/HEAD//' | sed -e 's/remotes\///' | sed -e 's/HEAD -> origin\///' | sed -e 's/origin\///' | sort -fu)

  local select_branch_choice=""

  if (( multiple )); then
    select_branch_choice=$(choose_multiple_ "choose branches" $(echo "$branch_choices" | tr ' ' '\n'))
  else
    local branch_choices_count=$(echo "$branch_choices" | wc -l)
    print_debug_ "select_branch_ : branch_choices_count=$branch_choices_count"
  # $(echo "$branch_choices" | tr ' ' '\n')
    if [ $branch_choices_count -gt 20 ]; then
      select_branch_choice=$(choose_auto_one_by_filtering_ "choose a branch" "type branch name" $(echo "$branch_choices" | tr ' ' '\n'))
    else
      select_branch_choice=$(choose_auto_one_ "choose a branch" $(echo "$branch_choices" | tr ' ' '\n'))
    fi
  fi

  print_debug_ "select_branch_ : select_branch_choice=[$select_branch_choice]"

  echo "$select_branch_choice"
}

function select_pr_() {
  local pr_list=$(gh pr list | grep -i "$1" | awk -F'\t' '{print $1 "\t" $2 "\t" $3}');
  local count=$(echo "$pr_list" | wc -l);

  if [[ -n "$pr_list" ]]; then
    print " no pull requests found" >&2
    print "" >&2
    return 1;
  fi

  local titles=$(echo "$pr_list" | cut -f2);

  local select_pr_title=""
  if [ $count -gt 20 ]; then
    print "${purple_cor} choose pull request: ${reset_cor}" >&2
    select_pr_title=$(echo "$titles" | gum filter --select-if-one --height 24  --indicator=">" --placeholder=" type pull request title");
    print "" >&2
  else
    select_pr_title=$(echo "$titles" | gum choose --select-if-one --height 24 --header=" choose pull request:");
  fi

  if [[ -z "$select_pr_title" ]]; then
    return 1;
  fi

  local select_pr_choice="$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $1}')"
  local select_pr_branch="$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $3}')"

  if [[ -z "$select_pr_choice" || -z "$select_pr_branch" ]]; then
    return 1;
  fi

  local pr=($select_pr_choice $select_pr_title $select_pr_branch)
  
  echo "${pr[@]}"
  return 0;
}

function gha_() {
  local workflow="$1"

  print_debug_ "gha_ : workflow=$workflow"

  if [[ -z "$workflow" ]]; then
    print " no workflow name provided" >&2
    print " ${yellow_cor} gha -h${reset_cor} to see usage" >&2

    return 1;
  fi

  print_debug_ "gh run list --workflow="${workflow}" --limit 1 --json databaseId --jq '.[0].databaseId'"

  local workflow_id="$(gh run list --workflow="${workflow}" --limit 1 --json databaseId --jq '.[0].databaseId')"

  if [[ -z "$workflow_id" ]]; then
    print "⚠️${yellow_cor} workflow not found ${reset_cor}" >&2
    return 1;
  fi

  local workflow_status="$(gh run list --workflow="${workflow}" --limit 1 --json conclusion --jq '.[0].conclusion')"

  if [[ -z "$workflow_status" ]]; then
    print " ⏳\e[90m workflow is still running ${reset_cor}" >&2
    return 0; # this nust be zero for auto mode
  fi

  # Output status with emoji
  if [[ "$workflow_status" == "success" ]]; then
    print " ✅${green_cor} workflow passed: $workflow ${reset_cor}"
  else
    print "\a ❌${red_cor} workflow failed (status: $workflow_status) ${reset_cor}"

    local extracted_repo=""

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
      print "  check out${blue_cor} https://github.com/$extracted_repo/actions/runs/$workflow_id ${reset_cor}"
    fi
  fi
  
  return 0;
}

function gha() {
  eval "$(parse_flags_ "gha_" "" "$@")"

  if (( gha_is_h )); then
    print "${yellow_cor} gha${solid_yellow_cor} [<workflow>]${reset_cor} : to check status of workflow in current project"
    print "${yellow_cor} gha <pro>${solid_yellow_cor} [<workflow>]${reset_cor} : to check status of a workflow for a project"
    print "${yellow_cor} gha -a${reset_cor} : to run in auto mode"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " gha requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi

  local workflow_arg=""
  local proj_arg=""

  # Parse arguments
  if [[ -n "$2" ]]; then
    local i=0
    for i in {1..9}; do
      if [[ "$1" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        proj_arg="$1"
        break
      fi
    done
    if [[ -n "$proj_arg" ]]; then
      workflow_arg="$2"
    fi
  elif [[ -n "$1" ]]; then
    local i=0
    for i in {1..9}; do
      if [[ "$1" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        proj_arg="$1"
        break
      fi
    done
    if [[ -z "$proj_arg" ]]; then
      workflow_arg="$1"
      proj_arg="$Z_CURRENT_PROJECT_SHORT_NAME"
    fi
  else
    proj_arg="$Z_CURRENT_PROJECT_SHORT_NAME"
  fi

  print_debug_ "gha - proj_arg: $proj_arg"

  local proj_folder="$(PWD)"  # default is current folder
  local gha_interval=""
  local gha_workflow=""

  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
      proj_folder=$(get_prj_folder_ -s $i "$Z_PROJECT_FOLDER[$i]")
      if [ -z "$proj_folder" ]; then return 1; fi

      gha_interval="${Z_GHA_INTERVAL[$i]}"
      gha_workflow="${Z_GHA_WORKFLOW[$i]}"
      break
    fi
  done

  local _pwd="$(PWD)";

  print_debug_ "gha - proj_folder: $proj_folder"

  if [[ -n "$proj_folder" ]]; then
    open_prj_for_git_ "$proj_folder"
    if (( $? != 0 )); then
      cd "$_pwd"
      return 1;
    fi
    proj_folder="$(PWD)";
  else
    print " no project folder found" >&2
    cd "$_pwd"
    return 1;
  fi

  print_debug_ "gha - pwd: $(PWD)"

  local ask_save=0

  if [[ -z "$workflow_arg" && -z "$gha_workflow" ]]; then
    local workflow_choices=$(gh workflow list | cut -f1)
    if [[ -z "$workflow_choices" || "$workflow_choices" == "No workflows found" ]]; then
      cd "$_pwd"
      print " no workflows found" >&2
      return 1;
    fi
    
    local chosen_workflow=$(gh workflow list | cut -f1 | gum choose --header " choose workflow:");
    if [[ -z "$chosen_workflow" ]]; then
      cd "$_pwd"
      return 1;
    fi

    workflow_arg="$chosen_workflow"
    ask_save=1
  elif [[ -n "$workflow_arg" ]]; then
    ask_save=1
  elif [[ -n "$gha_workflow" ]]; then
    workflow_arg="$gha_workflow"
    ask_save=0    
  fi

  if [[ -z "$workflow_arg" ]]; then
    print " no workflow name provided" >&2
    print " ${yellow_cor} gha -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( ! gha_is_a )); then
    print " checking workflow${purple_cor} $workflow_arg${reset_cor}..."
    gha_ "$workflow_arg"
    RET=$?
  else
    if [[ -z "$gha_interval" ]]; then
      gha_interval=10
    fi

    print " running every $gha_interval minutes, press cmd+c to stop"
    print ""

    while true; do
      print " checking workflow${purple_cor} $workflow_arg${reset_cor}..."

      gha_ "$workflow_arg"
      RET=$?

      if (( $? != 0 )); then
        return 1;
      fi
      
      print ""
      print " sleeping $gha_interval minutes..."
      sleep $(($gha_interval * 60))
    done
  fi

  if (( RET == 0 && ask_save )); then
    # ask to save the workflow
    if confirm_from_ "would you like to save \"$workflow_arg\" as the default workflow for this project?"; then
      local i=0
      for i in {1..9}; do
        if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
          Z_GHA_WORKFLOW[$i]="$workflow_arg"
          update_config_ $i "Z_GHA_WORKFLOW" "\"$workflow_arg\""
          break
        fi
      done
    fi
  fi
}

function co() {
  eval "$(parse_flags_ "co_" "aprebx" "$@")"

  if (( co_is_h )); then
    print "${yellow_cor} co${reset_cor} : to list local branches to switch"
    print "${yellow_cor} co -a${reset_cor} : to list all branches"
    print "${yellow_cor} co -pr${reset_cor} : to list PRs to check out (similar to rev but does not create a new review folder, only switches branches)"
    print "${yellow_cor} co -r${reset_cor} : to list remote branches only"
    print " --"
    print "${yellow_cor} co <branch>${reset_cor} : to switch to an existing branch"
    print "${yellow_cor} co -e <branch>${reset_cor} : to switch to exact branch"
    print "${yellow_cor} co -b <branch>${solid_yellow_cor} [<base_branch>]${reset_cor} : to create branch off of current HEAD"
    print "${yellow_cor} co <branch> <base_branch>${reset_cor} : to create branch off of base branch"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " co requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  print_debug_ "co - co_is_a: $co_is_a co_is_r: $co_is_r co_is_b: $co_is_b co_is_e: $co_is_e co_is_p: $co_is_p"

  # co pr
  if (( co_is_p && co_is_r )); then
    print_debug_ "co -pr asking for: $@"
    local pr=("${(@f)$(select_pr_ "$1")}")
    if (( $? != 0 )); then return 0; fi

    print " pr: ${pr[@]}"

    return 0;

    # if [[ -n "${pr[1]}" ]]; then
    #   print " checking out PR: ${pr[2]}"
    #   gh pr checkout ${pr[1]}
    # fi

    # return 0;
  fi

  # co -a all branches
  if (( co_is_a )); then
    print_debug_ "co -a asking for: $@"
    fetch --quiet
    local branch_choice="$(select_branch_ -a "$1")"
    print_debug_ "co -a branch_choice: $branch_choice"

    if [[ -z "$branch_choice" ]]; then
      return 1;
    fi

    co -e $branch_choice
    return $?
  fi

  # co -r remote branches
  if (( co_is_r )); then
    print_debug_ "co -r asking for: $@"
    fetch --quiet
    local branch_choice="$(select_branch_ -r "$1")"
    print_debug_ "co -r branch_choice: $branch_choice"

    if [[ -z "$branch_choice" ]]; then
      return 1;
    fi    
    co -e $branch_choice
    return $?
  fi

  # co -b branch create branch
  if (( co_is_b )); then
    print_debug_ "co -b asking for: $@"
    local branch="$1"
    local base_branch="$2"

    if [[ -z "$branch" ]]; then
      print " branch is required" >&2
      print " ${yellow_cor} co -b <branch>${reset_cor} : to create branch off of current HEAD" >&2
      print " ${yellow_cor} co -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if [[ -z "$base_branch" ]]; then
      base_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
    fi

    print_debug_ "co -b branch: "$branch" base_branch: "$base_branch""

    fetch --quiet

    git checkout -b "$branch" "$base_branch"

    if (( $? == 0 )); then
      ll_add_node_ "" "$(PWD)" "$base_branch"

      local remote_branch=$(git ls-remote --heads origin "$base_branch" | awk '{print $2}')

      if [[ -n "$remote_branch" ]]; then
        git config branch."$branch".gh-merge-base "$remote_branch"
      else
        git config branch."$branch".gh-merge-base "$base_branch"
      fi
      return 0;
    fi

    return 1;
  fi

  # co -e branch just checkout, do not create branch
  if (( co_is_e )); then
    print_debug_ "co -e asking for: $@"

    local branch="$1"

    if [[ -z "$branch" ]]; then
      print " branch is required" >&2
      print " ${yellow_cor} co -e <branch>${reset_cor} : to switch to exact branch" >&2
      print " ${yellow_cor} co -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    local current_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
    local _past_folder="$(PWD)"

    git switch "$branch" --quiet

    if (( $? == 0 )); then
      ll_add_node_
      return 0;
    fi

    return 1;
  fi

  # co (no arguments)
  if [[ -z "$1" ]]; then
    print_debug_ "co (no arguments and no flags)"
    local branch_choice="$(select_branch_ --list)"
    print_debug_ "co - branch_choice: $branch_choice"

    if [[ -z "$branch_choice" ]]; then
      return 1;
    fi

    co -e $branch_choice
    return $?
  fi

  # co branch (no flags, no base branch)
  if [[ -z "$2" ]]; then
    print_debug_ "co asking for: $1 (no flags)"
    co -a $1
    return $?
  fi

  print_debug_ "co asking for: $@"
  # co branch BASE_BRANCH (creating branch)
  local branch="$1"
  
  local choices=$(git branch -a --list --format="%(refname:strip=2)" | grep -i "$2" | sed 's/^[* ]*//g' | sed -e 's/HEAD//' | sed -e 's/remotes\///' | sed -e 's/HEAD -> origin\///' | sed -e 's/origin\///' | sort -fu)
  if [[ -z "$choices" ]]; then
    print " did not match any branch known to git: $2" >&2
    return 1;
  fi

  local base_branch=$(choose_auto_one_ "search base branch:" $(echo "$choices" | tr ' ' '\n'))

  if [[ -z "$base_branch" ]]; then
    return 0;
  fi

  local current_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

  fetch --quiet

  git switch "$base_branch" --quiet
  if (( $? != 0 )); then return 1; fi

  pull --quiet
  git branch "$branch" "$base_branch" # create branch
  if (( $? != 0 )); then return 1; fi

  git switch "$branch"
  if (( $? != 0 )); then return 1; fi

  ll_add_node_ "" "$(PWD)" "$current_branch"

  local remote_branch=$(git ls-remote --heads origin "$base_branch" | awk '{print $2}')

  if [[ -n "$remote_branch" ]]; then
    git config branch."$branch".gh-merge-base "$remote_branch"
  else
    git config branch."$branch".gh-merge-base "$base_branch"
  fi
}

function next() {
  eval "$(parse_flags_ "next_" "" "$@")"

  if (( next_is_h )); then
    print "${yellow_cor} next${reset_cor} : to go the next folder and branch"
    return 0;
  fi

  if [[ -z "$head" ]]; then
    print " no next folder or branch found" >&2
    return 1;
  fi

  $head=$ll_next[$head]
  open_working_
}

function prev() {
  eval "$(parse_flags_ "prev_" "" "$@")"

  if (( prev_is_h )); then
    print "${yellow_cor} prev${reset_cor} : to go the previous folder and branch"
    return 0;
  fi

  if [[ -z "$head" ]]; then
    print " no previous folder or branch found" >&2
    return 1;
  fi

  $head=$ll_prev[$head]
  open_working_
}

function open_working_() {
  local project="$node_project[$head]"
  local folder="$node_folder[$head]"
  local branch="$node_branch[$head]"

  print_debug_ "head: $head - $project - $folder - $branch"

  local past_folder="$(PWD)"
  local past_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
  
  if [[ -n "$folder" ]]; then
    pushd "$folder" &>/dev/null
    if (( $? == 0 )); then
      if [[ -n "$branch" ]]; then
        co -ex "$branch"
        ll_add_node_ "$project" "$past_folder" "$past_branch"
      fi
    fi
  elif [[ -n "$branch" ]]; then
    co -ex "$branch"
  fi
}

# checkout dev or develop branch
function dev() {
  eval "$(parse_flags_ "dev_" "" "$@")"

  if (( dev_is_h )); then
    print "${yellow_cor} dev${reset_cor} : to switch to dev or develop in current project"
    return 0;
  fi

  if [[ -n "$(git branch -a --list | grep -w dev)" ]]; then
    co -e dev
  elif [[ -n "$(git branch -a --list | grep -w develop)" ]]; then
    co -e develop
  else
    print " did not match a dev or develop branch known to git: $1" >&2
    return 1;
  fi
}

# checkout main branch
function main() {
  eval "$(parse_flags_ "main_" "" "$@")"

  if (( main_is_h )); then
    print "${yellow_cor} main${reset_cor} : to switch to main in current project"
    return 0;
  fi

  if [[ -n "$(git branch -a --list | grep -w main)" ]]; then
    co -e main
  elif [[ -n "$(git branch -a --list | grep -w master)" ]]; then
    co -e master
  else
    print " did not match a main branch known to git: $1" >&2
    return 1;
  fi
}

# checkout stage branch
function stage() {
  eval "$(parse_flags_ "stage_" "" "$@")"

  if (( stage_is_h )); then
      print "${yellow_cor} main${reset_cor} : to switch to stage or staging in current project"
    return 0;
  fi

  if [[ -n "$(git branch -a --list | grep -w stage)" ]]; then
    co -e stage
  elif [[ -n "$(git branch -a --list | grep -w staging)" ]]; then
    co -e staging
  else
    print " did not match a stage or staging branch known to git: $1" >&2
    return 1;
  fi
}

# Merging & Rebasing -----------------------------------------------------------------------=
# rebase $1 or main
function rebase() {
  eval "$(parse_flags_ "rebase_" "" "$@")"

  if (( rebase_is_h )); then
      print "${yellow_cor} rebase${reset_cor} : to apply the commits from your branch on top of the HEAD commit of $(git config --get init.defaultBranch)"
      print "${yellow_cor} rebase${solid_yellow_cor} [<branch>]${reset_cor} : to apply the commits from your branch on top of the HEAD commit of a branch"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
  local default_main_branch="$(git config --get init.defaultBranch)"
  local main_branch="${1:-$default_main_branch}"

  if [[ "$my_branch" == "$default_main_branch" ]]; then
    print " cannot rebase, branches are the same" >&2
    return 1;
  fi

  git fetch origin --quiet

  print " rebase from branch${blue_cor} "$main_branch" ${reset_cor}"
  git rebase origin/"$main_branch"

  if (( $? == 0 )); then
    if confirm_from_ "done. now git push?"; then
      git push --force-with-lease --no-verify --set-upstream origin "$my_branch"
    fi
  fi
}

# merge branch $1 or default branch
function merge() {
  eval "$(parse_flags_ "merge_" "" "$@")"

  if (( merge_is_h )); then
      print "${yellow_cor} merge${reset_cor} : to create a new merge commit from $(git config --get init.defaultBranch)"
      print "${yellow_cor} merge${solid_yellow_cor} [<branch>]${reset_cor} : to create a new merge commit from a branch"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
  local default_main_branch="$(git config --get init.defaultBranch)"
  local main_branch="${1:-$default_main_branch}"

  if [[ "$my_branch" == "$default_main_branch" ]]; then
    print " cannot merge, branches are the same" >&2
    return 1;
  fi

  git fetch origin --quiet

  print " merge from branch${blue_cor} "$main_branch" ${reset_cor}"
  git merge origin/"$main_branch" --no-edit

  if (( $? == 0 )); then
    if confirm_from_ "done. now git push?"; then
      git push --no-verify --set-upstream origin "$my_branch"
    fi
  fi
}

# Delete branches ===========================================================
function prune() {
  eval "$(parse_flags_ "prune_" "" "$@")"

  if (( prune_is_h )); then
      print "${yellow_cor} prune${reset_cor} : to clean up unreachable or orphaned git branches and tags"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  local default_main_branch="$(git config --get init.defaultBranch)"

  # delets all tags
  git tag -l | xargs git tag -d >/dev/null
  # fetch tags that exist in the remote
  git fetch origin --prune --prune-tags --force
  
  # lists all branches that have been merged into the currently checked-out branch
  # that can be safely deleted without losing any unmerged work and filters out the default branch
  local branches=$(git branch --merged | grep -v "^\*\\|$default_main_branch")

  for branch in $branches; do
    git config --remove-section branch."$branch" &>/dev/null
    git branch -D "$branch"
  done

  local current_branches=$(git branch --format '%(refname:short)')

  # Loop through all Git config sections to find old branches
  for config in $(git config --get-regexp "^branch\." | awk '{print $1}'); do
    local branch_name="${config#branch.}"

    # Check if the branch exists locally
    if ! echo "$current_branches" | grep -q "^$branch_name$"; then
      git config --remove-section "branch."$branch_name"" &>/dev/null
    fi
  done

  git prune "$@"
}

# list branches and select one to delete or delete $1
function delb() {
  eval "$(parse_flags_ "delb_" "s" "$@")"

  if (( delb_is_h )); then
    print "${yellow_cor} delb${solid_yellow_cor} [<branch>]${reset_cor} : to find branches to delete"
    print "${yellow_cor} delb <branch>${solid_yellow_cor} [<branch>]${reset_cor} : to find branches to delete"
    print "${yellow_cor} delb -s${reset_cor} : to delete without confirmation"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  local branch_arg="$1"
  local is_deleted=1;

  local selected_branches=($(select_branch_ --list "$branch_arg" 1))
  for branch in ${selected_branches[@]}; do
    if (( ! delb_is_s )); then
      local confirm_msg="delete local branch: "$'\e[0;95m'$branch$'\e[0m'"?"
      confirm_from_ $confirm_msg
      RET=$?
      if (( RET == 130 )); then
        break;
      elif (( RET == 1 )); then
        continue;
      fi
    fi

    git config --remove-section branch."$branch" &>/dev/null
    git branch -D "$branch"
    is_deleted=$?
  done

  if (( ! is_deleted )); then
    delete_pump_workings_ "$pump_working_branch" "$proj_arg" "$selected_branches"
  fi

  cd "$_pwd"
}

function delete_pump_working_(){
  local item="$1"
  local pump_working_branch="$2"
  local proj_arg="$3"

  if [[ -z "$pump_working_branch" || -z "$proj_arg" ]]; then
    return 0;
  fi

  if [[ "$item" == "$pump_working_branch" ]]; then
    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        rm -f "${PUMP_WORKING_FILE[$i]}"
        PUMP_WORKING[$i]=""
        break
      fi
    done
  fi
}

function delete_pump_workings_(){
  local pump_working_branch="$1"
  local proj_arg="$2"
  local selected_items="$3"

  if [[ -z "$pump_working_branch" || -z "$proj_arg" ]]; then
    return 0;
  fi

  for item in $selected_items; do
    delete_pump_working_ "$item" "$pump_working_branch" "$proj_arg"
  done
}

function pop() {
  eval "$(parse_flags_ "pop_" "a" "$@")"

  if (( pop_is_h )); then
    print "${yellow_cor} pop${reset_cor} : to pop stash"
    print "${yellow_cor} pop -a${reset_cor} : to pop all stashes"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  if (( pop_is_a )); then
    git stash list | awk '{print $1}' | xargs git stash pop --index
  else
    git stash pop --index
  fi
}

function st() {
  eval "$(parse_flags_ "st_" "" "$@")"

  if (( st_is_h )); then
    print "${yellow_cor} st${reset_cor} : to show git status"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  git status -sb $@
}

function stashes() {
  eval "$(parse_flags_ "stashes_" "" "$@")"

  if (( stashes_is_h )); then
    print "${yellow_cor} stashes${reset_cor} : to show git stashes"
    return 0;
  fi

  check_git_; if (( $? != 0 )); then return 1; fi

  git stash list
}

function load_config_entry_() {
  local i=${1:-0}

  keys=(
    Z_PROJECT_REPO
    Z_PROJECT_SINGLE_MODE
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
        Z_PROJECT_SINGLE_MODE)
          value="0"
          ;;
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
      Z_PROJECT_SINGLE_MODE)
        Z_PROJECT_SINGLE_MODE[$i]="$value"
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
        Z_GHA_WORKFLOW[$i]=$(echo "$value" | tr -d '"')
        ;;
      Z_PUSH_ON_REFIX)
        Z_PUSH_ON_REFIX[$i]="$value"
        ;;
      Z_PRINT_README)
        Z_PRINT_README[$i]="$value"
        ;;
    esac
    # print "$i - key: $key, value: $value"
  done
}

function load_config_() {
  load_config_entry_
  # Iterate over the first 10 project configurations
  local i=0
  for i in {1..9}; do
    local short_name=$(sed -n "s/^Z_PROJECT_SHORT_NAME_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE")
    [[ -z "$short_name" ]] && continue  # Skip if not defined

    Z_PROJECT_SHORT_NAME[$i]=$short_name
    # echo "$i - key: Z_PROJECT_SHORT_NAME, value: $short_name"

    print_debug_ "$i - key: Z_PROJECT_SHORT_NAME, value: $short_name"

    # Set project folder path
    local _folder=$(sed -n "s/^Z_PROJECT_FOLDER_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE")
    Z_PROJECT_FOLDER[$i]=$_folder
    # echo "$i - key: Z_PROJECT_FOLDER, value: $realfolder"

    print_debug_ "$i - key: Z_PROJECT_FOLDER, value: $_folder"

    load_config_entry_ $i
  done
}

load_config_
clear_curr_prj_

PUMP_PRO_FILE="$(dirname "$0")/.pump"

# auto pro ===============================================================
# pro pwd
function activate_pro_() {
  print_debug_ "pro pwd"

  pro -f pwd &>/dev/null
  if (( $? != 0 )); then
    # Read the current project short name from the PUMP_PRO_FILE if it exists
    pump_pro_file_value=""
    if [[ -f "$PUMP_PRO_FILE" ]]; then
      pump_pro_file_value=$(<"$PUMP_PRO_FILE")

      if [[ -n "$pump_pro_file_value" ]]; then
        local i=0
        for i in {1..9}; do
          if [[ "$pump_pro_file_value" == "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
            check_prj_name_ $i "$pump_pro_file_value" >/dev/null
            if (( $? != 0 )); then
              rm -f "$PUMP_PRO_FILE" &>/dev/null
              pump_pro_file_value=""
            fi
            break;
          fi
        done
      fi
    fi

    # Create an array of project names to loop through
    project_names=("$pump_pro_file_value")

    # Loop through 1 to 10 to add additional project names to the array
    local i=0
    for i in {1..9}; do
      if [[ -n "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
        if [[ ! " ${project_names[@]} " =~ " ${Z_PROJECT_SHORT_NAME[$i]} " ]]; then
          project_names+=("${Z_PROJECT_SHORT_NAME[$i]}")
        fi
      fi
    done
    
    # Remove any empty values in the array (e.g., if $pump_pro_file_value is empty)
    project_names=("${project_names[@]/#/}")

    #print "project_names: ${project_names[@]}"

    # Loop over the projects to check and execute them
    for project in "${project_names[@]}"; do
      if [[ -n "$project" ]]; then
        #print " pro project: $project"
        pro -f "$project" # &>/dev/null
        if (( $? == 0 )); then
          #print "good: $project"
          break  # Exit loop once a valid project is found and executed successfully
        else
          #print "bad: $project"
        fi
      fi
    done
  fi
}

activate_pro_
# ==========================================================================

# project functions =========================================================
function z_project_handler_() { # pump() project()
  local i="$1"
  shift

  eval "$(parse_flags_ "z_project_handler_" "lm" "$@")"
  
  local proj_folder=$(get_prj_folder_ -s $i "$Z_PROJECT_FOLDER[$i]")
  if [[ -z "$proj_folder" ]]; then return 1; fi

  local short_name="${Z_PROJECT_SHORT_NAME[$i]}"
  local working="${PUMP_WORKING[$i]}"

  local single_mode=$(is_project_single_mode_ $i)

  if (( z_project_handler_is_h )); then
    print "${yellow_cor} $short_name ${reset_cor}: to set project to $short_name and cd into it"
    (( ! single_mode )) && print "${yellow_cor} $short_name -l${reset_cor}: to list all folders in $short_name"
    print "${yellow_cor} $short_name -m${reset_cor}: to set project to $short_name and cd into the default branch folder (in multiple mode or branch in single mode)"
    print "${yellow_cor} $short_name <folder> ${reset_cor}: to set project to $short_name, cd into folder"
    (( single_mode )) && print "${yellow_cor} $short_name <folder> <branch> ${reset_cor}: to set project to $short_name, cd into folder and switch to branch"
    return 0;
  fi

  if (( z_project_handler_is_l )); then
    local folders=($(get_folders_ "$proj_folder"))
    if [[ -n "${folders[*]}" ]]; then
      for folder in "${folders[@]}"; do
        print "${pink_cor} $folder ${reset_cor}"
      done
    else
      print " no folders"
    fi
    return 0;
  fi

  print_debug_ "z_project_handler_: single_mode: $single_mode, proj_folder: $proj_folder"

  local folder_arg=""
  local branch_arg=""

  print_debug_ "z_project_handler_: \$1: $1, \$2: $2, \$3: $3"

  local use_default_folder=0

  if [[ -n "$2" ]]; then
    (( single_mode )) && branch_arg="$2"
    folder_arg="$1"
  elif [[ -n "$1" ]]; then
    if [[ -d "$proj_folder/$1" ]] || (( ! single_mode )); then
      folder_arg="$1"
    else
      branch_arg="$1"
    fi
  elif (( z_project_handler_is_m )); then
    if (( ! single_mode )); then
      use_default_folder=1
      folder_arg="$(get_default_folder_ "$proj_folder")"
    fi
  fi

  # resolve folder_arg
  if (( single_mode )); then
    folder_arg="$proj_folder"
  else
    if [[ -n "$folder_arg" && -d "${proj_folder}/${folder_arg}" ]]; then
      (( ! use_default_folder )) && folder_arg="${proj_folder}/${folder_arg}"
    else
      folder_arg="$proj_folder"
      local folders=($(get_folders_ "$proj_folder"))
      if [[ -n "${folders[*]}" ]]; then
        local chosen_folder=($(choose_auto_one_ "choose folder" "${folders[@]}"))
        print_debug_ "z_project_handler_: chosen_folder: $chosen_folder"
        if [[ -n "$chosen_folder" ]]; then
          folder_arg="${proj_folder}/${chosen_folder}"
        fi
      fi
    fi
  fi

  print_debug_ "z_project_handler_: folder_arg: $folder_arg, branch_arg: $branch_arg"

  pro "$short_name"

  if [[ -n "$folder_arg" ]]; then
    pushd "$folder_arg" &>/dev/null
  fi

  if (( single_mode )); then
    if [[ -n "$branch_arg" ]]; then
      co "$branch_arg"
    else
      # get default branch
      local default_branch=$(git config --get init.defaultBranch)
      co -e "$default_branch"
    fi
  fi

  # if [[ -n "$folder_arg" ]]; then
  #   pushd "$folder_arg" &>/dev/null
  #   if (( $? == 0 )); then
  #     print_debug_ "z_project_handler_: checking is_git_repo_"
  #     if is_git_repo_; then
  #       print_debug_ "z_project_handler_: is_git_repo_ is true"
  #       local past_branch="$(git branch --show-current)"
  


  #       if (( $? == 0 )); then
  #         ll_add_node_ "$short_name" "$past_folder" "$past_branch"
  #       fi
  #     fi
  #   fi
  # fi

}

local i=0
for i in {1..9}; do
  if [[ -n "${Z_PROJECT_SHORT_NAME[$i]}" ]]; then
    eval "
      function ${Z_PROJECT_SHORT_NAME[$i]}() {
        z_project_handler_ $i \"\$@\"
      }
    "
  fi
done

# ==========================================================================
# 1>/dev/null or >/dev/null	  Hide stdout, show stderr
# 2>/dev/null                 show stdout, hide stderr
# &>/dev/null	                Hide both stdout and stderr outputs
