# HomePI Infrastructure

Raspberry Pi running Home Assistant and serving as remote development environment.

## Access

**Via Tailscale:**
- Hostname: `TODO: homepi tailscale hostname`
- IP: `TODO: tailscale IP`
- SSH: `ssh TODO:user@homepi`

**From Phone:**
- Termux with full dev environment
- SSH to homepi via Tailscale
- Can run Claude Code sessions remotely

**From Tot (Android Laptop):**
- Full terminal access
- Same SSH setup as phone

## Services Running

### Home Assistant
- Port: `TODO: HA port (typically 8123)`
- Zigbee coordination via `TODO: coordinator type`
- Integrations: Tuya, SONOFF, custom sensors

### Development Environment
- Python: `TODO: version`
- Node.js: `TODO: version if applicable`
- Docker: `TODO: if running`

## Credentials

### GitHub
- SSH key location: `TODO: ~/.ssh/github_key`
- Configured for: `TODO: username/email`
- Access to all personal repos

### AWS
- Profile: `TODO: profile name`
- Credentials file: `~/.aws/credentials`
- Region: `TODO: default region (likely eu-west-2 given London location)`
- Access level: Full administrative (use with care)

## Network Topology

```
Internet
    |
Tailscale VPN
    |
    ├─ homepi (Raspberry Pi)
    ├─ Phone (via Termux)
    └─ Tot (Android laptop)
```

Exit nodes: `TODO: if any configured`
Subnet routing: `TODO: if exposing local network`

## Recording Setup

Audio routing for meeting recordings:
- `TODO: Document your audio setup`
- `TODO: Any specific configurations or gotchas`

## Thermal Considerations

Raspberry Pi may thermal throttle during:
- Heavy Docker builds
- Extended compilation
- Multiple simultaneous services

Monitor with: `vcgencmd measure_temp`

## Backup Strategy

`TODO: How homepi data is backed up`
- Home Assistant configs
- Development work in progress
- SSH keys and credentials

## Common Tasks

### Starting Claude Code Session
```bash
ssh homepi
cd ~/projects/[project-name]
# Read relevant context from dev-ops repo first
claude-code
```

### Syncing Dev-Ops Repo
```bash
cd ~/dev-ops
git pull
```

### Restarting Services
```bash
# Home Assistant
TODO: restart command

# Other services
TODO: if applicable
```

## Known Quirks

- `TODO: Any specific behavior to remember`
- `TODO: Workarounds for known issues`
