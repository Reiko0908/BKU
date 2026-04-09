# 📦 BKU (Backup Utility)

A lightweight, Git-inspired local version control system built entirely in Bash.  
BKU is designed to selectively back up source code files within a project, storing only the exact differences (diffs) between commits instead of full file copies.

> Developed for the Operating Systems course at Ho Chi Minh City University of Technology (HCMUT).

---

## ✨ Features

- **Local Initialization**  
  Initializes a `.bku` repository strictly within the project root to avoid accidental global tracking.

- **Selective Tracking**  
  Track individual files or all files in the directory with simple commands.

- **Smart Diffing**  
  Uses standard Linux tools (`diff`, `patch`) to store only changes between commits, saving disk space.

- **Read-Only Status Checks**  
  View changes without modifying any files.

- **Chronological History**  
  Maintain a timestamped log of all commits and modified files.

- **Version Restoration**  
  Roll back files to their previous committed state instantly.

- **Automated Scheduling**  
  Schedule backups using `cron` (daily, hourly, weekly).

---

## 🛠️ Prerequisites

Ensure the following tools are installed:

- `bash`
- `diffutils` (`diff`, `patch`)
- `cron`

---

## 🚀 Installation

### 1. Make scripts executable

```bash
chmod +x bku.sh setup.sh
```

### 2. Install globally

```bash
./setup.sh --install
```

### 3. Uninstall (optional)

```bash
./setup.sh --uninstall
```

> 💡 You can also run locally without installing:
```bash
./bku.sh <command>
```

---

## 📖 Usage Guide

### 1. Initialize

Create a `.bku` repository in the current directory:

```bash
bku init
```

---

### 2. Add Files

Track files for backup:

```bash
bku add                 # Track all files (excluding .bku)
bku add ./src/main.c    # Track a specific file
```

---

### 3. Check Status

View changes since last commit:

```bash
bku status              # All tracked files
bku status ./src/main.c # Specific file
```

---

### 4. Commit Changes

Save changes as diffs:

```bash
bku commit "Fix typo in loop"
bku commit "Update main" ./src/main.c
```

---

### 5. View History

Show commit logs:

```bash
bku history
```

---

### 6. Restore Files

Revert to previous version:

```bash
bku restore
bku restore ./src/main.c
```

---

### 7. Schedule Automated Backups

Use cron-based scheduling:

```bash
bku schedule --daily
bku schedule --hourly
bku schedule --weekly
bku schedule --off
```

---

### 8. Remove Backup System

Delete `.bku` and disable scheduled jobs:

```bash
bku stop
```

---

## 📂 Project Structure

```
.
├── bku.sh
├── setup.sh
└── .bku/
    ├── backup/
    ├── diffs/
    ├── logs/
    └── tracked_files.txt
```

---

## ⚠️ Notes

- All commands must be executed from the project root (where `.bku` is initialized).
- `.bku` directory should not be modified manually.
- Designed for **local usage only** (not a replacement for Git).

---

## 👤 Author

**Reiko0908**
