# Tot - Android Laptop

Android laptop serving as mobile development environment.

## Specifications

- Model: `TODO: laptop model`
- OS: Android `TODO: version`
- Terminal: `TODO: Termux or other`

## Access Patterns

### Local Development
- Can run lighter development tasks directly
- Full terminal environment via `TODO: app name`

### Remote Development via HomePI
- SSH to homepi via Tailscale
- Run heavier builds remotely
- Access Home Assistant for testing

## Credentials

### GitHub
- SSH key location: `TODO: key path`
- Same access as homepi
- Can push/pull all repos

### AWS
- AWS CLI configured: `TODO: yes/no`
- Profile: `TODO: profile name`
- Same credentials as homepi

## Tailscale Setup

- Device name: `TODO: tailscale device name`
- IP: `TODO: tailscale IP`
- Connected to same network as homepi

## Installed Tools

- `TODO: Python version/location`
- `TODO: Git version`
- `TODO: AWS CLI`
- `TODO: Other dev tools`

## Use Cases

**Ideal for:**
- Quick edits and commits
- Reading code/documentation
- Monitoring running services
- Lightweight Claude Code sessions

**Not ideal for:**
- Heavy builds (use homepi instead)
- Resource-intensive testing
- Large file operations

## Syncing with HomePI

Work typically flows:
1. Start work on tot
2. SSH to homepi for heavy operations
3. Commit and push from either device
4. Both have synchronized git repos via GitHub

## Battery Considerations

`TODO: Battery life during typical dev sessions`
`TODO: Power management settings for long sessions`

## Known Issues

`TODO: Any limitations or workarounds needed`
