# Debugging Patterns

Systematic approaches to troubleshooting based on empirical testing and first-principles thinking.

## Philosophy

1. **Test empirically, don't trust documentation alone**
   - Documentation may be outdated or wrong
   - Actual behavior is ground truth
   - Build minimal reproducible tests

2. **First principles thinking**
   - Understand underlying mechanisms
   - Don't cargo-cult solutions
   - Physics/engineering background applies to debugging

3. **Systematic data collection**
   - Record observations methodically
   - Look for patterns over time
   - Your 36-year notebook habit applies to bug tracking

## General Approach

### 1. Reproduce Reliably
```
- Minimal test case
- Document exact steps
- Note environmental factors (time, load, etc.)
- Can I make it happen on demand?
```

### 2. Isolate Variables
```
- Change one thing at a time
- Return to known-good state between tests
- Control for confounding factors
- What's actually correlated vs coincidental?
```

### 3. Gather Data
```
- Logs at appropriate verbosity
- System metrics during failure
- Network traffic if relevant
- Timeline of events
```

### 4. Form Hypothesis
```
- What mechanism could cause this?
- Is it consistent with all observations?
- What would disprove this hypothesis?
- Test the hypothesis explicitly
```

### 5. Test and Iterate
```
- Design experiment to test hypothesis
- Run test, record results
- Refine or reject hypothesis
- Repeat until root cause found
```

## Common Debugging Scenarios

### Network Issues

**Symptoms:** Intermittent failures, timeouts, dropped connections

**Approach:**
```bash
# Test basic connectivity
ping -c 10 host

# Trace route
traceroute host

# Check DNS
dig host
nslookup host

# Test port accessibility
nc -zv host port
telnet host port

# Monitor over time
while true; do
    date >> connectivity.log
    ping -c 1 -W 2 host >> connectivity.log 2>&1
    sleep 60
done

# Analyze patterns
# - Time of day correlation?
# - Network load correlation?
# - Specific device/route?
```

**Your context:**
- Tailscale overlay network
- WiFi vs Zigbee reliability
- Monitor empirically, don't assume

### Service Failures

**Symptoms:** Crashes, hangs, unexpected behavior

**Approach:**
```bash
# Check service status
systemctl status service-name

# View recent logs
journalctl -u service-name -n 100
# or
tail -f /var/log/service.log

# Check resource usage at time of failure
# Was it OOM? CPU? Disk?

# Restart with verbose logging
# Set log level to debug
# Reproduce issue with full logging
```

**Check for:**
- Memory leaks (gradual degradation)
- File descriptor exhaustion
- Disk space (especially on Raspberry Pi)
- Thermal throttling (Raspberry Pi specific)

### AWS Issues

**Symptoms:** API errors, permission denied, throttling

**Approach:**
```bash
# Enable debug logging
aws --debug ec2 describe-instances

# Check CloudTrail for what actually happened
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances

# Test IAM permissions explicitly
aws iam simulate-principal-policy \
    --policy-source-arn arn:aws:iam::ACCOUNT:user/USERNAME \
    --action-names ec2:DescribeInstances

# Rate limiting: exponential backoff
# Check service quotas
```

**Common gotchas:**
- Security group rules (recent work area)
- IAM eventual consistency
- Region mismatch
- Resource limits/quotas

### Home Assistant Issues

**Symptoms:** Devices offline, automations not triggering, sensor data incorrect

**Approach:**
```bash
# Check HA logs
tail -f /config/home-assistant.log

# Zigbee network visualization
# Check coordinator health
# Verify device pairing status

# Test sensor individually
# Remove from automation
# Verify readings directly
# Compare multiple sensors (your current approach)
```

**Your specific context:**
- Temperature sensor comparison ongoing
- Network reliability monitoring
- Empirical testing of WiFi vs Zigbee

### Python Debugging

