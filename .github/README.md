# GitHub Configuration & CI/CD

This directory contains GitHub-specific configurations including automated CI/CD workflows for Terraform infrastructure.

## 📁 Contents

```
.github/
├── workflows/              # GitHub Actions workflows
│   ├── terraform-plan.yml      # PR validation & planning
│   ├── terraform-apply.yml     # Production deployment
│   ├── terraform-destroy.yml   # Infrastructure destruction
│   ├── terraform-drift.yml     # Daily drift detection
│   └── README.md               # Workflow documentation
├── CICD-SETUP.md          # Complete setup guide
└── README.md              # This file
```

## 🚀 Quick Start

### 1. Complete the Setup
Follow the detailed guide: [CICD-SETUP.md](CICD-SETUP.md)

**Summary:**
- Set up AWS OIDC for GitHub Actions
- Configure GitHub Secrets
- Create GitHub Environments with approval
- Push code to GitHub

### 2. Test Your First PR

```bash
# Create feature branch
git checkout -b feature/test-cicd

# Make a small change
echo "# CI/CD test" >> README.md

# Commit and push
git add .
git commit -m "test: Verify CI/CD pipeline"
git push origin feature/test-cicd

# Create PR on GitHub
# Watch the workflows run automatically! 🎉
```

## 🎯 What Gets Automated

### Every Pull Request ✅
- ✓ Terraform format check
- ✓ Terraform validation
- ✓ Security scanning (tfsec, Checkov)
- ✓ Terraform plan generation
- ✓ Cost estimation (optional)
- ✓ Automated PR comments with results

### Every Merge to Main ✅
- ✓ Terraform plan review
- ⏸️ Wait for approval
- ✓ Terraform apply
- ✓ Success/failure notification
- ✓ Outputs saved as artifacts

### Daily (6 AM UTC) ✅
- ✓ Drift detection
- ✓ Issue creation if drift found
- ✓ Auto-close when resolved

### Manual Triggers ⚙️
- ⚠️ Infrastructure destruction (with multiple safeguards)
- 🔄 Manual drift check
- 🚀 Manual deployment

## 🔒 Security Features

### 1. No Long-Lived Credentials
- Uses AWS OIDC for authentication
- Temporary credentials per workflow
- Automatic expiration

### 2. Automated Security Scanning
- **tfsec**: Catches AWS misconfigurations
- **Checkov**: Policy-as-code compliance
- Results visible in Security tab

### 3. Approval Requirements
- Production changes require human approval
- Configurable reviewers
- Optional wait timers

### 4. Audit Trail
- All changes logged in GitHub issues
- Plans saved as artifacts
- Permanent records for compliance

## 📊 Monitoring

### GitHub Actions UI
- **Actions Tab**: See all workflow runs
- **Pull Requests**: Automated checks and comments
- **Issues**: Automated notifications
- **Security Tab**: Security scan results

### What You'll See

**On Pull Requests:**
```
✅ Terraform Format Check
✅ Terraform Validation
✅ Security Scan (tfsec)
✅ Security Scan (Checkov)
✅ Terraform Plan
⏳ Cost Estimation
```

**On Main Branch:**
```
✅ Terraform Apply
   ⏸️ Waiting for approval...
   ✅ Apply completed
   ✅ Outputs saved
   ✅ Issue created
```

## 💰 Cost Considerations

### GitHub Actions Minutes
- **Free tier**: 2,000 minutes/month for public repos
- **Private repos**: Varies by plan
- Typical run times:
  - Plan workflow: 3-5 minutes
  - Apply workflow: 5-10 minutes
  - Drift detection: 2-3 minutes

### Recommendations
- Use self-hosted runners for heavy usage
- Optimize workflows to reduce run time
- Cache Terraform plugins

## 🎓 Interview Talking Points

### Pipeline Architecture
**"I implemented a complete GitOps workflow for infrastructure:**
- Pull requests automatically run validation, security scanning, and cost estimation
- Changes are reviewed by the team with full visibility into what will change
- Production deployments require manual approval through GitHub Environments
- Daily drift detection catches manual changes with automatic issue creation
- All changes are auditable through GitHub issues and artifacts"

### Security & Compliance
**"Security is built into every stage:**
- OIDC authentication eliminates long-lived credentials
- Automated security scanning with tfsec and Checkov catches issues early
- Multi-level approval gates prevent unauthorized changes
- Complete audit trail for compliance requirements
- Principle of least privilege for IAM permissions"

### Automation Benefits
**"The CI/CD pipeline provides several key benefits:**
- Reduces manual errors through automation
- Enforces consistent processes across the team
- Provides early feedback on changes
- Enables safe, frequent deployments
- Maintains infrastructure state and security posture
- Creates documentation automatically through artifacts and issues"

## 🔧 Customization

### Change Approval Requirements
Edit environment settings in GitHub:
**Settings → Environments → production**

### Modify Workflow Triggers
Edit workflow files in `workflows/` directory

### Add Notifications
Add steps to workflows:
- Slack notifications
- Email alerts
- Custom webhooks

### Adjust Retention
Change artifact retention periods:
```yaml
- name: Upload Artifact
  uses: actions/upload-artifact@v4
  with:
    retention-days: 30  # Adjust this
```

## 📚 Documentation

- **[CICD-SETUP.md](CICD-SETUP.md)** - Complete setup guide with step-by-step instructions
- **[workflows/README.md](workflows/README.md)** - Detailed workflow documentation
- **Workflow files** - Inline comments explain each step

## 🐛 Common Issues

### "Permission denied" errors
- Check AWS_ROLE_ARN secret is correct
- Verify IAM role trust policy
- Ensure role has necessary permissions

### Workflows not running
- Check workflow file syntax
- Verify branch protection rules
- Check repository settings

### Plan shows drift immediately
- Manual changes in AWS Console
- Changes by other automation
- Check drift detection issues

## ✨ Best Practices

1. **Always create feature branches** - Never commit directly to main
2. **Review plans carefully** - Check PR comments before merging
3. **Use staging environment** - Test changes before production
4. **Keep state secure** - Use remote state with locking
5. **Document changes** - Clear commit messages and PR descriptions
6. **Monitor workflows** - Check Actions tab regularly
7. **Review security findings** - Address tfsec/Checkov issues

## 🎯 Next Steps

1. ✅ Complete [CICD-SETUP.md](CICD-SETUP.md)
2. 🔄 Create your first test PR
3. 👀 Watch the workflows in action
4. 📊 Review the automated comments and artifacts
5. ✍️ Practice the approval process
6. 🎓 Prepare to discuss in your interview!

---

**Ready to deploy?** Follow the setup guide and push your code to see the CI/CD pipeline in action! 🚀
