#!/usr/bin/env bash

INSTALL_PATH="/usr/local/bin/bku"
BKU_SOURCE="bku.sh"
DEPENDENCIES=("diff" "patch" "tac" "sed" "find" "date" "realpath" "crontab")
PACKAGES=("diffutils" "patch" "coreutils" "sed" "findutils" "coreutils" "coreutils" "cron")

do_install() {
  echo "Checking dependencies..."
  local missing_pkgs=()
  for i in "${!DEPENDENCIES[@]}"; do
    command -v "${DEPENDENCIES[$i]}" &>/dev/null || missing_pkgs+=("${PACKAGES[$i]}")
  done
  if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
    sudo apt-get update -y &>/dev/null
    if ! sudo apt-get install -y "${missing_pkgs[@]}" &>/dev/null; then
      echo "Error: Failed to install packages. Please check your package manager or install them manually."
      exit 1
    fi
  fi
  echo "All dependencies installed."
  if [[ ! -f "$BKU_SOURCE" ]]; then
    echo "Error: $BKU_SOURCE not found in current directory."
    exit 1
  fi
  sudo cp "$BKU_SOURCE" "$INSTALL_PATH" || { echo "Error: Failed to install BKU."; exit 1; }
  sudo chmod +x "$INSTALL_PATH"
  echo "BKU installed to $INSTALL_PATH."
}

do_uninstall() {
  echo "Checking BKU installation..."
  if [[ ! -f "$INSTALL_PATH" ]]; then
    echo "Error: BKU is not installed in $INSTALL_PATH. Nothing to uninstall."
    exit 1
  fi
  echo "Removing BKU from $INSTALL_PATH..."
  sudo rm -f "$INSTALL_PATH"
  echo "Removing scheduled backups..."
  crontab -l 2>/dev/null | grep -v "bku" | crontab - 2>/dev/null || true
  sudo crontab -l 2>/dev/null | grep -v "bku" | sudo crontab - 2>/dev/null || true
  echo "BKU successfully uninstalled."
}

case "${1:-}" in
  --install)   do_install ;;
  --uninstall) do_uninstall ;;
  *)
    echo "Usage: $0 --install | --uninstall"
    exit 1
    ;;
esac
