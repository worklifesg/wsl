# Automated WSL Image Builder (End-to-End)

## Overview
This repo builds a custom WSL rootfs (tarball) locally or via CI (CodeBuild/GitHub Actions) and uploads it to S3 for distribution.

## Run locally (quick)
On Ubuntu (or WSL host with sudo):
1. sudo apt-get update
2. sudo apt-get install -y debootstrap tar xz-utils sudo
3. sudo bash build.sh
4. Copy `custom-wsl.tar.gz` to Windows and import:
   - use `windows/install-wsl-image.ps1` or:
     `wsl --import MyDevDistro C:\WSL\MyDevDistro C:\path\to\custom-wsl.tar.gz --version 2`

Optional: enable systemd by adding `[boot]\nsystemd=true` to `/etc/wsl.conf` inside the distro and run `wsl --shutdown`.

## Run in AWS (automated pipeline)
Option 1 — CloudFormation:
1. Push repo to GitHub.
2. Deploy CloudFormation: provide GitHubOwner, GitHubRepo, GitHubBranch, GitHubToken, and optionally `ReleaseBucketName`.

```bash
aws cloudformation deploy --template-file cloudformation/pipeline.yml --stack-name wsl-image-pipeline \
  --parameter-overrides GitHubOwner=your-github-username GitHubRepo=your-repo-name GitHubBranch=main GitHubToken=ghp_YOUR_TOKEN ReleaseBucketName=my-wsl-images
```

3. Pipeline will produce `custom-wsl-<DATE>-<BUILD>.tar.gz` and `custom-wsl-latest.tar.gz` in the Release Bucket (if specified).

Option 2 — GitHub Actions (OIDC):
1. Deploy the OIDC setup stack to create the S3 bucket and IAM role:
   ```bash
   aws cloudformation deploy --template-file cloudformation/github-oidc-setup.yml --stack-name wsl-oidc-setup \
     --capabilities CAPABILITY_NAMED_IAM --parameter-overrides GitHubOrg=your-github-org GitHubRepo=your-repo-name
   ```
2. Note the `RoleArn` and `BucketName` from the stack outputs.
3. Add the following secrets to your GitHub repository:
   - `AWS_ROLE_ARN`: The Role ARN from step 2.
   - `S3_BUCKET`: The Bucket Name from step 2.
   - `AWS_REGION`: Your AWS region (e.g., `us-east-1`).
4. Push to `main` (or `develop`) to trigger the build. The workflow uses OIDC for secure, temporary credentials.

## Import on Windows:
Use `windows/import-and-setup.ps1` to download & import. You can specify a version (default is "latest").

```powershell
.\windows\import-and-setup.ps1 -BucketName "my-wsl-images" -Version "latest" -DistroName "MyDevDistro"
```

## Customization
- Create a `packages.txt` file in the root to override the default package list.


## Notes
- No VPC needed for typical builds.
- Image sizes will be large if you include everything; consider a minimal variant.
- Add IAM least-privilege for production.

