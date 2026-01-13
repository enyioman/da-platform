# GitHub Actions Workflows

This directory contains CI/CD workflows for Terraform infrastructure management.

## 📋 Workflows Overview

| Workflow | Trigger | Purpose | Approval Required |
|----------|---------|---------|-------------------|
| **terraform-plan.yml** | Pull Request | Validate, plan, scan security | No |
| **terraform-apply.yml** | Push to main | Apply changes to infrastructure | Yes (production env) |
| **terraform-destroy.yml** | Manual only | Destroy infrastructure | Yes (production-destroy env) |
| **terraform-drift.yml** | Daily schedule | Detect configuration drift | No |

## 🔄 Workflow Diagram

```
┌─────────────────┐
│  Feature Branch │
│   Development   │
└────────┬────────┘
         │
         │ Create PR
         ▼
┌─────────────────────────────────┐
│   terraform-plan.yml            │
│   • Validate & Format Check     │
│   • Security Scan (tfsec)       │
│   • Generate Plan               │
│   • Cost Estimate (Infracost)  │
│   • Comment on PR               │
└────────┬────────────────────────┘
         │
         │ PR Approved & Merged
         ▼
┌─────────────────────────────────┐
│   terraform-apply.yml           │
│   • Run Plan                    │
│   • Wait for Approval ⏸️        │
│   • Apply Changes               │
│   • Create Success Issue        │
└─────────────────────────────────┘

         ┌────────────────┐
         │  Daily at 6AM  │
         └────────┬───────┘
                  │
                  ▼
         ┌─────────────────────────────┐
         │   terraform-drift.yml       │
         │   • Check for Drift         │
         │   • Create Issue if Found   │
         │   • Auto-close if Resolved  │
         └─────────────────────────────┘
```

## 🎯 Workflow Details

### 1. Terraform Plan (`terraform-plan.yml`)

**Purpose:** Automated validation and planning for pull requests

**Jobs:**
1. `terraform-validate` - Format and syntax validation
2. `terraform-security-scan` - Run tfsec and Checkov
3. `terraform-plan` - Generate execution plan
4. `terraform-cost-estimate` - Estimate costs with Infracost

**Outputs:**
- ✅ PR comment with plan summary
- 📊 Cost estimation (if Infracost configured)
- 🔒 Security scan results in Security tab
- 📦 Plan artifact (5 day retention)

**Example PR Comment:**
```
### Terraform Plan Results 📋

#### Terraform Format and Style 🖌 `success`
#### Terraform Initialization ⚙️ `success`
#### Terraform Validation 🤖 `success`
#### Terraform Plan 📖 `success`

#### Changes Summary
- **To Add:** 5 resources
- **To Change:** 2 resources
- **To Destroy:** 0 resources

<details><summary>Show Plan</summary>
...
</details>
```

### 2. Terraform Apply (`terraform-apply.yml`)

**Purpose:** Apply approved changes to production infrastructure

**Environment:** `production` (requires approval)

**Jobs:**
1. `terraform-apply` - Execute the apply
2. `notify-success` - Create success issue with outputs

**Outputs:**
- 📦 Apply plan artifact (30 day retention)
- 📊 Terraform outputs (90 day retention)
- 📝 GitHub issue with results
- ✅ Success notification

**When It Runs:**
- Automatically on push to `main`
- Manually via workflow_dispatch

**Approval Process:**
1. Workflow triggered
2. Waits for reviewer approval in GitHub UI
3. Once approved, executes apply
4. Creates issue with results

### 3. Terraform Destroy (`terraform-destroy.yml`)

**Purpose:** Safely destroy infrastructure with audit trail

**Environment:** `production-destroy` (requires approval)

**Inputs Required:**
- `confirm`: Must type "destroy"
- `reason`: Explanation for destruction

**Jobs:**
1. `validate-input` - Verify confirmation
2. `terraform-destroy` - Execute destruction

