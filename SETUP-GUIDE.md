# Complete Setup Guide

This guide will walk you through setting up the entire infrastructure from scratch. Follow these steps in order.

## Prerequisites Checklist

- [ ] AWS Account with admin access
- [ ] AWS CLI installed and configured (`aws configure`)
- [ ] Terraform installed (version >= 1.0)
- [ ] Docker installed (for building application images)
- [ ] Git installed
- [ ] A text editor (VS Code recommended)

## Step 1: Verify AWS Credentials

```bash
# Test AWS credentials
aws sts get-caller-identity

# You should see your account ID, user ARN, and user ID
```

## Step 2: Clone and Prepare the Project

```bash
# If you created this as a git repo
git clone <your-repo-url>
cd terraform-project

# Or if you created it locally
cd /path/to/terraform-project

# Copy the example tfvars file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars  # or vim, or code terraform.tfvars
```

## Step 3: Set Up Remote State (One-Time Setup)

Terraform state tracks your infrastructure. Store it remotely for safety and team collaboration.

```bash
# Set your variables
export AWS_REGION="eu-west-2"
export STATE_BUCKET="your-name-terraform-state"
export STATE_TABLE="terraform-state-lock"

# Create S3 bucket for state
aws s3 mb s3://${STATE_BUCKET} --region ${AWS_REGION}

# Enable versioning (for state recovery)
aws s3api put-bucket-versioning \
  --bucket ${STATE_BUCKET} \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket ${STATE_BUCKET} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access (security best practice)
aws s3api put-public-access-block \
  --bucket ${STATE_BUCKET} \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name ${STATE_TABLE} \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region ${AWS_REGION}

echo "Remote state setup complete!"
echo "Update backend.tf with your bucket name: ${STATE_BUCKET}"
```

## Step 4: Configure Backend

Edit `backend.tf` and uncomment the backend configuration:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-name-terraform-state"  # Replace with your bucket
    key            = "dev/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

## Step 5: Initialize Terraform

```bash
# Initialize Terraform (downloads providers, sets up backend)
terraform init

# You should see "Terraform has been successfully initialized!"
```

## Step 6: Review the Plan

```bash
# See what Terraform will create
terraform plan

# Review the output carefully
# You should see ~50-70 resources to be created
```

## Step 7: Create the Infrastructure

```bash
# Apply the configuration
terraform apply

# Type "yes" when prompted
# This will take 10-15 minutes (RDS and NAT Gateways take time)

# Watch for any errors
# If it fails, read the error, fix it, and run terraform apply again
```

## Step 8: Verify Infrastructure

```bash
# Check outputs
terraform output

# Test ALB endpoint
ALB_DNS=$(terraform output -raw alb_dns_name)
curl http://${ALB_DNS}

# You should see nginx default page (since we're using nginx:latest as placeholder)
```

## Step 9: Build and Deploy Your Application

Now let's create a simple application and deploy it.

```bash
# Create ECR repository
aws ecr create-repository \
  --repository-name dals-practice/sample-app \
  --region eu-west-2

# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Build sample application (we'll create this next)
cd docker/sample-app
docker build -t sample-app:latest .

# Tag for ECR
docker tag sample-app:latest ${ACCOUNT_ID}.dkr.ecr.eu-west-2.amazonaws.com/dals-practice/sample-app:latest

# Login to ECR
aws ecr get-login-password --region eu-west-2 | \
  docker login --username AWS --password-stdin \
  ${ACCOUNT_ID}.dkr.ecr.eu-west-2.amazonaws.com

# Push image
docker push ${ACCOUNT_ID}.dkr.ecr.eu-west-2.amazonaws.com/dals-practice/sample-app:latest

# Update terraform.tfvars with your ECR image
# container_image = "123456789.dkr.ecr.eu-west-2.amazonaws.com/dals-practice/sample-app:latest"

# Apply changes
cd ../..
terraform apply
```

## Step 10: Test the Application

```bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)

# Test the endpoint
curl http://${ALB_DNS}
curl http://${ALB_DNS}/health

# Check ECS service
aws ecs describe-services \
  --cluster dals-practice-dev-cluster \
  --services dals-practice-dev-service \
  --region eu-west-2

# Check CloudWatch logs
aws logs tail /ecs/dals-practice-dev-app --follow --region eu-west-2
```

## Step 11: Monitor with CloudWatch

```bash
# Open CloudWatch dashboard
# Go to AWS Console > CloudWatch > Dashboards
# Find "dals-practice-dev-dashboard"

# View metrics:
# - ALB request count and response times
# - ECS CPU and memory utilization
# - RDS connections and CPU
# - Redis connections

# Check alarms
aws cloudwatch describe-alarms --region eu-west-2
```

## Step 12: Practice Scenarios

### Scenario 1: Simulate High Traffic
```bash
# Install Apache Bench (ab) or use hey
brew install hey  # macOS

# Generate load
hey -z 60s -c 10 http://${ALB_DNS}

# Watch ECS tasks scale up (if auto-scaling is configured)
watch aws ecs describe-services \
  --cluster dals-practice-dev-cluster \
  --services dals-practice-dev-service \
  --query 'services[0].runningCount' \
  --region eu-west-2
```

### Scenario 2: Simulate Task Failure
```bash
# Stop a task to see ECS automatically replace it
TASK_ARN=$(aws ecs list-tasks \
  --cluster dals-practice-dev-cluster \
  --service-name dals-practice-dev-service \
  --query 'taskArns[0]' \
  --output text \
  --region eu-west-2)

aws ecs stop-task \
  --cluster dals-practice-dev-cluster \
  --task ${TASK_ARN} \
  --region eu-west-2

# Watch ECS start a replacement task
watch aws ecs describe-services \
  --cluster dals-practice-dev-cluster \
  --services dals-practice-dev-service \
  --region eu-west-2
```

