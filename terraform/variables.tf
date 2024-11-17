variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment (dev, staging, prod)"
}

variable "location" {
  type        = string
  description = "Azure region for resources"
  default     = "eastus"
}

variable "app_service_sku" {
  type        = string
  description = "SKU for App Service Plan"
  default     = "P1v2"
}

variable "docker_registry_url" {
  type        = string
  description = "Docker registry URL"
  default     = "https://index.docker.io"
}

variable "docker_image_name" {
  type        = string
  description = "Docker image name"
}

variable "docker_image_tag" {
  type        = string
  description = "Docker image tag"
  default     = "latest"
}

variable "docker_registry_username" {
  type        = string
  description = "Docker registry username"
  default     = ""
}

variable "docker_registry_password" {
  type        = string
  description = "Docker registry password"
  sensitive   = true
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
} 