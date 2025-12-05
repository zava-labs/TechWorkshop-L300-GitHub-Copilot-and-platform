# ZavaStorefront Infrastructure

This directory contains the Bicep Infrastructure as Code (IaC) templates for deploying the ZavaStorefront application to Azure.

## Architecture

The infrastructure includes:

- **Azure Container Registry (ACR)**: Stores Docker container images
- **App Service Plan**: Linux-based plan for hosting containers
- **Web App**: Web App for Containers with system-assigned managed identity
- **Application Insights**: Application monitoring and telemetry
- **Log Analytics Workspace**: Backend for Application Insights
- **RBAC Role Assignment**: AcrPull permissions for Web App to pull from ACR

## Structure

```
infra/
├── main.bicep              # Main orchestration template
├── main.bicepparam         # Parameters file for dev environment
└── modules/
    ├── container-registry.bicep   # ACR module
    ├── app-service-plan.bicep     # App Service Plan module
    ├── web-app.bicep              # Web App module
    ├── app-insights.bicep         # Application Insights module
    └── role-assignment.bicep      # RBAC role assignment module
```

## Prerequisites

- Azure CLI installed and authenticated
- Azure Developer CLI (azd) installed
- Bicep CLI installed
- An Azure subscription with appropriate permissions

## Deployment

### Using Azure Developer CLI (Recommended)

1. Initialize the environment:
   ```bash
   azd auth login
   azd env new dev
   ```

2. Provision the infrastructure:
   ```bash
   azd provision
   ```

3. Deploy the application:
   ```bash
   azd deploy
   ```

4. Or do both in one command:
   ```bash
   azd up
   ```

### Using Azure CLI

1. Create a resource group:
   ```bash
   az group create --name rg-zavastore-dev-westus3 --location westus3
   ```

2. Validate the deployment:
   ```bash
   az deployment group what-if \
     --resource-group rg-zavastore-dev-westus3 \
     --template-file infra/main.bicep \
     --parameters infra/main.bicepparam
   ```

3. Deploy the infrastructure:
   ```bash
   az deployment group create \
     --resource-group rg-zavastore-dev-westus3 \
     --template-file infra/main.bicep \
     --parameters infra/main.bicepparam
   ```

## Building and Pushing Container Images

Since the infrastructure uses managed identity for ACR access, you don't need Docker locally. Use cloud builds:

```bash
# Get ACR name from deployment output
ACR_NAME=$(az deployment group show \
  --resource-group rg-zavastore-dev-westus3 \
  --name main \
  --query properties.outputs.containerRegistryName.value -o tsv)

# Build and push using ACR
az acr build \
  --registry $ACR_NAME \
  --image zavastore:latest \
  --file Dockerfile \
  ./src
```

## Parameters

Key parameters in `main.bicepparam`:

- `environmentName`: Environment identifier (dev, staging, prod)
- `location`: Azure region (default: westus3)
- `applicationName`: Base name for resources
- `containerRegistrySku`: ACR SKU (Basic, Standard, Premium)
- `appServicePlanSku`: App Service Plan SKU
- `dockerImageAndTag`: Initial Docker image to deploy

## Security Considerations

- ✅ Managed identity authentication (no passwords)
- ✅ HTTPS only for Web App
- ✅ TLS 1.2 minimum
- ✅ Admin user disabled on ACR
- ✅ Application Insights connection strings marked as secure
- ✅ FTPS disabled

## Cost Optimization

For dev environment:
- ACR: Basic SKU (~$5/month)
- App Service Plan: B1 SKU (~$13/month)
- Application Insights: Pay-as-you-go
- Log Analytics: 30-day retention

**Estimated monthly cost: ~$20-30**

## Outputs

After deployment, the template outputs:

- `containerRegistryName`: ACR name
- `containerRegistryLoginServer`: ACR login server URL
- `webAppName`: Web App name
- `webAppUrl`: Web App public URL
- `appInsightsName`: Application Insights name
- `resourceGroupName`: Resource group name

## Cleanup

To delete all resources:

```bash
az group delete --name rg-zavastore-dev-westus3 --yes --no-wait
```

Or with azd:

```bash
azd down
```
