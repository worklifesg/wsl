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
  --parameter-overrides GitHubOwner=you GitHubRepo=wsl-custom GitHubBranch=main GitHubToken=ghp_xxx ReleaseBucketName=my-wsl-images
```

3. Pipeline will produce `custom-wsl-<DATE>-<BUILD>.tar.gz` and `custom-wsl-latest.tar.gz` in the Release Bucket (if specified).

Option 2 — GitHub Actions:
- Add AWS secrets (S3 bucket, credentials) and push to `main`; workflow builds and uploads artifact.

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

