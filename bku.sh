#!/bin/bash
ACTION=$1; PARAM1=$2; PARAM2=$3
timestamp=$(date "+%H:%M-%d/%m/%Y")

# ===== ROOT CHECK =====
if [[ "$ACTION" != "init" && ! -d ".bku/" ]]; then
  echo "Must be a BKU root folder."
  exit 1
fi

# ===== INIT =====
if [[ "$ACTION" = "init" ]]; then
  if [[ -d ".bku" ]]; then
    echo "Error: Backup already initialized in this folder."
    exit 1
  else
    mkdir -p .bku/backup
    touch .bku/tracked_files.txt
    touch .bku/history.log
    echo "Backup initialized."
    echo "$timestamp: BKU Init." >> .bku/history.log
  fi

# ===== ADD =====
elif [[ "$ACTION" = "add" ]]; then
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
elif [[ "$ACTION" = "status" ]]; then
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
    if [[ -z "dif" ]]; then
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
elif [[ "$ACTION" = "commit" ]]; then
  if [[ -z "$PARAM1" ]]; then
    echo "Error: Commit message is required."
    exit 1
  fi
  
  has_changed=0
  changed_files=()
  commit_file() {
    local file="$1"
    [[ -f "$file" ]] || return
    dif=$(diff -u .bku/backup/$file $file | tail -n +3)
    if [[ -n "$dif" ]]; then
      if [[ -f ".bku/backup/$file" ]]; then
        cp ".bku/backup/$file" ".bku/backup/$file.prev"
      fi
      echo "$dif" > ".bku/backup/$file.patch"
      cp "$file" ".bku/backup/$file"
      echo "Committed $file with ID $timestamp."
      changed_files+=("$file")
      has_changed=1
    fi
  }

  if [[ -z "$PARAM2" ]]; then
    while read -r line; do
      [[ -f "$line" ]] && commit_file "$line"
    done < .bku/tracked_files.txt
  else
    file="${PARAM2#./}"
    if ! grep -Fxq "$file" .bku/tracked_files.txt; then
      echo "Error: $file is not tracked."
      exit 1
    fi
    commit_file "$file"
  fi
  if [[ $has_changed -eq 0 ]]; then
    echo "Error: No change to commit."
    exit 1
  fi
  file_list=$(IFS=,; echo "${changed_files[*]}")
  echo "$timestamp: $PARAM1 ($file_list)" >> .bku/history.log

# ===== HISTORY =====
elif [[ "$ACTION" = "history" ]]; then tac .bku/history.log

# ==== RESTORE ====
elif [[ "$ACTION" = "restore" ]]; then
  if [[ ! -s .bku/tracked_files.txt ]]; then
    echo "Error: Nothing has been tracked."
    exit 1
  fi

  has_restored=0; update_history=0
  restore_file() {
    local file="$1"
    if [[ -f ".bku/backup/$file.patch" ]]; then
      patch -R -s --no-backup-if-mismatch "$file" < ".bku/backup/$file.patch" >/dev/null 2>&1
      if [[ $? -ne 0 ]]; then
        cp ".bku/backup/$file" "$file"
        rm -f "$file.rej"
        echo "Error: Restored $file to latest committed version."
        has_restored=1
        return
      fi      
      echo "Restored $file to its previous version."
      has_restored=1
      update_history=1
      return
    else
      echo "Error: No previous version available for $file."
    fi
  }
  
  if [[ -z "$PARAM1" ]]; then
    while read -r line; do
      [[ -f "$line" ]] && restore_file "$line"
    done < .bku/tracked_files.txt
  else
    file="${PARAM1#./}"
    if ! grep -Fxq "$file" .bku/tracked_files.txt; then
      echo "Error: $file is not tracked."
      exit 1
    fi
    restore_file "$file"
  fi
  if [[ $has_restored -eq 0 ]]; then
    echo "Error: No file to be restored."
    exit 1
  fi
  if [[ $update_history -eq 1 ]]; then
    sed -i '$d' .bku/history.log
  fi

# ==== SCHEDULE ====
elif [[ "$ACTION" = "schedule" ]]; then
  if [[ -z "$PARAM1" ]]; then
    echo "Error: Invalid schedule option."
    exit 1
  fi
  SCRIPT_PATH="$(realpath "$0")"
  (crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH commit \"Scheduled backup\"") | crontab -
  case "$PARAM1" in
    --daily)
      (crontab -l 2>/dev/null; echo "0 0 * * * cd $PWD && bash $SCRIPT_PATH commit \"Scheduled backup\"") | crontab -
      echo "Scheduled daily backups at daily."
      ;;

    --hourly)
      (crontab -l 2>/dev/null; echo "0 * * * * cd $PWD && bash $SCRIPT_PATH commit \"Scheduled backup\"") | crontab -
      echo "Scheduled hourly backups at hourly."
      ;;

    --weekly)
      (crontab -l 2>/dev/null; echo "0 0 * * 1 cd $PWD && bash $SCRIPT_PATH commit \"Scheduled backup\"") | crontab -
      echo "Scheduled weekly backups at weekly."
      ;;

    --off)
      echo "Backup scheduling disabled."
      ;;

    *)
      echo "Error: Invalid schedule option."
      exit 1
      ;;
  esac
# ==== STOP ====
elif [[ "$ACTION" = "stop" ]]; then
  if [[ ! -d ".bku" ]]; then
    echo "Error: No backup system to be removed."
    exit 1
  fi
  SCRIPT_PATH="$(realpath "$0")"
  (crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH commit \"Scheduled backup\"") | crontab -
  rm -rf .bku
  echo "Backup system removed."
fi
