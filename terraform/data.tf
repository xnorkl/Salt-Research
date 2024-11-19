# Key Vault data sources
data "azurerm_key_vault" "terraform_vault" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group
}

# Key Vault secrets
data "azurerm_key_vault_secret" "subscription_id" {
  name         = "terraform-subscription-id"
  key_vault_id = data.azurerm_key_vault.terraform_vault.id
}

data "azurerm_key_vault_secret" "tenant_id" {
  name         = "terraform-tenant-id"
  key_vault_id = data.azurerm_key_vault.terraform_vault.id
}

data "azurerm_key_vault_secret" "client_id" {
  name         = "terraform-client-id"
  key_vault_id = data.azurerm_key_vault.terraform_vault.id
}

data "azurerm_key_vault_secret" "admin_username" {
  name         = "vm-admin-username"
  key_vault_id = data.azurerm_key_vault.terraform_vault.id
}

data "azurerm_key_vault_secret" "admin_password" {
  name         = "vm-admin-password"
  key_vault_id = data.azurerm_key_vault.terraform_vault.id
}

data "azurerm_key_vault_secret" "docker_registry_username" {
  name         = "docker-registry-username"
  key_vault_id = data.azurerm_key_vault.terraform_vault.id
}

data "azurerm_key_vault_secret" "docker_registry_password" {
  name         = "docker-registry-password"
  key_vault_id = data.azurerm_key_vault.terraform_vault.id
}

# Client IP for NSG rules
data "http" "my_ip" {
  url = "https://api.ipify.org?format=text"
} 