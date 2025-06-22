#!/bin/bash

# Empty Directory Cleanup Script
# Intelligently finds and removes empty directories with advanced filtering options
# Compatible with macOS (M1/M2) and Linux systems

# =============================================================================
# CONFIGURATION SECTION - Modify these as needed
# =============================================================================

# Default ignore patterns (files that don't count as "content")
DEFAULT_IGNORE_PATTERNS="*.DS_Store|*.nomedia|*.Thumbs.db|*.desktop.ini|*.~*"

# Depth limit for directory traversal (0 = no limit)
MAX_DEPTH=0

# Safety mode - require confirmation before deletion
SAFETY_MODE=true

# Logging settings
ENABLE_LOGGING=true
LOG_DIRECTORY=""  # Empty = same as target directory

# Output colors
USE_COLORS=true

# Recursive cleanup (repeatedly scan until no more empty dirs found)
RECURSIVE_CLEANUP=true
MAX_ITERATIONS=10

# =============================================================================
# SCRIPT VARIABLES
# =============================================================================

SCRIPT_VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_FILE=""
TEMP_FILE=""

# Statistics
TOTAL_SCANNED=0
TOTAL_FOUND=0
TOTAL_DELETED=0
TOTAL_FAILED=0
ITERATIONS=0

# Colors
if [[ "$USE_COLORS" == "true" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE='' NC=''
fi

# =============================================================================
# FUNCTIONS
# =============================================================================

print_usage() {
    echo "Empty Directory Cleanup Script v$SCRIPT_VERSION"
    echo "Usage: $0 [OPTIONS] [TARGET_DIR]"
    echo ""
    echo "Parameters:"
    echo "  TARGET_DIR              Directory to clean (default: current directory)"
    echo ""
    echo "Options:"
    echo "  -i, --ignore PATTERNS   Comma or pipe-separated ignore patterns"
    echo "                          (default: $DEFAULT_IGNORE_PATTERNS)"
    echo "  -d, --depth DEPTH       Maximum depth to search (0 = unlimited)"
    echo "  -r, --recursive         Enable recursive cleanup until no empty dirs found"
    echo "  -f, --force             Skip confirmation prompt (dangerous!)"
    echo "  -q, --quiet             Quiet mode - minimal output"
    echo "  -v, --verbose           Verbose mode - detailed output"
    echo "  --dry-run               Show what would be deleted without deleting"
    echo "  --no-log                Disable logging"
    echo "  --no-color              Disable colored output"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Clean current directory"
    echo "  $0 ~/Downloads                       # Clean Downloads folder"
    echo "  $0 -i \"*.DS_Store|*.tmp\" ~/folder   # Custom ignore patterns"
    echo "  $0 --dry-run ~/test                  # Preview without deleting"
    echo "  $0 -f -r ~/cleanup                   # Force recursive cleanup"
    echo ""
    echo "Ignore Patterns:"
    echo "  Use wildcards: *.DS_Store, temp_*, .hidden"
    echo "  Separate multiple patterns with | or ,"
    echo "  Case-sensitive matching"
}

log_message() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ "$ENABLE_LOGGING" == "true" && -n "$LOG_FILE" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
}

print_colored() {
    local color="$1"
    local message="$2"
    local no_newline="$3"
    
    if [[ "$no_newline" == "true" ]]; then
        echo -ne "${color}${message}${NC}"
    else
        echo -e "${color}${message}${NC}"
    fi
}

print_header() {
    echo ""
    print_colored "$CYAN" "════════════════════════════════════════════════════════════════"
    print_colored "$WHITE" "           Empty Directory Cleanup Script v$SCRIPT_VERSION"
    print_colored "$CYAN" "════════════════════════════════════════════════════════════════"
    echo ""
}

is_effectively_empty() {
    local dir="$1"
    local ignore_patterns="$2"
    local files=()
    local skip=false
    
    # Enable hidden file matching
    shopt -s nullglob dotglob
    
    # Check all files in directory
    for file in "$dir"/*; do
        # Skip if file doesn't exist (empty glob)
        [[ ! -e "$file" ]] && continue
        
        skip=false
        filename=$(basename "$file")
        
        # Check against ignore patterns
        IFS='|,' read -ra PATTERNS <<< "$ignore_patterns"
        for pattern in "${PATTERNS[@]}"; do
            pattern=$(echo "$pattern" | xargs) # trim whitespace
            if [[ "$filename" == $pattern ]]; then
                skip=true
                break
            fi
        done
        
        # If file doesn't match ignore patterns, directory is not empty
        if [[ "$skip" == "false" ]]; then
            shopt -u nullglob dotglob
            return 1
        fi
    done
    
    shopt -u nullglob dotglob
    return 0
}

find_empty_directories() {
    local target_dir="$1"
    local ignore_patterns="$2"
    local max_depth="$3"
    local empty_dirs=()
    
    # Build find command
    local find_cmd="find \"$target_dir\" -type d"
    if [[ $max_depth -gt 0 ]]; then
        find_cmd="$find_cmd -maxdepth $max_depth"
    fi
    
    # Create temporary file for results
    TEMP_FILE=$(mktemp)
    
    # Find directories and check if they're effectively empty
    eval "$find_cmd" | while IFS= read -r dir; do
        ((TOTAL_SCANNED++))
        if is_effectively_empty "$dir" "$ignore_patterns"; then
            echo "$dir" >> "$TEMP_FILE"
        fi
    done
    
    # Read results from temp file
    if [[ -f "$TEMP_FILE" ]]; then
        mapfile -t empty_dirs < "$TEMP_FILE"
        rm -f "$TEMP_FILE"
    fi
    
    printf '%s\n' "${empty_dirs[@]}"
}

confirm_deletion() {
    local count="$1"
    local dirs=("${@:2}")
    
    if [[ "$SAFETY_MODE" == "false" ]]; then
        return 0
    fi
    
    echo ""
    print_colored "$YELLOW" "⚠️  Found $count empty directories:"
    echo ""
    
    for dir in "${dirs[@]}"; do
        print_colored "$PURPLE" "🗂️  $dir"
    done
    
    echo ""
    print_colored "$YELLOW" "❓ Do you want to delete these $count directories? " "true"
    read -rp "(yes/no/list): " CONFIRM
    
    case "${CONFIRM,,}" in
        "yes"|"y")
            return 0
            ;;
        "list"|"l")
            echo ""
            print_colored "$BLUE" "📋 Detailed directory list:"
            for i, dir in "${!dirs[@]}"; do
                echo "  $((i+1)). $dir"
                # Show ignored files if any
                if [[ -d "$dir" ]]; then
                    shopt -s nullglob dotglob
                    local ignored_files=()
                    for file in "$dir"/*; do
                        [[ -e "$file" ]] && ignored_files+=("$(basename "$file")")
                    done
                    if [[ ${#ignored_files[@]} -gt 0 ]]; then
                        echo "     └─ Ignored files: ${ignored_files[*]}"
                    fi
                    shopt -u nullglob dotglob
                fi
            done
            echo ""
            confirm_deletion "$count" "${dirs[@]}"
            return $?
            ;;
        *)
            return 1
            ;;
    esac
}

delete_directories() {
    local dirs=("$@")
    local success=0
    local failed=0
    
    print_colored "$BLUE" "🧹 Starting deletion process..."
    echo ""
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            print_colored "$YELLOW" "⚠️  Directory no longer exists: $dir"
            log_message "Directory no longer exists: $dir" "WARN"
            continue
        fi
        
        if rmdir "$dir" 2>/dev/null; then
            print_colored "$GREEN" "✅ Deleted: $dir"
            log_message "Successfully deleted: $dir" "SUCCESS"
            ((success++))
        else
            print_colored "$RED" "❌ Failed to delete: $dir"
            log_message "Failed to delete: $dir ($(ls -la "$dir" 2>/dev/null | wc -l) items)" "ERROR"
            ((failed++))
        fi
    done
    
    TOTAL_DELETED=$success
    TOTAL_FAILED=$failed
    
    echo ""
    print_colored "$CYAN" "📊 Deletion Summary:"
    print_colored "$GREEN" "   ✅ Successfully deleted: $success directories"
    if [[ $failed -gt 0 ]]; then
        print_colored "$RED" "   ❌ Failed to delete: $failed directories"
    fi
}

cleanup_iteration() {
    local target_dir="$1"
    local ignore_patterns="$2"
    local max_depth="$3"
    local iteration="$4"
    
    print_colored "$BLUE" "🔍 Iteration $iteration: Scanning for empty directories..."
    
    # Find empty directories
    local empty_dirs_array=()
    mapfile -t empty_dirs_array < <(find_empty_directories "$target_dir" "$ignore_patterns" "$max_depth")
    
    local count=${#empty_dirs_array[@]}
    TOTAL_FOUND=$count
    
    if [[ $count -eq 0 ]]; then
        print_colored "$GREEN" "✅ No empty directories found."
        log_message "No empty directories found in iteration $iteration" "INFO"
        return 1 # Signal completion
    fi
    
    print_colored "$YELLOW" "📁 Found $count empty directories"
    log_message "Found $count empty directories in iteration $iteration" "INFO"
    
    # List directories in verbose mode
    if [[ "$VERBOSE_MODE" == "true" ]]; then
        for dir in "${empty_dirs_array[@]}"; do
            print_colored "$PURPLE" "   🗂️  $dir"
        done
    fi
    
    # Confirm deletion
    if [[ "$DRY_RUN" == "true" ]]; then
        print_colored "$CYAN" "🔍 DRY RUN - Would delete:"
        for dir in "${empty_dirs_array[@]}"; do
            print_colored "$PURPLE" "   🗂️  $dir"
        done
        return 1 # Don't continue in dry-run mode
    fi
    
    if confirm_deletion "$count" "${empty_dirs_array[@]}"; then
        delete_directories "${empty_dirs_array[@]}"
        return 0 # Continue for recursive cleanup
    else
        print_colored "$YELLOW" "🚫 Deletion cancelled by user."
        log_message "Deletion cancelled by user in iteration $iteration" "INFO"
        return 1 # User cancelled
    fi
}

# =============================================================================
# MAIN SCRIPT
# =============================================================================

# Parse command line arguments
TARGET_DIR=""
IGNORE_PATTERNS="$DEFAULT_IGNORE_PATTERNS"
QUIET_MODE=false
VERBOSE_MODE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--ignore)
            IGNORE_PATTERNS="$2"
            shift 2
            ;;
        -d|--depth)
            MAX_DEPTH="$2"
            shift 2
            ;;
        -r|--recursive)
            RECURSIVE_CLEANUP=true
            shift
            ;;
        -f|--force)
            SAFETY_MODE=false
            shift
            ;;
        -q|--quiet)
            QUIET_MODE=true
            VERBOSE_MODE=false
            shift
            ;;
        -v|--verbose)
            VERBOSE_MODE=true
            QUIET_MODE=false
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-log)
            ENABLE_LOGGING=false
            shift
            ;;
        --no-color)
            USE_COLORS=false
            RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE='' NC=''
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

# Set default target directory
TARGET_DIR="${TARGET_DIR:-$(pwd)}"

# Validate target directory
if [[ ! -d "$TARGET_DIR" ]]; then
    print_colored "$RED" "❌ Directory not found: $TARGET_DIR"
    exit 1
fi

# Convert to absolute path
TARGET_DIR=$(cd "$TARGET_DIR" && pwd)

# Setup logging
if [[ "$ENABLE_LOGGING" == "true" ]]; then
    if [[ -n "$LOG_DIRECTORY" ]]; then
        LOG_FILE="$LOG_DIRECTORY/clean_empty_dirs_$TIMESTAMP.log"
    else
        LOG_FILE="$TARGET_DIR/clean_empty_dirs_$TIMESTAMP.log"
    fi
    
    # Create log file
    touch "$LOG_FILE" 2>/dev/null || {
        print_colored "$YELLOW" "⚠️  Cannot create log in target directory, using script directory"
        LOG_FILE="$SCRIPT_DIR/clean_empty_dirs_$TIMESTAMP.log"
        touch "$LOG_FILE"
    }
fi

# Start logging
log_message "=== Empty Directory Cleanup Started ===" "START"
log_message "Target directory: $TARGET_DIR"
log_message "Ignore patterns: $IGNORE_PATTERNS"
log_message "Max depth: $MAX_DEPTH"
log_message "Recursive cleanup: $RECURSIVE_CLEANUP"
log_message "Safety mode: $SAFETY_MODE"
log_message "Dry run: $DRY_RUN"

# Print header unless in quiet mode
if [[ "$QUIET_MODE" == "false" ]]; then
    print_header
    print_colored "$BLUE" "🎯 Target Directory: $TARGET_DIR"
    print_colored "$YELLOW" "🔍 Ignore Patterns: $IGNORE_PATTERNS"
    if [[ $MAX_DEPTH -gt 0 ]]; then
        print_colored "$YELLOW" "📏 Max Depth: $MAX_DEPTH"
    fi
    if [[ "$ENABLE_LOGGING" == "true" ]]; then
        print_colored "$CYAN" "📝 Log File: $LOG_FILE"
    fi
    if [[ "$DRY_RUN" == "true" ]]; then
        print_colored "$PURPLE" "🔍 DRY RUN MODE - No files will be deleted"
    fi
    echo ""
fi

# Main cleanup loop
START_TIME=$(date +%s)

if [[ "$RECURSIVE_CLEANUP" == "true" && "$DRY_RUN" == "false" ]]; then
    # Recursive cleanup
    for ((i=1; i<=MAX_ITERATIONS; i++)); do
        ITERATIONS=$i
        if ! cleanup_iteration "$TARGET_DIR" "$IGNORE_PATTERNS" "$MAX_DEPTH" "$i"; then
            break
        fi
        
        if [[ $i -lt $MAX_ITERATIONS ]]; then
            echo ""
            print_colored "$BLUE" "🔄 Continuing cleanup (directories may have become empty after deletion)..."
            echo ""
        fi
    done
    
    if [[ $ITERATIONS -eq $MAX_ITERATIONS ]]; then
        print_colored "$YELLOW" "⚠️  Reached maximum iterations ($MAX_ITERATIONS). Some empty directories may remain."
    fi
else
    # Single iteration
    ITERATIONS=1
    cleanup_iteration "$TARGET_DIR" "$IGNORE_PATTERNS" "$MAX_DEPTH" "1"
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Final summary
echo ""
print_colored "$CYAN" "════════════════════════════════════════════════════════════════"
print_colored "$WHITE" "                          FINAL SUMMARY"
print_colored "$CYAN" "════════════════════════════════════════════════════════════════"
print_colored "$BLUE" "🎯 Target Directory: $TARGET_DIR"
print_colored "$YELLOW" "🔍 Directories Scanned: $TOTAL_SCANNED"
print_colored "$PURPLE" "📁 Empty Directories Found: $TOTAL_FOUND"
if [[ "$DRY_RUN" == "false" ]]; then
    print_colored "$GREEN" "✅ Directories Deleted: $TOTAL_DELETED"
    if [[ $TOTAL_FAILED -gt 0 ]]; then
        print_colored "$RED" "❌ Deletion Failures: $TOTAL_FAILED"
    fi
fi
print_colored "$CYAN" "🔄 Cleanup Iterations: $ITERATIONS"
print_colored "$BLUE" "⏱️  Total Time: ${DURATION}s"

if [[ "$ENABLE_LOGGING" == "true" ]]; then
    print_colored "$CYAN" "📝 Detailed log: $LOG_FILE"
fi

# Log final summary
log_message "=== Cleanup Completed ===" "END"
log_message "Directories scanned: $TOTAL_SCANNED"
log_message "Empty directories found: $TOTAL_FOUND"
log_message "Directories deleted: $TOTAL_DELETED"
log_message "Deletion failures: $TOTAL_FAILED"
log_message "Iterations: $ITERATIONS"
log_message "Duration: ${DURATION}s"

# Cleanup
rm -f "$TEMP_FILE"

# Exit with appropriate code
if [[ $TOTAL_FAILED -gt 0 ]]; then
    exit 2
elif [[ "$DRY_RUN" == "true" ]]; then
    exit 0
elif [[ $TOTAL_DELETED -gt 0 ]]; then
    exit 0
else
    exit 0
fi
