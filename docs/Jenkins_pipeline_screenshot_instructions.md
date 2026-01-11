# Jenkins Pipeline Screenshot Instructions

## Overview

This guide explains what to screenshot from Jenkins for documentation and review purposes.

## Screenshots to Capture

### 1. Pipeline Overview (Main Dashboard)

**Location**: Jenkins Dashboard → Your Pipeline Job

**What to Capture**:
- Job name and status (✓ or ✗)
- Last build number and status
- Build history (last 5-10 builds)
- Weather icon (indicates build stability)

**How to Capture**:
1. Navigate to Jenkins dashboard
2. Find your pipeline job (`login-app-cicd`)
3. Take screenshot showing job status and build history

### 2. Pipeline Stage View

**Location**: Pipeline Job → Stage View

**What to Capture**:
- All pipeline stages (Checkout, Build, Test, Push, Deploy, Verify)
- Stage status (✓ green, ✗ red, ⏸ yellow)
- Stage duration times
- Overall pipeline duration

**How to Capture**:
1. Click on your pipeline job
2. Click **Stage View** tab (or view in main job page)
3. Take screenshot showing all stages and their status

### 3. Successful Build Console Output

**Location**: Pipeline Job → Build #X → Console Output

**What to Capture**:
- Build number and status
- All stage logs (especially key sections):
  - Git checkout information
  - Docker build output
  - Image push confirmation
  - Deployment logs
  - Verification results
- Final "Pipeline completed successfully" message

**How to Capture**:
1. Click on a successful build (green ✓)
2. Click **Console Output**
3. Scroll to show:
   - Beginning (checkout info)
   - Middle (build/push stages)
   - End (deployment and verification)
4. Take multiple screenshots or one long screenshot

### 4. Build Parameters/Environment

**Location**: Pipeline Job → Build #X → Build Information

**What to Capture**:
- Git commit SHA
- Branch name
- Build timestamp
- Environment variables (if visible)
- Image tags used

**How to Capture**:
1. Click on a build
2. Look for **Build Information** or **Environment Variables** section
3. Take screenshot

### 5. Credentials Configuration (Anonymized)

**Location**: Manage Jenkins → Credentials → System → Global credentials

**What to Capture** (with sensitive data blurred):
- List of credential IDs:
  - `DOCKER_REGISTRY_CRED`
  - `SSH_DEPLOY_KEY`
  - Other configured credentials
- Credential types (Username/Password, SSH Key, etc.)
- **IMPORTANT**: Blur or redact actual credential values

**How to Capture**:
1. Navigate to **Manage Jenkins** → **Credentials**
2. Click **System** → **Global credentials**
3. Take screenshot showing credential IDs (not values)
4. Use image editor to blur any sensitive information

### 6. Pipeline Configuration

**Location**: Pipeline Job → Configure

**What to Capture** (with sensitive data redacted):
- Pipeline definition (SCM or script)
- Build triggers
- General configuration
- **IMPORTANT**: Blur repository URLs, credentials, or IPs if sensitive

**How to Capture**:
1. Click on pipeline job
2. Click **Configure**
3. Take screenshots of:
   - General section
   - Pipeline definition section
   - Build triggers section
4. Redact sensitive information

### 7. Failed Build (if applicable)

**Location**: Pipeline Job → Failed Build #X → Console Output

**What to Capture**:
- Error messages
- Failed stage
- Stack traces (if any)
- Error context

**How to Capture**:
1. Click on a failed build (red ✗)
2. Click **Console Output**
3. Scroll to error section
4. Take screenshot showing error details

## Screenshot Best Practices

### 1. Anonymize Sensitive Data

- **Blur or redact**:
  - IP addresses
  - Hostnames (if sensitive)
  - Repository URLs (if private)
  - Credential values
  - API keys or tokens

- **Keep visible**:
  - Credential IDs (names only)
  - Stage names
  - Build numbers
  - Status indicators
  - Generic error messages

### 2. Use High Resolution

- Capture at full resolution
- Ensure text is readable
- Use PNG format for better quality

### 3. Include Context

- Show URL bar (if web-based)
- Include timestamps
- Show relevant UI elements

### 4. Organize Screenshots

Name files descriptively:
```
jenkins-pipeline-stage-view-success.png
jenkins-console-output-build-42.png
jenkins-credentials-list.png
jenkins-pipeline-config.png
```

## Example Screenshot Checklist

- [ ] Pipeline dashboard showing job status
- [ ] Stage view with all stages (✓)
- [ ] Console output (beginning - checkout)
- [ ] Console output (middle - build/push)
- [ ] Console output (end - deploy/verify)
- [ ] Build information (commit SHA, branch)
- [ ] Credentials list (IDs only, values blurred)
- [ ] Pipeline configuration (sensitive data redacted)
- [ ] Failed build (if any, for troubleshooting)

## Tools for Screenshots

### Windows
- **Snipping Tool** or **Snip & Sketch**
- **ShareX** (advanced, with annotation)

### macOS
- **Cmd + Shift + 4** (select area)
- **Cmd + Shift + 3** (full screen)

### Linux
- **GNOME Screenshot**
- **Flameshot** (with annotation)

### Browser Extensions
- **Awesome Screenshot** (Chrome/Firefox)
- **Nimbus Screenshot** (Chrome/Firefox)

## Anonymization Tools

- **GIMP** (free, cross-platform)
- **Paint.NET** (Windows)
- **Preview** (macOS) - use markup tools
- **Online tools**: Photopea, remove.bg

## Submission Format

When submitting screenshots:

1. **Create a folder**: `docs/screenshots/`
2. **Organize by category**:
   - `pipeline/` - Pipeline runs
   - `configuration/` - Jenkins config
   - `credentials/` - Credential setup (anonymized)
3. **Include README**: `docs/screenshots/README.md` explaining what each screenshot shows

## Example README for Screenshots

```markdown
# Jenkins Screenshots

## Pipeline Runs

- `pipeline-success-build-42.png` - Successful pipeline run showing all stages
- `pipeline-console-output.png` - Full console output from successful build

## Configuration

- `pipeline-config.png` - Pipeline job configuration (sensitive data redacted)
- `credentials-list.png` - List of configured credentials (values blurred)

## Notes

- All IP addresses and hostnames have been redacted
- Credential values are blurred, only IDs are visible
- Repository URL is redacted for privacy
```

## Privacy Considerations

**DO NOT** include in screenshots:
- Actual passwords or tokens
- Private IP addresses (unless in private network)
- Internal hostnames
- Repository URLs (if private)
- API keys or secrets

**OK to include**:
- Credential IDs (names)
- Public IPs (if already public)
- Generic error messages
- Build numbers and statuses
- Stage names and durations

