#!/bin/bash

# USAGE: ./setup_keyvault.sh from the root directory.

# Source the .env file from the root directory
ROOT_DIR=$(pwd)

if [ -f "${ROOT_DIR}/.env" ]; then
    source "${ROOT_DIR}/.env"
elif [ -f ".env" ]; then
    source ".env"
else
    echo "Error: .env file not found in either current or parent directory"
    exit 1
fi


# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI is not installed"
    exit 1
fi

# Check if user is logged in to Azure CLI
if ! az account show &> /dev/null; then
    echo "Not logged in to Azure CLI. Initiating login..."
    az login
fi    

# Verify login was successful
if ! az account show &> /dev/null; then
    echo "Error: Azure CLI login failed"
    exit 1
fi

# Update the REQUIRED_SECRETS array
REQUIRED_SECRETS=(
    "TERRAFORM-SUBSCRIPTION-ID"
    "VM-ADMIN-USERNAME"
    "VM-ADMIN-PASSWORD"
    "DOCKER-REGISTRY-USERNAME"
    "DOCKER-REGISTRY-PASSWORD"
)

# Create resource group if it doesn't exist
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# Create Key Vault if it doesn't exist
az keyvault create \
    --name "$KEYVAULT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --enable-rbac-authorization true

# Load secrets from .env file and create them in Key Vault
while IFS='=' read -r key value || [ -n "$key" ]; do
    # Skip empty lines and comments
    [[ $key =~ ^[[:space:]]*$ ]] && continue
    [[ $key =~ ^# ]] && continue
    
    # Clean up key and value (remove quotes, spaces, and convert to uppercase)
    key=$(echo "$key" | tr -d '"' | tr -d "'" | tr -d ' ' | tr '[:lower:]' '[:upper:]')
    value=$(echo "$value" | tr -d '"' | tr -d "'" | tr -d ' ')
    
    # Check if this secret is required (compare in uppercase)
    if printf '%s\n' "${REQUIRED_SECRETS[@]}" | grep -q "^${key}$"; then
        echo "Setting secret: $key"
        az keyvault secret set --vault-name "$KEYVAULT_NAME" --name "$key" --value "$value"
    fi
done < <(grep -v '^#' .env)

# Verify all required secrets are present
for secret in "${REQUIRED_SECRETS[@]}"; do
    if ! az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "$secret" >/dev/null 2>&1; then
        echo "Error: Required secret '$secret' is missing from Key Vault"
        exit 1
    fi
done

echo "Key Vault setup completed successfully!"