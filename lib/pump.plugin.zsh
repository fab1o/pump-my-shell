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
  update_ "-f";

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

  _pro=$(which_pro_pwd)
  proj_folder=""
  pump_working_branch=""

  if [[ -n "$_pro" ]]; then
    if [[ "$_pro" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
      proj_folder="$Z_PROJECT_FOLDER_1"
      pump_working_branch="$PUMP_WORKING_BRANCH_1"
    elif [[ "$_pro" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
      proj_folder="$Z_PROJECT_FOLDER_2"
      pump_working_branch="$PUMP_WORKING_BRANCH_2"
    elif [[ "$_pro" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      proj_folder="$Z_PROJECT_FOLDER_3"
      pump_working_branch="$PUMP_WORKING_BRANCH_3"
    fi
  fi

  if [[ -z "$1" ]]; then
    if [[ -n ${(f)"$(get_folders_)"} ]]; then
      folders=($(get_folders_))
      selected_folders=($(gum choose --no-limit --height 20 --header=" choose folder to delete" "${folders[@]}"))

      for folder in "${selected_folders[@]}"; do
        if [[ -n "$pump_working_branch" && -n "$_pro" ]]; then
          if [[ "$folder" == "$pump_working_branch" ]]; then
            if [[ "$_pro" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
              rm -f "$PUMP_WORKING_BRANCH_FILE_1"
              PUMP_WORKING_BRANCH_1=""
              pump_working_branch=""
            elif [[ "$_pro" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
              rm -f "$PUMP_WORKING_BRANCH_FILE_2"
              PUMP_WORKING_BRANCH_2=""
              pump_working_branch=""
            elif [[ "$_pro" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
              rm -f "$PUMP_WORKING_BRANCH_FILE_3"
              PUMP_WORKING_BRANCH_3=""
              pump_working_branch=""
            fi
          fi
        fi
      
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
      echo "$i"
      folder="${i%/}"

      if [[ -n "$pump_working_branch" && -n "$_pro" ]]; then
        if [[ "$folder" == "$pump_working_branch" ]]; then
          if [[ "$_pro" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
            rm -f "$PUMP_WORKING_BRANCH_FILE_1"
            PUMP_WORKING_BRANCH_1=""
            pump_working_branch=""
          elif [[ "$_pro" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
            rm -f "$PUMP_WORKING_BRANCH_FILE_2"
            PUMP_WORKING_BRANCH_2=""
            pump_working_branch=""
          elif [[ "$_pro" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
            rm -f "$PUMP_WORKING_BRANCH_FILE_3"
            PUMP_WORKING_BRANCH_3=""
            pump_working_branch=""
          fi
        fi
      fi
  
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
          confirm_from_ "delete all remaining $pattern?"
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

        if [[ "$folder" == "$pump_working_branch" ]]; then
          if [[ "$_pro" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
            rm -f "$PUMP_WORKING_BRANCH_FILE_1"
            PUMP_WORKING_BRANCH_1=""
            pump_working_branch=""
          elif [[ "$_pro" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
            rm -f "$PUMP_WORKING_BRANCH_FILE_2"
            PUMP_WORKING_BRANCH_2=""
            pump_working_branch=""
          elif [[ "$_pro" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
            rm -f "$PUMP_WORKING_BRANCH_FILE_3"
            PUMP_WORKING_BRANCH_3=""
            pump_working_branch=""
          fi
        fi
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
    if [[ "$folder" == "$pump_working_branch" ]]; then
      if [[ "$_pro" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
        rm -f "$PUMP_WORKING_BRANCH_FILE_1"
        PUMP_WORKING_BRANCH_1=""
        pump_working_branch=""
      elif [[ "$_pro" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
        rm -f "$PUMP_WORKING_BRANCH_FILE_2"
        PUMP_WORKING_BRANCH_2=""
        pump_working_branch=""
      elif [[ "$_pro" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
        rm -f "$PUMP_WORKING_BRANCH_FILE_3"
        PUMP_WORKING_BRANCH_3=""
        pump_working_branch=""
      fi
    fi
  fi

  gum spin --title "deleting... $file_path" -- rm -rf "$file_path"
  echo "${magenta_cor} deleted${blue_cor} $file_path_log ${clear_cor}"

  if [[ -n "$folder_to_move" ]]; then
    cd "$folder_to_move"
  fi
}

update_() {
  RELEASE_API="https://api.github.com/repos/fab1o/pump-my-shell/releases/latest"
  LATEST_VERSION=$(curl -s $RELEASE_API | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

  if [[ -n "$LATEST_VERSION" && "$PUMP_VERSION" != "$LATEST_VERSION" ]]; then
    echo " new version available for pump-my-shell:${yellow_cor} $PUMP_VERSION -> $LATEST_VERSION ${clear_cor}"

    if [[ -z "$1" ]]; then
      if ! confirm_from_ "do you want to install new version?"; then
        return 0;
      fi
    fi

    echo " if you encounter an error after installation, don't worry — simply restart your terminal"

    /bin/bash -c "$(curl -H "Cache-Control: no-cache" -fsSL https://raw.githubusercontent.com/fab1o/pump-my-shell/refs/heads/main/scripts/update.sh)"
    return 1;
  else
    if [[ -n "$1" ]]; then
      echo " no update available for pump-my-shell:${yellow_cor} $PUMP_VERSION ${clear_cor}"
    fi
  fi
}

# ========================================================================
# Project configuration
PUMP_CONFIG_FILE="$(dirname "$0")/config/pump.zshenv"

if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
  echo "${red_cor} fatal: config file '$PUMP_CONFIG_FILE' does not exist, re-install pump-my-shell ${clear_cor}"
  return 1
fi

PUMP_PRO_FILE="$(dirname "$0")/.pump"
PUMP_VERSION="0.0.0"
PUMP_WORKING_BRANCH_1=""
PUMP_WORKING_BRANCH_2=""
PUMP_WORKING_BRANCH_3=""

_version_file_path="$(dirname "$0")/.version"
[[ -f "$_version_file_path" ]] && PUMP_VERSION=$(<"$_version_file_path")

PUMP_WORKING_BRANCH_FILE_1="$(dirname "$0")/.working_branch_1"
[[ -f "$PUMP_WORKING_BRANCH_FILE_1" ]] && PUMP_WORKING_BRANCH_1=$(<"$PUMP_WORKING_BRANCH_FILE_1")

PUMP_WORKING_BRANCH_FILE_2="$(dirname "$0")/.working_branch_2"
[[ -f "$PUMP_WORKING_BRANCH_FILE_2" ]] && PUMP_WORKING_BRANCH_2=$(<"$PUMP_WORKING_BRANCH_FILE_2")

PUMP_WORKING_BRANCH_FILE_3="$(dirname "$0")/.working_branch_3"
[[ -f "$PUMP_WORKING_BRANCH_FILE_3" ]] && PUMP_WORKING_BRANCH_3=$(<"$PUMP_WORKING_BRANCH_FILE_3")
# ========================================================================

# project 1 ==============================================================
Z_PROJECT_FOLDER_1_=$(sed -n 's/^Z_PROJECT_FOLDER_1=\([^ ]*\)/\1/p' "$PUMP_CONFIG_FILE"); Z_PROJECT_FOLDER_1_="${Z_PROJECT_FOLDER_1_/#\~/$HOME}"
if [[ -n "$Z_PROJECT_FOLDER_1_" ]]; then
  Z_PROJECT_FOLDER_1_="${Z_PROJECT_FOLDER_1_%/}"
  Z_PROJECT_FOLDER_1=$(realpath "$Z_PROJECT_FOLDER_1_" 2>/dev/null)
fi
Z_PROJECT_SHORT_NAME_1=$(sed -n 's/^Z_PROJECT_SHORT_NAME_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PROJECT_REPO_1=$(sed -n 's/^Z_PROJECT_REPO_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PACKAGE_MANAGER_1=${$(sed -n 's/^Z_PACKAGE_MANAGER_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-npm}
Z_CODE_EDITOR_1=${$(sed -n 's/^Z_CODE_EDITOR_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-code}
Z_CLONE_1=$(sed -n 's/^Z_CLONE_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_SETUP_1=$(sed -n 's/^Z_SETUP_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_RUN_1=${$(sed -n 's/^Z_RUN_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_1 $([[ $Z_PACKAGE_MANAGER_1 == "yarn" ]] && echo "" || echo "run ")dev}
Z_RUN_STAGE_1=${$(sed -n 's/^Z_RUN_STAGE_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_1 $([[ $Z_PACKAGE_MANAGER_1 == "yarn" ]] && echo "" || echo "run ")stage}
Z_RUN_PROD_1=${$(sed -n 's/^Z_RUN_PROD_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_1 $([[ $Z_PACKAGE_MANAGER_1 == "yarn" ]] && echo "" || echo "run ")prod}
Z_PRO_1=$(sed -n 's/^Z_PRO_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_TEST_1=${$(sed -n 's/^Z_TEST_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_1 $([[ $Z_PACKAGE_MANAGER_1 == "yarn" ]] && echo "" || echo "run ")test}
Z_COV_1=${$(sed -n 's/^Z_COV_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_1 $([[ $Z_PACKAGE_MANAGER_1 == "yarn" ]] && echo "" || echo "run ")test:coverage}
Z_TEST_WATCH_1=${$(sed -n 's/^Z_TEST_WATCH_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_1 $([[ $Z_PACKAGE_MANAGER_1 == "yarn" ]] && echo "" || echo "run ")test:watch}
Z_E2E_1=${$(sed -n 's/^Z_E2E_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_1 $([[ $Z_PACKAGE_MANAGER_1 == "yarn" ]] && echo "" || echo "run ")test:e2e}
Z_E2EUI_1=${$(sed -n 's/^Z_E2EUI_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_1 $([[ $Z_PACKAGE_MANAGER_1 == "yarn" ]] && echo "" || echo "run ")test:e2e-ui}
Z_PR_TEMPLATE_1=$(sed -n 's/^Z_PR_TEMPLATE_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PR_REPLACE_1=$(sed -n 's/^Z_PR_REPLACE_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PR_APPEND_1=${$(sed -n 's/^Z_PR_APPEND_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-0}
Z_PR_RUN_TEST_1=$(sed -n 's/^Z_PR_RUN_TEST_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_GHA_INTERVAL_1=${$(sed -n 's/^Z_GHA_INTERVAL_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-10}
Z_COMMIT_ADD_1=$(sed -n 's/^Z_COMMIT_ADD_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_DEFAULT_BRANCH_1=$(sed -n 's/^Z_DEFAULT_BRANCH_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_GHA_WORKFLOW_1=$(sed -n 's/^Z_GHA_WORKFLOW_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PUSH_ON_REFIX_1=$(sed -n 's/^Z_PUSH_ON_REFIX_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PRINT_README_1=${$(sed -n 's/^Z_PRINT_README_1=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-0}

# project 2 ========================================================================
Z_PROJECT_FOLDER_2=""
Z_PROJECT_FOLDER_2_=$(sed -n 's/^Z_PROJECT_FOLDER_2=\([^ ]*\)/\1/p' "$PUMP_CONFIG_FILE"); Z_PROJECT_FOLDER_2_="${Z_PROJECT_FOLDER_2_/#\~/$HOME}"
if [[ -n "$Z_PROJECT_FOLDER_2_" ]]; then
  Z_PROJECT_FOLDER_2_="${Z_PROJECT_FOLDER_2_%/}"
  Z_PROJECT_FOLDER_2=$(realpath "$Z_PROJECT_FOLDER_2_" 2>/dev/null)
fi
Z_PROJECT_SHORT_NAME_2=$(sed -n 's/^Z_PROJECT_SHORT_NAME_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PROJECT_REPO_2=$(sed -n 's/^Z_PROJECT_REPO_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PACKAGE_MANAGER_2=${$(sed -n 's/^Z_PACKAGE_MANAGER_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-npm};
Z_CODE_EDITOR_2=${$(sed -n 's/^Z_CODE_EDITOR_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-code}
Z_CLONE_2=$(sed -n 's/^Z_CLONE_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_SETUP_2=$(sed -n 's/^Z_SETUP_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_RUN_2=${$(sed -n 's/^Z_RUN_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_2 $([[ $Z_PACKAGE_MANAGER_2 == "yarn" ]] && echo "" || echo "run ")dev}
Z_RUN_STAGE_2=${$(sed -n 's/^Z_RUN_STAGE_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_2 $([[ $Z_PACKAGE_MANAGER_2 == "yarn" ]] && echo "" || echo "run ")stage}
Z_RUN_PROD_2=${$(sed -n 's/^Z_RUN_PROD_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_2 $([[ $Z_PACKAGE_MANAGER_2 == "yarn" ]] && echo "" || echo "run ")prod}
Z_PRO_2=$(sed -n 's/^Z_PRO_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_TEST_2=${$(sed -n 's/^Z_TEST_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_2 $([[ $Z_PACKAGE_MANAGER_2 == "yarn" ]] && echo "" || echo "run ")test}
Z_COV_2=${$(sed -n 's/^Z_COV_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_2 $([[ $Z_PACKAGE_MANAGER_2 == "yarn" ]] && echo "" || echo "run ")test:coverage}
Z_TEST_WATCH_2=${$(sed -n 's/^Z_TEST_WATCH_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_2 $([[ $Z_PACKAGE_MANAGER_2 == "yarn" ]] && echo "" || echo "run ")test:watch}
Z_E2E_2=${$(sed -n 's/^Z_E2E_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_2 $([[ $Z_PACKAGE_MANAGER_2 == "yarn" ]] && echo "" || echo "run ")test:e2e}
Z_E2EUI_2=${$(sed -n 's/^Z_E2EUI_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_2 $([[ $Z_PACKAGE_MANAGER_2 == "yarn" ]] && echo "" || echo "run ")test:e2e-ui}
Z_PR_TEMPLATE_2=$(sed -n 's/^Z_PR_TEMPLATE_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PR_REPLACE_2=$(sed -n 's/^Z_PR_REPLACE_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PR_APPEND_2=${$(sed -n 's/^Z_PR_APPEND_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-0}
Z_PR_RUN_TEST_2=$(sed -n 's/^Z_PR_RUN_TEST_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_GHA_INTERVAL_2=${$(sed -n 's/^Z_GHA_INTERVAL_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-10}
Z_COMMIT_ADD_2=$(sed -n 's/^Z_COMMIT_ADD_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_DEFAULT_BRANCH_2=$(sed -n 's/^Z_DEFAULT_BRANCH_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_GHA_WORKFLOW_2=$(sed -n 's/^Z_GHA_WORKFLOW_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PUSH_ON_REFIX_2=$(sed -n 's/^Z_PUSH_ON_REFIX_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PRINT_README_2=${$(sed -n 's/^Z_PRINT_README_2=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-0}

# project 3 ========================================================================
Z_PROJECT_FOLDER_3=""
Z_PROJECT_FOLDER_3_=$(sed -n 's/^Z_PROJECT_FOLDER_3=\([^ ]*\)/\1/p' "$PUMP_CONFIG_FILE"); Z_PROJECT_FOLDER_3_="${Z_PROJECT_FOLDER_3_/#\~/$HOME}"
if [[ -n "$Z_PROJECT_FOLDER_3_" ]]; then
  Z_PROJECT_FOLDER_3_="${Z_PROJECT_FOLDER_3_%/}"
  Z_PROJECT_FOLDER_3=$(realpath "$Z_PROJECT_FOLDER_3_" 2>/dev/null)
fi
Z_PROJECT_SHORT_NAME_3=$(sed -n 's/^Z_PROJECT_SHORT_NAME_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PROJECT_REPO_3=$(sed -n 's/^Z_PROJECT_REPO_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PACKAGE_MANAGER_3=${$(sed -n 's/^Z_PACKAGE_MANAGER_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-npm};
Z_CODE_EDITOR_3=${$(sed -n 's/^Z_CODE_EDITOR_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-code}
Z_CLONE_3=$(sed -n 's/^Z_CLONE_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_SETUP_3=$(sed -n 's/^Z_SETUP_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_RUN_3=${$(sed -n 's/^Z_RUN_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_3 $([[ $Z_PACKAGE_MANAGER_3 == "yarn" ]] && echo "" || echo "run ")dev}
Z_RUN_STAGE_3=${$(sed -n 's/^Z_RUN_STAGE_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_3 $([[ $Z_PACKAGE_MANAGER_3 == "yarn" ]] && echo "" || echo "run ")stage}
Z_RUN_PROD_3=${$(sed -n 's/^Z_RUN_PROD_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_3 $([[ $Z_PACKAGE_MANAGER_3 == "yarn" ]] && echo "" || echo "run ")prod}
Z_PRO_3=$(sed -n 's/^Z_PRO_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_TEST_3=${$(sed -n 's/^Z_TEST_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_3 $([[ $Z_PACKAGE_MANAGER_3 == "yarn" ]] && echo "" || echo "run ")test}
Z_COV_3=${$(sed -n 's/^Z_COV_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_3 $([[ $Z_PACKAGE_MANAGER_3 == "yarn" ]] && echo "" || echo "run ")test:coverage}
Z_TEST_WATCH_3=${$(sed -n 's/^Z_TEST_WATCH_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_3 $([[ $Z_PACKAGE_MANAGER_3 == "yarn" ]] && echo "" || echo "run ")test:watch}
Z_E2E_3=${$(sed -n 's/^Z_E2E_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_3 $([[ $Z_PACKAGE_MANAGER_3 == "yarn" ]] && echo "" || echo "run ")test:e2e}
Z_E2EUI_3=${$(sed -n 's/^Z_E2EUI_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-$Z_PACKAGE_MANAGER_3 $([[ $Z_PACKAGE_MANAGER_3 == "yarn" ]] && echo "" || echo "run ")test:e2e-ui}
Z_PR_TEMPLATE_3=$(sed -n 's/^Z_PR_TEMPLATE_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PR_REPLACE_3=$(sed -n 's/^Z_PR_REPLACE_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PR_APPEND_3=${$(sed -n 's/^Z_PR_APPEND_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-0}
Z_PR_RUN_TEST_3=$(sed -n 's/^Z_PR_RUN_TEST_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_GHA_INTERVAL_3=${$(sed -n 's/^Z_GHA_INTERVAL_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-10}
Z_COMMIT_ADD_3=$(sed -n 's/^Z_COMMIT_ADD_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_DEFAULT_BRANCH_3=$(sed -n 's/^Z_DEFAULT_BRANCH_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_GHA_WORKFLOW_3=$(sed -n 's/^Z_GHA_WORKFLOW_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PUSH_ON_REFIX_3=$(sed -n 's/^Z_PUSH_ON_REFIX_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE)
Z_PRINT_README_3=${$(sed -n 's/^Z_PRINT_README_3=\([^ ]*\)/\1/p' $PUMP_CONFIG_FILE):-0}

Z_PROJECT_FOLDER=""
Z_PROJECT_SHORT_NAME=""
Z_PROJECT_REPO=""
Z_PACKAGE_MANAGER=""
Z_CODE_EDITOR=""
Z_CLONE=""
Z_SETUP=""
Z_RUN=""
Z_RUN_STAGE=""
Z_RUN_PROD=""
Z_PRO=""
Z_TEST=""
Z_COV=""
Z_TEST_WATCH=""
Z_E2E=""
Z_E2EUI=""
Z_PR_TEMPLATE=""
Z_PR_REPLACE=""
Z_PR_APPEND=""
Z_PR_RUN_TEST=""
Z_GHA_INTERVAL=""
Z_COMMIT_ADD=""
Z_DEFAULT_BRANCH=""
Z_GHA_WORKFLOW=""
Z_PUSH_ON_REFIX=""
Z_PRINT_README=""

PUMP_PAST_BRANCH=""

ERROR_PROJ=0;
ERROR_PROJ_1=0;
ERROR_PROJ_2=0;
ERROR_PROJ_3=0;

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
    echo " ${gray_cor}updated $key in the config ${clear_cor}"
  fi
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
    typed_value=$(gum input --no-show-help --placeholder="${2:-$1}")
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
  name=${1:-$Z_PROJECT_SHORT_NAME}

  invalid_proj_names=(
    "yarn" "npm" "pnpm" "bun" "back"
    "pro" "rev" "revs" "clone" "setup" "run" "test" "testw" "covc" "cov" "e2e" "e2eui" "recommit" "refix"
    "rdev" "dev" "stage" "prod" "gha" "pr" "push" "repush" "pushf" "add" "commit" "build" "i" "ig" "deploy" "fix" "format" "lint"
    "tsc" "start" "sbb" "sb" "renb" "co" "reseta" "clean" "delb" "prune" "discard" "restore"
    "st" "gconf" "fetch" "pull" "glog" "gll" "glr" "reset" "reset1" "reset2" "reset3" "reset4" "reset5" "reset6"
    "dtag" "tag" "tags" "pop" "stash" "stashes" "rebase" "merge" "rc" "conti" "mc" "chp" "chc" "abort"
    "cl" "del" "help" "kill" "ll" "nver" "nlist" "path" "refresh" "pwd" "empty" "upgrade" "-q" "quiet" "skip" "-" "." ".."
  )

  if [[ " ${invalid_proj_names[@]} " =~ " $name " ]]; then
    if [[ "$2" != "-q" ]]; then
      echo " project name is invalid, choose another one"
    fi
    return 1
  fi
}

save_project_1_() {
  if [[ -z "$Z_PROJECT_FOLDER_1_" ]]; then
    echo ""
    echo " type your project's folder path:"
    typed_folder_1=$(input_path_ "$HOME/pump-my-shell" $Z_PROJECT_FOLDER_1_)
    if [[ -n "$typed_folder_1" ]]; then
      check_prj_folder_1_ "-" "$typed_folder_1";
      if [[ $? -ne 0 ]]; then
        Z_PROJECT_FOLDER_1_=""
        return 1;
      fi
      echo "  $typed_folder_1"
      # Z_PROJECT_FOLDER_1_=$typed_folder_1 - check_prj_folder_1_ will do this
    else
      return 1;
    fi
  fi

  if [[ -z "$Z_PROJECT_SHORT_NAME_1" ]]; then
    echo " type your project's abbreviated name (one short word):"
    typed_name_1=$(input_name_ 10 "pump")
    if [[ -n "$typed_name_1" ]]; then
      if [[ "$typed_name_1" == "$Z_PROJECT_SHORT_NAME_2" || "$typed_name_1" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
        echo " project name already exists, please choose another one"
        return 1;
      fi
      check_proj_name_valid_ "$typed_name_1"; if [[ $? -ne 0 ]]; then return 1; fi
      echo "  $typed_name_1"
      Z_PROJECT_SHORT_NAME_1=$typed_name_1
    else
      return 1;
    fi
  fi

  if [[ -n "$typed_folder_1" || -n "$typed_name_1" ]]; then
    if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
      echo "${red_cor} fatal: config file '$PUMP_CONFIG_FILE' does not exist, re-install pump-my-shell ${clear_cor}"
      return 1
    fi

    cp -R "$PUMP_CONFIG_FILE" "$PUMP_CONFIG_FILE.$PUMP_VERSION.X.bak"

    # Update each key with its respective environment variable value
    if [[ -n "$typed_folder_1" ]]; then
      update_config_ "Z_PROJECT_FOLDER_1" "$typed_folder_1"
    fi

    if [[ -n "$typed_name_1" ]]; then
      update_config_ "Z_PROJECT_SHORT_NAME_1" "$typed_name_1"
    fi

    echo ""
    if [[ -n "$Z_PROJECT_SHORT_NAME_1" ]]; then
      echo " now run${yellow_cor} refresh${clear_cor}, then run${yellow_cor} $Z_PROJECT_SHORT_NAME_1 ${clear_cor}"
    else
      echo " now run${yellow_cor} refresh ${clear_cor}"
    fi
    echo ""
  fi
}

save_project_2_() {
  if [[ -z "$Z_PROJECT_FOLDER_2_" ]]; then
    echo ""
    echo " type your project's folder path:"
    typed_folder_2=$(input_path_ "$HOME/pump-my-shell" $Z_PROJECT_FOLDER_2_)
    if [[ -n "$typed_folder_2" ]]; then
      check_prj_folder_2_ "-" "$typed_folder_2";
      if [[ $? -ne 0 ]]; then
        Z_PROJECT_FOLDER_2_=""
        return 1;
      fi
      echo "  $typed_folder_2"
    else
      return 1;
    fi
  fi

  if [[ -z "$Z_PROJECT_SHORT_NAME_2" ]]; then
    echo " type your project's abbreviated name (one short word):"
    typed_name_2=$(input_name_ 10 "pump")
    if [[ -n "$typed_name_2" ]]; then
      if [[ "$typed_name_2" == "$Z_PROJECT_SHORT_NAME_1" || "$typed_name_2" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
        echo " project name already exists, please choose another one"
        return 1;
      fi
      check_proj_name_valid_ "$typed_name_2"; if [[ $? -ne 0 ]]; then return 1; fi
      echo "  $typed_name_2"
      Z_PROJECT_SHORT_NAME_2=$typed_name_2
    else
      return 1;
    fi
  fi

  if [[ -n "$typed_folder_2" || -n "$typed_name_2" ]]; then
    if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
      echo "${red_cor} fatal: config file '$PUMP_CONFIG_FILE' does not exist, re-install pump-my-shell ${clear_cor}"
      return 1
    fi

    cp -R "$PUMP_CONFIG_FILE" "$PUMP_CONFIG_FILE.$PUMP_VERSION.X.bak"

    # Update each key with its respective environment variable value
    if [[ -n "$typed_folder_2" ]]; then
      update_config_ "Z_PROJECT_FOLDER_2" "$typed_folder_2"
    fi

    if [[ -n "$typed_name_2" ]]; then
      update_config_ "Z_PROJECT_SHORT_NAME_2" "$typed_name_2"
    fi

    echo ""
    if [[ -n "$Z_PROJECT_SHORT_NAME_2" ]]; then
      echo " now run${yellow_cor} refresh${clear_cor}, then run${yellow_cor} $Z_PROJECT_SHORT_NAME_2 ${clear_cor}"
    else
      echo " now run${yellow_cor} refresh ${clear_cor}"
    fi
    echo ""
  fi
}

save_project_3_() {
  if [[ -z "$Z_PROJECT_FOLDER_3_" ]]; then
    echo ""
    echo " type your project's folder path:"
    typed_folder_3=$(input_path_ "$HOME/pump-my-shell" $Z_PROJECT_FOLDER_3_)
    if [[ -n "$typed_folder_3" ]]; then
      check_prj_folder_3_ "-" "$typed_folder_3";
      if [[ $? -ne 0 ]]; then
        Z_PROJECT_FOLDER_1_=""
        return 1;
      fi
      echo "  $typed_folder_3"
    else
      return 1;
    fi
  fi

  if [[ -z "$Z_PROJECT_SHORT_NAME_3" ]]; then
    echo " type your project's abbreviated name (one short word):"
    typed_name_3=$(input_name_ 10 "pump")
    if [[ -n "$typed_name_3" ]]; then
      if [[ "$typed_name_3" == "$Z_PROJECT_SHORT_NAME_1" || "$typed_name_3" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
        echo " project name already exists, please choose another one"
        return 1;
      fi
      check_proj_name_valid_ "$typed_name_3"; if [[ $? -ne 0 ]]; then return 1; fi
      echo "  $typed_name_3"
      Z_PROJECT_SHORT_NAME_3=$typed_name_3
    else
      return 1;
    fi
  fi

  if [[ -n "$typed_folder_3" || -n "$typed_name_3" ]]; then
    if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
      echo "${red_cor} fatal: config file '$PUMP_CONFIG_FILE' does not exist, re-install pump-my-shell ${clear_cor}"
      return 1
    fi

    cp -R "$PUMP_CONFIG_FILE" "$PUMP_CONFIG_FILE.$PUMP_VERSION.X.bak"

    # Update each key with its respective environment variable value
    if [[ -n "$typed_folder_3" ]]; then
      update_config_ "Z_PROJECT_FOLDER_3" "$typed_folder_3"
    fi

    if [[ -n "$typed_name_3" ]]; then
      update_config_ "Z_PROJECT_SHORT_NAME_3" "$typed_name_3"
    fi

    echo ""
    if [[ -n "$Z_PROJECT_SHORT_NAME_3" ]]; then
      echo " now run${yellow_cor} refresh${clear_cor}, then run${yellow_cor} $Z_PROJECT_SHORT_NAME_3 ${clear_cor}"
    else
      echo " now run${yellow_cor} refresh ${clear_cor}"
    fi
    echo ""
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
  total_width1=${3:-68}
  word2=$4
  total_width2=${5:-68}

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

  echo "$color $help_line_line ${clear_cor}"
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

  if [[ -n "$Z_PROJECT_SHORT_NAME" ]]; then
    echo ""
    echo "  your project is set to:${solid_blue_cor} $Z_PROJECT_SHORT_NAME${clear_cor} with${solid_magenta_cor} $Z_PACKAGE_MANAGER ${clear_cor}"
    echo "  to switch project, type:${solid_blue_cor} pro${clear_cor} or${solid_blue_cor} pro -h${clear_cor} to see usage"
  fi

  echo ""
  echo "  to learn more, visit:${blue_cor} https://github.com/fab1o/pump-my-shell/wiki ${clear_cor}"

  check_prj_1_ -q
  if [[ $ERROR_PROJ_1 -ne 0 ]]; then
    echo ""
    if [[ -z "$Z_PROJECT_FOLDER_1_" ]]; then
      echo " let's configure your first project!"
    fi
    
    save_project_1_

    if [[ -z "$Z_PROJECT_FOLDER_1" || -z "$Z_PROJECT_SHORT_NAME_1" ]]; then
      echo " configure${solid_yellow_cor} $PUMP_CONFIG_FILE${clear_cor} as shown in the example below:"
      echo ""
      echo " Z_PROJECT_FOLDER_1=${Z_PROJECT_FOLDER_1:-/Users/fab1o/Developer/pump-my-shell}"
      echo " Z_PROJECT_SHORT_NAME_1=${Z_PROJECT_SHORT_NAME_1:-pump}"
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
  echo " ${solid_blue_cor} pro ${clear_cor}\t\t = switch project"

  if [[ -n "$Z_PROJECT_FOLDER_1" && -n "$Z_PROJECT_SHORT_NAME_1" ]] then
    echo " ${solid_blue_cor} $Z_PROJECT_SHORT_NAME_1 ${clear_cor}$([ ${#Z_PROJECT_SHORT_NAME_1} -lt 5 ] && echo -e "\t\t = set project and cd $(shorten_path_ "$Z_PROJECT_FOLDER_1" 1 no)" || echo -e "\t = set project and cd $(shorten_path_ "$Z_PROJECT_FOLDER_1" 1)")";
  fi
  if [[ -n "$Z_PROJECT_FOLDER_2" && -n "$Z_PROJECT_SHORT_NAME_2" ]] then
    echo " ${solid_blue_cor} $Z_PROJECT_SHORT_NAME_2 ${clear_cor}$([ ${#Z_PROJECT_SHORT_NAME_2} -lt 5 ] && echo -e "\t\t = set project and cd $(shorten_path_ "$Z_PROJECT_FOLDER_2" 1 no)" || echo -e "\t = set project and cd $(shorten_path_ "$Z_PROJECT_FOLDER_2" 1)")";
  fi
  if [[ -n "$Z_PROJECT_FOLDER_3" && -n "$Z_PROJECT_SHORT_NAME_3" ]] then
    echo " ${solid_blue_cor} $Z_PROJECT_SHORT_NAME_3 ${clear_cor}$([ ${#Z_PROJECT_SHORT_NAME_3} -lt 5 ] && echo -e "\t\t = set project and cd $(shorten_path_ "$Z_PROJECT_FOLDER_3" 1 no)" || echo -e "\t = set project and cd $(shorten_path_ "$Z_PROJECT_FOLDER_3" 1)")";
  fi

  echo ""
  help_line_ "project" "${blue_cor}"
  echo ""
  echo " ${blue_cor} clone ${clear_cor}\t = clone project or branch"
  _setup=${Z_SETUP:-$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")setup}
  if (( ${#_setup} > 50 )); then
    echo " ${blue_cor} setup ${clear_cor}\t = ${_setup[1,50]}"
  else
    echo " ${blue_cor} setup ${clear_cor}\t = $_setup"
  fi
  if (( ${#Z_RUN} > 50 )); then
    echo " ${blue_cor} run ${clear_cor}\t\t = ${Z_RUN[1,50]}"
  else
    echo " ${blue_cor} run ${clear_cor}\t\t = $Z_RUN"
  fi
  if (( ${#Z_RUN_STAGE} > 50 )); then
    echo " ${blue_cor} run stage ${clear_cor}\t = ${Z_RUN_STAGE[1,50]}"
  else
    echo " ${blue_cor} run stage ${clear_cor}\t = $Z_RUN_STAGE"
  fi
  if (( ${#Z_RUN_PROD} > 50 )); then
    echo " ${blue_cor} run prod ${clear_cor}\t = ${Z_RUN_PROD[1,50]}"
  else
    echo " ${blue_cor} run prod ${clear_cor}\t = $Z_RUN_PROD"
  fi

  echo ""
  help_line_ "code review" "${cyan_cor}"
  echo ""
  echo " ${cyan_cor} rev ${clear_cor}\t\t = select branch to review"
  echo " ${cyan_cor} rev \$1${clear_cor}\t = open a review"
  echo " ${cyan_cor} revs ${clear_cor}\t\t = list existing reviews"
  echo " ${cyan_cor} prune revs ${clear_cor}\t = delete merged reviews"

  pause_output  # Wait for user input to continue
  if [[ $? -ne 0 ]]; then
    return 0;
  fi

  help_line_ "$Z_PACKAGE_MANAGER" "${solid_magenta_cor}"
  echo ""
  echo " ${solid_magenta_cor} build ${clear_cor}\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")build"
  echo " ${solid_magenta_cor} deploy ${clear_cor}\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")deploy"
  echo " ${solid_magenta_cor} fix ${clear_cor}\t\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")format + lint"
  echo " ${solid_magenta_cor} format ${clear_cor}\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")format"
  echo " ${solid_magenta_cor} i ${clear_cor}\t\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")install"
  echo " ${solid_magenta_cor} ig ${clear_cor}\t\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")install global"
  echo " ${solid_magenta_cor} lint ${clear_cor}\t\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")lint"
  echo " ${solid_magenta_cor} rdev ${clear_cor}\t\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")dev"
  echo " ${solid_magenta_cor} sb ${clear_cor}\t\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook"
  echo " ${solid_magenta_cor} sbb ${clear_cor}\t\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook:build"
  echo " ${solid_magenta_cor} start ${clear_cor}\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")start"
  echo " ${solid_magenta_cor} tsc ${clear_cor}\t\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")tsc"
  
  echo ""
  help_line_ "test $Z_PROJECT_SHORT_NAME" "${magenta_cor}"
  echo ""
  if [[ "$Z_COV" != "$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage" ]]; then
    echo " ${solid_magenta_cor} ${Z_PACKAGE_MANAGER:0:1}cov ${clear_cor}\t\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage"
  fi
  if [[ "$Z_E2E" != "$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e" ]]; then
    echo " ${solid_magenta_cor} ${Z_PACKAGE_MANAGER:0:1}e2e ${clear_cor}\t\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e"
  fi
  if [[ "$Z_E2EUI" != "$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui" ]]; then
    echo " ${solid_magenta_cor} ${Z_PACKAGE_MANAGER:0:1}e2eui ${clear_cor}\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui"
  fi
  if [[ "$Z_TEST" != "$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test" ]]; then
    echo " ${solid_magenta_cor} ${Z_PACKAGE_MANAGER:0:1}test ${clear_cor}\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test"
  fi
  if [[ "$Z_TEST_WATCH" != "$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch" ]]; then
    echo " ${solid_magenta_cor} ${Z_PACKAGE_MANAGER:0:1}testw ${clear_cor}\t = $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch"
  fi
  echo " ${magenta_cor} cov ${clear_cor}\t\t = $Z_COV"
  echo " ${magenta_cor} e2e ${clear_cor}\t\t = $Z_E2E"
  echo " ${magenta_cor} e2eui ${clear_cor}\t = $Z_E2EUI"
  echo " ${magenta_cor} test ${clear_cor}\t\t = $Z_TEST"
  echo " ${magenta_cor} testw ${clear_cor}\t = $Z_TEST_WATCH"

  echo ""
  help_line_ "git" "${solid_cyan_cor}"
  echo ""
  echo " ${solid_cyan_cor} gconf ${clear_cor}\t = git config"
  echo " ${solid_cyan_cor} gha ${clear_cor}\t\t = view last workflow run"
  echo " ${solid_cyan_cor} st ${clear_cor}\t\t = git status"
  
  pause_output  # Wait for user input to continue
  if [[ $? -ne 0 ]]; then
    return 0;
  fi

  help_line_ "git branch" "${solid_cyan_cor}"
  echo ""
  echo " ${solid_cyan_cor} back ${clear_cor}\t\t = go back to previous branch"
  echo " ${solid_cyan_cor} co ${clear_cor}\t\t = switch branch"
  echo " ${solid_cyan_cor} co \$1 \$2 ${clear_cor}\t = create branch off of \$2"
  echo " ${solid_cyan_cor} dev ${clear_cor}\t\t = switch to develop or dev"
  echo " ${solid_cyan_cor} main ${clear_cor}\t\t = switch to master or main"
  echo " ${solid_cyan_cor} renb \$1${clear_cor}\t = rename branch"
  echo " ${solid_cyan_cor} stage ${clear_cor}\t = switch to staging or stage"

  echo ""
  help_line_ "git clean" "${solid_cyan_cor}"
  echo ""
  echo " ${solid_cyan_cor} clean${clear_cor}\t\t = clean + restore"
  echo " ${solid_cyan_cor} delb ${clear_cor}\t\t = delete branches"
  echo " ${solid_cyan_cor} discard ${clear_cor}\t = reset local changes"
  echo " ${solid_cyan_cor} prune ${clear_cor}\t = prune branches and tags"
  echo " ${solid_cyan_cor} reset1 ${clear_cor}\t = reset soft 1 commit"
  echo " ${solid_cyan_cor} reset2 ${clear_cor}\t = reset soft 2 commits"
  echo " ${solid_cyan_cor} reset3 ${clear_cor}\t = reset soft 3 commits"
  echo " ${solid_cyan_cor} reset4 ${clear_cor}\t = reset soft 4 commits"
  echo " ${solid_cyan_cor} reset5 ${clear_cor}\t = reset soft 5 commits"
  echo " ${solid_cyan_cor} reseta ${clear_cor}\t = reset hard origin + clean"
  echo " ${solid_cyan_cor} restore ${clear_cor}\t = undo edits since last commit"
  
  echo ""
  help_line_ "git log" "${solid_cyan_cor}"
  echo ""
  echo " ${solid_cyan_cor} glog ${clear_cor}\t\t = git log"
  echo " ${solid_cyan_cor} gll ${clear_cor}\t\t = list branches"
  echo " ${solid_cyan_cor} gll \$1 ${clear_cor}\t = list branches matching \$1"
  echo " ${solid_cyan_cor} glr ${clear_cor}\t\t = list remote branches"
  echo " ${solid_cyan_cor} glr \$1 ${clear_cor}\t = list remote branches matching \$1"

  pause_output  # Wait for user input to continue
  if [[ $? -ne 0 ]]; then
    return 0;
  fi

  help_line_ "git pull" "${solid_cyan_cor}"
  echo ""
  echo " ${solid_cyan_cor} fetch ${clear_cor}\t = fetch from origin"
  echo " ${solid_cyan_cor} pull ${clear_cor}\t\t = pull all branches from origin"
  echo " ${solid_cyan_cor} pull tags${clear_cor}\t = pull all tags from origin"

  echo ""
  help_line_ "git push" "${solid_cyan_cor}"
  echo ""
  echo " ${solid_cyan_cor} add ${clear_cor}\t\t = add files to index"
  echo " ${solid_cyan_cor} commit ${clear_cor}\t = open commit wizard"
  echo " ${solid_cyan_cor} commit \$1${clear_cor}\t = commit message"
  echo " ${solid_cyan_cor} pr ${clear_cor}\t\t = create pull request"
  echo " ${solid_cyan_cor} push ${clear_cor}\t\t = push all no-verify to origin"
  echo " ${solid_cyan_cor} pushf ${clear_cor}\t = push force all to origin"
  
  echo ""
  help_line_ "git rebase" "${solid_cyan_cor}"
  echo ""
  echo " ${solid_cyan_cor} abort${clear_cor}\t\t = abort rebase/merge/chp"
  echo " ${solid_cyan_cor} chc ${clear_cor}\t\t = continue cherry-pick"
  echo " ${solid_cyan_cor} chp ${clear_cor}\t\t = cherry-pick commit"
  echo " ${solid_cyan_cor} conti ${clear_cor}\t = continue rebase/merge/chp"
  echo " ${solid_cyan_cor} mc ${clear_cor}\t\t = continue merge"
  echo " ${solid_cyan_cor} merge ${clear_cor}\t = merge from $(git config --get init.defaultBranch) branch"
  echo " ${solid_cyan_cor} merge \$1 ${clear_cor}\t = merge from branch"
  echo " ${solid_cyan_cor} rc ${clear_cor}\t\t = continue rebase"
  echo " ${solid_cyan_cor} rebase ${clear_cor}\t = rebase from $(git config --get init.defaultBranch) branch"
  echo " ${solid_cyan_cor} rebase \$1 ${clear_cor}\t = rebase from branch"

  pause_output  # Wait for user input to continue
  if [[ $? -ne 0 ]]; then
    return 0;
  fi
  
  help_line_ "git stash" "${solid_cyan_cor}"
  echo ""
  echo " ${solid_cyan_cor} pop ${clear_cor}\t\t = stash pop index"
  echo " ${solid_cyan_cor} stash ${clear_cor}\t = stash unnamed"
  echo " ${solid_cyan_cor} stash \$1 ${clear_cor}\t = stash with name"
  echo " ${solid_cyan_cor} stashes ${clear_cor}\t = list all stashes"

  echo ""
  help_line_ "git tags" "${solid_cyan_cor}"
  echo ""
  echo " ${solid_cyan_cor} dtag ${clear_cor}\t\t = delete tag remotely"
  echo " ${solid_cyan_cor} tag ${clear_cor}\t\t = create tag remotely"
  echo " ${solid_cyan_cor} tags ${clear_cor}\t\t = list latest tags"
  echo " ${solid_cyan_cor} tags 1 ${clear_cor}\t = display latest tag"

  echo ""
  help_line_ "general" "${solid_cyan_cor}"
  echo ""
  echo " ${solid_yellow_cor} cl ${clear_cor}\t\t = clear"
  echo " ${solid_yellow_cor} del ${clear_cor}\t\t = delete utility"
  echo " ${solid_yellow_cor} help ${clear_cor}\t\t = display this help"
  echo " ${solid_yellow_cor} hg \$1 ${clear_cor}\t = history | grep"
  echo " ${solid_yellow_cor} kill \$1 ${clear_cor}\t = kill port"
  echo " ${solid_yellow_cor} ll ${clear_cor}\t\t = ls -laF"
  echo " ${solid_yellow_cor} nver ${clear_cor}\t\t = node version"
  echo " ${solid_yellow_cor} nlist ${clear_cor}\t = npm list global"
  echo " ${solid_yellow_cor} path ${clear_cor}\t\t = echo \$PATH"
  echo " ${solid_yellow_cor} refresh ${clear_cor}\t = source .zshrc"
  echo " ${solid_yellow_cor} upgrade ${clear_cor}\t = upgrade pump + zsh + omp"
  echo ""
  help_line_ "multi-step tasks" "${pink_cor}"
  echo ""
  echo " ${pink_cor} covc ${clear_cor}\t\t = compare test coverage with another branch"
  echo " ${pink_cor} refix ${clear_cor}\t = reset last commit then run fix then re-commit"
  echo " ${pink_cor} recommit ${clear_cor}\t = reset last commit then re-commit all changes"
  echo " ${pink_cor} repush ${clear_cor}\t = reset last commit then re-push all changes"
  echo " ${pink_cor} rev ${clear_cor}\t\t = select branch to review"
  echo ""
}

check_prj_folder_1_() {
  ERROR_PROJ_1=0;

  if [[ -z "$Z_PROJECT_FOLDER_1" || -n "$2" ]]; then
    if [[ -n "$2" ]]; then
      Z_PROJECT_FOLDER_1_="$2"
    else
      if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
        echo "${red_cor} fatal: config file '$PUMP_CONFIG_FILE' does not exist, re-install pump-my-shell ${clear_cor}"
        return 1
      fi
      Z_PROJECT_FOLDER_1_=$(sed -n 's/^Z_PROJECT_FOLDER_1=\([^ ]*\)/\1/p' "$PUMP_CONFIG_FILE");
      Z_PROJECT_FOLDER_1_="${Z_PROJECT_FOLDER_1_/#\~/$HOME}"
    fi
    if [[ -z "$Z_PROJECT_FOLDER_1_" ]]; then
      if [[ "$1" != "-q" ]]; then
        echo "${red_cor} error: project folder not found ${clear_cor}";
      fi
      ERROR_PROJ_1=1
    else
      Z_PROJECT_FOLDER_1_="${Z_PROJECT_FOLDER_1_%/}"
      Z_PROJECT_FOLDER_1=$(realpath "$Z_PROJECT_FOLDER_1_" 2>/dev/null)
      if [[ -z "$Z_PROJECT_FOLDER_1" ]]; then
        #echo "mkdir -p $Z_PROJECT_FOLDER_1_"
        mkdir -p "$Z_PROJECT_FOLDER_1_" &>/dev/null
        if [ $? -eq 0 ]; then
          Z_PROJECT_FOLDER_1=$(realpath $Z_PROJECT_FOLDER_1_);
          if [[ -z "$Z_PROJECT_FOLDER_1" ]]; then
            ERROR_PROJ_1=2
          fi
        else
          if [[ "$1" != " skip" ]]; then
            echo "${red_cor} cannot establish path $Z_PROJECT_FOLDER_1_ ${clear_cor}";
          fi
          ERROR_PROJ_1=2
        fi
      fi
    fi
  fi

  return $ERROR_PROJ_1;
}

check_prj_folder_2_() {
  ERROR_PROJ_2=0;

  if [[ -z "$Z_PROJECT_FOLDER_2" || -n "$2" ]]; then
    if [[ -n "$2" ]]; then
      Z_PROJECT_FOLDER_2_="$2"
    else
      if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
        echo "${red_cor} fatal: config file '$PUMP_CONFIG_FILE' does not exist, re-install pump-my-shell ${clear_cor}"
        return 1
      fi
      Z_PROJECT_FOLDER_2_=$(sed -n 's/^Z_PROJECT_FOLDER_2=\([^ ]*\)/\1/p' "$PUMP_CONFIG_FILE");
      Z_PROJECT_FOLDER_2_="${Z_PROJECT_FOLDER_2_/#\~/$HOME}"
    fi
    if [[ -z "$Z_PROJECT_FOLDER_2_" ]]; then
      if [[ "$1" != "-q" ]]; then
        echo "${red_cor} error: project folder not found ${clear_cor}";
      fi
      ERROR_PROJ_2=1
    else
      Z_PROJECT_FOLDER_2_="${Z_PROJECT_FOLDER_2_%/}"
      Z_PROJECT_FOLDER_2=$(realpath "$Z_PROJECT_FOLDER_2_" 2>/dev/null)
      if [[ -z "$Z_PROJECT_FOLDER_2" ]]; then
        #echo "mkdir -p $Z_PROJECT_FOLDER_2_"
        mkdir -p "$Z_PROJECT_FOLDER_2_" &>/dev/null
        if [ $? -eq 0 ]; then
          Z_PROJECT_FOLDER_2=$(realpath $Z_PROJECT_FOLDER_2_);
          if [[ -z "$Z_PROJECT_FOLDER_2" ]]; then
            ERROR_PROJ_2=2
          fi
        else
          if [[ "$1" != " skip" ]]; then
            echo "${red_cor} cannot establish path $Z_PROJECT_FOLDER_2_ ${clear_cor}";
          fi
          ERROR_PROJ_2=2
        fi
      fi
    fi
  fi

  return $ERROR_PROJ_2;
}

check_prj_folder_3_() {
  ERROR_PROJ_3=0;

  if [[ -z "$Z_PROJECT_FOLDER_3" || -n "$2" ]]; then
    if [[ -n "$2" ]]; then
      Z_PROJECT_FOLDER_3_="$2"
    else
      if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
        echo "${red_cor} fatal: config file '$PUMP_CONFIG_FILE' does not exist, re-install pump-my-shell ${clear_cor}"
        return 1
      fi
      Z_PROJECT_FOLDER_3_=$(sed -n 's/^Z_PROJECT_FOLDER_3=\([^ ]*\)/\1/p' "$PUMP_CONFIG_FILE");
      Z_PROJECT_FOLDER_3_="${Z_PROJECT_FOLDER_3_/#\~/$HOME}"
    fi
    if [[ -z "$Z_PROJECT_FOLDER_3_" ]]; then
      if [[ "$1" != "-q" ]]; then
        echo "${red_cor} error: project folder not found ${clear_cor}";
      fi
      ERROR_PROJ_3=1
    else
      Z_PROJECT_FOLDER_3_="${Z_PROJECT_FOLDER_3_%/}"
      Z_PROJECT_FOLDER_3=$(realpath "$Z_PROJECT_FOLDER_3_" 2>/dev/null)
      if [[ -z "$Z_PROJECT_FOLDER_3" ]]; then
        #echo "mkdir -p $Z_PROJECT_FOLDER_3_"
        mkdir -p "$Z_PROJECT_FOLDER_3_" &>/dev/null
        if [ $? -eq 0 ]; then
          Z_PROJECT_FOLDER_3=$(realpath $Z_PROJECT_FOLDER_3_);
          if [[ -z "$Z_PROJECT_FOLDER_3" ]]; then
            ERROR_PROJ_3=2
          fi
        else
          if [[ "$1" != " skip" ]]; then
            echo "${red_cor} cannot establish path $Z_PROJECT_FOLDER_3_ ${clear_cor}";
          fi
          ERROR_PROJ_3=2
        fi
      fi
    fi
  fi

  return $ERROR_PROJ_3;
}

check_prj_1_() {
  ERROR_PROJ_1=0;

  check_prj_folder_1_ "$1" "$2"
  ERROR_PROJ_1=$?

  if [[ -z "$Z_PROJECT_SHORT_NAME_1" ]]; then
    if [[ "$1" != "-q" ]]; then
      echo "${red_cor} error: not found Z_PROJECT_SHORT_NAME_1= ${clear_cor}";
    fi
    ERROR_PROJ_1=1
  fi

  return $ERROR_PROJ_1;
}

check_prj_2_() {
  ERROR_PROJ_2=0

  check_prj_folder_2_ "$1" "$2"
  ERROR_PROJ_2=$?

  if [[ -z "$Z_PROJECT_SHORT_NAME_2" ]]; then
    if [[ "$1" != "-q" ]]; then
      echo "${red_cor} error: not found Z_PROJECT_SHORT_NAME_2= ${clear_cor}";
    fi
    ERROR_PROJ_2=1
  fi

  return $ERROR_PROJ_2;
}

check_prj_3_() {
  ERROR_PROJ_3=0

  check_prj_folder_3_ "$1" "$2"
  ERROR_PROJ_3=$?

  if [[ -z "$Z_PROJECT_SHORT_NAME_3" ]]; then
    if [[ "$1" != "-q" ]]; then
      echo "${red_cor} error: not found Z_PROJECT_SHORT_NAME_3= ${clear_cor}";
    fi
    ERROR_PROJ_3=1
  fi

  return $ERROR_PROJ_3;
}

# check what project is set
which_pro() {
  if [[ "$1" == "-q" ]]; then
    return 0;
  fi

  if [[ -n "$Z_PROJECT_SHORT_NAME" ]]; then
    echo " your project is set to:${solid_blue_cor} $Z_PROJECT_SHORT_NAME${clear_cor} with${solid_magenta_cor} $Z_PACKAGE_MANAGER ${clear_cor}"
    echo ""
  fi
  echo " options:"

  is_any=0

  if [[ -n "$Z_PROJECT_SHORT_NAME_1" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_1" ]]; then
    echo "${yellow_cor} pro $Z_PROJECT_SHORT_NAME_1 ${clear_cor}";
    is_any=1
  fi
  if [[ -n "$Z_PROJECT_SHORT_NAME_2" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_2" ]]; then
    echo "${yellow_cor} pro $Z_PROJECT_SHORT_NAME_2 ${clear_cor}";
    is_any=1
  fi
  if [[ -n "$Z_PROJECT_SHORT_NAME_3" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_3" ]]; then
    echo "${yellow_cor} pro $Z_PROJECT_SHORT_NAME_3 ${clear_cor}";
    is_any=1
  fi

  if [[ $is_any -eq 0 ]]; then
    echo " type${yellow_cor} pro${clear_cor} to set project"
  fi
}

which_pro_pwd() {
  if [[ -n "$Z_PROJECT_SHORT_NAME_1" && -n "$Z_PROJECT_FOLDER_1" ]]; then
    if [[ $(PWD) == $Z_PROJECT_FOLDER_1* ]]; then
      echo $Z_PROJECT_SHORT_NAME_1
      return 0;
    fi
  fi

  if [[ -n "$Z_PROJECT_SHORT_NAME_2" && -n "$Z_PROJECT_FOLDER_2" ]]; then
    if [[ $(PWD) == $Z_PROJECT_FOLDER_2* ]]; then
      echo $Z_PROJECT_SHORT_NAME_2
      return 0;
    fi
  fi

  if [[ -n "$Z_PROJECT_SHORT_NAME_3" && -n "$Z_PROJECT_FOLDER_3" ]]; then
    if [[ $(PWD) == $Z_PROJECT_FOLDER_3* ]]; then
      echo $Z_PROJECT_SHORT_NAME_3
      return 0;
    fi
  fi

  # cannot determine project based on pwd
  return 1;
}

pro() {
  if [[ -z "$1" ]]; then
    if [[ -n "$Z_PROJECT_SHORT_NAME" ]]; then
      echo " your project is set to:${solid_blue_cor} $Z_PROJECT_SHORT_NAME${clear_cor} with${solid_magenta_cor} $Z_PACKAGE_MANAGER ${clear_cor}"
      echo ""
    else
      # user has no projects in config
      if [[ "$2" != "-q" ]]; then
        echo " no project set, type${yellow_cor} help${clear_cor} to set project"
      fi
      return 1;
    fi

    if [[ -n "$Z_PROJECT_SHORT_NAME_1" && -n "$Z_PROJECT_SHORT_NAME_2" && -n "$Z_PROJECT_SHORT_NAME_3" ]]; then
      pro_choices=("$Z_PROJECT_SHORT_NAME_1" "$Z_PROJECT_SHORT_NAME_2" "$Z_PROJECT_SHORT_NAME_3")
      choice=$(choose_one_ "set project:" $pro_choices);

      if [[ $? -eq 0 && -n "$choice" ]]; then
        pro "$choice"
        if [ $? -eq 0 ]; then return 0; else return 1; fi
      fi

    elif [[ "$2" != "-q" ]]; then
      if confirm_from_ "Would you like to set a new project?"; then
        if [[ -z "$Z_PROJECT_SHORT_NAME_1" ]]; then
          save_project_1_
        elif [[ -z "$Z_PROJECT_SHORT_NAME_2" ]]; then
          save_project_2_
        elif [[ -z "$Z_PROJECT_SHORT_NAME_3" ]]; then
          save_project_3_
        else
          echo " no more projects available, please remove one to add a new one"
        fi
      fi
    fi
    return 0;
  fi

  # check if current folder is a project, then set project to that
  if [[ "$1" == "pwd" ]]; then
    _pwd=$(which_pro_pwd);
    if [[ -n "$_pwd" ]]; then
      pro "$_pwd" "$2"
      if [ $? -eq 0 ]; then return 0; else return 1; fi
    fi
    return 1;
  fi

  if [[ "$1" != "$Z_PROJECT_SHORT_NAME_1" && "$1" != "$Z_PROJECT_SHORT_NAME_2" && "$1" != "$Z_PROJECT_SHORT_NAME_3" ]]; then    
    which_pro $2;
    return 1;
  fi

  if [[ "$1" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
    check_prj_1_ $2;
    if [ $? -ne 0 ]; then return 1; fi

    Z_PROJECT_FOLDER="$Z_PROJECT_FOLDER_1"
    Z_PROJECT_SHORT_NAME="$Z_PROJECT_SHORT_NAME_1"
    Z_PROJECT_REPO="$Z_PROJECT_REPO_1"
    Z_PACKAGE_MANAGER="$Z_PACKAGE_MANAGER_1"
    Z_CODE_EDITOR="$Z_CODE_EDITOR_1"
    Z_CLONE="$Z_CLONE_1"
    Z_SETUP="$Z_SETUP_1"
    Z_RUN="$Z_RUN_1"
    Z_RUN_STAGE="$Z_RUN_STAGE_1"
    Z_RUN_PROD="$Z_RUN_PROD_1"
    Z_PRO="$Z_PRO_1"
    Z_TEST="$Z_TEST_1"
    Z_COV="$Z_COV_1"
    Z_TEST_WATCH="$Z_TEST_WATCH_1"
    Z_E2E="$Z_E2E_1"
    Z_E2EUI="$Z_E2EUI_1"
    Z_PR_TEMPLATE="$Z_PR_TEMPLATE_1"
    Z_PR_REPLACE="$Z_PR_REPLACE_1"
    Z_PR_APPEND="$Z_PR_APPEND_1"
    Z_PR_RUN_TEST="$Z_PR_RUN_TEST_1"
    Z_GHA_INTERVAL="$Z_GHA_INTERVAL_1"
    Z_COMMIT_ADD="$Z_COMMIT_ADD_1"
    Z_DEFAULT_BRANCH="$Z_DEFAULT_BRANCH_1"
    Z_GHA_WORKFLOW="$Z_GHA_WORKFLOW_1"
    Z_PUSH_ON_REFIX="$Z_PUSH_ON_REFIX_1"
    Z_PRINT_README="$Z_PRINT_README_1"

  elif [[ "$1" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
    check_prj_2_ $2;
    if [ $? -ne 0 ]; then return 1; fi

    Z_PROJECT_FOLDER="$Z_PROJECT_FOLDER_2"
    Z_PROJECT_SHORT_NAME="$Z_PROJECT_SHORT_NAME_2"
    Z_PROJECT_REPO="$Z_PROJECT_REPO_2"
    Z_PACKAGE_MANAGER="$Z_PACKAGE_MANAGER_2"
    Z_CODE_EDITOR="$Z_CODE_EDITOR_2"
    Z_CLONE="$Z_CLONE_2"
    Z_SETUP="$Z_SETUP_2"
    Z_RUN="$Z_RUN_2"
    Z_RUN_STAGE="$Z_RUN_STAGE_2"
    Z_RUN_PROD="$Z_RUN_PROD_2"
    Z_PRO="$Z_PRO_2"
    Z_TEST="$Z_TEST_2"
    Z_COV="$Z_COV_2"
    Z_TEST_WATCH="$Z_TEST_WATCH_2"
    Z_E2E="$Z_E2E_2"
    Z_E2EUI="$Z_E2EUI_2"
    Z_PR_TEMPLATE="$Z_PR_TEMPLATE_2"
    Z_PR_REPLACE="$Z_PR_REPLACE_2"
    Z_PR_APPEND="$Z_PR_APPEND_2"
    Z_PR_RUN_TEST="$Z_PR_RUN_TEST_2"
    Z_GHA_INTERVAL="$Z_GHA_INTERVAL_2"
    Z_COMMIT_ADD="$Z_COMMIT_ADD_2"
    Z_DEFAULT_BRANCH="$Z_DEFAULT_BRANCH_2"
    Z_GHA_WORKFLOW="$Z_GHA_WORKFLOW_2"
    Z_PUSH_ON_REFIX="$Z_PUSH_ON_REFIX_2"
    Z_PRINT_README="$Z_PRINT_README_2"

  elif [[ "$1" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
    check_prj_3_ $2;
    if [ $? -ne 0 ]; then return 1; fi

    Z_PROJECT_FOLDER="$Z_PROJECT_FOLDER_3"
    Z_PROJECT_SHORT_NAME="$Z_PROJECT_SHORT_NAME_3"
    Z_PROJECT_REPO="$Z_PROJECT_REPO_3"
    Z_PACKAGE_MANAGER="$Z_PACKAGE_MANAGER_3"
    Z_CODE_EDITOR="$Z_CODE_EDITOR_3"
    Z_CLONE="$Z_CLONE_3"
    Z_SETUP="$Z_SETUP_3"
    Z_RUN="$Z_RUN_3"
    Z_RUN_STAGE="$Z_RUN_STAGE_3"
    Z_RUN_PROD="$Z_RUN_PROD_3"
    Z_PRO="$Z_PRO_3"
    Z_TEST="$Z_TEST_3"
    Z_COV="$Z_COV_3"
    Z_TEST_WATCH="$Z_TEST_WATCH_3"
    Z_E2E="$Z_E2E_3"
    Z_E2EUI="$Z_E2EUI_3"
    Z_PR_TEMPLATE="$Z_PR_TEMPLATE_3"
    Z_PR_REPLACE="$Z_PR_REPLACE_3"
    Z_PR_APPEND="$Z_PR_APPEND_3"
    Z_PR_RUN_TEST="$Z_PR_RUN_TEST_3"
    Z_GHA_INTERVAL="$Z_GHA_INTERVAL_3"
    Z_COMMIT_ADD="$Z_COMMIT_ADD_3"
    Z_DEFAULT_BRANCH="$Z_DEFAULT_BRANCH_3"
    Z_GHA_WORKFLOW="$Z_GHA_WORKFLOW_3"
    Z_PUSH_ON_REFIX="$Z_PUSH_ON_REFIX_3"
    Z_PRINT_README="$Z_PRINT_README_3"

  else
    which_pro $2;
    return 0;
  fi

  echo "$Z_PROJECT_SHORT_NAME" > "$PUMP_PRO_FILE"

  # which_pro $2;

  if [[ $(PWD) != $Z_PROJECT_FOLDER* ]]; then
    if [[ "$2" != "-q" ]]; then
      mkdir -p "$Z_PROJECT_FOLDER" &>/dev/null
      cd "$Z_PROJECT_FOLDER"
    fi
  fi

  # if [[ -n "$Z_PRO" && "$2" != "-q" ]]; then
  #   eval "$Z_PRO"
  # fi
  
  export Z_PROJECT_SHORT_NAME="$Z_PROJECT_SHORT_NAME"

  if [[ "$2" != "-q" ]]; then
    refresh
  fi
}

if [[ -n "$Z_PROJECT_SHORT_NAME_1" ]]; then
  check_proj_name_valid_ "$Z_PROJECT_SHORT_NAME_1" -q
  if [ $? -ne 0 ]; then
    Z_PROJECT_SHORT_NAME_1=""
  fi
fi

if [[ -n "$Z_PROJECT_SHORT_NAME_2" ]]; then
  check_proj_name_valid_ "$Z_PROJECT_SHORT_NAME_2" -q
  if [ $? -ne 0 ]; then
    Z_PROJECT_SHORT_NAME_2=""
  fi
fi

if [[ -n "$Z_PROJECT_SHORT_NAME_3" ]]; then
  check_proj_name_valid_ "$Z_PROJECT_SHORT_NAME_3" -q
  if [ $? -ne 0 ]; then
    Z_PROJECT_SHORT_NAME_3=""
  fi
fi

# auto pro ===============================================================
pro pwd -q
# get stored project and set project but do not change current directory
if [ $? -ne 0 ]; then
  # pump_pro_file_value="$(head -n 1 "$PUMP_PRO_FILE" &>/dev/null)";
  [[ -f "$PUMP_PRO_FILE" ]] && pump_pro_file_value=$(<"$PUMP_PRO_FILE")

  if [[ -n "$pump_pro_file_value" ]]; then
    check_proj_name_valid_ "$pump_pro_file_value" -q
    if [ $? -ne 0 ]; then
      rm -f "$PUMP_PRO_FILE" &>/dev/null
      pump_pro_file_value=""
    fi
  fi

  project_names=("$pump_pro_file_value" "$Z_PROJECT_SHORT_NAME_1" "$Z_PROJECT_SHORT_NAME_2" "$Z_PROJECT_SHORT_NAME_3")
  project_names=("${project_names[@]/#/}")

  for project in "${project_names[@]}"; do
    if [[ -n "$project" ]]; then
      pro "$project" -q
      if [[ $? -eq 0 ]]; then
        break  # Exit loop once a valid project is found and executed successfully
      fi
    fi
  done
fi

if [[ -n "$Z_PROJECT_SHORT_NAME" ]]; then
  echo " your project is set to:${solid_blue_cor} $Z_PROJECT_SHORT_NAME${clear_cor} with${solid_magenta_cor} $Z_PACKAGE_MANAGER ${clear_cor}"
  echo ""
else
  return 0;
fi

if [[ -n "$Z_PRO" ]]; then
  eval "$Z_PRO"
fi
# ==========================================================================

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

  $Z_PACKAGE_MANAGER run format &>/dev/null
  $Z_PACKAGE_MANAGER run lint &>/dev/null
  $Z_PACKAGE_MANAGER run format &>/dev/null

  echo "   refixing \"$last_commit_msg\"..."

  echo "done" > "$pipe_name" &>/dev/null
  rm "$pipe_name"
  wait $spin_pid &>/dev/null

  setopt notify
  setopt monitor

  git add .
  git commit -m "$last_commit_msg" "$@"

  if [[ -n "$Z_PUSH_ON_REFIX" && $Z_PUSH_ON_REFIX -eq 0 ]]; then
    return 0;
  fi

  if [[ "$1" != "-q" ]]; then
    if confirm_from_ "fix done, push now?"; then
      if confirm_from_ "save this preference and don't ask again?"; then
        if [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
          update_config_ "Z_PUSH_ON_REFIX_1" 1
        elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
          update_config_ "Z_PUSH_ON_REFIX_2" 1
        elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
          update_config_ "Z_PUSH_ON_REFIX_3" 1
        fi
        Z_PUSH_ON_REFIX=1
      fi
    else
      return 0;
    fi
  fi

  pushf "$@"
}

alias i="$Z_PACKAGE_MANAGER install"
# Package manager aliases =========================================================
alias build="$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")build"
alias deploy="$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")deploy"
alias fix="$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")format && $Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")lint"
alias format="$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")format"
alias ig="$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")install --global"
alias lint="$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")lint"
alias rdev="$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")dev"
alias tsc="$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")tsc"
alias sb="$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook"
alias sbb="$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook:build"
alias start="$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")start"

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

if [[ "$Z_COV" != "$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage" ]]; then
  alias ${Z_PACKAGE_MANAGER:0:1}cov="$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage"
fi
if [[ "$Z_TEST" != "$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test" ]]; then
  alias ${Z_PACKAGE_MANAGER:0:1}test="$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test"
fi
if [[ "$Z_E2E" != "$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e" ]]; then
  alias ${Z_PACKAGE_MANAGER:0:1}e2e="$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e"
fi
if [[ "$Z_E2EUI" != "$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui" ]]; then
  alias ${Z_PACKAGE_MANAGER:0:1}e2eui="$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui"
fi
if [[ "$Z_TEST_WATCH" != "$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch" ]]; then
  alias ${Z_PACKAGE_MANAGER:0:1}testw="$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch"
fi

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

# project functions =========================================================
if [[ -n "$Z_PROJECT_SHORT_NAME_1" ]]; then
  $Z_PROJECT_SHORT_NAME_1() {
    if [[ -z "$Z_PROJECT_FOLDER_1" ]]; then
      save_project_1_
      return 1;
    fi

    check_any_pkg_silent_ "$Z_PROJECT_FOLDER_1"
    single_mode=$?;

    if [[ "$1" == "-h" ]]; then
      echo "${yellow_cor} $Z_PROJECT_SHORT_NAME_1${clear_cor} : to cd into $Z_PROJECT_SHORT_NAME_1"
      if [ $single_mode -eq 0 ]; then
        echo "${yellow_cor} $Z_PROJECT_SHORT_NAME_1${solid_yellow_cor} [<branch>]${clear_cor} : to cd into $Z_PROJECT_SHORT_NAME_1 and switch to branch"
      else
        echo "${yellow_cor} $Z_PROJECT_SHORT_NAME_1 -l${clear_cor} : to list all $Z_PROJECT_SHORT_NAME_1's working folders"
        echo "${yellow_cor} $Z_PROJECT_SHORT_NAME_1${solid_yellow_cor} [<folder>]${clear_cor} : to cd into $Z_PROJECT_SHORT_NAME_1 into a folder"
        echo "${yellow_cor} $Z_PROJECT_SHORT_NAME_1${solid_yellow_cor} [<folder>] [<branch>]${clear_cor} : to cd into $Z_PROJECT_SHORT_NAME_1 into a folder and switch to branch"
      fi
      return 0;
    fi

    if [[ "$1" == "-l" ]]; then
      if [[ $single_mode -eq 0 ]]; then
        echo " project is in 'single mode'"
        echo " ${yellow_cor} $Z_PROJECT_SHORT_NAME_1 -h${clear_cor} to see usage"
        return 0;
      fi

      if [[ -n ${(f)"$(get_folders_ "$Z_PROJECT_FOLDER_1")"} ]]; then
        folders=($(get_folders_ "$Z_PROJECT_FOLDER_1"))

        for folder in "${folders[@]}"; do
          echo "${pink_cor} $folder ${clear_cor}"
        done
      else
        echo " no folders yet"
      fi
      return 0;
    fi

    if [[ -z "$1" && $single_mode -eq 1 ]]; then
      if [[ -n ${(f)"$(get_folders_ "$Z_PROJECT_FOLDER_1")"} ]]; then
        folders=($(get_folders_ "$Z_PROJECT_FOLDER_1"))
        selected_folder=($(choose_auto_one_ "choose work folder:" "${folders[@]}"))
        if [[ -z "$selected_folder" ]]; then
          return 1;
        fi

        eval "$Z_PROJECT_SHORT_NAME_1" "$selected_folder"
        return 0;
      fi
    fi

    arg2=""
    if [[ "$Z_PROJECT_SHORT_NAME_1" == "$Z_PROJECT_SHORT_NAME" ]]; then
      arg2="-q"
    fi

    pro "$Z_PROJECT_SHORT_NAME_1" $arg2
    cd "$Z_PROJECT_FOLDER_1"

    folder=""
    branch=""
    is_working_branch=0

    if [ $single_mode -eq 0 ]; then # true, is single mode
      branch="$1"
      if [[ -z "$branch" ]]; then
        is_working_branch=1
        branch=$(git branch | grep -w "$PUMP_WORKING_BRANCH_1" | cut -c 3- | head -n 1)
      fi
    else
      if [[ -z "$1" ]]; then
        is_working_branch=1
        folder="$PUMP_WORKING_BRANCH_1"
        if [[ -z "$folder" || ! -d "$folder" ]]; then
          folder=$(get_default_branch_folder_ "$Z_PROJECT_FOLDER_1")
        fi
      else
        folder="$1"
      fi
      branch="$2"
    fi

    if [[ -n "$folder" ]]; then
      if [[ $is_working_branch -eq 1 ]]; then check_any_pkg_silent_ "$folder"; else check_any_pkg_ "$folder"; fi
      if [ $? -eq 0 ]; then
        cd "$folder"
      fi
    fi
    
    if [[ -n "$branch" ]]; then
      co -e $branch $is_working_branch
      st
    fi
  }
fi

if [[ -n "$Z_PROJECT_SHORT_NAME_2" ]]; then
  $Z_PROJECT_SHORT_NAME_2() {
    if [[ -z "$Z_PROJECT_FOLDER_2" ]]; then
      save_project_2_
      return 1;
    fi

    check_any_pkg_silent_ "$Z_PROJECT_FOLDER_2"
    single_mode=$?;

    if [[ "$1" == "-h" ]]; then
      echo "${yellow_cor} $Z_PROJECT_SHORT_NAME_2${clear_cor} : to cd into $Z_PROJECT_SHORT_NAME_2"
      if [ $single_mode -eq 0 ]; then
        echo "${yellow_cor} $Z_PROJECT_SHORT_NAME_2${solid_yellow_cor} [<branch>]${clear_cor} : to cd into $Z_PROJECT_SHORT_NAME_2 and switch to branch"
      else
        echo "${yellow_cor} $Z_PROJECT_SHORT_NAME_2 -l${clear_cor} : to list all $Z_PROJECT_SHORT_NAME_2's working folders"
        echo "${yellow_cor} $Z_PROJECT_SHORT_NAME_2${solid_yellow_cor} [<folder>]${clear_cor} : to cd into $Z_PROJECT_SHORT_NAME_2 into a folder"
        echo "${yellow_cor} $Z_PROJECT_SHORT_NAME_2${solid_yellow_cor} [<folder> <branch>]${clear_cor} : to cd into $Z_PROJECT_SHORT_NAME_2 into a folder and switch to branch"
      fi
      return 0;
    fi

    if [[ "$1" == "-l" ]]; then
      if [[ $single_mode -eq 0 ]]; then
        echo " project is in 'single mode'"
        echo " ${yellow_cor} $Z_PROJECT_SHORT_NAME_2 -h${clear_cor} to see usage"
        return 0;
      fi
      if [[ -n ${(f)"$(get_folders_ "$Z_PROJECT_FOLDER_2")"} ]]; then
        folders=($(get_folders_ "$Z_PROJECT_FOLDER_2"))

        for folder in "${folders[@]}"; do
          echo "${pink_cor} $folder ${clear_cor}"
        done
      else
        echo " no folders yet"
      fi
      return 0;
    fi

    if [[ -z "$1" && $single_mode -eq 1 ]]; then
      if [[ -n ${(f)"$(get_folders_ "$Z_PROJECT_FOLDER_2")"} ]]; then
        folders=($(get_folders_ "$Z_PROJECT_FOLDER_2"))
        selected_folder=($(choose_auto_one_ "choose work folder:" "${folders[@]}"))
        if [[ -z "$selected_folder" ]]; then
          return 1;
        fi

        eval "$Z_PROJECT_SHORT_NAME_2" "$selected_folder"
        return 0;
      fi
    fi

    arg2=""
    if [[ "$Z_PROJECT_SHORT_NAME_2" == "$Z_PROJECT_SHORT_NAME" ]]; then
      arg2="-q"
    fi

    pro "$Z_PROJECT_SHORT_NAME_2" $arg2
    cd "$Z_PROJECT_FOLDER_2"

    folder=""
    branch=""
    is_working_branch=0

    if [ $single_mode -eq 0 ]; then # true, is single mode
      branch="$1"
      if [[ -z "$branch" ]]; then
        is_working_branch=1
        branch=$(git branch | grep -w "$PUMP_WORKING_BRANCH_2" | cut -c 3- | head -n 1)
      fi
    else
      if [[ -z "$1" ]]; then
        is_working_branch=1
        folder="$PUMP_WORKING_BRANCH_2"
        if [[ -z "$folder" || ! -d "$folder" ]]; then
          folder=$(get_default_branch_folder_ "$Z_PROJECT_FOLDER_2")
        fi
      else
        folder="$1"
      fi
      branch="$2"
    fi

    if [[ -n "$folder" ]]; then
      if [[ $is_working_branch -eq 1 ]]; then check_any_pkg_silent_ "$folder"; else check_any_pkg_ "$folder"; fi
      if [ $? -eq 0 ]; then
        cd "$folder"
      fi
    fi
    
    if [[ -n "$branch" ]]; then
      co -e $branch $is_working_branch
      st
    fi
  }
fi

if [[ -n "$Z_PROJECT_SHORT_NAME_3" ]]; then
  $Z_PROJECT_SHORT_NAME_3() {
    if [[ -z "$Z_PROJECT_FOLDER_3" ]]; then
      save_project_3_
      return 1;
    fi

    check_any_pkg_silent_ "$Z_PROJECT_FOLDER_3"
    single_mode=$?;

    if [[ "$1" == "-h" ]]; then
        echo "${yellow_cor} $Z_PROJECT_SHORT_NAME_3${clear_cor} : to cd into $Z_PROJECT_SHORT_NAME_3"
      if [ $single_mode -eq 0 ]; then
        echo "${yellow_cor} $Z_PROJECT_SHORT_NAME_3${solid_yellow_cor} [<branch>]${clear_cor} : to cd into $Z_PROJECT_SHORT_NAME_3 and switch to branch"
      else
        echo "${yellow_cor} $Z_PROJECT_SHORT_NAME_3 -l${clear_cor} : to list all $Z_PROJECT_SHORT_NAME_3's working folders"
        echo "${yellow_cor} $Z_PROJECT_SHORT_NAME_3${solid_yellow_cor} [<folder>]${clear_cor} : to cd into $Z_PROJECT_SHORT_NAME_3 into a folder"
        echo "${yellow_cor} $Z_PROJECT_SHORT_NAME_3${solid_yellow_cor} [<folder> <branch>]${clear_cor} : to cd into $Z_PROJECT_SHORT_NAME_3 into a folder and switch to branch"
      fi
      return 0;
    fi

    if [[ "$1" == "-l" ]]; then
      if [[ $single_mode -eq 0 ]]; then
        echo " project is in 'single mode'"
        echo " ${yellow_cor} $Z_PROJECT_SHORT_NAME_3 -h${clear_cor} to see usage"
        return 0;
      fi

      if [[ -n ${(f)"$(get_folders_ "$Z_PROJECT_FOLDER_3")"} ]]; then
        folders=($(get_folders_ "$Z_PROJECT_FOLDER_3"))

        for folder in "${folders[@]}"; do
          echo "${pink_cor} $folder ${clear_cor}"
        done
      else
        echo " no folders yet"
      fi
      return 0;
    fi

    if [[ -z "$1" && $single_mode -eq 1 ]]; then
      if [[ -n ${(f)"$(get_folders_ "$Z_PROJECT_FOLDER_3")"} ]]; then
        folders=($(get_folders_ "$Z_PROJECT_FOLDER_3"))
        selected_folder=($(choose_auto_one_ "choose work folder:" "${folders[@]}"))
        if [[ -z "$selected_folder" ]]; then
          return 1;
        fi

        eval "$Z_PROJECT_SHORT_NAME_3" "$selected_folder"
        return 0;
      fi
    fi

    arg2=""
    if [[ "$Z_PROJECT_SHORT_NAME_3" == "$Z_PROJECT_SHORT_NAME" ]]; then
      arg2="-q"
    fi

    pro "$Z_PROJECT_SHORT_NAME_3" $arg2
    cd "$Z_PROJECT_FOLDER_3"

    folder=""
    branch=""
    is_working_branch=0

    if [ $single_mode -eq 0 ]; then # true, is single mode
      branch="$1"
      if [[ -z "$branch" ]]; then
        is_working_branch=1
        branch=$(git branch | grep -w "$PUMP_WORKING_BRANCH_3" | cut -c 3- | head -n 1)
      fi
    else
      if [[ -z "$1" ]]; then
        is_working_branch=1
        folder="$PUMP_WORKING_BRANCH_3"
        if [[ -z "$folder" || ! -d "$folder" ]]; then
          folder=$(get_default_branch_folder_ "$Z_PROJECT_FOLDER_3")
        fi
      else
        folder="$1"
      fi
      branch="$2"
    fi

    if [[ -n "$folder" ]]; then
      if [[ $is_working_branch -eq 1 ]]; then check_any_pkg_silent_ "$folder"; else check_any_pkg_ "$folder"; fi
      if [ $? -eq 0 ]; then
        cd "$folder"
      fi
    fi
    
    if [[ -n "$branch" ]]; then
      co -e $branch $is_working_branch
      st
    fi
  }
fi

covc() {
  if [[ -z "$1" || "$1" == "-h" ]]; then
    echo "${yellow_cor} covc <branch>${clear_cor} : to compare test coverage with another branch"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    echo " fatal: covc requires gum"
    echo " install gum:${blue_cor} https://github.com/charmbracelet/gum ${clear_cor}"
    return 1;
  fi

  if [[ -z "$Z_COV" && -z "$Z_SETUP" ]]; then
    echo " fatal: Z_COV and Z_SETUP are not set for${blue_cor} $Z_PROJECT_SHORT_NAME${clear_cor} - edit your pump.zshenv then run${yellow_cor} refresh ${clear_cor}"
    return 1;
  fi

  if [[ -z "$Z_COV" ]]; then
    echo " fatal: Z_COV is not set for${blue_cor} $Z_PROJECT_SHORT_NAME${clear_cor} - edit your pump.zshenv then run${yellow_cor} refresh ${clear_cor}"
    return 1;
  fi

  if [[ -z "$Z_SETUP" ]]; then
    echo " fatal: Z_SETUP is not set for${blue_cor} $Z_PROJECT_SHORT_NAME${clear_cor} - edit your pump.zshenv then run${yellow_cor} refresh ${clear_cor}"
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

  cov_folder="$Z_PROJECT_FOLDER/.coverage"

  check_git_silent_ $cov_folder;
  if [[ $? -eq 0 ]]; then
    pushd "$cov_folder" &>/dev/null

    git reset --hard --quiet origin
    git switch "$1" --quiet
    git pull origin --quiet
  else
    rm -rf "$cov_folder" &>/dev/null
    git clone $Z_PROJECT_REPO "$cov_folder" --quiet
    if [ $? -ne 0 ]; then
      return 1;
    fi
    pushd "$cov_folder" &>/dev/null
    if [[ -n "$Z_CLONE" ]]; then
      eval "$Z_CLONE" &>/dev/null
    fi
    git switch "$1" --quiet
  fi

  eval "$Z_SETUP" &>/dev/null

  is_delete_cov_folder=0;

  if [[ ! -d "coverage" ]]; then
    is_delete_cov_folder=1;
    mkdir -p coverage &>/dev/null
  fi

  eval "$Z_COV" --coverageReporters=text-summary > "coverage/coverage-summary.$1.txt" 2>&1
  if [ $? -ne 0 ]; then
    eval "$Z_COV" --coverageReporters=text-summary > "coverage/coverage-summary.$1.txt" 2>&1
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

  eval "$Z_COV" --coverageReporters=text-summary > "coverage/coverage-summary.$my_branch.txt" 2>&1
  if [ $? -ne 0 ]; then
    eval "$Z_COV" --coverageReporters=text-summary > "coverage/coverage-summary.$my_branch.txt" 2>&1
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

  color=$(if [[ $statements1 -gt $statements2 ]]; then echo "${red_cor}"; elif [[ $statements1 -lt $statements2 ]]; then echo "${green_cor}"; else echo " "; fi)
  echo "$color Statements\t\t: $(printf "%.2f" $statements1)%  |$color Statements\t\t: $(printf "%.2f" $statements2)% ${clear_cor}"
  
  color=$(if [[ $branches1 -gt $branches2 ]]; then echo "${red_cor}"; elif [[ $branches1 -lt $branches2 ]]; then echo "${green_cor}"; else echo " "; fi)
  echo "$color Branches\t\t: $(printf "%.2f" $branches1)%  |$color Branches\t\t: $(printf "%.2f" $branches2)% ${clear_cor}"
  
  color=$(if [[ $funcs1 -gt $funcs2 ]]; then echo "${red_cor}"; elif [[ $funcs1 -lt $funcs2 ]]; then echo "${green_cor}"; else echo " "; fi)
  echo "$color Functions\t\t: $(printf "%.2f" $funcs1)%  |$color Functions\t\t: $(printf "%.2f" $funcs2)% ${clear_cor}"
  
  color=$(if [[ $lines1 -gt $lines2 ]]; then echo "${red_cor}"; elif [[ $lines1 -lt $lines2 ]]; then echo "${green_cor}"; else echo " "; fi)
  echo "$color Lines\t\t\t: $(printf "%.2f" $lines1)%  |$color Lines\t\t: $(printf "%.2f" $lines2)% ${clear_cor}"
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

  eval "$Z_TEST" "$@"
  if [ $? -ne 0 ]; then
    eval "$Z_TEST" "$@"
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

  if [[ -z "$Z_COV" ]]; then
    echo " fatal: Z_COV is not set for${blue_cor} $Z_PROJECT_SHORT_NAME${clear_cor} - edit your pump.zshenv then run${yellow_cor} refresh ${clear_cor}"
    return 1;
  fi
  
  eval "$Z_COV" "$@"
  if [ $? -ne 0 ]; then
    eval "$Z_COV" "$@"
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

  eval "$Z_TEST_WATCH" "$@"
}

e2e() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} e2e${clear_cor} : to run Z_E2E"
    echo "${yellow_cor} e2e <project>${clear_cor} : to run Z_E2E --project <project>"
    return 0;
  fi

  check_pkg_; if [ $? -ne 0 ]; then return 1; fi

  if [[ -z "$1" ]]; then
    eval "$Z_E2E"
  else
    eval "$Z_E2E" --project="$1" "${@:2}"
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
    eval "$Z_E2EUI"
  else
    eval "$Z_E2EUI" --project="$1" "${@:2}"
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

  if [[ -f "$Z_PR_TEMPLATE" && -n "$Z_PR_REPLACE" ]]; then
    PR_TEMPLATE=$(cat $Z_PR_TEMPLATE)

    if [[ $Z_PR_APPEND -eq 1 ]]; then
      # Append commit msgs right after Z_PR_REPLACE in pr template
      pr_body=$(echo "$PR_TEMPLATE" | perl -pe "s/(\Q$Z_PR_REPLACE\E)/\1\n\n$commit_msgs\n/")
    else
      # Replace Z_PR_REPLACE with commit msgs in pr template
      pr_body=$(echo "$PR_TEMPLATE" | perl -pe "s/\Q$Z_PR_REPLACE\E/$commit_msgs/g")
    fi
  fi

  if [[ -z "$Z_PR_RUN_TEST" ]]; then
    if confirm_from_ "run tests before a pull request?"; then
      test
      if [ $? -ne 0 ]; then
        echo "${solid_red_cor} fatal: tests are not passing,${clear_cor} did not push";
        return 1;
      fi
      if [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
        update_config_ "Z_PR_RUN_TEST_1" 1
      elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
        update_config_ "Z_PR_RUN_TEST_2" 1
      elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
        update_config_ "Z_PR_RUN_TEST_3" 1
      fi
      echo ""
    else
      if [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
        update_config_ "Z_PR_RUN_TEST_1" 0
      elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
        update_config_ "Z_PR_RUN_TEST_2" 0
      elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
        update_config_ "Z_PR_RUN_TEST_3" 0
      fi
      echo ""
    fi
  fi

  if [[ $Z_PR_RUN_TEST -eq 1 && "$1" != "-s" ]]; then
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
    echo "${yellow_cor} run <folder>${clear_cor} : to run $Z_PROJECT_SHORT_NAME's folder on dev environment"
    echo " --"
    echo "${yellow_cor} run dev${clear_cor} : to run dev in current folder"
    echo "${yellow_cor} run stage${clear_cor} : to run stage in current folder"
    echo "${yellow_cor} run prod${clear_cor} : to run prod in current folder"
    echo " --"
    if [[ -n "$Z_PROJECT_SHORT_NAME" ]]; then
      echo "${yellow_cor} run${solid_yellow_cor} [<folder>] [<env>]${clear_cor} : to run $Z_PROJECT_SHORT_NAME's folder on environment"
      echo " --"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_1" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_1" ]]; then
      echo "${yellow_cor} run $Z_PROJECT_SHORT_NAME_1${solid_yellow_cor} [<folder>] [<env>]${clear_cor} : to run $Z_PROJECT_SHORT_NAME_1's folder on environment"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_2" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_2" ]]; then
      echo "${yellow_cor} run $Z_PROJECT_SHORT_NAME_2${solid_yellow_cor} [<folder>] [<env>]${clear_cor} : to run $Z_PROJECT_SHORT_NAME_2's folder on environment"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_3" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_3" ]]; then
      echo "${yellow_cor} run $Z_PROJECT_SHORT_NAME_3${solid_yellow_cor} [<folder>] [<env>]${clear_cor} : to run $Z_PROJECT_SHORT_NAME_3's folder on environment"
    fi
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
    if [[ "$1" == "$Z_PROJECT_SHORT_NAME_1" || "$1" == "$Z_PROJECT_SHORT_NAME_2" || "$1" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      proj_arg="${1:-$Z_PROJECT_SHORT_NAME}"
      if [[ "$2" == "dev" || "$2" == "stage" || "$2" == "prod" ]]; then
        if [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
          check_any_pkg_silent_ "$Z_PROJECT_FOLDER_1";
        elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
          check_any_pkg_silent_ "$Z_PROJECT_FOLDER_2";
        elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
          check_any_pkg_silent_ "$Z_PROJECT_FOLDER_3";
        fi
        if [[ $? -eq 0 ]]; then
          _env="$2"
        else
          folder_arg="$2"
        fi
      else
        folder_arg="$2"
      fi
    else
      folder_arg="$1"
      _env="$2"
    fi
  elif [[ -n "$1" ]]; then
    if [[ "$1" == "$Z_PROJECT_SHORT_NAME_1" || "$1" == "$Z_PROJECT_SHORT_NAME_2" || "$1" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      proj_arg="$1"
    elif [[ "$1" == "dev" || "$1" == "stage" || "$1" == "prod" ]]; then
      _env="$1"
    else
      folder_arg="$1"
    fi
  fi

  # it's possible to run a project without proj_arg

  if [[ "$_env" != "dev" && "$_env" != "stage" && "$_env" != "prod" ]]; then
    echo " fatal: env is incorrect, valid options: dev, stage or prod"
    echo " ${yellow_cor} run -h${clear_cor} to see usage"
    return 1;
  fi

  proj_folder="";
  _run="$Z_RUN";

  if [[ "$_env" == "stage" ]]; then
    _run="$Z_RUN_STAGE"
  elif [[ "$_env" == "prod" ]]; then
    _run="$Z_RUN_PROD"
  fi

  if [[ -n "$proj_arg" ]]; then
    if [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
      check_prj_1_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_1"
      _run="$Z_RUN_1"

      if [[ "$_env" == "stage" ]]; then
        _run="$Z_RUN_STAGE_1"
      elif [[ "$_env" == "prod" ]]; then
        _run="$Z_RUN_PROD_1"
      fi

    elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
      check_prj_2_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_2"
      _run="$Z_RUN_2"

      if [[ "$_env" == "stage" ]]; then
        _run="$Z_RUN_STAGE_2"
      elif [[ "$_env" == "prod" ]]; then
        _run="$Z_RUN_PROD_2"
      fi

    elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      check_prj_3_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_3"
      _run="$Z_RUN_3"

      if [[ "$_env" == "stage" ]]; then
        _run="$Z_RUN_STAGE_3"
      elif [[ "$_env" == "prod" ]]; then
        _run="$Z_RUN_PROD_3"
      fi
    fi
  else
    proj_arg="$Z_PROJECT_SHORT_NAME"
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
      if [[ -n "$Z_PROJECT_SHORT_NAME" ]]; then
        echo "${yellow_cor} setup <folder>${clear_cor} : to setup $Z_PROJECT_SHORT_NAME's folder"
      fi
      echo " --"
    if [[ -n "$Z_PROJECT_SHORT_NAME_1" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_1" ]]; then
      echo "${yellow_cor} setup $Z_PROJECT_SHORT_NAME_1${solid_yellow_cor} [<folder>]${clear_cor} : to setup $Z_PROJECT_SHORT_NAME_1's folder"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_2" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_2" ]]; then
      echo "${yellow_cor} setup $Z_PROJECT_SHORT_NAME_2${solid_yellow_cor} [<folder>]${clear_cor} : to setup $Z_PROJECT_SHORT_NAME_2's folder"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_3" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_3" ]]; then
      echo "${yellow_cor} setup $Z_PROJECT_SHORT_NAME_3${solid_yellow_cor} [<folder>]${clear_cor} : to setup $Z_PROJECT_SHORT_NAME_3's folder"
    fi
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
    if [[ "$1" == "$Z_PROJECT_SHORT_NAME_1" || "$1" == "$Z_PROJECT_SHORT_NAME_2" || "$1" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      proj_arg="$1"
    else
      folder_arg="$1"
    fi
  fi

  proj_folder="";
  _setup=${Z_SETUP:-$Z_PACKAGE_MANAGER $([[ $Z_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")setup}

  if [[ -n "$proj_arg" ]]; then
    if [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
      check_prj_1_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_1"
      _setup=${Z_SETUP_1:-$Z_PACKAGE_MANAGER_1 $([[ $Z_PACKAGE_MANAGER_1 == "yarn" ]] && echo "" || echo "run ")setup}

    elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
      check_prj_2_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_2"
      _setup=${Z_SETUP_2:-$Z_PACKAGE_MANAGER_2 $([[ $Z_PACKAGE_MANAGER_2 == "yarn" ]] && echo "" || echo "run ")setup}

    elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      check_prj_3_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_3"
      _setup=${Z_SETUP_3:-$Z_PACKAGE_MANAGER_3 $([[ $Z_PACKAGE_MANAGER_3 == "yarn" ]] && echo "" || echo "run ")setup}

    else
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
    echo "${yellow_cor} revs${clear_cor} : to list reviews from $Z_PROJECT_SHORT_NAME"
    echo "${yellow_cor} revs <pro>${clear_cor} : to list reviews from project"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    echo " fatal: revs requires gum"
    echo " install gum:${blue_cor} https://github.com/charmbracelet/gum ${clear_cor}"
    return 1;
  fi
  
  proj_arg="$Z_PROJECT_SHORT_NAME"

  if [[ -n "$1" ]]; then
    if [[ "$1" == "$Z_PROJECT_SHORT_NAME_1" || "$1" == "$Z_PROJECT_SHORT_NAME_2" || "$1" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      proj_arg="${1:-$Z_PROJECT_SHORT_NAME}"
    else
      echo " fatal: not a valid project: $1"
      echo " ${yellow_cor} pro -h${clear_cor} to see usage"
      return 1;
    fi
  fi

  proj_folder=""

  if [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
    check_prj_1_; if [ $? -ne 0 ]; then return 1; fi
    proj_folder="$Z_PROJECT_FOLDER_1"

  elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
    check_prj_2_; if [ $? -ne 0 ]; then return 1; fi
    proj_folder="$Z_PROJECT_FOLDER_2"

  elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
    check_prj_3_; if [ $? -ne 0 ]; then return 1; fi
    proj_folder="$Z_PROJECT_FOLDER_3"

  else
      echo " fatal: not a valid project: $proj_arg"
      echo " ${yellow_cor} revs -h${clear_cor} to see usage"
    return 1;
  fi

  if [[ -z "$proj_folder" ]]; then
    echo " could not located project folder, please check your config"
    echo "  run${yellow_cor} help${clear_cor} for more information"
    return 1;
  fi

  revs_folder="$proj_folder/revs"

  if [[ ! -d "$revs_folder" ]]; then
    revs_folder="$proj_folder-revs"
  fi

  if [[ ! -d "$revs_folder" ]]; then
    echo " fatal: no revs folder was found in $proj_folder"
    echo " ${yellow_cor} rev -h${clear_cor} to see usage"
    return 1;
  fi

  # REVS__pwd="$(PWD)";

  cd "$revs_folder"
  rev_choices=$(ls -d rev* | xargs -0 | sort -fu)

  if [[ -z "$rev_choices" ]]; then
    echo " fatal: no rev was found in $proj_folder"
    echo " ${yellow_cor} rev -h${clear_cor} to see usage"
    # cd "$REVS__pwd"
    return 1;
  fi

  choice=$(gum choose --limit=1 --header " choose review folder:" $(echo "$rev_choices" | tr ' ' '\n'))
  if [[ $? -eq 0 && -n "$choice" ]]; then
    rev "$proj_arg" "${choice//rev./}" -q
  fi

  # cd "$REVS__pwd"
  return 0;
}

rev() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} rev${clear_cor} : to open a branch for review"
    echo "${yellow_cor} rev <branch>${clear_cor} : to open $Z_PROJECT_SHORT_NAME's branch for review"
    if [[ -n "$Z_PROJECT_SHORT_NAME_1" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_1" ]]; then
      echo "${yellow_cor} rev $Z_PROJECT_SHORT_NAME_1${solid_yellow_cor} [<branch>]${clear_cor} : to open $Z_PROJECT_SHORT_NAME_1's branch for review"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_2" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_2" ]]; then
      echo "${yellow_cor} rev $Z_PROJECT_SHORT_NAME_2${solid_yellow_cor} [<branch>]${clear_cor} : to open $Z_PROJECT_SHORT_NAME_2's branch for review"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_3" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_3" ]]; then
      echo "${yellow_cor} rev $Z_PROJECT_SHORT_NAME_3${solid_yellow_cor} [<branch>]${clear_cor} : to open $Z_PROJECT_SHORT_NAME_3's branch for review"
    fi
    return 0;
  fi

  if [[ $1 == -* ]]; then
    eval "rev -h"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    echo " fatal: rev requires gum"
    echo " install gum:${blue_cor} https://github.com/charmbracelet/gum ${clear_cor}"
    return 1;
  fi

  proj_arg="$Z_PROJECT_SHORT_NAME"
  branch_arg=""

  if [[ -n "$2" ]]; then
    proj_arg="$1"
    branch_arg="$2"
  elif [[ -n "$1" ]]; then
    if [[ "$1" == "$Z_PROJECT_SHORT_NAME_1" || "$1" == "$Z_PROJECT_SHORT_NAME_2" || "$1" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      proj_arg="$1"
    else
      branch_arg="$1"
    fi
  fi

  proj_repo=""
  proj_folder=""
  _setup="";
  _clone="";
  code_editor="$Z_CODE_EDITOR";

  if [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
    check_prj_1_; if [ $? -ne 0 ]; then return 1; fi
    if [[ -z "$Z_PROJECT_REPO_1" ]]; then
      echo " type the repository uri you use for${solid_blue_cor} $proj_arg ${clear_cor}"
      Z_PROJECT_REPO_1=$(gum input --placeholder="git@github.com:fab1o/pump-my-shell.git")
      if [[ -z "$Z_PROJECT_REPO_1" ]]; then
        return 1;
      fi
      echo "  $Z_PROJECT_REPO_1"
      update_config_ "Z_PROJECT_REPO_1" "$Z_PROJECT_REPO_1"
      echo ""
    fi

    proj_repo="$Z_PROJECT_REPO_1"
    proj_folder="$Z_PROJECT_FOLDER_1"
    _setup="$Z_SETUP_1"
    _clone="$Z_CLONE_1"
    code_editor="$Z_CODE_EDITOR_1"

  elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
    check_prj_2_; if [ $? -ne 0 ]; then return 1; fi
    if [[ -z "$Z_PROJECT_REPO_2" ]]; then
      echo " type the repository uri you use for${solid_blue_cor} $proj_arg ${clear_cor}"
      Z_PROJECT_REPO_2=$(gum input --placeholder="git@github.com:fab1o/pump-my-shell.git")
      if [[ -z "$Z_PROJECT_REPO_2" ]]; then
        return 1;
      fi
      echo "  $Z_PROJECT_REPO_2"
      update_config_ "Z_PROJECT_REPO_2" "$Z_PROJECT_REPO_2"
      echo ""
    fi

    proj_repo="$Z_PROJECT_REPO_2"
    proj_folder="$Z_PROJECT_FOLDER_2"
    _setup="$Z_SETUP_2"
    _clone="$Z_CLONE_2"
    code_editor="$Z_CODE_EDITOR_2"

  elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
    check_prj_3_; if [ $? -ne 0 ]; then return 1; fi
    if [[ -z "$Z_PROJECT_REPO_3" ]]; then
      echo " type the repository uri you use for${solid_blue_cor} $proj_arg ${clear_cor}"
      Z_PROJECT_REPO_3=$(gum input --placeholder="git@github.com:fab1o/pump-my-shell.git")
      if [[ -z "$Z_PROJECT_REPO_3" ]]; then
        return 1;
      fi
      echo "  $Z_PROJECT_REPO_3"
      update_config_ "Z_PROJECT_REPO_3" "$Z_PROJECT_REPO_3"
      echo ""
    fi

    proj_repo="$Z_PROJECT_REPO_3"
    proj_folder="$Z_PROJECT_FOLDER_3"
    _setup="$Z_SETUP_3"
    _clone="$Z_CLONE_3"
    code_editor="$Z_CODE_EDITOR_3"

  else
    echo " fatal: not a valid project: $proj_arg"
    echo " ${yellow_cor} rev -h${clear_cor} to see usage"
    return 1;
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
  check_any_pkg_silent_ "$proj_folder"
  if [[ $? -eq 0 ]]; then
    revs_folder="$proj_folder-revs"
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
  if [ $? -ne 0 ]; then
    return 1;
  fi
  if [ $? -ne 0 ]; then
    return 1;
  fi

  pushd "$full_rev_folder" &>/dev/null

  if [[ -n "$_clone" ]]; then
    eval "$_clone" &>/dev/null
  fi

  error_msg=""
  git checkout "$branch" --quiet
  git pull origin --quiet
  if [ $? -ne 0 ]; then
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
    if [[ -n "$Z_PROJECT_SHORT_NAME" ]]; then
      echo "${yellow_cor} clone <branch>${clear_cor} : to clone $Z_PROJECT_SHORT_NAME branch"
      echo "${yellow_cor} clone $Z_PROJECT_SHORT_NAME${solid_yellow_cor} [<branch>]${clear_cor} : to clone $Z_PROJECT_SHORT_NAME branch"
      echo "${yellow_cor} clone $Z_PROJECT_SHORT_NAME ${solid_yellow_cor}<branch>${clear_cor} : to clone $Z_PROJECT_SHORT_NAME branch in multiple mode"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_1" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_1" ]]; then
      echo "${yellow_cor} clone $Z_PROJECT_SHORT_NAME_1${solid_yellow_cor} [<branch>]${clear_cor} : to clone $Z_PROJECT_SHORT_NAME_1 branch"
      echo "${yellow_cor} clone $Z_PROJECT_SHORT_NAME_1 ${solid_yellow_cor}<branch>${clear_cor} : to clone $Z_PROJECT_SHORT_NAME_1 branch in multiple mode"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_2" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_2" ]]; then
      echo "${yellow_cor} clone $Z_PROJECT_SHORT_NAME_2${solid_yellow_cor} [<branch>]${clear_cor} : to clone $Z_PROJECT_SHORT_NAME_2 branch"
      echo "${yellow_cor} clone $Z_PROJECT_SHORT_NAME_2 ${solid_yellow_cor}<branch>${clear_cor} : to clone $Z_PROJECT_SHORT_NAME_2 branch in multiple mode"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_3" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_3" ]]; then
      echo "${yellow_cor} clone $Z_PROJECT_SHORT_NAME_3${solid_yellow_cor} [<branch>]${clear_cor} : to clone $Z_PROJECT_SHORT_NAME_3 branch"
      echo "${yellow_cor} clone $Z_PROJECT_SHORT_NAME_3 ${solid_yellow_cor}<branch>${clear_cor} : to clone $Z_PROJECT_SHORT_NAME_3 branch in multiple mode"
    fi
    return 0;
  fi

  if [[ $1 == -* ]]; then
    eval "clone -h"
    return 0;
  fi

  proj_arg="$Z_PROJECT_SHORT_NAME"
  branch_arg=""

  if [[ -n "$2" ]]; then
    proj_arg="$1"
    branch_arg="$2"
  elif [[ -n "$1" ]]; then
    if [[ "$1" == "$Z_PROJECT_SHORT_NAME_1" || "$1" == "$Z_PROJECT_SHORT_NAME_2" || "$1" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      proj_arg="$1"
    else
      branch_arg="$1"
    fi
  else
    pro_choices=("$Z_PROJECT_SHORT_NAME_1" "$Z_PROJECT_SHORT_NAME_2" "$Z_PROJECT_SHORT_NAME_3")
    proj_arg=$(choose_auto_one_ "choose project to clone:" $pro_choices);
    if [[ -z "$proj_arg" ]]; then
      return 1;
    fi
  fi

  proj_repo=""
  proj_folder=""
  _clone="";
  default_branch=""
  print_readme=1

  if [[ -n "$$proj_arg" ]]; then
    if [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
      if [[ -z "$Z_PROJECT_REPO_1" ]]; then
        echo " type the repository uri you use for${solid_blue_cor} $proj_arg ${clear_cor}"
        Z_PROJECT_REPO_1=$(input_from_ "git@github.com:fab1o/pump-my-shell.git")
        if [[ -z "$Z_PROJECT_REPO_1" ]]; then
          return 1;
        fi
        echo "  $Z_PROJECT_REPO_1"
        update_config_ "Z_PROJECT_REPO_1" "$Z_PROJECT_REPO_1"
        echo ""
      fi
  
      check_prj_1_ -q
      proj_repo="$Z_PROJECT_REPO_1"
      proj_folder="$Z_PROJECT_FOLDER_1"
      _clone="$Z_CLONE_1"
      default_branch="$Z_DEFAULT_BRANCH_1"
      print_readme="$Z_PRINT_README_1"

    elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
      if [[ -z "$Z_PROJECT_REPO_2" ]]; then
        echo " type the repository uri you use for${solid_blue_cor} $proj_arg ${clear_cor}"
        Z_PROJECT_REPO_2=$(input_from_ "git@github.com:fab1o/pump-my-shell.git")
        if [[ -z "$Z_PROJECT_REPO_2" ]]; then
          return 1;
        fi
        echo "  $Z_PROJECT_REPO_2"
        update_config_ "Z_PROJECT_REPO_2" "$Z_PROJECT_REPO_2"
        echo ""
      fi

      check_prj_2_ -q
      proj_repo="$Z_PROJECT_REPO_2"
      proj_folder="$Z_PROJECT_FOLDER_2"
      _clone="$Z_CLONE_2"
      default_branch="$Z_DEFAULT_BRANCH_2"
      print_readme="$Z_PRINT_README_2"

    elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      if [[ -z "$Z_PROJECT_REPO_3" ]]; then
        echo " type the repository uri you use for${solid_blue_cor} $proj_arg ${clear_cor}"
        Z_PROJECT_REPO_3=$(input_from_ "git@github.com:fab1o/pump-my-shell.git")
        if [[ -z "$Z_PROJECT_REPO_3" ]]; then
          return 1;
        fi
        echo "  $Z_PROJECT_REPO_3"
        update_config_ "Z_PROJECT_REPO_3" "$Z_PROJECT_REPO_3"
        echo ""
      fi
  
      check_prj_3_ -q
      proj_repo="$Z_PROJECT_REPO_3"
      proj_folder="$Z_PROJECT_FOLDER_3"
      _clone="$Z_CLONE_3"
      default_branch="$Z_DEFAULT_BRANCH_3"
      print_readme="$Z_PRINT_README_3"
    fi
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
    check_git_silent_ "$proj_folder";
    if [ $? -eq 0 ]; then             # SINGLE MODE
      echo "${solid_blue_cor} $proj_arg${clear_cor} already cloned in 'single mode': $proj_folder"
      echo ""
      echo " to clone a different branch, you must start over in 'multiple mode':"
      echo "  1. either delete:${yellow_cor} del \"$proj_folder\" ${clear_cor}"
      echo "     or change the entry in your pump.zshenv then${yellow_cor} refresh${clear_cor}"
      echo "  2. clone again:${yellow_cor} clone $proj_arg $branch_arg ${clear_cor}"
      return 1;
    else
      if [[ -n "$(ls -A "$proj_folder")" ]]; then
        # is multiple mode
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
        echo "  ${solid_yellow_cor}project folder '$proj_folder' is not empty, going with multiple mode ${clear_cor}"
      else
        branch_to_clone=$(get_clone_default_branch_ "$proj_repo" "$proj_folder");

        if [[ -z "$branch_to_clone" ]]; then
          return 0;
        fi

        if command -v gum &>/dev/null; then
          gum spin --title "cloning... $proj_repo on $branch_to_clone" -- git clone --quiet $proj_repo "$proj_folder"
          echo "   cloning... $proj_repo on $branch_to_clone"
        else
          echo "  cloning... $proj_repo on $branch_to_clone"
          git clone --quiet $proj_repo "$proj_folder"
        fi
        if [ $? -ne 0 ]; then
          echo "  could not clone"
          if [[ -d "$proj_folder" ]]; then
            echo "  project folder already exists: $proj_folder"
          fi
          return 1;
        fi        

        pushd "$proj_folder" &>/dev/null

        git config init.defaultBranch "$branch_to_clone"
        git checkout "$branch_to_clone" --quiet

        if [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
          PUMP_WORKING_BRANCH_1=$(git branch --show-current)
          echo "$PUMP_WORKING_BRANCH_1" > "$PUMP_WORKING_BRANCH_FILE_1";
        elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
          PUMP_WORKING_BRANCH_2=$(git branch --show-current)
          echo "$PUMP_WORKING_BRANCH_2" > "$PUMP_WORKING_BRANCH_FILE_2";
        elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
          PUMP_WORKING_BRANCH_3=$(git branch --show-current)
          echo "$PUMP_WORKING_BRANCH_3" > "$PUMP_WORKING_BRANCH_FILE_3";
        fi

        #refresh >/dev/null 2>&1

        if [[ -n "$_clone" ]]; then
          echo "   ${pink_cor}$_clone ${clear_cor}"
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

        if [[ "$proj_arg" != "$Z_PROJECT_SHORT_NAME" ]]; then
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
      if [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
        update_config_ "Z_DEFAULT_BRANCH_1" "$default_branch"
        Z_DEFAULT_BRANCH_1="$default_branch"
      elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
        update_config_ "Z_DEFAULT_BRANCH_2" "$default_branch"
        Z_DEFAULT_BRANCH_2="$default_branch"
      elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
        update_config_ "Z_DEFAULT_BRANCH_3" "$default_branch"
        Z_DEFAULT_BRANCH_3="$default_branch"
      fi
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
  if [ $? -ne 0 ]; then
    echo "  could not clone"
    if [[ -d "$proj_folder/$branch_to_clone_folder" ]]; then
      echo "  project folder exists: $proj_folder/$branch_to_clone_folder"
    fi
    return 1;
  fi

  pushd "$proj_folder/$branch_to_clone_folder" &>/dev/null
  
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

  if [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
    PUMP_WORKING_BRANCH_1=$(git branch --show-current)
    echo "$PUMP_WORKING_BRANCH_1" > "$PUMP_WORKING_BRANCH_FILE_1";
  elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
    PUMP_WORKING_BRANCH_2=$(git branch --show-current)
    echo "$PUMP_WORKING_BRANCH_2" > "$PUMP_WORKING_BRANCH_FILE_2";
  elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
    PUMP_WORKING_BRANCH_3=$(git branch --show-current)
    echo "$PUMP_WORKING_BRANCH_3" > "$PUMP_WORKING_BRANCH_FILE_3";
  fi

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

  if [[ "$proj_arg" != "$Z_PROJECT_SHORT_NAME" ]]; then
    pro $proj_arg
  fi
}

# Git -----------------------------------------------------------------------==
alias pop="git stash pop --index"
alias st="git status"
alias stashes="git stash list"

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
    echo "${yellow_cor} repush -q${clear_cor} : suppress all output unless an error occurs"
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

    if [[ -z "$Z_COMMIT_ADD" ]]; then
      if confirm_from_ "do you want to recommit all changes with '$last_commit_msg'?"; then
        git add .
        if confirm_from_ "save this preference and don't ask again?"; then
          if [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
            update_config_ "Z_COMMIT_ADD_1" 1
          elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
            update_config_ "Z_COMMIT_ADD_2" 1
          elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
            update_config_ "Z_COMMIT_ADD_3" 1
          fi
          Z_COMMIT_ADD=1
          echo ""
        fi
      fi
    elif [[ $Z_COMMIT_ADD -eq 1 ]]; then
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
    echo ""
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
  elif [[ -z "$Z_COMMIT_ADD" ]]; then
    if confirm_from_ "do you want to recommit all changes?"; then
      git add .
      if confirm_from_ "save this preference and don't ask again?"; then
        if [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
          update_config_ "Z_COMMIT_ADD_1" 1
        elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
          update_config_ "Z_COMMIT_ADD_2" 1
        elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
          update_config_ "Z_COMMIT_ADD_3" 1
        fi
        Z_COMMIT_ADD=1
        echo ""
      fi
    else
      if confirm_from_ "save this preference and don't ask again?"; then
        if [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
          update_config_ "Z_COMMIT_ADD_1" 0
        elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
          update_config_ "Z_COMMIT_ADD_2" 0
        elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
          update_config_ "Z_COMMIT_ADD_3" 0
        fi
        Z_COMMIT_ADD=0
        echo ""
      fi
    fi
  elif [[ $Z_COMMIT_ADD -eq 1 ]]; then
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
    echo "${yellow_cor} push -q${clear_cor} : suppress all output unless an error occurs"
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
    echo ""
  fi
}

pushf() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} pushf${clear_cor} : to force push no-verify to remote"
    echo "${yellow_cor} pushf tags${clear_cor} : to force push tags to remote"
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
    echo ""
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
    return 0;
  fi

  # let git command fail

  if [[ "$1" == "tags" ]] then
    git pull origin --tags "$@"
  else
    git pull origin "$@"
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
  choice=$(echo "$1" | gum filter --limit 1 --indicator ">" --placeholder " $2")
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
    if [ $branch_choices_count -gt 30 ]; then
      select_branch_choice=$(filter_branch_ "$branch_choices" "search branch:" ${@:3})
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

    if [ $PRS_COUNT -gt 30 ]; then
      select_pr_title=$(echo "$titles" | gum filter --select-if-one --height 30 --placeholder " search pull request:");
    else
      select_pr_title=$(echo "$titles" | gum choose --select-if-one --height 30 --header " choose pull request:");
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

    if [[ "$Z_PROJECT_REPO" == git@*:* ]]; then
      # SSH-style: git@host:user/repo.git
      if [[ "$Z_PROJECT_REPO" =~ '^[^@]+@[^:]+:([^[:space:]]+)(\.git)?$' ]]; then
        extracted_repo="${match[1]}"
      fi
    elif [[ "$Z_PROJECT_REPO" == http*://* ]]; then
      # HTTPS-style: https://host/user/repo(.git)
      if [[ "$Z_PROJECT_REPO" =~ '^https\?*://[^/]+/([^[:space:]]+)(\.git)?$' ]]; then
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
    echo "${yellow_cor} gha -a${clear_cor} : to run in auto mode"
    echo "${yellow_cor} gha${solid_yellow_cor} [<workflow>]${clear_cor} : to check status of workflow in current project"
    if [[ -n "$Z_PROJECT_SHORT_NAME_1" ]]; then
      echo "${yellow_cor} gha $Z_PROJECT_SHORT_NAME_1${solid_yellow_cor} [<workflow>]${clear_cor} : to check status of $Z_PROJECT_SHORT_NAME_1's workflow"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_2" ]]; then
      echo "${yellow_cor} gha $Z_PROJECT_SHORT_NAME_2${solid_yellow_cor} [<workflow>]${clear_cor} : to check status of $Z_PROJECT_SHORT_NAME_2's workflow"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_3" ]]; then
      echo "${yellow_cor} gha $Z_PROJECT_SHORT_NAME_3${solid_yellow_cor} [<workflow>]${clear_cor} : to check status of $Z_PROJECT_SHORT_NAME_3's workflow"
    fi
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    echo " fatal: gha requires gum"
    echo " install gum:${blue_cor} https://github.com/charmbracelet/gum ${clear_cor}"
    return 1;
  fi

  workflow_arg="";
  proj_arg="";
  _mode="";

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
      return 1;
    fi
  elif [[ -n "$2" ]]; then
    if [[ "$2" == "-a" ]]; then
      _mode="$2"
      if [[ "$1" == "$Z_PROJECT_SHORT_NAME_1" || "$1" == "$Z_PROJECT_SHORT_NAME_2" || "$1" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
        proj_arg="$1"
      else
        workflow_arg="$1"
      fi
    elif [[ "$1" == "-a" ]]; then
      _mode="$1"
      if [[ "$2" == "$Z_PROJECT_SHORT_NAME_1" || "$2" == "$Z_PROJECT_SHORT_NAME_2" || "$2" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
        proj_arg="$2"
      else
        workflow_arg="$2"
      fi
    else
      if [[ "$1" == "$Z_PROJECT_SHORT_NAME_1" || "$1" == "$Z_PROJECT_SHORT_NAME_2" || "$1" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
        proj_arg="$1"
      else
        workflow_arg="$2"
      fi
    fi
  elif [[ -n "$1" ]]; then
    if [[ "$1" == "-a" ]]; then
      _mode="$1"
    else
      if [[ "$1" == "$Z_PROJECT_SHORT_NAME_1" || "$1" == "$Z_PROJECT_SHORT_NAME_2" || "$1" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
        proj_arg="$1"
      else
        workflow_arg="$1"
      fi
    fi
  fi

  proj_folder="$(PWD)" # default is current folder
  gha_interval="";
  gha_workflow=""

  if [[ -n "$proj_arg" ]]; then
    if [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
      check_prj_1_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_1"
      gha_interval=$Z_GHA_INTERVAL_1
      gha_workflow="$Z_GHA_WORKFLOW_1"

    elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
      check_prj_2_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_2"
      gha_interval=$Z_GHA_INTERVAL_2
      gha_workflow="$Z_GHA_WORKFLOW_2"

    elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      check_prj_3_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_3"
      gha_interval=$Z_GHA_INTERVAL_3
      gha_workflow="$Z_GHA_WORKFLOW_3"
    else
      echo " invalid project name: $proj_arg"
      echo " valid project names are: $Z_PROJECT_SHORT_NAME_1, $Z_PROJECT_SHORT_NAME_2, $Z_PROJECT_SHORT_NAME_3"
      return 1;
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
        if [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
          update_config_ "Z_GHA_WORKFLOW_1" "$chosen_workflow"
          Z_GHA_WORKFLOW_1="$chosen_workflow"
        elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
          update_config_ "Z_GHA_WORKFLOW_2" "$chosen_workflow"
          Z_GHA_WORKFLOW_2="$chosen_workflow"
        elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
          update_config_ "Z_GHA_WORKFLOW_3" "$chosen_workflow"
          Z_GHA_WORKFLOW_3="$chosen_workflow"
        fi
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
    eval "co -h"
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
        git checkout -b "$2"
        if [ $? -eq 0 ]; then
          PUMP_PAST_BRANCH="$pump_past_branch"
          return 0;
        fi
      else
        git checkout -b "$1"
        if [ $? -eq 0 ]; then
          PUMP_PAST_BRANCH="$pump_past_branch"
          return 0;
        fi
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
        if [[ $3 -eq 1 ]]; then git switch "$2" --quiet &>/dev/null; else git switch "$2" --quiet; fi
        if [ $? -eq 0 ]; then
          PUMP_PAST_BRANCH="$pump_past_branch"
          return 0;
        fi
      else
        if [[ $3 -eq 1 ]]; then git switch "$1" --quiet &>/dev/null; else git switch "$1" --quiet; fi
        if [ $? -eq 0 ]; then
          PUMP_PAST_BRANCH="$pump_past_branch"
          return 0;
        fi
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

  PUMP_PAST_BRANCH="$pump_past_branch" # svae this for back() function

  if [[ -n "$Z_PROJECT_FOLDER" && -n "$Z_PROJECT_SHORT_NAME" && -d "$Z_PROJECT_FOLDER" ]]; then
    check_git_silent_ "$Z_PROJECT_FOLDER";
    if [ $? -eq 0 ]; then
      if ! confirm_from_ "save '$branch' as working branch? running "$'\e[34m'$Z_PROJECT_SHORT_NAME$'\e[0m'" will take you back to this branch?"; then
        return 0;
      fi
    fi
  fi

  if [[ -n "$Z_PROJECT_SHORT_NAME" ]]; then
    if [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
      PUMP_WORKING_BRANCH_1=$(git branch --show-current)
      echo "$PUMP_WORKING_BRANCH_1" > "$PUMP_WORKING_BRANCH_FILE_1";
    elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
      PUMP_WORKING_BRANCH_2=$(git branch --show-current)
      echo "$PUMP_WORKING_BRANCH_2" > "$PUMP_WORKING_BRANCH_FILE_2";
    elif [[ "$Z_PROJECT_SHORT_NAME" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      PUMP_WORKING_BRANCH_3=$(git branch --show-current)
      echo "$PUMP_WORKING_BRANCH_3" > "$PUMP_WORKING_BRANCH_FILE_3";
    fi
  fi
}

back() {
  if [[ "$1" == "-h" ]]; then
    echo "${yellow_cor} back${clear_cor} : to go back to previous branch if switched"
    return 0;
  fi

  check_git_; if [ $? -ne 0 ]; then return 1; fi

  if [[ -n "$PUMP_PAST_BRANCH" ]]; then
    co "$PUMP_PAST_BRANCH"
  fi
}

# checkout dev or develop branch
dev() {
  if [[ "$1" == "-h" ]]; then
      echo "${yellow_cor} dev${clear_cor} : to switch to dev in current project"
    if [[ -n "$Z_PROJECT_SHORT_NAME_1" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_1" ]]; then
      echo "${yellow_cor} dev $Z_PROJECT_SHORT_NAME_1 ${clear_cor} : to switch to dev in $Z_PROJECT_SHORT_NAME_1"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_2" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_2" ]]; then
      echo "${yellow_cor} dev $Z_PROJECT_SHORT_NAME_2 ${clear_cor} : to switch to dev in $Z_PROJECT_SHORT_NAME_2"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_3" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_3" ]]; then
      echo "${yellow_cor} dev $Z_PROJECT_SHORT_NAME_3 ${clear_cor} : to switch to dev in $Z_PROJECT_SHORT_NAME_3"
    fi
    return 0;
  fi

  proj_folder="$(PWD)"

  if [[ -n "$1" ]]; then
    if [[ "$1" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
      check_prj_1_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_1"

    elif [[ "$1" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
      check_prj_2_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_2"

    elif [[ "$1" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      check_prj_3_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_3"

    else
      echo " fatal: not a valid project: $1"
      echo " ${yellow_cor} dev -h${clear_cor} to see usage"
      return 1;
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
    if [[ -n "$Z_PROJECT_SHORT_NAME_1" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_1" ]]; then
      echo "${yellow_cor} main $Z_PROJECT_SHORT_NAME_1 ${clear_cor}: to switch to main in $Z_PROJECT_SHORT_NAME_1"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_2" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_2" ]]; then
      echo "${yellow_cor} main $Z_PROJECT_SHORT_NAME_2 ${clear_cor}: to switch to main in $Z_PROJECT_SHORT_NAME_2"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_3" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_3" ]]; then
      echo "${yellow_cor} main $Z_PROJECT_SHORT_NAME_3 ${clear_cor}: to switch to main in $Z_PROJECT_SHORT_NAME_3"
    fi
    return 0;
  fi

  proj_folder="$(PWD)"

  if [[ -n "$1" ]]; then
    if [[ "$1" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
      check_prj_1_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_1"

    elif [[ "$1" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
      check_prj_2_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_2"

    elif [[ "$1" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      check_prj_3_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_3"

    else
      echo " fatal: not a valid project: $1"
      echo " ${yellow_cor} main -h${clear_cor} to see usage"
      return 1;
    fi
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
      echo "${yellow_cor} stage${clear_cor} : to switch to stage in current project"
    if [[ -n "$Z_PROJECT_SHORT_NAME_1" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_1" ]]; then
      echo "${yellow_cor} stage $Z_PROJECT_SHORT_NAME_1 ${clear_cor}: to switch to stage in $Z_PROJECT_SHORT_NAME_1"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_2" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_2" ]]; then
      echo "${yellow_cor} stage $Z_PROJECT_SHORT_NAME_2 ${clear_cor}: to to switch to stage in $Z_PROJECT_SHORT_NAME_2"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_3" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_3" ]]; then
      echo "${yellow_cor} stage $Z_PROJECT_SHORT_NAME_3 ${clear_cor}: to to switch to stage in $Z_PROJECT_SHORT_NAME_3"
    fi
    return 0;
  fi

  proj_folder="$(PWD)"

  if [[ -n "$1" ]]; then
    if [[ "$1" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
      check_prj_1_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_1"

    elif [[ "$1" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
      check_prj_2_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_2"

    elif [[ "$1" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      check_prj_3_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_3"

    else
      echo " fatal: not a valid project: $1"
      echo " ${yellow_cor} stage -h${clear_cor} to see usage"
      return 1;
    fi
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
    echo "${yellow_cor} delb -f${clear_cor} : to delete default braches too"
    if [[ -n "$Z_PROJECT_SHORT_NAME" ]]; then 
      echo "${yellow_cor} delb${solid_yellow_cor} [<branch>]${clear_cor} : to find branches to delete"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_1" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_1" ]]; then
      echo "${yellow_cor} delb $Z_PROJECT_SHORT_NAME_1${solid_yellow_cor} [<branch>]${clear_cor} : to find branches to delete in $Z_PROJECT_SHORT_NAME_1"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_2" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_2" ]]; then
      echo "${yellow_cor} delb $Z_PROJECT_SHORT_NAME_2${solid_yellow_cor} [<branch>]${clear_cor} : to find branches to delete in $Z_PROJECT_SHORT_NAME_2"
    fi
    if [[ -n "$Z_PROJECT_SHORT_NAME_3" && "$Z_PROJECT_SHORT_NAME" != "$Z_PROJECT_SHORT_NAME_3" ]]; then
      echo "${yellow_cor} delb $Z_PROJECT_SHORT_NAME_3${solid_yellow_cor} [<branch>]${clear_cor} : to find branches to delete in $Z_PROJECT_SHORT_NAME_3"
    fi
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
    if [[ "$1" == "$Z_PROJECT_SHORT_NAME_1" || "$1" == "$Z_PROJECT_SHORT_NAME_2" || "$1" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      proj_arg="$1"
    else
      branch_arg="$1"
    fi
  fi

  proj_folder=""
  pump_working_branch=""

  if [[ -n "$proj_arg" ]]; then
    if [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
      check_prj_1_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_1"
      pump_working_branch="$PUMP_WORKING_BRANCH_1"

    elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
      check_prj_2_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_2"
      pump_working_branch="$PUMP_WORKING_BRANCH_2"

    elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
      check_prj_3_; if [ $? -ne 0 ]; then return 1; fi
      proj_folder="$Z_PROJECT_FOLDER_3"
      pump_working_branch="$PUMP_WORKING_BRANCH_3"

    else
      echo " fatal: not a valid project: $proj_arg"
      echo " ${yellow_cor} delb -h${clear_cor} to see usage"
      return 1;
    fi
  else
    proj_folder="$(PWD)"
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
    if [[ -z "$pump_working_branch" && -z "$proj_arg" ]]; then
      proj_arg=$(which_pro_pwd)
      if [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
        pump_working_branch="$PUMP_WORKING_BRANCH_1"
      elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
        pump_working_branch="$PUMP_WORKING_BRANCH_2"
      elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
        pump_working_branch="$PUMP_WORKING_BRANCH_3"
      fi
    fi
    if [[ -n "$pump_working_branch" && -n "$proj_arg" ]]; then
      for branch in $selected_branches; do
        if [[ "$branch" == "$pump_working_branch" ]]; then
          if [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_1" ]]; then
            rm -f "$PUMP_WORKING_BRANCH_FILE_1"
            PUMP_WORKING_BRANCH_1=""
          elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_2" ]]; then
            rm -f "$PUMP_WORKING_BRANCH_FILE_2"
            PUMP_WORKING_BRANCH_2=""
          elif [[ "$proj_arg" == "$Z_PROJECT_SHORT_NAME_3" ]]; then
            rm -f "$PUMP_WORKING_BRANCH_FILE_3"
            PUMP_WORKING_BRANCH_3=""
          fi
        fi
      done
    fi
  fi

  cd "$_pwd"
}

update_

# ==========================================================================
# &>/dev/null	                Hide both stdout and stderr outputs
# 2>/dev/null                 show stdout, hide stderr  
# 1>/dev/null or >/dev/null	  Hide stdout, show stderr
