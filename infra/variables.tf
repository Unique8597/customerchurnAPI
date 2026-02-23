variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
}

variable "aml_workspace_id" {
  description = "Azure ML workspace resource ID (for Event Grid source)"
  type        = string
}

variable "github_token" {
  description = "GitHub PAT for the Azure Function to dispatch workflows"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub repo owner"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo name"
  type        = string
}

variable "github_workflow_id" {
  description = "API workflow file to dispatch e.g deploy-api.yml"
  type        = string
  default     = "deploy-api.yml"
}