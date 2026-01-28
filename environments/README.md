# Environment Configurations

This directory contains environment-specific Terraform variable files for dev, staging, and production environments.

## Usage

### Deploy to Development
```bash
# From project root
terraform init
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

### Deploy to Staging
```bash
terraform init
terraform plan -var-file=environments/staging/terraform.tfvars
terraform apply -var-file=environments/staging/terraform.tfvars
```

### Deploy to Production
```bash
terraform init
terraform plan -var-file=environments/prod/terraform.tfvars
terraform apply -var-file=environments/prod/terraform.tfvars
```

## Environment Differences

### Development
- **Purpose**: Local development and testing
- **Cost**: ~$128/month
- **Config**: 
  - 2 AZs (cost savings)
  - 1 ECS task
  - Single-AZ RDS
  - Smaller instance sizes
  - No HTTPS
  - Minimal backups

### Staging
- **Purpose**: Pre-production testing, mirrors production
- **Cost**: ~$200-250/month
- **Config**:
  - 3 AZs
  - 2 ECS tasks
  - Multi-AZ RDS
  - Medium instance sizes
  - Optional HTTPS
  - 7-day backups

### Production
- **Purpose**: Live production workload
- **Cost**: ~$473/month (can be optimized with Reserved Instances)
- **Config**:
  - 3 AZs (full HA)
  - 3+ ECS tasks
  - Multi-AZ RDS
  - Production-sized instances
  - HTTPS required
  - 30-day backups
  - Full monitoring

## Backend Configuration

Each environment should have its own state file. Update `backend.tf` accordingly:

```hcl
# For dev
terraform {
  backend "s3" {
    bucket = "your-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "eu-west-2"
  }
}

# For staging
terraform {
  backend "s3" {
    bucket = "your-terraform-state"
    key    = "staging/terraform.tfstate"
    region = "eu-west-2"
  }
}

# For prod
terraform {
  backend "s3" {
    bucket = "your-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "eu-west-2"
  }
}
```

## Best Practices

1. **Always test in dev first** before deploying to staging or production
2. **Use different AWS accounts** for dev/staging/prod (ideal but optional)
3. **Different VPC CIDRs** prevent conflicts if you ever need VPC peering
4. **Tag resources** with environment name for cost tracking
5. **Separate state files** prevent accidental cross-environment changes
6. **Production changes** should require approval/review process

## Cost Comparison

| Resource | Dev | Staging | Production |
|----------|-----|---------|------------|
| NAT Gateways | 2x ($64) | 3x ($96) | 3x ($96) |
| ECS Tasks | 1 small | 2 medium | 3 large |
| RDS | t3.micro | t3.small Multi-AZ | t3.medium Multi-AZ |
| ElastiCache | 1x t3.micro | 2x t3.small | 3x t3.medium |
| **Total** | **~$128/mo** | **~$220/mo** | **~$473/mo** |

## Interview Talking Points

"I structured the infrastructure to support multiple environments with different configurations. Dev uses smaller instances and single-AZ for cost savings, staging mirrors production architecture but with medium sizing, and production uses full HA across three availability zones with appropriate instance sizing. Each environment has its own tfvars file and state file, and the same Terraform modules are reused across all environments - only the variables change."
