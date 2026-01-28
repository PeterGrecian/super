# Terraform Patterns

Infrastructure as Code patterns for AWS and cloud infrastructure management.

## Project Structure

```
terraform-project/
├── README.md
├── main.tf              # Primary resources
├── variables.tf         # Input variables
├── outputs.tf          # Output values
├── terraform.tfvars    # Variable values (gitignored if sensitive)
├── backend.tf          # State backend configuration
├── versions.tf         # Provider version constraints
└── modules/
    └── custom-module/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## State Management

### Remote State (Recommended)
```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "TODO-your-terraform-state"
    key            = "project/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### Local State (Simple Projects)
```hcl
# Default - state in terraform.tfstate
# Good for:
# - Personal experiments
# - Learning
# - Single-user projects

# Never commit to git!
```

## Provider Configuration

```hcl
# versions.tf
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Allow minor version updates
    }
  }
}

# main.tf
provider "aws" {
  region = var.aws_region
  
  # Profile from ~/.aws/credentials
  profile = "default"  # Or your profile name
  
  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = var.project_name
    }
  }
}
```

## Variable Patterns

```hcl
# variables.tf
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-2"  # London
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

# Complex types
variable "subnets" {
  description = "Subnet configuration"
  type = list(object({
    cidr_block        = string
    availability_zone = string
  }))
}
```

## Resource Naming

```hcl
# Consistent naming pattern
resource "aws_instance" "web_server" {
  # Resource name in Terraform: web_server
  # AWS tag Name: project-env-component
  
  tags = {
    Name = "${var.project_name}-${var.environment}-web"
  }
}

# Use locals for computed names
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }
}

resource "aws_instance" "app" {
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-app"
      Role = "application"
    }
  )
}
```

## Security Groups

```hcl
# security-groups.tf
resource "aws_security_group" "web" {
  name_prefix = "${local.name_prefix}-web-"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  # Use separate rules for maintainability
  lifecycle {
    create_before_destroy = true
  }
  
  tags = merge(
    local.common_tags,
    { Name = "${local.name_prefix}-web" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id
  
  description = "HTTP from anywhere"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "web_https" {
  security_group_id = aws_security_group.web.id
  
  description = "HTTPS from anywhere"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web.id
  
  description = "Allow all outbound"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}
```

## Data Sources

```hcl
# Reference existing resources
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Use in resources
resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
}
```

## Outputs

```hcl
# outputs.tf
output "instance_public_ip" {
  description = "Public IP of web server"
  value       = aws_instance.web.public_ip
}

output "security_group_id" {
  description = "ID of web security group"
  value       = aws_security_group.web.id
}

# Sensitive outputs
output "database_password" {
  description = "Database password"
  value       = aws_db_instance.main.password
  sensitive   = true
}

# Complex outputs
output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value = {
    for subnet in aws_subnet.private :
    subnet.tags["Name"] => subnet.id
  }
}
```

## Modules

### Creating a Module
```hcl
# modules/ec2-instance/main.tf
resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  
  vpc_security_group_ids = var.security_group_ids
  
  tags = merge(
    var.tags,
    { Name = var.name }
  )
}

# modules/ec2-instance/variables.tf
variable "ami_id" {
  description = "AMI ID to use"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

# ... other variables

# modules/ec2-instance/outputs.tf
output "instance_id" {
  value = aws_instance.this.id
}

output "private_ip" {
  value = aws_instance.this.private_ip
}
```

### Using a Module
```hcl
module "web_server" {
  source = "./modules/ec2-instance"
  
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = "t3.small"
  subnet_id          = aws_subnet.public.id
  security_group_ids = [aws_security_group.web.id]
  name               = "${local.name_prefix}-web"
  
  tags = local.common_tags
}

# Reference module outputs
output "web_server_ip" {
  value = module.web_server.private_ip
}
```

## Common Patterns

### Conditional Resources
```hcl
resource "aws_instance" "optional" {
  count = var.create_instance ? 1 : 0
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
}

# Access with:
# aws_instance.optional[0] if created
```

### Dynamic Blocks
```hcl
resource "aws_security_group" "dynamic" {
  name = "dynamic-sg"
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

### For Each
```hcl
# Create multiple similar resources
resource "aws_subnet" "private" {
  for_each = toset(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(var.availability_zones, each.key))
  availability_zone = each.key
  
  tags = {
    Name = "${local.name_prefix}-private-${each.key}"
  }
}
```

## Workflow

### Daily Usage
```bash
# Initialize (first time or after provider changes)
terraform init

# Format code
terraform fmt -recursive

# Validate
terraform validate

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Show current state
terraform show

# List resources
terraform state list

# Destroy everything
terraform destroy
```

### State Operations
```bash
# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0

# Remove from state (doesn't delete resource)
terraform state rm aws_instance.example

# Move resource in state
terraform state mv aws_instance.old aws_instance.new

# Pull remote state
terraform state pull > state.json
```

## Testing

### Validation
```bash
# Syntax
terraform fmt -check
terraform validate

# Plan for different environments
terraform plan -var-file=dev.tfvars
terraform plan -var-file=prod.tfvars
```

### Terraform Console
```bash
# Interactive testing
terraform console

# Try expressions
> local.name_prefix
> aws_instance.web.public_ip
> cidrsubnet("10.0.0.0/16", 8, 1)
```

## Best Practices

### General
- Use remote state for team projects
- Version control everything except secrets
- Use variables for anything that might change
- Tag all resources consistently
- Use modules for reusable components
- Document non-obvious decisions

### Security
- Never commit credentials
- Use IAM roles over access keys where possible
- Encrypt state (S3 encryption, DynamoDB for locking)
- Restrict state access with IAM
- Use .gitignore for sensitive files:
  ```
  .terraform/
  *.tfstate
  *.tfstate.backup
  *.tfvars  # If contains secrets
  .terraform.lock.hcl  # Optional, some prefer to commit
  ```

### Performance
- Use data sources sparingly (they query on every plan)
- Limit resource count when possible
- Consider splitting large projects
- Use targeted applies for big infrastructures:
  ```bash
  terraform apply -target=aws_instance.web
  ```

## Debugging

```bash
# Verbose logging
export TF_LOG=DEBUG
terraform plan

# Log to file
export TF_LOG_PATH=terraform.log
terraform apply

# Specific provider logging
export TF_LOG_PROVIDER=DEBUG
```

## Common Issues

### State Lock
```bash
# If state stuck locked
terraform force-unlock LOCK_ID

# Prevention: always use DynamoDB for locking
```

### Provider Version Conflicts
```hcl
# Pin versions in versions.tf
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 5.0"  # Not "latest"
  }
}
```

### Circular Dependencies
```
# Error: Cycle detected
# Solution: Use depends_on explicitly or restructure
```

## Integration with Your Workflow

- Store Terraform projects in git
- Use dev-ops repo to track which infrastructures exist
- Document state backend locations
- Link to AWS account structure
- Your AWS credentials on homepi and tot already configured