### Scenario 3: Database Connection Test
```bash
# Get RDS endpoint
RDS_ENDPOINT=$(terraform output -raw db_endpoint)

# Connect from an ECS task (exec into running container)
TASK_ARN=$(aws ecs list-tasks \
  --cluster dals-practice-dev-cluster \
  --service-name dals-practice-dev-service \
  --query 'taskArns[0]' \
  --output text \
  --region eu-west-2)

aws ecs execute-command \
  --cluster dals-practice-dev-cluster \
  --task ${TASK_ARN} \
  --container app \
  --interactive \
  --command "/bin/sh" \
  --region eu-west-2

# Inside the container, test database connection
# psql -h ${RDS_ENDPOINT} -U dbadmin -d appdb
```

### Scenario 4: Update Application
```bash
# Make changes to your application
# Rebuild and push Docker image with new tag
docker build -t sample-app:v2 .
docker tag sample-app:v2 ${ACCOUNT_ID}.dkr.ecr.eu-west-2.amazonaws.com/dals-practice/sample-app:v2
docker push ${ACCOUNT_ID}.dkr.ecr.eu-west-2.amazonaws.com/dals-practice/sample-app:v2

# Update ECS service (blue-green deployment)
aws ecs update-service \
  --cluster dals-practice-dev-cluster \
  --service dals-practice-dev-service \
  --force-new-deployment \
  --region eu-west-2

# Watch rolling deployment
watch aws ecs describe-services \
  --cluster dals-practice-dev-cluster \
  --services dals-practice-dev-service \
  --region eu-west-2
```

## Step 13: Practice Terraform Operations

### Check for Drift
```bash
# Detect if infrastructure has drifted from code
terraform plan -detailed-exitcode

# Exit code 0 = no changes
# Exit code 1 = error
# Exit code 2 = changes detected
```

### Update Infrastructure
```bash
# Modify variables in terraform.tfvars
# For example, change ecs_desired_count from 2 to 3

# Plan the change
terraform plan

# Apply the change
terraform apply
```

### Destroy Specific Resource
```bash
# Destroy only ElastiCache (for example)
terraform destroy -target=module.elasticache

# Note: This is useful for learning but NOT recommended for production
```

## Step 14: Cost Monitoring

```bash
# Check current month's costs
aws ce get-cost-and-usage \
  --time-period Start=2025-01-01,End=2025-01-13 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE \
  --region us-east-1

# Set up budget alert
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget.json \
  --region us-east-1
```

## Step 15: Cleanup (When Done Practicing)

```bash
# Destroy all infrastructure
terraform destroy

# Review what will be destroyed
# Type "yes" to confirm

# Manually delete ECR images
aws ecr batch-delete-image \
  --repository-name dals-practice/sample-app \
  --image-ids imageTag=latest \
  --region eu-west-2

# Delete ECR repository
aws ecr delete-repository \
  --repository-name dals-practice/sample-app \
  --force \
  --region eu-west-2

# Optionally delete state bucket (if you're completely done)
aws s3 rb s3://${STATE_BUCKET} --force

# Delete DynamoDB table
aws dynamodb delete-table --table-name ${STATE_TABLE} --region eu-west-2
```

## Troubleshooting Common Issues

### Issue: "Error creating NAT Gateway"
**Cause:** EIP limit reached (default is 5 per region)
**Solution:** Request EIP limit increase or use fewer AZs

### Issue: "Error creating RDS instance"
**Cause:** RDS instance limit reached or invalid security group
**Solution:** Check AWS Service Quotas, verify security group exists

### Issue: "Terraform state locked"
**Cause:** Previous terraform operation didn't complete
**Solution:** 
```bash
# Check DynamoDB for locks
aws dynamodb scan --table-name terraform-state-lock --region eu-west-2

# Delete lock manually if needed (only if you're sure no one is running terraform)
aws dynamodb delete-item \
  --table-name terraform-state-lock \
  --key '{"LockID": {"S": "your-lock-id"}}' \
  --region eu-west-2
```

### Issue: "ECS tasks failing to start"
**Cause:** Usually IAM permissions or networking issues
**Solution:**
```bash
# Check CloudWatch Logs for detailed error
aws logs tail /ecs/dals-practice-dev-app --follow --region eu-west-2

# Common fixes:
# 1. Verify ECR permissions in IAM role
# 2. Check security groups allow outbound HTTPS
# 3. Verify NAT Gateway exists if using private subnets
# 4. Check container image exists and is correct
```

### Issue: "Can't connect to RDS from ECS"
**Cause:** Security group misconfiguration
**Solution:**
```bash
# Verify security group allows ECS tasks to reach RDS
aws ec2 describe-security-groups \
  --filters Name=group-name,Values=dals-practice-dev-rds-sg \
  --region eu-west-2

# Should show ingress rule from ECS security group on port 5432
```

## Next Steps

1. **Add CI/CD**: Set up GitHub Actions or GitLab CI
2. **Add Monitoring**: Integrate Prometheus and Grafana
3. **Add Security Scanning**: Integrate Trivy in pipeline
4. **Practice Scenarios**: Simulate outages, test disaster recovery
5. **Document Your Learnings**: Keep notes for interview discussion

## Interview Preparation

Practice explaining:
- Why you chose this architecture
- How the security groups provide defense in depth
- How the multi-AZ setup provides high availability
- How you'd handle a production incident
- How you'd optimize costs
- What you'd change for production vs dev

Good luck with your interview!
