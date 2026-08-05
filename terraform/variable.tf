variable "resource_group_name" {
  description = "The name of the resource group to create."
  type        = string
  default     = "rg-compliance"
}


variable "location" {
  description = "The Azure region where the resources will be created."
  type        = string
  default     = "eastus"
}

variable "azurerm_storage_account_name" {
  description = "The name of the Azure Storage Account to create."
  type        = string
  default     = "compliancelabsa"
}

variable "azurerm_key_vault_name" {
  description = "The name of the Azure Key Vault to create."
  type        = string
  default     = "compliance-lab-kv"
}

variable "azurerm_managed_identity_name" {
  description = "The name of the Azure Managed Identity to create."
  type        = string
  default     = "compliance-lab-mi"
}

