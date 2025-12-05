# GitHub Actions Deployment Setup

This workflow builds the .NET application as a Docker container and deploys it to Azure App Service.

## Required GitHub Secrets

Add these in your repository: **Settings → Secrets and variables → Actions → Secrets**

### `AZURE_CREDENTIALS`
Service Principal credentials for Azure authentication. Create with:

```bash
az ad sp create-for-rbac \
  --name "github-actions-zavastore" \
  --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-zavastore-dev-westus3 \
  --sdk-auth
```

Copy the entire JSON output and paste it as the secret value.

## Required GitHub Variables

Add these in your repository: **Settings → Secrets and variables → Actions → Variables**

| Variable Name | Value | How to Get It |
|--------------|-------|---------------|
| `ACR_NAME` | Your Container Registry name | Run: `az acr list --query "[].name" -o tsv` |
| `RESOURCE_GROUP_NAME` | `rg-zavastore-dev-westus3` | Your resource group name from Bicep deployment |

## Verify Setup

After configuring secrets and variables:

1. Push code to `main` or `dev` branch, or
2. Go to **Actions** tab → Select "Build and Deploy to Azure App Service" → **Run workflow**

The workflow will:
- Build the Docker image using Azure Container Registry (no local Docker needed)
- Push the image with commit SHA and `latest` tags
- Deploy the new image to your App Service
- Restart the app

## Troubleshooting

- **Authentication fails**: Verify `AZURE_CREDENTIALS` secret is valid JSON from `az ad sp` command
- **ACR not found**: Check `ACR_NAME` variable matches your registry name exactly
- **Permission denied**: Ensure the service principal has Contributor role on the resource group
