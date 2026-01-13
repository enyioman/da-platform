# Quick Start Guide

## Absolute Minimum to Get Started (15 minutes)

### 1. Prerequisites
```bash
# Verify installations
terraform version  # Should be >= 1.0
aws --version
docker --version

# Configure AWS credentials
aws configure
```

### 2. Set Up Remote State
```bash
# Replace 'your-name' with your actual name
export STATE_BUCKET="your-name-terraform-state"
export AWS_REGION="eu-west-2"

# Create state bucket
aws s3 mb s3://${STATE_BUCKET} --region ${AWS_REGION}
aws s3api put-bucket-versioning --bucket ${STATE_BUCKET} \
  --versioning-configuration Status=Enabled

# Create lock table
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region ${AWS_REGION}
```

### 3. Configure Project
```bash
cd terraform-project

# Copy and edit tfvars
cp terraform.tfvars.example terraform.tfvars

# Edit these values in terraform.tfvars:
# - alarm_email = "your-real-email@example.com"
# - owner = "Your Name"

# Edit backend.tf and replace bucket name with your STATE_BUCKET
```

### 4. Deploy Infrastructure
```bash
# Initialize
terraform init

# Plan (review what will be created)
terraform plan

# Apply (create infrastructure)
terraform apply
# Type 'yes' when prompted
# Wait 10-15 minutes
```

### 5. Test It Works
```bash
# Get ALB DNS name
terraform output alb_dns_name

# Test endpoint (should see nginx default page)
curl http://$(terraform output -raw alb_dns_name)

# Check AWS Console:
# - VPC Dashboard: See your VPC with 6 subnets
# - ECS Dashboard: See your cluster and service
# - RDS Dashboard: See your database
# - CloudWatch: See your dashboard
```

### 6. Clean Up When Done
```bash
# Destroy everything
terraform destroy
# Type 'yes' when prompted

# Delete state bucket (optional)
aws s3 rb s3://${STATE_BUCKET} --force
aws dynamodb delete-table --table-name terraform-state-lock --region ${AWS_REGION}
```

## What You Just Built

✅ **VPC with 3-tier architecture:**
   - Public subnets (ALB)
   - Private subnets (ECS)
   - Database subnets (RDS)

✅ **High Availability:**
   - Multi-AZ subnets
   - NAT Gateways in each AZ
   - ECS auto-healing

✅ **Security:**
   - Security groups with least privilege
   - IAM roles for ECS tasks
   - Private subnets for app/database

✅ **Monitoring:**
   - CloudWatch dashboards
   - CloudWatch alarms
   - VPC Flow Logs

✅ **Best Practices:**
   - Infrastructure as Code
   - Modular Terraform
   - Remote state with locking
   - Resource tagging

## Estimated Cost

**Monthly cost:** ~$160-175

**Breakdown:**
- NAT Gateways (3 AZs): $96/month
- Application Load Balancer: $22/month
- ECS Fargate (2 tasks): $30/month
- RDS db.t3.micro: $15/month
- ElastiCache t3.micro: $12/month
- VPC Endpoints: $7/month
- Data transfer: $10/month

**Cost Saving Tips:**
- Use 2 AZs instead of 3: Saves $32/month
- Use 1 NAT Gateway (not HA): Saves $64/month
- Turn off RDS Multi-AZ in dev: Saves $15/month
- Stop environment when not using: Saves ~50%

## Key Files to Understand

```
terraform-project/
├── main.tf              # Composes all modules together
├── variables.tf         # Input variables
├── terraform.tfvars     # Your specific values
├── backend.tf           # Remote state configuration
├── modules/
│   ├── vpc/            # Network infrastructure
│   ├── security-groups/ # All security groups
│   ├── alb/            # Load balancer
│   ├── ecs/            # Container orchestration
│   ├── rds/            # Database
│   ├── elasticache/    # Redis cache
│   ├── s3/             # Object storage
│   └── monitoring/     # CloudWatch dashboards
```

## Interview Talking Points

**When asked about VPC design:**
"I built a three-tier VPC architecture with public, private, and database subnet tiers across 3 availability zones. Public subnets host the load balancer, private subnets host the application in ECS Fargate, and database subnets are isolated for RDS and ElastiCache. Each tier has appropriate security groups implementing least privilege access."

**When asked about security:**
"I implemented defense in depth with security groups, where the ALB accepts traffic from the internet, but only the ALB can reach the ECS tasks, and only the ECS tasks can reach the database. I used IAM roles for ECS tasks instead of long-lived credentials, and VPC endpoints to keep AWS service traffic private."

**When asked about high availability:**
"The architecture spans multiple availability zones. If one AZ fails, the load balancer automatically routes traffic to healthy tasks in other AZs. RDS is configured for Multi-AZ deployment with automatic failover. ECS service auto-scaling ensures desired task count is maintained."

**When asked about monitoring:**
"I set up CloudWatch dashboards showing key metrics like ALB response times, ECS CPU/memory, RDS connections, and Redis metrics. CloudWatch alarms notify via SNS when thresholds are breached. VPC Flow Logs capture network traffic for security analysis."

**When asked about IaC:**
"The entire infrastructure is defined in Terraform using modular, reusable code. Each module is self-contained with clear inputs and outputs. I use remote state in S3 with DynamoDB locking for team collaboration. All changes go through terraform plan before apply."

## Next Steps for Interview Prep

1. **Deploy this infrastructure** - Hands-on is best
2. **Break something and fix it** - Simulate incidents
3. **Modify the code** - Add features, change configs
4. **Practice explaining** - Teach it to someone
5. **Document your learnings** - Write a blog post

## Common Interview Questions You Can Answer Now

❓ "Design a highly available web application on AWS"
✅ You just built one - explain the architecture

❓ "How do you implement security in AWS?"
✅ Point to your security groups, IAM roles, and network isolation

❓ "Explain your experience with Terraform"
✅ Show them your modular code structure and remote state setup

❓ "How do you ensure high availability?"
✅ Explain Multi-AZ deployment, auto-scaling, and health checks

❓ "Walk me through your deployment process"
✅ Describe the ECS deployment with rolling updates

❓ "How do you monitor infrastructure?"
✅ Show your CloudWatch dashboards and alarms

❓ "Tell me about a time you optimized costs"
✅ Explain NAT Gateway consolidation or instance right-sizing

Good luck with your DALS interview! 🚀
