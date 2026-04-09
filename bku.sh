#!/bin/bash
ACTION=$1; PARAM1=$2; PARAM2=$3
timestamp=$(date "+%H:%M-%d/%m/%Y")

# ===== ROOT CHECK =====
if [[ "$ACTION" != "init" ]]; then
  if [[ ! -d ".bku" ]]; then
    echo "Must be a BKU root folder."
    exit 1
  fi
fi

# ===== INIT =====
if [[ $ACTION = "init" ]]; then
  if [[ -d ".bku" ]]; then
    echo "Error: Backup already initialized in this folder."
    exit 1
  fi
  mkdir -p .bku/backup
  touch .bku/tracked_files.txt
  touch .bku/history.log
  echo "Backup initialized."

# ===== ADD =====
elif [[ $ACTION = "add" ]]; then
  if [[ -z "$PARAM1" ]]; then
    find * -type f | while read -r file; do
    if grep -Fxq "$file" .bku/tracked_files.txt; then
      echo "Error: $file is already tracked."
    else
      echo $file >>.bku/tracked_files.txt
      cp --parents $file .bku/backup/
      echo "Added $file to backup tracking."
    fi
  done
else
  file="${PARAM1#./}"
  if [[ ! -f "$file" ]]; then
    echo "Error: $file does not exist."
    exit 1
  fi
  if grep -Fxq "$file" .bku/tracked_files.txt; then
    echo "Error: $file is already tracked."
    exit 1
  fi
  echo "$file" >> .bku/tracked_files.txt
  cp --parents $file .bku/backup/
  echo "Added $file to backup tracking."
  fi

# ==== STATUS =====
elif [[ $ACTION = "status" ]]; then
  if [[ ! -s .bku/tracked_files.txt ]]; then
    echo "Error: Nothing has been tracked."
    exit 1
  fi

  show_status() {
    local file="$1"
    if [[ ! -f ".bku/backup/$file" ]]; then
      echo "$file: No changes"
      return
    fi

    dif=$(diff -u .bku/backup/$file $file | tail -n +3)
    if [[ -z dif ]]; then
      echo "$file: No changes"
    else
      echo "$file:"
      echo "$dif"
    fi
  }

  if [[ -z "$PARAM1" ]]; then
    while read -r line; do
      [[ -f "$line" ]] && show_status "$line"
    done < .bku/tracked_files.txt
  else
    file="${PARAM1#./}"
    if ! grep -Fxq "$file" .bku/tracked_files.txt; then
      echo "Error: $file is not tracked."
      exit 1
    fi
    show_status "$file"
  fi  

# ==== COMMIT =====
elif [[ $ACTION = "commit" ]]; then
  if [[ -z "$PARAM1" ]]; then
    echo "Error: Commit message is required."
    exit 1
  fi
  
  has_changed = 0
  commit_file() {
    file="$1"
    [[ -f $file""]] || return
    diff=$(diff -u .bku/backup/$file $file | tail -n +3)
    if [[ -n "$diff" ]]; then
      if [[ -f ".bku/backup/$file" ]]; then
        cp ".bku/backup/$file" ".bku/backup/$file.prev"
      fi
      echo "$diff" > ".bku/backup/$file.patch"
      cp
    fi
  }
fi

