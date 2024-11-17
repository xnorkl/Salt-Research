terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-backend-rg"
    storage_account_name = "paresbackend"
    container_name       = "tfstate"
    key                 = "range.tfstate"
    use_msi             = true
    subscription_id     = "fd9e7885-ce5c-4fef-8925-9b7f57262bb7"
    tenant_id           = "5247fd73-baa3-4ba6-8e07-4c0e4bae109f"
    client_id           = "2256e54e-8213-4e04-9471-0a427e454629"
  }
}