**Tools:**
```python
# Print debugging (sometimes simplest)
print(f"Variable: {var!r}")  # repr for exact value

# Logging
import logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)
logger.debug(f"State: {state}")

# Interactive debugger
import pdb; pdb.set_trace()  # Set breakpoint
# Or post-mortem after crash:
import pdb; pdb.pm()

# Better debugger
import ipdb; ipdb.set_trace()  # If available
```

**Strategies:**
- Test functions in isolation
- Use type hints and mypy to catch early
- Write minimal reproduction
- Check assumptions with assertions

### Bash Debugging

**Tools:**
```bash
# Trace execution
set -x  # Print each command
set -v  # Print input lines

# Validate before running
bash -n script.sh  # Syntax check only

# Run with explicit error handling
set -euo pipefail
trap 'echo "Error on line $LINENO"' ERR
```

**Strategies:**
- Echo variables at decision points
- Use ShellCheck
- Test each pipeline stage independently
- Verify assumptions about file contents

### Performance Issues

**Symptoms:** Slow response, high resource usage, timeouts

**Approach:**
```bash
# Profile the code
# Python: cProfile, line_profiler
# Bash: time command, set -x

# System monitoring
top
htop
iotop  # Disk I/O
nethogs  # Network by process

# Identify bottleneck
# CPU? Memory? Disk? Network?
# Optimize the actual bottleneck, not assumptions
```

**Your approach:**
- Measure, don't guess
- Quantitative analysis
- Compare before/after metrics
- Understand why optimization works

## Data Collection Patterns

### Long-term Monitoring
```bash
# Continuous data collection
while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    value=$(get_metric)
    echo "${timestamp},${value}" >> metrics.csv
    sleep 300  # 5 minutes
done
```

### Pattern Analysis
```bash
# Extract patterns from logs
grep ERROR logfile | cut -d' ' -f1-3 | uniq -c

# Time-based analysis
awk '{print $1}' logfile | cut -d: -f1 | sort | uniq -c

# Correlate events
join -t, timestamps1.csv timestamps2.csv
```

### Statistical Analysis
```python
import pandas as pd
import numpy as np

# Load data
df = pd.read_csv('metrics.csv', parse_dates=['timestamp'])

# Descriptive stats
df.describe()

# Look for correlations
df.corr()

# Time-based patterns
df.groupby(df.timestamp.dt.hour).mean()
```

## When Stuck

### Take a Break
- Physics background knows: fresh perspective helps
- Walk away, come back
- Explain problem to someone (rubber duck)

### Question Assumptions
- List everything assumed true
- Test each assumption
- Often the "obvious" thing is wrong

### Simplify
- Remove complexity until it works
- Add back piece by piece
- Find exact point of failure

### Search Strategically
- Exact error messages
- Version-specific issues
- GitHub issues for similar problems
- But verify solutions empirically

### Ask for Help
- Provide minimal reproduction
- Show what you've tested
- Include system details
- Be specific about observations

## Documentation

### Record Solutions
```
Problem: Brief description
Symptoms: What you observed
Root cause: What was actually wrong
Solution: What fixed it
Lesson: What to remember

Example:
Problem: Home Assistant sensors showing stale data
Symptoms: Temperature unchanged for hours, not unavailable
Root cause: Zigbee network congestion, sensors couldn't report
Solution: Reduced polling frequency, added Zigbee router
Lesson: "Unavailable" vs "stale" are different failure modes
```

### Build Knowledge Base
- Add to this dev-ops repo
- Cross-reference related issues
- Include your systematic data
- Future you will thank you

## Anti-Patterns to Avoid

- **Changing multiple things at once:** Can't tell what fixed it
- **Not recording results:** Repeat same dead ends
- **Trusting documentation blindly:** Test empirically
- **Premature optimization:** Measure first
- **Ignoring error messages:** Read them carefully
- **Not having backups:** Can't return to known-good state

## Remember

You have:
- Physics degree (understand systems)
- 36 years of systematic notes
- 15+ years debugging complex systems
- Preference for empirical testing

Use these strengths. Build reproducible tests, collect data systematically, and think from first principles.
