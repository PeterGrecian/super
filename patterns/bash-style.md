# Bash Scripting Style

Personal bash preferences for system automation and DevOps tasks.

## Expertise Level

Expert bash scripting for:
- Infrastructure automation
- CI/CD pipelines
- System administration
- Glue between tools

## Script Structure

### Shebang and Settings
```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
# set -x  # Uncomment for debugging
```

### Template
```bash
#!/bin/bash
set -euo pipefail

# Script: script-name.sh
# Purpose: Brief description
# Usage: ./script-name.sh [args]

# Configuration
readonly CONFIG_FILE="${HOME}/.config/app/config"
readonly LOG_DIR="/var/log/app"

# Functions
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Description of what script does.

OPTIONS:
    -h, --help      Show this help
    -v, --verbose   Verbose output
EOF
}

main() {
    # Main logic here
    :
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
    shift
done

main "$@"
```

## Best Practices

### Variables
```bash
# Use meaningful names
input_file="/path/to/file"
max_retries=3

# UPPERCASE for environment/global
export AWS_REGION="eu-west-2"

# readonly for constants
readonly MAX_CONNECTIONS=100

# Quote variables to prevent word splitting
echo "${input_file}"  # Good
echo $input_file      # Risky
```

### Conditionals
```bash
# Prefer [[ ]] over [ ]
if [[ -f "${config_file}" ]]; then
    source "${config_file}"
fi

# Check command success
if command -v aws >/dev/null 2>&1; then
    echo "AWS CLI found"
fi

# Multiple conditions
if [[ -n "${var}" && -f "${file}" ]]; then
    process_file "${file}"
fi
```

### Loops
```bash
# Iterate over files
for file in *.txt; do
    [[ -e "${file}" ]] || continue  # Skip if glob didn't match
    process "${file}"
done

# Read lines (handles spaces/special chars)
while IFS= read -r line; do
    echo "${line}"
done < input.txt

# C-style for counter
for ((i=0; i<10; i++)); do
    echo "${i}"
done
```

### Functions
```bash
# Function definition
function_name() {
    local arg1="$1"
    local arg2="${2:-default}"  # Default value
    
    # Validate inputs
    if [[ -z "${arg1}" ]]; then
        echo "Error: arg1 required" >&2
        return 1
    fi
    
    # Do work
    echo "Processing ${arg1}"
}

# Call with explicit arguments
function_name "value1" "value2"
```

## Error Handling

### Exit Codes
```bash
# Return meaningful codes
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_CONFIG_ERROR=2

# Use in functions
validate_config() {
    if [[ ! -f "${config_file}" ]]; then
        echo "Config not found: ${config_file}" >&2
        return "${EXIT_CONFIG_ERROR}"
    fi
}
```

### Trap for Cleanup
```bash
# Cleanup on exit
cleanup() {
    rm -f "${temp_file}"
    echo "Cleaned up"
}
trap cleanup EXIT

# Create temp file
temp_file=$(mktemp)
```

## Command Patterns

### AWS CLI
```bash
# Get running instances
aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text

# With error handling
if ! aws s3 sync ./local s3://bucket/path; then
    echo "S3 sync failed" >&2
    exit 1
fi
```

### SSH/Remote
```bash
# SSH with error handling
ssh -o ConnectTimeout=5 user@host 'command' || {
    echo "SSH failed" >&2
    exit 1
}

# Copy files
scp -o ConnectTimeout=5 file user@host:/path/ || exit 1
```

### Git Operations
```bash
# Check if repo is clean
if [[ -n $(git status --porcelain) ]]; then
    echo "Working directory not clean" >&2
    exit 1
fi

# Safe pull
git fetch origin
git merge --ff-only origin/main || {
    echo "Cannot fast-forward" >&2
    exit 1
}
```

## Logging and Output

### Structured Logging
```bash
# Functions for log levels
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

log_debug() {
    [[ "${DEBUG:-0}" == "1" ]] && echo "[DEBUG] $*" >&2
}

# Usage
log_info "Starting process"
log_error "Failed to connect"
DEBUG=1 log_debug "Variable value: ${var}"
```

### Output Redirection
```bash
# Discard output
command >/dev/null 2>&1

# Log to file
command >> logfile 2>&1

# Tee for both file and stdout
command 2>&1 | tee -a logfile
```

## JSON/YAML Processing

### jq for JSON
```bash
# Parse JSON response
instance_id=$(aws ec2 describe-instances | \
    jq -r '.Reservations[0].Instances[0].InstanceId')

# Pretty print
echo "${json}" | jq .

# Filter and transform
cat data.json | jq '.items[] | select(.active == true) | .name'
```

### yq for YAML (if available)
```bash
# Similar to jq but for YAML
yq eval '.database.host' config.yaml
```

## Testing Scripts

### Dry-run Pattern
```bash
readonly DRY_RUN="${DRY_RUN:-0}"

execute() {
    if [[ "${DRY_RUN}" == "1" ]]; then
        echo "[DRY-RUN] Would execute: $*"
    else
        "$@"
    fi
}

# Usage
DRY_RUN=1 ./script.sh  # Shows what would happen
```

### Validation
```bash
# Check dependencies
check_dependencies() {
    local deps=(aws jq git)
    for cmd in "${deps[@]}"; do
        if ! command -v "${cmd}" >/dev/null 2>&1; then
            log_error "Required command not found: ${cmd}"
            exit 1
        fi
    done
}
```

## Performance

### Avoid Subshells When Possible
```bash
# Slow - spawns subshell per iteration
for file in *.txt; do
    count=$(wc -l < "${file}")
done

# Better - read into variable
while IFS= read -r file; do
    # Process
done < <(ls *.txt)
```

### Use Built-ins
```bash
# Slow - external command
dirname=$(dirname "${path}")

# Fast - parameter expansion
dirname="${path%/*}"

# Also fast for basename
filename="${path##*/}"
```

## Security

### Never eval User Input
```bash
# Dangerous
eval "${user_input}"

# Safe - validate and use directly
if [[ "${user_input}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    process "${user_input}"
fi
```

### Quote Variables
```bash
# Prevents injection and word splitting
rm "${file}"  # Good
rm $file      # Dangerous
```

## When to Use Bash vs Python

**Use Bash for:**
- Simple automation glue
- Pipeline composition
- System commands coordination
- Quick scripts (<100 lines)

**Use Python for:**
- Complex logic
- Data processing
- Anything needing data structures
- Scripts that will grow

## Common Gotchas

```bash
# Word splitting in for loop
# Wrong:
for file in $(ls); do  # Breaks on spaces

# Right:
for file in *; do
# Or:
while IFS= read -r file; do ...

# Return vs exit in functions
# exit terminates script
# return exits function

# Arithmetic
# Wrong: result = $a + $b  (syntax error)
# Right:
result=$((a + b))
# Or:
((result = a + b))
```

## Tools and Linters

- **ShellCheck:** Use religiously
- **shfmt:** Format consistently (optional)

```bash
# Run shellcheck
shellcheck script.sh

# Auto-fix some issues
shellcheck -f diff script.sh | patch
```

## Documentation

- Use comments for WHY, not WHAT
- Document non-obvious behavior
- Include usage examples
- Note assumptions and requirements
