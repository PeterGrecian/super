# Python Coding Style

Personal Python preferences and patterns for consistent code across projects.

## Expertise Level

Expert Python programmer with 15+ years experience across:
- Infrastructure automation
- Data processing and analysis
- VFX pipeline tools
- Cloud platform integration

## Code Organization

### Project Structure
```
project/
├── README.md
├── requirements.txt
├── setup.py (if distributable)
├── src/
│   └── module/
│       ├── __init__.py
│       └── core.py
├── tests/
│   └── test_core.py
└── scripts/
    └── entrypoint.py
```

### Module Design
- Keep modules focused and cohesive
- Avoid circular imports
- Use `__init__.py` to expose clean API

## Naming Conventions

- **Functions/variables:** `snake_case`
- **Classes:** `PascalCase`
- **Constants:** `UPPER_SNAKE_CASE`
- **Private:** `_leading_underscore`

Be descriptive but concise - clarity over brevity.

## Code Style

### Formatting
- Follow PEP 8 generally
- Line length: flexible, prefer readability
- Use Black or similar if desired, but not required

### Type Hints
```python
# Use for public APIs and complex functions
def process_data(input_path: str, threshold: float = 0.5) -> dict[str, any]:
    ...

# Optional for simple, obvious code
def add(a, b):
    return a + b
```

### Documentation
```python
def complex_function(param1: str, param2: int) -> list[str]:
    """Brief description of what function does.
    
    Longer explanation if needed. Focus on WHY and WHEN to use,
    not just WHAT it does.
    
    Args:
        param1: Description
        param2: Description
        
    Returns:
        Description of return value
        
    Raises:
        ExceptionType: When and why
    """
```

## Error Handling

### Be Explicit
```python
# Good - specific exceptions
try:
    value = config['required_key']
except KeyError as e:
    raise ConfigurationError(f"Missing required key: {e}")

# Avoid bare except
except:  # Don't do this
    pass
```

### Let It Fail
- Don't catch exceptions you can't handle
- Fail fast and noisily for development
- Log comprehensively for production

## Common Patterns

### File I/O
```python
# Prefer context managers
with open(filepath, 'r') as f:
    data = f.read()

# For paths, use pathlib
from pathlib import Path
config_path = Path.home() / '.config' / 'app' / 'config.yaml'
```

### Configuration
```python
# Environment variables for secrets
import os
aws_key = os.environ['AWS_ACCESS_KEY_ID']

# Config files for structure
import yaml
with open('config.yaml') as f:
    config = yaml.safe_load(f)
```

### Logging
```python
import logging

logger = logging.getLogger(__name__)

# Use appropriate levels
logger.debug("Detailed diagnostic")
logger.info("Normal operation")
logger.warning("Something unexpected but handled")
logger.error("Error that should be investigated")
```

## AWS Integration

### Boto3 Patterns
```python
import boto3

# Explicit client creation
ec2 = boto3.client('ec2', region_name='eu-west-2')

# Error handling
from botocore.exceptions import ClientError

try:
    response = ec2.describe_instances()
except ClientError as e:
    if e.response['Error']['Code'] == 'UnauthorizedOperation':
        logger.error("Insufficient permissions")
    raise
```

## Data Processing

### Prefer comprehensions
```python
# List comprehension
results = [process(item) for item in items if item.valid]

# Dict comprehension
mapping = {k: transform(v) for k, v in data.items()}
```

### NumPy/Pandas when appropriate
- Use for numerical work
- Vectorize operations
- Mind memory for large datasets

## Testing

### Structure
```python
import pytest

def test_function_behavior():
    # Arrange
    input_data = create_test_data()
    
    # Act
    result = function_under_test(input_data)
    
    # Assert
    assert result == expected_value
```

### Coverage
- Test edge cases
- Don't test trivial code
- Focus on behavior, not implementation

## Dependencies

- Pin versions in requirements.txt for reproducibility
- Use virtual environments
- Document system dependencies in README

## Anti-Patterns to Avoid

- Over-engineering simple tasks
- Premature optimization
- Excessive abstraction
- Magic numbers (use named constants)
- Global state unless absolutely necessary

## When to Break Rules

These are guidelines, not laws. Break them when:
- Specific domain requires different approach
- Integration with existing codebase
- Performance critically requires it
- Readability significantly improved by deviation

Document why you broke the rule.

## Tools

- **Linting:** ruff, pylint, or flake8 (optional)
- **Formatting:** black (optional, use if team requires)
- **Testing:** pytest
- **Type checking:** mypy (for large projects)

Use what helps, skip what doesn't.
