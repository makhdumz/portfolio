trigger:
- main

pool:
  vmImage: ubuntu-latest

stages:
# STAGE 1: DEPLOY INFRASTRUCTURE
# This stage runs your Terraform code.
- stage: DeployInfrastructure
  displayName: 'Deploy Terraform Infrastructure'
  jobs:
  - job: Terraform
    displayName: 'Run Terraform Apply'
    steps:
    - script: |
        terraform init
        terraform apply -auto-approve
      displayName: 'Terraform Init and Apply'
      env:
        ARM_CLIENT_ID: $(servicePrincipalId)
        ARM_CLIENT_SECRET: $(servicePrincipalKey)
        ARM_SUBSCRIPTION_ID: $(subscriptionId)
        ARM_TENANT_ID: $(tenantId)

# STAGE 2: BUILD, PUSH, AND DEPLOY CONTAINER
# This stage builds your Docker image and deploys it.
- stage: BuildPushAndDeploy
  displayName: 'Build, Push, and Deploy Image'
  dependsOn: DeployInfrastructure
  jobs:
  - job: Docker
    displayName: 'Build, Push and Deploy'
    steps:
    # Step 2.1: Login to your container registry
    - task: Docker@2
      displayName: 'Login to ACR'
      inputs:
        command: 'login'
        # This is your Docker Registry service connection in Azure DevOps
        containerRegistry: 'YourAzureContainerRegistryServiceConnection' 

    # Step 2.2: Build the image and push it to the registry
    - task: Docker@2
      displayName: 'Build and Push Image to ACR'
      inputs:
        command: 'buildAndPush'
        repository: 'portfolio-site' # This will be the image name
        dockerfile: '**/Dockerfile'
        tags: 'latest'

    # Step 2.3: Deploy the new image to your Web App
    - task: AzureWebAppContainer@1
      displayName: 'Deploy Container to App Service'
      inputs:
        # This is your main Azure service connection
        azureSubscription: 'Dev-Portal'
        # The name of the Web App defined in your main.tf
        appName: 'portfolio-demo'
        # The full name of the image to deploy
        imageName: 'portfolioregistrytf020qrb.azurecr.io/portfolio-site:latest'