**Safety Features:**
- ⚠️ Manual trigger only (can't be accidental)
- 🔐 Requires typing "destroy" to confirm
- 👥 Requires approval from designated reviewers
- 📝 Creates permanent audit issue
- 📦 Saves destroy plan (90 day retention)

**Example Usage:**
```bash
# Via GitHub UI:
# 1. Go to Actions → Terraform Destroy
# 2. Click "Run workflow"
# 3. Type "destroy" in confirm field
# 4. Enter reason: "Tearing down dev environment"
# 5. Click "Run workflow"
# 6. Wait for approval
# 7. Approve in Environments tab
```

### 4. Drift Detection (`terraform-drift.yml`)

**Purpose:** Detect manual changes to infrastructure

**Schedule:** Daily at 6:00 AM UTC (configurable)

**Jobs:**
- `detect-drift` - Run plan and check for changes

**Exit Codes:**
- `0` = No drift (infrastructure matches code)
- `2` = Drift detected (changes found)
- `1` = Error

**What It Does:**
- ✅ No drift: Closes any open drift issues
- ⚠️ Drift found: Creates GitHub issue with details
- ❌ Error: Creates error issue

**Example Drift Issue:**
```
## Infrastructure Drift Detected

Terraform has detected differences between the code in `main` 
branch and the actual infrastructure.

**Detected:** 2025-01-13T06:00:00Z

### Changes Summary
- **Resources to Add:** 0
- **Resources to Change:** 3
- **Resources to Destroy:** 0

### Possible Causes
- Manual changes made in AWS Console
- Changes made outside of Terraform
- Infrastructure modified by other tools

### Recommended Actions
1. Review the drift plan
2. Determine if changes are intentional
3. Either import changes or run apply
```

## 🔒 Security Features

### 1. OIDC Authentication
- No long-lived AWS credentials
- Temporary credentials per workflow run
- Automatic expiration

### 2. Security Scanning
- **tfsec**: AWS security best practices
- **Checkov**: Policy-as-code compliance
- Results uploaded to GitHub Security tab

### 3. Approval Gates
- Production changes require manual approval
- Destruction requires separate environment approval
- Configurable reviewers and wait times

### 4. Audit Trail
- All applies create GitHub issues
- Destroy operations logged permanently
- Drift detection creates tracking issues
- Artifacts retained for compliance

## 📊 Artifacts & Retention

| Artifact Type | Retention | Purpose |
|---------------|-----------|---------|
| Terraform Plan | 5 days | PR review |
| Apply Plan | 30 days | Production audit |
| Terraform Outputs | 90 days | Long-term reference |
| Drift Plan | 30 days | Investigation |
| Destroy Plan | 90 days | Compliance audit |

## 🎛️ Configuration

### Customizing Workflows

**Change Terraform Version:**
```yaml
env:
  TF_VERSION: 1.6.0  # Update this
```

**Change AWS Region:**
```yaml
env:
  AWS_REGION: eu-west-2  # Update this
```

**Change Drift Detection Schedule:**
```yaml
on:
  schedule:
    - cron: '0 6 * * *'  # Daily at 6 AM UTC
    # - cron: '0 */6 * * *'  # Every 6 hours
    # - cron: '0 0 * * 1'  # Weekly on Monday
```

**Disable Cost Estimation:**
Remove or comment out the `terraform-cost-estimate` job

**Add Slack Notifications:**
Add this step to workflows:
```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}
```

## 🐛 Troubleshooting

### Workflow Not Triggering
- Check branch protection rules
- Verify workflow file syntax with yamllint
- Check workflow permissions in repo settings

### Authentication Failures
- Verify AWS_ROLE_ARN secret
- Check OIDC trust policy
- Ensure IAM role has necessary permissions

### Plan Shows Unexpected Changes
- Check for manual changes in AWS Console
- Review Terraform state
- Look at drift detection issues

### Security Scan Failures
- Review findings in Security tab
- Add exceptions if needed (document why)
- Fix security issues in code

## 📚 Best Practices

### 1. Branch Protection
Enable on `main`:
- Require PR reviews
- Require status checks to pass
- Include administrators

### 2. Environment Protection
Configure `production`:
- Required reviewers: 2+
- Wait timer: Optional
- Limit to `main` branch

### 3. State Management
- Use remote state (S3)
- Enable versioning
- Use state locking (DynamoDB)

### 4. Testing Strategy
- Test in feature branches
- Use staging environment
- Gradual rollout to production

### 5. Documentation
- Update comments in workflows
- Document custom configurations
- Maintain troubleshooting guide

## 🎓 Learning Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments)
- [OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

---

**Need Help?** Check the [CICD-SETUP.md](../CICD-SETUP.md) for detailed setup instructions.
