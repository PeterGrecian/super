# AWS Setup

AWS infrastructure and credential management across devices.

## Account Structure

- Account ID: `TODO: AWS account ID`
- Primary region: `TODO: likely eu-west-2 (London)`
- Organization: `TODO: if using AWS Organizations`

## IAM Setup

### Users
- Username: `TODO: IAM username`
- Access level: `TODO: AdministratorAccess or specific policies`

### Roles
`TODO: Document any roles used for cross-account access or service access`

## Credentials Distribution

### HomePI
- Location: `~/.aws/credentials`
- Profile name: `TODO: profile name (likely 'default')`
- Configured via: AWS CLI

### Tot
- Location: `TODO: credentials path`
- Profile name: `TODO: profile name`
- Same access keys as homepi

## Security Considerations

- **Never commit credentials to git**
- Rotate access keys periodically
- Use IAM roles for EC2/ECS where possible
- MFA: `TODO: enabled yes/no`

## Common Services Used

### Compute
- EC2: `TODO: instance types, regions used`
- Lambda: `TODO: if used`

### Storage
- S3: `TODO: bucket naming patterns`
- EBS: `TODO: if directly managed`

### Networking
- VPC: `TODO: VPC IDs if relevant`
- Security Groups: `TODO: common patterns`
- Subnets: `TODO: if custom networking`

### Infrastructure as Code
- Terraform state: `TODO: S3 bucket location if using remote state`
- CloudFormation: `TODO: if used`

## Cost Management

- Budget alerts: `TODO: configured yes/no`
- Primary cost drivers: `TODO: EC2, data transfer, etc.`
- Cleanup strategy: `TODO: how you manage unused resources`

## Regions

Primary: `TODO: eu-west-2 or other`
Secondary: `TODO: if multi-region`

Latency considerations from London base.

## AWS CLI Patterns

### Frequently Used Commands

```bash
# List running instances
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"

# S3 sync
aws s3 sync ./local s3://bucket/path

# TODO: Add your common commands
```

### Security Group Management

```bash
# Your recent work involved security group configurations
# TODO: Document common patterns for ingress/egress rules
```

## Terraform Usage

- State backend: `TODO: local or S3`
- Module patterns: `TODO: if you use modules`
- Variable management: `TODO: how you handle secrets`

See `patterns/terraform.md` for coding standards.

## Known Issues

`TODO: Any recurring AWS quirks or gotchas you've encountered`
- Security group rule limits
- Rate limiting on certain APIs
- Region-specific service availability
