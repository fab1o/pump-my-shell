#!/bin/zsh
# This script is used to migrate the pump plugin config to a newer version

set -e
setopt extended_glob

DEST_DIR="$HOME/.oh-my-zsh/plugins/pump"
DEST_DIR_CONFIG="$DEST_DIR/config"
DEST_CONFIG="$DEST_DIR_CONFIG/pump.zshenv"
BACKUP_SUFFIX="bak"
#$(date +%Y%m%d%H%M%S)"
SRC_CONFIG="./config/pump.zshenv"

if [[ ! -f "$DEST_CONFIG" ]]; then
  #echo " 📦 copying configuration file..."

  mkdir -p "$DEST_DIR_CONFIG"
  cp -R "$SRC_CONFIG" "$DEST_CONFIG"
  exit 0
fi

#echo " 🔄 merging configuration... $DEST_CONFIG"

# remove old backup files
# List all matching files
files=($DEST_DIR_CONFIG/pump.zshenv.[0-9]##.[0-9]##.[0-9]##.bak(N))
if [[ -n "$files" ]]; then
  # Extract versions and associate them with filenames
  typeset -A version_map

  for file in $files; do
    if [[ "$file" =~ pump\.zshenv\.([0-9]+)\.([0-9]+)\.([0-9]+)\.bak ]]; then
      version="${match[1]}.${match[2]}.${match[3]}"
      version_map[$version]=$file
    fi
  done

  # Sort versions in reverse (descending) using version sort
  sorted_versions=($(print -l ${(k)version_map} | sort -V -r))

  # Take the top two highest versions
  top_versions=($sorted_versions[1] $sorted_versions[2])

  # Get files to keep
  keep_files=()
  for v in $top_versions; do
    keep_files+=($version_map[$v])
  done

  # Remove all others
  for file in $files; do
    if [[ ! " ${keep_files[@]} " =~ " $file " ]]; then
      rm "$file"
    fi
  done
fi

# VERSION=$(curl -s $RELEASE_API | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
VERSION=$(awk -F'"' '/"version"/ {print $4}' package.json)
cp "$DEST_CONFIG" "${DEST_CONFIG}.$VERSION.$BACKUP_SUFFIX"
#echo " 📋 backup created: ${DEST_CONFIG}.$VERSION.$BACKUP_SUFFIX"

# Create associative arrays for lookups
typeset -A src_keys dest_keys

# Helper function to extract key from a line
extract_key() {
  echo "$1" | sed -n 's/^\([A-Z_0-9]*\)=.*$/\1/p'
}

# Read source keys
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" =~ "^#" ]] && continue
  key=$(extract_key "$line")
  [[ -n "$key" ]] && src_keys[$key]="$line"
done < "$SRC_CONFIG"

# Read destination values
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" =~ "^#" ]] && continue
  key=$(extract_key "$line")
  [[ -n "$key" ]] && dest_keys[$key]="$line"
done < "$DEST_CONFIG"

# Build the new file
new_lines=()

while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ -z "$line" || "$line" =~ "^#" ]]; then
    new_lines+=("$line")
    continue
  fi

  key=$(extract_key "$line")

  if [[ -n "$key" ]]; then
    if [[ -v dest_keys[$key] ]]; then
      new_lines+=("${dest_keys[$key]}")
    else
      new_lines+=("$line")
    fi
  else
    new_lines+=("$line")
  fi
done < "$SRC_CONFIG"

# Append remaining keys in dest that are NOT in source
for key in "${(@k)dest_keys}"; do
  if [[ -z "${src_keys[$key]}" ]]; then
    #echo " 🗑️  removing orphan key: $key"
    continue
  fi
done

# Write new merged content
printf "%s\n" "${new_lines[@]}" > "$DEST_CONFIG"

echo " config synced."
