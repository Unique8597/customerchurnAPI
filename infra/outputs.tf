output "acr_login_server" {
  description = "ACR login server URL"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_username" {
  description = "ACR admin username"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "acr_password" {
  description = "ACR admin password"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "container_app_name" {
  description = "Container App name"
  value       = azurerm_container_app.api.name
}

output "container_app_url" {
  description = "Container App public URL"
  value       = "https://${azurerm_container_app.api.ingress[0].fqdn}"
}

output "function_app_name" {
  description = "Azure Function App name"
  value       = azurerm_linux_function_app.event_listener.name
}

output "event_subscription_name" {
  description = "Event Grid subscription name"
  value       = azurerm_eventgrid_event_subscription.model_registered.name
}