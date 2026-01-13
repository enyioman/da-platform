# CI/CD Pipeline Setup Guide

This guide explains how to set up the complete CI/CD pipeline for your Terraform infrastructure using GitHub Actions.

## 🎯 Overview

The CI/CD pipeline provides:
- ✅ Automated `terraform plan` on pull requests
- ✅ Security scanning with tfsec and Checkov
- ✅ Cost estimation with Infracost
- ✅ Automated `terraform apply` on main branch (with approval)
- ✅ Daily drift detection
- ✅ Manual destroy workflow with audit trail

## 📋 Prerequisites

1. **GitHub Repository**: Create a repository for your Terraform code
2. **AWS Account**: With appropriate permissions
3. **GitHub Secrets**: Configured (see below)

## 🔐 Step 1: Set Up AWS OIDC for GitHub Actions

### Why OIDC?
- No long-lived AWS credentials stored in GitHub
- More secure than access keys
- Automatic credential rotation

### Create IAM Role for GitHub Actions

```bash
# 1. Create trust policy
cat > github-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
EOF

# Replace ACCOUNT_ID with your AWS account ID
# Replace YOUR_GITHUB_USERNAME/YOUR_REPO_NAME with your repo

# 2. Create OIDC provider (if not already exists)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# 3. Create IAM role
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://github-trust-policy.json

# 4. Attach permissions
# Create a custom policy or use AWS managed policies
aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# For production, use least-privilege custom policy instead
```

### Create Least-Privilege Policy (Recommended for Production)

```bash
cat > terraform-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "ecs:*",
        "ecr:*",
        "rds:*",
        "elasticache:*",
        "s3:*",
        "iam:*",
        "logs:*",
        "cloudwatch:*",
        "secretsmanager:*",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name TerraformPolicy \
  --policy-document file://terraform-policy.json

aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/TerraformPolicy
```

## 🔑 Step 2: Configure GitHub Secrets

Go to your repository: **Settings → Secrets and variables → Actions**

### Required Secrets

```bash
# 1. AWS Role ARN
Name: AWS_ROLE_ARN
Value: arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole

# 2. Infracost API Key (optional, for cost estimation)
Name: INFRACOST_API_KEY
Value: <get from https://www.infracost.io/>
```

### Optional Secrets

```bash
# For Slack notifications (optional)
Name: SLACK_WEBHOOK_URL
Value: <your-slack-webhook-url>

# For custom notifications (optional)
Name: NOTIFICATION_EMAIL
Value: your-email@example.com
```

## 🏗️ Step 3: Configure GitHub Environments

### Create Production Environment with Approval

1. Go to **Settings → Environments**
2. Click **New environment**
3. Name it `production`
4. Configure:
   - ✅ **Required reviewers**: Add team members who can approve applies
   - ✅ **Wait timer**: Optional delay before deployment
   - ⚠️ **Deployment branches**: Limit to `main` branch only

### Create Production-Destroy Environment

1. Create another environment named `production-destroy`
2. Configure:
   - ✅ **Required reviewers**: Multiple approvers recommended
   - ✅ **Wait timer**: Consider 5-10 minute delay
   - 📝 This provides extra protection for destroy operations

## 📁 Step 4: Push Code to GitHub

```bash
# 1. Initialize git repository
git init

# 2. Add remote
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# 3. Create main branch
git checkout -b main

# 4. Add all files
git add .

# 5. Commit
git commit -m "Initial commit: Complete Terraform infrastructure with CI/CD"

# 6. Push to GitHub
git push -u origin main
```

## 🔄 Step 5: Test the Pipeline

### Test PR Workflow

```bash
# 1. Create a feature branch
git checkout -b feature/add-monitoring

# 2. Make a change (e.g., update a variable in terraform.tfvars)
echo '# Test change' >> variables.tf

# 3. Commit and push
git add .
git commit -m "Test: Add monitoring configuration"
git push origin feature/add-monitoring

# 4. Create pull request on GitHub
# The pipeline will automatically:
# - Run terraform fmt check
# - Validate Terraform code
# - Run security scans (tfsec, Checkov)
# - Generate terraform plan
# - Estimate costs with Infracost
# - Comment results on the PR
```

### Test Apply Workflow

```bash
# 1. Merge the PR to main
# 2. The apply workflow will:
#    - Wait for approval (if configured)
#    - Run terraform plan
#    - Apply changes
#    - Create success/failure issue
#    - Upload outputs as artifacts
```

## 🎛️ Workflow Details

### 1. Terraform Plan (`.github/workflows/terraform-plan.yml`)

**Triggers:** Pull requests to `main` or `develop`

**Steps:**
1. **Validate** - Format check, validate syntax
2. **Security Scan** - tfsec and Checkov
3. **Plan** - Generate execution plan
4. **Cost Estimate** - Infracost breakdown
5. **Comment** - Post results on PR

**Usage:**
- Automatically runs on every PR
- Blocks merge if validation fails
- Provides cost estimates before changes

### 2. Terraform Apply (`.github/workflows/terraform-apply.yml`)

**Triggers:** 
- Push to `main` branch
- Manual workflow dispatch

