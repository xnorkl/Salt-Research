terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-backend-rg"
    storage_account_name = "paresbackend"
    container_name      = "tfstate"
    key                 = "range.tfstate"
    use_msi             = true
  }
}

# Configure the Azure provider with the secrets
provider "azurerm" {
  features {}
  
  subscription_id = data.azurerm_key_vault_secret.subscription_id.value
  tenant_id       = data.azurerm_key_vault_secret.tenant_id.value
  client_id       = data.azurerm_key_vault_secret.client_id.value
}
