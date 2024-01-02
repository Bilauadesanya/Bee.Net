resource "azurerm_resource_group" "rg" {
  name     = "Mc-Bee-123"
  location = var.location
  tags = {
    "Application" = "BeeNetApp"
  }
}
resource "azurerm_service_plan" "cd-asp" {
  name                = "bee-cd-asp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Windows"
  sku_name            = "B1"
  depends_on = [
    azurerm_subnet.cd-subnet
  ]
}


resource "azurerm_service_plan" "cm-asp" {
  name                = "bee-cm-asp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Windows"
  sku_name            = "B1"
  depends_on = [
    azurerm_subnet.cm-subnet
  ]
}

#Frontend
# Create the web app, pass in the App Service Plan ID
resource "azurerm_windows_web_app" "cd-webapp" {
  name                = "cd-webapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.cd-asp.id
  https_only          = true
  site_config {
    minimum_tls_version = "1.2"
    always_on           = true

    application_stack {
      current_stack       = "dotnet"
      dotnet_version = "v6.0" # .NET 7 version
    }
  }

  app_settings = {

    "APPINSIGHTS_INSTRUMENTATIONKEY"             = azurerm_application_insights.bee-appinsights.instrumentation_key
    "APPINSIGHTS_PROFILERFEATURE_VERSION"        = "1.0.0"
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~2"
  }


  depends_on = [
    azurerm_service_plan.cd-asp, azurerm_application_insights.bee-appinsights
  ]
}



#Backend
# Create the web app, pass in the App Service Plan ID
resource "azurerm_windows_web_app" "cm-webapp" {
  name                = "cm-webapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.cm-asp.id
  https_only          = true
  site_config {
    minimum_tls_version = "1.2"
    always_on           = true


  }

  app_settings = {

    "APPINSIGHTS_INSTRUMENTATIONKEY"             = azurerm_application_insights.bee-appinsights.instrumentation_key
    "APPINSIGHTS_PROFILERFEATURE_VERSION"        = "1.0.0"
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~2"
  }


  depends_on = [
    azurerm_service_plan.cm-asp, azurerm_application_insights.bee-appinsights
  ]
}

#vnet integration of backend webapp
resource "azurerm_app_service_virtual_network_swift_connection" "cm-vnet-integration" {
  app_service_id = azurerm_windows_web_app.cm-webapp.id
  subnet_id      = azurerm_subnet.cm-subnet.id
  depends_on = [
    azurerm_windows_web_app.cm-webapp
  ]
}

#vnet integration of frontend webapp
resource "azurerm_app_service_virtual_network_swift_connection" "cd-vnet-integration" {
  app_service_id = azurerm_windows_web_app.cd-webapp.id
  subnet_id      = azurerm_subnet.cd-subnet.id
  depends_on = [
    azurerm_windows_web_app.cd-webapp
  ]
}

data "azurerm_client_config" "current" {}



resource "azurerm_key_vault" "bee-keyvault" {
  name                        = "beekeyvault2024"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"


}

resource "azurerm_key_vault_access_policy" "kv_access_policy_01" {
  #This policy adds databaseadmin group with below permissions
  key_vault_id       = azurerm_key_vault.bee-keyvault.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = "86f50fc0-0d0d-4c26-941d-17dd64ed03a6"
  key_permissions    = ["Get", "List"]
  secret_permissions = ["Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Set"]

  depends_on = [azurerm_key_vault.bee-keyvault]
}

resource "azurerm_key_vault_access_policy" "kv_access_policy_02" {
  #This policy adds databaseadmin group with below permissions
  key_vault_id       = azurerm_key_vault.bee-keyvault.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = "da96d180-3c89-4f4d-b1c3-2c67dec3218c"
  key_permissions    = ["Get", "List"]
  secret_permissions = ["Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Set"]

  depends_on = [azurerm_key_vault.bee-keyvault]
}


resource "azurerm_key_vault_access_policy" "kv_access_policy_03" {
  #This policy adds databaseadmin group with below permissions
  key_vault_id       = azurerm_key_vault.bee-keyvault.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = "ef581861-a1a9-4d40-9fcb-cd6f6b97bf4b"
  key_permissions    = ["Get", "List"]
  secret_permissions = ["Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Set"]

  depends_on = [azurerm_key_vault.bee-keyvault]
}



#Create Random password 
resource "random_password" "randompassword" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}







#Create Key Vault Secret
resource "azurerm_key_vault_secret" "sqladminpassword" {
  # checkov:skip=CKV_AZURE_41:Expiration not needed 
  name         = "sqladmin"
  value        = random_password.randompassword.result
  key_vault_id = azurerm_key_vault.bee-keyvault.id
  content_type = "text/plain"
  depends_on = [
    azurerm_key_vault.bee-keyvault, azurerm_key_vault_access_policy.kv_access_policy_01, azurerm_key_vault_access_policy.kv_access_policy_02, azurerm_key_vault_access_policy.kv_access_policy_03
  ]
}

#Azure sql database
resource "azurerm_mssql_server" "azuresql" {
  name                         = "bee-sqldb"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "4adminu$er"
  administrator_login_password = random_password.randompassword.result

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = "86f50fc0-0d0d-4c26-941d-17dd64ed03a6"
  }
}

#add subnet from the backend vnet
#adding a new comment in main branch
resource "azurerm_mssql_virtual_network_rule" "allow-cm" {
  name      = "cm-sql-vnet-rule"
  server_id = azurerm_mssql_server.azuresql.id
  subnet_id = azurerm_subnet.cm-subnet.id
  depends_on = [
    azurerm_mssql_server.azuresql
  ]
}

resource "azurerm_mssql_database" "bee-database" {
  name           = "bee-db"
  server_id      = azurerm_mssql_server.azuresql.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb    = 2
  read_scale     = false
  sku_name       = "S0"
  zone_redundant = false

  tags = {
    Application = "Bee-Net"
    Env         = "Prod"
  }
}

resource "azurerm_key_vault_secret" "sqldb_cnxn" {
  name         = "fgsqldbconstring"
  value        = "Driver={ODBC Driver 18 for SQL Server};Server=tcp:bee-sqldb.database.windows.net,1433;Database=bee-db;Uid=4adminu$er;Pwd=${random_password.randompassword.result};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
  key_vault_id = azurerm_key_vault.bee-keyvault.id
  depends_on = [
    azurerm_mssql_database.bee-database, azurerm_key_vault_access_policy.kv_access_policy_01, azurerm_key_vault_access_policy.kv_access_policy_02, azurerm_key_vault_access_policy.kv_access_policy_03
  ]
}

resource "azurerm_log_analytics_workspace" "bee-loganalytics" {
  name                = "bee-la-workspace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "bee-appinsights" {
  name                = "bee-appinsights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.bee-loganalytics.id
  application_type    = "web"
  depends_on = [
    azurerm_log_analytics_workspace.bee-loganalytics
  ]
}

resource "azurerm_storage_account" "bee-storage" {
  name                     = "beestorageaccount1989"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "prod"
  }
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "bee-vnet-test"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}


#get output variables
output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

#Create subnets
resource "azurerm_subnet" "cd-subnet" {
  name                 = "cd-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/26"]
  service_endpoints    = ["Microsoft.Web"]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action", "Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }


  }

  lifecycle {
    ignore_changes = [
      delegation,
    ]
  }
}

#Create subnets
resource "azurerm_subnet" "cm-subnet" {
  name                 = "cm-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.64/26"]
  service_endpoints    = ["Microsoft.Sql"]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action", "Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }


  }

  lifecycle {
    ignore_changes = [
      delegation,
    ]
  }
}


