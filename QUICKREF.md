# Quick Reference

Fast lookup for common tasks and commands.

## Using This Repo with Claude Code

### Starting a Session
```bash
# SSH to homepi
ssh homepi

# Navigate to your project
cd ~/projects/your-project

# Start Claude Code and reference relevant context
claude-code

# In Claude Code session:
"Read ~/dev-ops/infrastructure/homepi.md and ~/dev-ops/projects/your-project.md"
```

### After a Work Session
```bash
# Update project context
vim ~/dev-ops/projects/your-project.md

# Commit changes
cd ~/dev-ops
git add .
git commit -m "Update project context: describe what changed"
git push
```

## Common Commands

### Git Operations
```bash
# Quick commit all changes
git add -A && git commit -m "message" && git push

# Sync dev-ops across devices
cd ~/dev-ops && git pull

# See what changed
git status
git diff
```

### AWS CLI
```bash
# List running instances
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,PublicIpAddress]' \
  --output table

# List S3 buckets
aws s3 ls

# Describe security group
aws ec2 describe-security-groups --group-ids sg-xxxxx
```

### Tailscale
```bash
# Check status
tailscale status

# List devices
tailscale status | grep -v '^#'

# Reconnect
sudo tailscale up

# Show IP
tailscale ip -4
```

### Home Assistant
```bash
# View logs
tail -f /config/home-assistant.log

# Restart Home Assistant
# TODO: Add your specific command

# Check service status
# TODO: Add your specific command
```

### System Monitoring
```bash
# Raspberry Pi temperature
vcgencmd measure_temp

# Disk usage
df -h

# Memory usage
free -h

# Process monitoring
htop

# Network connections
ss -tulpn
```

### Python Quick Tasks
```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install from requirements
pip install -r requirements.txt

# Quick HTTP server
python3 -m http.server 8000

# Format JSON
echo '{"key":"value"}' | python3 -m json.tool

# Quick calculation
python3 -c "print(2**10)"
```

### Bash One-Liners
```bash
# Find large files
find . -type f -size +100M -exec ls -lh {} \;

# Process CSV
awk -F',' '{print $1,$3}' data.csv

# Monitor log in real-time
tail -f logfile | grep ERROR

# Create backup with timestamp
cp file "file.backup.$(date +%Y%m%d_%H%M%S)"

# Find and replace in files
find . -name "*.py" -exec sed -i 's/old/new/g' {} \;
```

### File Operations
```bash
# Create tarball
tar -czf archive.tar.gz directory/

# Extract tarball
tar -xzf archive.tar.gz

# Secure copy
scp file user@host:/path/

# Rsync (better for large transfers)
rsync -avz source/ user@host:/path/
```

## Environment-Specific

### HomePI
- Hostname: `TODO: fill in`
- Main services: Home Assistant, development
- Access: Tailscale SSH

### Tot (Android Laptop)
- Use for: Light edits, reading code
- SSH to homepi for heavy work
- Same GitHub/AWS access

## Troubleshooting Quick Checks

### Network Issue?
```bash
ping 8.8.8.8          # Internet connectivity
ping homepi           # Tailscale connectivity
tailscale status      # VPN status
```

### Service Down?
```bash
systemctl status service-name
journalctl -u service-name -n 50
```

### High Load?
```bash
top                   # Quick overview
htop                  # Better interface
iostat                # Disk I/O
```

### Git Issues?
```bash
git status            # What's the state?
git log --oneline -5  # Recent commits
git remote -v         # Where does this push?
```

## Project Templates

### Starting New Project
```bash
mkdir new-project
cd new-project
git init

# Create basic structure
touch README.md CONTEXT.md .gitignore
mkdir src tests docs

# Initial commit
git add .
git commit -m "Initial commit"

# Create on GitHub, then:
git remote add origin git@github.com:username/new-project.git
git push -u origin main

# Add to sync script
vim ~/dev-ops/scripts/sync-contexts.sh
```

### Python Project
```bash
mkdir project-name && cd project-name
python3 -m venv venv
source venv/bin/activate

cat > requirements.txt << EOF
boto3
requests
pyyaml
EOF

pip install -r requirements.txt

# Create structure
mkdir src tests
touch README.md CONTEXT.md
```

## Remember

- Update CONTEXT.md files regularly
- Sync dev-ops repo frequently: `cd ~/dev-ops && git pull`
- Document non-obvious solutions in patterns/
- Use empirical testing approach
- Keep credentials out of git

## Links

- AWS Console: https://console.aws.amazon.com/
- GitHub: https://github.com/
- Tailscale Admin: https://login.tailscale.com/admin
- Home Assistant: `TODO: your instance URL`

## Update This File

Add your frequently-used commands and workflows as you discover them.
