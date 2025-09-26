# This is the final, correct version of your main.tf file

terraform {
  required_providers {
    azurerm = {
      source  = "hashcorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Use your existing Resource Group named "low"
data "azurerm_resource_group" "rg" {
  name = "low"
}

# App Service Plan (Linux Free F1)
resource "azurerm_service_plan" "plan" {
  name                = "portfolio-plan"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "F1"
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "portfolioregistrytf020qrb"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Linux Web App running a Docker container
resource "azurerm_linux_web_app" "webapp" {
  name                = "portfolio-demo"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  # This block is empty to fix the "always_on" error with the Free plan
  site_config {}

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"      = "https://{azurerm_container_registry.acr.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME" = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = azurerm_container_registry.acr.admin_password
  }
}
