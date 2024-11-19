terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

# Create storage account for function app
resource "azurerm_storage_account" "sa" {
  name                     = "${var.project_name}${var.environment}sa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# Create app service plan
resource "azurerm_service_plan" "asp" {
  name                = "${var.project_name}-${var.environment}-asp"
  resource_group_name = azurerm_resource_group.rg.name
  location           = azurerm_resource_group.rg.location
  os_type            = "Linux"
  sku_name           = var.app_service_sku

  tags = var.tags
}

# Create function app
resource "azurerm_linux_function_app" "func" {
  name                       = "${var.project_name}-${var.environment}-func"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  service_plan_id            = azurerm_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key

  site_config {
    application_stack {
      docker {
        registry_url = var.docker_registry_url
        image_name   = var.docker_image_name
        image_tag    = var.docker_image_tag
      }
    }

    # Enable HTTPS-only
    http2_enabled = true
    ftps_state    = "FtpsOnly"
  }

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL          = var.docker_registry_url
    DOCKER_REGISTRY_SERVER_USERNAME     = var.docker_registry_username
    DOCKER_REGISTRY_SERVER_PASSWORD     = var.docker_registry_password
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    # Salt API settings
    SALT_API_URL                        = "https://${var.salt_master_url}"
    SALT_API_USER                       = var.salt_api_user
    SALT_API_PASSWORD                   = var.salt_api_password
    SALT_API_EAUTH                      = "pam"  # or your preferred auth method
  }

  tags = var.tags
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.project_name}-${var.environment}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_RDP"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Ports"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["2375", "2376", "5000"]
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Salt_Master"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4505"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Salt_Minion"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4506"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

