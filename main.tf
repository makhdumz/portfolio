# Pipeline: Terraform infra + Build, Push, Deploy

trigger:
- main

pool:
  vmImage: ubuntu-latest

stages:
# Stage 1: Terraform infra
- stage: DeployInfrastructure
  displayName: 'Deploy Terraform Infrastructure'
  jobs:
  - job: Terraform
    displayName: 'Run Terraform Apply'
    steps:
    - task: TerraformInstaller@1
      inputs:
        terraformVersion: 'latest'
    - task: TerraformTaskV4@4
      displayName: 'Terraform init'
      inputs:
        provider: 'azurerm'
        command: 'init'
        backendServiceArm: 'Dev-Portal'
        backendAzureRmResourceGroupName: 'low'
        backendAzureRmStorageAccountName: 'youruniquestorageaccountname'
        backendAzureRmContainerName: 'tfstate'
        backendAzureRmKey: 'portfolio.tfstate'
    - task: TerraformTaskV4@4
      displayName: 'Terraform apply'
      inputs:
        provider: 'azurerm'
        command: 'apply'
        commandOptions: '-auto-approve'
        environmentServiceNameAzureRM: 'Dev-Portal'

# Stage 2: Build, Push and Deploy container
- stage: BuildPushAndDeploy
  displayName: 'Build, Push, and Deploy Image'
  dependsOn: DeployInfrastructure
  jobs:
  - job: Docker
    displayName: 'Build, Push and Deploy'
    steps:
    - task: Docker@2
      displayName: 'Login to ACR'
      inputs:
        command: 'login'
        containerRegistry: 'Docker Reg'

    - task: Docker@2
      displayName: 'Build and Push Image to ACR'
      inputs:
        command: 'buildAndPush'
        repository: 'portfolio-site'
        dockerfile: '**/Dockerfile'
        tags: 'latest'

    - task: AzureWebAppContainer@1
      displayName: 'Deploy Container to App Service'
      inputs:
        azureSubscription: 'Dev-Portal'
        appName: 'portfolio-demo'
        imageName: 'portfolioregistrytf020qrb.azurecr.io/portfolio-site:latest'
