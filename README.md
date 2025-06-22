# Empty Directory Cleanup Script

A powerful and intelligent shell script that finds and removes empty directories with advanced filtering options, safety features, and comprehensive logging. Perfect for cleaning up cluttered file systems and maintaining organized directory structures.

## 🚀 Features

### Core Functionality
- **Smart Empty Detection**: Identifies truly empty directories while ignoring specified file patterns
- **Hidden File Awareness**: Properly handles hidden files like `.DS_Store`, `.nomedia`, `.Thumbs.db`
- **Recursive Cleanup**: Continues cleaning until no more empty directories are found
- **Safety First**: Interactive confirmation before deletion with preview options
- **Cross-Platform**: Works on macOS (M1/M2), Linux, and Unix-like systems

### Advanced Features
- **Flexible Ignore Patterns**: Customize which files don't count as "content"
- **Depth Control**: Limit how deep the search goes in directory tree
- **Dry Run Mode**: Preview what would be deleted without making changes
- **Comprehensive Logging**: Detailed logs with timestamps and operation history
- **Colored Output**: Easy-to-read terminal output with color coding
- **Statistics Tracking**: Monitor performance and results

## 📋 Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Command Line Options](#command-line-options)
- [Usage Examples](#usage-examples)
- [Configuration](#configuration)
- [System Requirements](#system-requirements)
- [How It Works](#how-it-works)
- [Safety Features](#safety-features)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)
- [Future Enhancements](#future-enhancements)

## 🛠️ Installation

### Method 1: Direct Download
```bash
# Download the script
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/clean_empty_dirs.sh

# Make it executable
chmod +x clean_empty_dirs.sh
```

### Method 2: Clone Repository
```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO
chmod +x clean_empty_dirs.sh
```

### Method 3: System Installation
```bash
# Copy to system PATH (optional)
sudo cp clean_empty_dirs.sh /usr/local/bin/clean-dirs
sudo chmod +x /usr/local/bin/clean-dirs

# Now you can run from anywhere
clean-dirs ~/Downloads
```

## 🚀 Quick Start

### Basic Usage
```bash
# Clean current directory
./clean_empty_dirs.sh

# Clean specific directory
./clean_empty_dirs.sh ~/Downloads

# Preview without deleting (dry run)
./clean_empty_dirs.sh --dry-run ~/Downloads
```

### Common Scenarios
```bash
# Clean with default ignore patterns (.DS_Store, .nomedia, etc.)
./clean_empty_dirs.sh ~/Documents

# Force deletion without confirmation (use with caution!)
./clean_empty_dirs.sh --force ~/temp_folder

# Recursive cleanup until all empty dirs are gone
./clean_empty_dirs.sh --recursive ~/project_folder
```

## ⚙️ Command Line Options

### Basic Options
| Option | Description | Example |
|--------|-------------|---------|
| `TARGET_DIR` | Directory to clean (default: current) | `~/Downloads` |
| `-h, --help` | Show help message | `--help` |
| `--dry-run` | Preview without deleting | `--dry-run ~/test` |

### Filtering Options
| Option | Description | Example |
|--------|-------------|---------|
| `-i, --ignore PATTERNS` | Custom ignore patterns | `-i "*.tmp\|*.bak"` |
| `-d, --depth DEPTH` | Maximum search depth | `-d 3` |

### Behavior Options
| Option | Description | Example |
|--------|-------------|---------|
| `-r, --recursive` | Keep cleaning until done | `--recursive` |
| `-f, --force` | Skip confirmation prompt | `--force` |
| `-q, --quiet` | Minimal output | `--quiet` |
| `-v, --verbose` | Detailed output | `--verbose` |

### Output Options
| Option | Description | Example |
|--------|-------------|---------|
| `--no-log` | Disable logging | `--no-log` |
| `--no-color` | Disable colored output | `--no-color` |

## 📝 Usage Examples

### Example 1: Basic Cleanup
```bash
./clean_empty_dirs.sh ~/Downloads
```
**Output:**
```
🔍 Iteration 1: Scanning for empty directories...
⚠️  Found 5 empty directories:
🗂️  /Users/username/Downloads/empty_folder1
🗂️  /Users/username/Downloads/empty_folder2
❓ Do you want to delete these 5 directories? (yes/no/list): yes
✅ Deleted: /Users/username/Downloads/empty_folder1
✅ Deleted: /Users/username/Downloads/empty_folder2
```

### Example 2: Custom Ignore Patterns
```bash
./clean_empty_dirs.sh -i "*.DS_Store|*.tmp|cache_*" ~/project
```
**What it does:** Ignores `.DS_Store`, `.tmp` files, and anything starting with `cache_`

### Example 3: Dry Run Preview
```bash
./clean_empty_dirs.sh --dry-run ~/test_folder
```
**Output:**
```
🔍 DRY RUN MODE - No files will be deleted
🔍 DRY RUN - Would delete:
   🗂️  /Users/username/test_folder/empty1
   🗂️  /Users/username/test_folder/empty2
```

### Example 4: Depth-Limited Search
```bash
./clean_empty_dirs.sh -d 2 ~/deep_folder_structure
```
**What it does:** Only searches 2 levels deep in the directory tree

### Example 5: Force Recursive Cleanup
```bash
./clean_empty_dirs.sh -f -r ~/cleanup_project
```
**What it does:** Automatically deletes all empty directories found, repeating until none remain

### Example 6: Quiet Mode with Logging
```bash
./clean_empty_dirs.sh --quiet ~/large_folder 2>&1 | grep "Summary"
```
**What it does:** Runs silently but shows only the final summary

## ⚙️ Configuration

The script includes a configuration section at the top that you can modify:

```bash
# Default ignore patterns
DEFAULT_IGNORE_PATTERNS="*.DS_Store|*.nomedia|*.Thumbs.db|*.desktop.ini|*.~*"

# Maximum iterations for recursive cleanup
MAX_ITERATIONS=10

# Safety mode (require confirmation)
SAFETY_MODE=true

# Enable colored output
USE_COLORS=true

# Enable logging by default
ENABLE_LOGGING=true
```

### Common Ignore Patterns

#### macOS Specific
```bash
IGNORE_PATTERNS="*.DS_Store|*.AppleDouble|*.LSOverride|.*._*"
```

#### Windows Specific
```bash
IGNORE_PATTERNS="*.Thumbs.db|*.desktop.ini|*.ini"
```

#### Development Projects
```bash
IGNORE_PATTERNS="*.gitkeep|*.gitignore|*.readme|*.md"
```

#### Media Folders
```bash
IGNORE_PATTERNS="*.nomedia|*.picasa.ini|*.face|Thumbs.db"
```

#### Temporary Files
```bash
IGNORE_PATTERNS="*.tmp|*.temp|*.bak|*.cache|*.lock"
```

## 💻 System Requirements

### Supported Operating Systems
- **macOS** (10.12 Sierra or later, including M1/M2 Macs)
- **Linux** (Ubuntu 16.04+, CentOS 7+, Debian 9+)
- **Unix-like systems** with bash support

### Required Commands
Standard Unix commands (available on most systems):
- `bash` (version 4.0+)
- `find`
- `rmdir`
- `date`
- `mktemp`

### Optional Dependencies
- `tput` - For better color support
- `stat` - For detailed file information (if available)

### Performance Considerations
- **Memory Usage**: Minimal, suitable for systems with 512MB+ RAM
- **Disk Space**: Requires minimal temporary space for logging
- **Processing Time**: ~1000 directories per second on modern systems

## 🔍 How It Works

### Detection Algorithm
1. **Directory Traversal**: Uses `find` to locate all directories
2. **Content Analysis**: Checks each directory for files
3. **Pattern Matching**: Applies ignore patterns to determine "effective emptiness"
4. **Safety Validation**: Confirms directories are still empty before deletion

### Empty Directory Criteria
A directory is considered empty if it contains only:
- No files at all, OR
- Only files matching ignore patterns (e.g., `.DS_Store`)

### Processing Flow
```
Start → Find Directories → Check Contents → Apply Patterns → 
Confirm with User → Delete → Log Results → Repeat (if recursive)
```

### Example Scenarios

#### Scenario 1: Truly Empty Directory
```
folder/
└── (nothing)
```
**Result**: ✅ Deleted

#### Scenario 2: Only Hidden System Files
```
folder/
├── .DS_Store
└── .nomedia
```
**Result**: ✅ Deleted (files match ignore patterns)

#### Scenario 3: Contains Real Content
```
folder/
├── .DS_Store
├── important_file.txt
└── photo.jpg
```
**Result**: ❌ Kept (contains real files)

#### Scenario 4: Nested Empty Directories
```
parent/
└── child/
    └── grandchild/
        └── .DS_Store
```
**Result**: ✅ All deleted (recursive cleanup)

## 🛡️ Safety Features

### Interactive Confirmation
- **Preview Mode**: Shows what will be deleted before confirmation
- **List Option**: Detailed view of directories and their ignored files
- **User Control**: Requires explicit "yes" to proceed

### Dry Run Protection
```bash
./clean_empty_dirs.sh --dry-run ~/important_folder
```
- Shows exactly what would be deleted
- No actual file system changes
- Safe for testing and verification

### Comprehensive Logging
- **Timestamped Logs**: Every operation recorded with timestamp
- **Error Tracking**: Failed deletions logged with reasons
- **Audit Trail**: Complete history of what was changed

### Error Handling
- **Graceful Failures**: Script continues even if some deletions fail
- **Permission Checks**: Handles permission-denied scenarios
- **Path Validation**: Ensures target directories exist

### Backup Recommendations
Before running on important directories:
```bash
# Create a backup
tar -czf backup_$(date +%Y%m%d).tar.gz ~/important_folder

# Run dry-run first
./clean_empty_dirs.sh --dry-run ~/important_folder

# Then run actual cleanup
./clean_empty_dirs.sh ~/important_folder
```

## 🐛 Troubleshooting

### Common Issues

#### Permission Denied
```bash
# Error: Permission denied deleting directory
# Solution: Check ownership and permissions
ls -la problematic_directory
sudo ./clean_empty_dirs.sh ~/protected_folder  # If necessary
```

#### Directory Not Empty (False Positive)
```bash
# Error: rmdir: directory not empty
# Cause: Hidden files not in ignore patterns
# Solution: Add custom ignore patterns
./clean_empty_dirs.sh -i "*.DS_Store|*.hidden_file" ~/folder
```

#### Script Not Executable
```bash
# Error: Permission denied executing script
# Solution: Make script executable
chmod +x clean_empty_dirs.sh
```

#### No Directories Found
```bash
# Issue: Script reports no empty directories but you see some
