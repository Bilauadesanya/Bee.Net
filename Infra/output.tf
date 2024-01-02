output "instrumentation_key" {
  value     = azurerm_application_insights.bee-appinsights.instrumentation_key
  sensitive = true
}

output "app_id" {
  value     = azurerm_application_insights.bee-appinsights.id
  sensitive = true
}
output "frontend_url" {

  value = "${azurerm_windows_web_app.cd-webapp.name}.azurewebsites.net"
}

output "backedn_url" {

  value = "${azurerm_windows_web_app.cm-webapp.name}.azurewebsites.net"
}