**Steps:**
1. **Plan** - Generate execution plan
2. **Wait for Approval** - If environment protection enabled
3. **Apply** - Execute changes
4. **Output** - Save Terraform outputs
5. **Notify** - Create issue with results

**Usage:**
- Requires approval before running
- Only runs on main branch
- Creates audit trail in issues

### 3. Terraform Destroy (`.github/workflows/terraform-destroy.yml`)

**Triggers:** Manual only (workflow_dispatch)

**Steps:**
1. **Validate Input** - Must type "destroy"
2. **Plan Destroy** - Show what will be destroyed
3. **Wait for Approval** - Requires approval
4. **Destroy** - Execute destruction
5. **Audit** - Create permanent issue record

**Usage:**
```bash
# 1. Go to Actions tab
# 2. Select "Terraform Destroy" workflow
# 3. Click "Run workflow"
# 4. Type "destroy" to confirm
# 5. Provide reason
# 6. Approve in Environments (if configured)
```

### 4. Drift Detection (`.github/workflows/terraform-drift.yml`)

**Triggers:** 
- Daily at 6 AM UTC
- Manual workflow dispatch

**Steps:**
1. **Plan** - Run plan against current infrastructure
2. **Detect Changes** - Check exit code
3. **Create Issue** - If drift detected
4. **Auto-Close** - If drift resolved

**Usage:**
- Runs automatically daily
- Creates issue when drift detected
- Helps catch manual changes

## 🔍 Security Scanning

### tfsec
- Scans for AWS security misconfigurations
- Checks for security best practices
- Results uploaded to GitHub Security tab

### Checkov
- Policy-as-code security scanning
- Checks compliance requirements
- Identifies potential vulnerabilities

### What's Checked
- Unencrypted resources
- Overly permissive security groups
- Missing logging/monitoring
- IAM policy issues
- Public access to resources

## 💰 Cost Estimation (Optional)

### Setup Infracost

1. Sign up at https://www.infracost.io/
2. Get API key
3. Add to GitHub Secrets as `INFRACOST_API_KEY`

### What It Provides
- Estimated monthly costs for changes
- Cost breakdown by resource
- Cost diff between current and proposed
- Comments on PR with estimates

## 📊 Monitoring Your Pipeline

### GitHub Actions UI
- **Actions tab**: See all workflow runs
- **Commits**: Green check = passed, red X = failed
- **Pull Requests**: Automated status checks

### Artifacts
- Terraform plans (5 day retention)
- Terraform outputs (90 day retention)
- Drift detection plans (30 day retention)

### Issues
- Apply success/failure automatically created
- Drift detection creates tracking issues
- Destroy operations create audit records

## 🐛 Troubleshooting

### "Error assuming role"
- Check AWS_ROLE_ARN secret is correct
- Verify OIDC trust policy includes your repo
- Ensure IAM role has necessary permissions

### "Terraform init failed"
- Check S3 bucket exists for state
- Verify DynamoDB table exists for locking
- Ensure role has access to state resources

### "Security scan errors"
- Review tfsec/Checkov findings
- Add exceptions if needed (with comments)
- Update code to fix security issues

### "Infracost not working"
- Add INFRACOST_API_KEY secret
- Or remove cost estimation job from workflow

## 🎓 Best Practices

### Branch Strategy
```
main (production)
  ↑
develop (staging)
  ↑
feature/* (development)
```

### Workflow
1. Create feature branch from `develop`
2. Make changes, push, create PR to `develop`
3. Review plan, merge to `develop` (auto-applies to staging)
4. Test in staging
5. Create PR from `develop` to `main`
6. Review, approve, merge (auto-applies to production)

### Approval Requirements
- **Staging**: Optional, or 1 approver
- **Production**: 2+ approvers recommended
- **Destroy**: 2+ approvers required

### State Management
- Use separate state files per environment
- Enable S3 versioning for state recovery
- Use DynamoDB locking to prevent conflicts
- Regular state backups

## 🎤 Interview Talking Points

**"I implemented a complete CI/CD pipeline for Terraform infrastructure using GitHub Actions with these key features:**

1. **Automated Testing**: Every PR runs validation, security scanning, and cost estimation before merging
2. **Security First**: Integrated tfsec and Checkov to catch misconfigurations early
3. **Approval Gates**: Production applies require manual approval through GitHub Environments
4. **Drift Detection**: Daily automated checks for manual changes with automatic issue creation
5. **Audit Trail**: All infrastructure changes logged in GitHub issues for compliance
6. **Cost Visibility**: Infracost integration shows cost impact before changes are applied
7. **OIDC Authentication**: No long-lived credentials, using AWS OIDC for secure authentication
8. **Safe Destroy**: Separate workflow with multiple confirmations for destruction

**Benefits:**
- Prevents bad code from reaching production
- Reduces manual errors
- Provides visibility into infrastructure changes
- Maintains compliance and audit trail
- Enables team collaboration with clear approval process"

## 📚 Additional Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [AWS OIDC Setup](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [tfsec](https://github.com/aquasecurity/tfsec)
- [Checkov](https://www.checkov.io/)
- [Infracost](https://www.infracost.io/docs/)

---

**Next Steps:**
1. Complete AWS OIDC setup
2. Add GitHub secrets
3. Configure environments
4. Push code and test
5. Create your first PR to see it in action!
