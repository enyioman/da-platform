# AWS Infrastructure Practice Project

## Project Overview
This project demonstrates production-ready AWS infrastructure using Terraform, covering all key areas from the DALS DevOps Engineer job description.

## What This Project Demonstrates
- ✅ VPC networking with public/private subnets across 3 AZs
- ✅ Application Load Balancer with proper security
- ✅ ECS Fargate for containerized applications
- ✅ RDS PostgreSQL with Multi-AZ deployment
- ✅ ElastiCache Redis for caching
- ✅ Route53 DNS management
- ✅ IAM roles following least privilege
- ✅ Security Groups with proper isolation
- ✅ CloudWatch monitoring and logging
- ✅ S3 for static assets with lifecycle policies
- ✅ Modular, reusable Terraform code
- ✅ Remote state management

## Architecture Diagram
```
Internet
    |
    v
Route53 → CloudFront (optional)
    |
    v
Application Load Balancer (Public Subnets)
    |
    v
ECS Fargate Tasks (Private Subnets)
    |
    +----> RDS PostgreSQL (Private DB Subnets)
    |
    +----> ElastiCache Redis (Private Subnets)
    |
    +----> S3 (Static Assets)
```

## Prerequisites
1. AWS Account with appropriate permissions
2. Terraform >= 1.0
3. AWS CLI configured (`aws configure`)
4. Docker (for building container images)
5. A domain name (or use AWS-provided ALB DNS)

## Project Structure
```
.
├── README.md
├── main.tf                 # Root module composition
├── variables.tf            # Root variables
├── outputs.tf              # Root outputs
├── terraform.tfvars        # Variable values (gitignored)
├── backend.tf              # Remote state configuration
├── modules/
│   ├── vpc/                # VPC with subnets, NAT, IGW
│   ├── security-groups/    # Security group definitions
│   ├── alb/                # Application Load Balancer
│   ├── ecs/                # ECS cluster and services
│   ├── rds/                # RDS PostgreSQL
│   ├── elasticache/        # Redis cache
│   ├── s3/                 # S3 buckets
│   └── monitoring/         # CloudWatch dashboards and alarms
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
├── docker/
│   └── sample-app/         # Sample application
└── scripts/
    └── setup.sh            # Initial setup script
```

## Quick Start

### Step 1: Clone and Setup
```bash
git clone <your-repo>
cd terraform-project

# Create your terraform.tfvars file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

### Step 2: Setup Remote State (One-time)
```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://your-terraform-state-bucket --region eu-west-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region eu-west-2
```

### Step 3: Initialize and Deploy
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

### Step 4: Build and Deploy Sample Application
```bash
# Build Docker image
cd docker/sample-app
docker build -t sample-app:latest .

# Tag for ECR
docker tag sample-app:latest <account-id>.dkr.ecr.eu-west-2.amazonaws.com/sample-app:latest

# Login to ECR
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.eu-west-2.amazonaws.com

# Push to ECR
docker push <account-id>.dkr.ecr.eu-west-2.amazonaws.com/sample-app:latest

# Update ECS service to use new image
aws ecs update-service --cluster <cluster-name> --service <service-name> --force-new-deployment
```

## What You'll Learn

### VPC Networking
- Creating VPCs with proper CIDR planning
- Public vs private subnets across multiple AZs
- NAT Gateways for private subnet internet access
- Route tables and routing configuration
- VPC endpoints for S3 and ECR

### Security
- Security groups with least privilege
- IAM roles for ECS tasks
- Secrets management with AWS Secrets Manager
- Network isolation (public/private/db subnets)
- Security group referencing for service-to-service communication

### High Availability
- Multi-AZ deployment for all critical components
- Auto-scaling for ECS services
- RDS Multi-AZ with automatic failover
- Application Load Balancer health checks

### Monitoring
- CloudWatch dashboards for infrastructure metrics
- CloudWatch alarms for critical metrics
- Centralized logging with CloudWatch Logs
- Custom metrics from applications

### Infrastructure as Code Best Practices
- Modular Terraform code
- Remote state management with locking
- Variable-driven configuration for multiple environments
- Proper use of outputs for module communication
- Documentation and examples

## Cost Considerations
Running this infrastructure will incur AWS costs. Approximate monthly costs:
- NAT Gateways: $96/month (3 AZs × $32)
- ALB: $22/month
- ECS Fargate: ~$30/month (2 tasks)
- RDS db.t3.micro: ~$15/month
- ElastiCache t3.micro: ~$12/month
- Total: ~$175/month

**Cost Optimization Tips:**
1. Use only 2 AZs instead of 3 (saves $32/month)
2. Use a single NAT Gateway (not HA, saves $64/month)
3. Stop non-production environments outside working hours
4. Use spot instances for development (Fargate Spot)

## Cleanup
```bash
# Destroy all infrastructure
terraform destroy

# Manually delete S3 buckets if they have objects
aws s3 rb s3://your-bucket-name --force
```

## Interview Talking Points

### Technical Depth
- "I built a production-ready AWS infrastructure from scratch using Terraform"
- "The VPC uses 3 AZs with public/private subnet tiers for high availability"
- "I implemented security best practices: least privilege IAM, security group isolation, private subnets for applications"
- "All infrastructure is code - I can rebuild everything in under 30 minutes"

### Architectural Decisions
- "I chose ECS Fargate over EC2 to eliminate server management overhead"
- "NAT Gateways are in each AZ to prevent cross-AZ traffic costs"
- "RDS is Multi-AZ for automatic failover with minimal downtime"
- "Used remote state in S3 with DynamoDB locking for team collaboration"

### Scalability
- "The architecture scales horizontally - ECS auto-scaling handles increased load"
- "Database read replicas can be added for read-heavy workloads"
- "CloudFront can be added for global content delivery"
- "The modular structure makes it easy to deploy to multiple regions"

### Security
- "ECS tasks use IAM roles, no long-lived credentials"
- "Database credentials stored in Secrets Manager with automatic rotation"
- "Security groups follow least privilege - each tier only talks to what it needs"
- "VPC endpoints keep traffic to AWS services private"

## Next Steps
1. Add CI/CD pipeline with GitHub Actions or GitLab CI
2. Implement automated testing with Terratest
3. Add monitoring with Prometheus and Grafana
4. Implement GitOps with ArgoCD for application deployments
5. Add security scanning with Trivy and OWASP ZAP

## Troubleshooting

### Common Issues
1. **"Error creating NAT Gateway"**
   - Ensure you have EIPs available in your account (default limit is 5)
   
2. **"Error creating RDS instance"**
   - Check if you've reached the RDS instance limit
   - Verify the security group allows connections

3. **"Terraform state locked"**
   - Another process is running terraform
   - If stuck, manually delete the lock from DynamoDB table

4. **"ECS tasks failing to start"**
   - Check CloudWatch Logs for container errors
   - Verify IAM role has permissions to pull from ECR
   - Check security groups allow outbound internet access

## Resources
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)