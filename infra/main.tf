terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Remote state in Azure Blob Storage
  backend "azurerm" {
    resource_group_name  = "CustomerChurnProject"
    storage_account_name = "animeridw98232"
    container_name       = "tfstate"
    key                  = "mlops-api.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# ── Resource Group ─────────────────────────────────────────────────────────────
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# ── Container Registry (ACR) ───────────────────────────────────────────────────
resource "azurerm_container_registry" "acr" {
  name                = "${replace(var.project_name, "-", "")}acr"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

# ── Container App Environment ──────────────────────────────────────────────────
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "main" {
  name                       = "${var.project_name}-env"
  resource_group_name        = data.azurerm_resource_group.main.name
  location                   = data.azurerm_resource_group.main.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

# ── Container App (API) ────────────────────────────────────────────────────────
resource "azurerm_container_app" "api" {
  name                         = "${var.project_name}-api"
  resource_group_name          = data.azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  revision_mode                = "Single"

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }

  template {
    container {
      name   = "api"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "MODEL_NAME"
        value = "placeholder"   
      }
      env {
        name  = "MODEL_VERSION"
        value = "1"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# ── Azure Function — Storage Account ──────────────────────────────────────────
data "azurerm_storage_account" "function" {
  name                = var.storage_account_name
  resource_group_name = data.azurerm_resource_group.main.name
}

# ── Azure Function — App Service Plan (Linux) ──────────────────────────────────
resource "azurerm_service_plan" "function" {
  name                = "${var.project_name}-fn-plan"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"   # Consumption plan
}

# ── Azure Function App ─────────────────────────────────────────────────────────
resource "azurerm_linux_function_app" "event_listener" {
  name                       = "${var.project_name}-event-listeners"
  resource_group_name        = data.azurerm_resource_group.main.name
  location                   = data.azurerm_resource_group.main.location
  storage_account_name       = data.azurerm_storage_account.function.name
  storage_account_access_key = data.azurerm_storage_account.function.primary_access_key
  service_plan_id            = azurerm_service_plan.function.id

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    FUNCTIONS_EXTENSION_VERSION  = "~4" 
    GITHUB_TOKEN             = var.github_token
    GITHUB_OWNER             = var.github_owner
    GITHUB_REPO              = var.github_repo
    GITHUB_WORKFLOW_ID       = var.github_workflow_id
    GITHUB_REF               = "main"
  }
}

# ── Event Grid — Subscribe to AML Model Registry events ───────────────────────
resource "azurerm_eventgrid_event_subscription" "model_registered" {
  name  = "${var.project_name}-model-registered-sub"
  scope = var.aml_workspace_id     # AML workspace resource ID

  included_event_types = [
    "Microsoft.MachineLearningServices.ModelRegistered"
  ]

  azure_function_endpoint {
    function_id = "${azurerm_linux_function_app.event_listener.id}/functions/OnModelRegistered"

    max_events_per_batch              = 1
    preferred_batch_size_in_kilobytes = 64
  }

  retry_policy {
    max_delivery_attempts = 3
    event_time_to_live    = 1440   # 24 hours in minutes
  }
}