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
  }

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL      = var.docker_registry_url
    DOCKER_REGISTRY_SERVER_USERNAME = data.azurerm_key_vault_secret.docker_registry_username.value
    DOCKER_REGISTRY_SERVER_PASSWORD = data.azurerm_key_vault_secret.docker_registry_password.value
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
  }

  tags = var.tags
}

# Create network security group
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
    name                       = "Allow_Docker"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2375"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_TLS"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2376"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_API"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2376"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry"
    priority                   = 1008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_TLS"
    priority                   = 1009
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_API"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry"
    priority                   = 1011
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_TLS"
    priority                   = 1012
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_API"
    priority                   = 1013
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry"
    priority                   = 1014
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_TLS"
    priority                   = 1015
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_API"
    priority                   = 1016
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry"
    priority                   = 1017
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1018
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_API"
    priority                   = 1019
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1021
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1022
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1023
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1024
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1025
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1026
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1027
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1028
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1029
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1030
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1031
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1032
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1033
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1034
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1035
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1036
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1037
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1038
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1039
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1040
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1041
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1042
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1043
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1044
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1045
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1046
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1047
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1048
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1049
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1050
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1051
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1052
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1053
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1054
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1055
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1056
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1057
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1058
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1059
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1060
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1061
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1062
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1063
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1064
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1065
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1066
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1067
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1068
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1069
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1070
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1071
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1072
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1073
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1074
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1075
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1076
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1077
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1078
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1079
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1080
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1081
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1082
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1083
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1084
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1085
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1086
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1087
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1088
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1089
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1090
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1091
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1092
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1093
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1094
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1095
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1096
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1097
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1098
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1099
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1106
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1107
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1108
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1109
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1111
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1112
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1113
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1114
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1115
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1116
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1117
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1118
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1119
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1121
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1122
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1123
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1124
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1125
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1126
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1127
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1128
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1129
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1131
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1132
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1133
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1134
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1135
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1136
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1137
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1138
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1139
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1141
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1142
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1143
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1144
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1145
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1146
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1147
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1148
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1149
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1151
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1152
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1153
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1154
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1155
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1156
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1157
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1158
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1159
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1160
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1161
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1162
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1163
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1164
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1165
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1166
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry"
    priority                   = 1167
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_TLS"
    priority                   = 1168
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "${data.http.my_ip.response_body}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Docker_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_Registry_API"
    priority                   = 1169
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
} 