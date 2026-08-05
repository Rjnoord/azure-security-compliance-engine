resource "azurerm_resource_group" "rg-compliance" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = "development"
    managed_by  = "terraform"
  }

}

resource "azurerm_storage_account" "sa-compliance" {
  name                     = var.azurerm_storage_account_name
  resource_group_name      = azurerm_resource_group.rg-compliance.name
  location                 = azurerm_resource_group.rg-compliance.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "development"
    managed_by  = "terraform"
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "compliance-lab-kv" {
  name                       = var.azurerm_key_vault_name
  resource_group_name        = azurerm_resource_group.rg-compliance.name
  location                   = azurerm_resource_group.rg-compliance.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true

  tags = {
    environment = "development"
    managed_by  = "terraform"
  }
}



resource "azurerm_user_assigned_identity" "compliance-lab-mi" {
  name                = var.azurerm_managed_identity_name
  resource_group_name = azurerm_resource_group.rg-compliance.name
  location            = azurerm_resource_group.rg-compliance.location

  tags = {
    environment = "development"
    managed_by  = "terraform"
  }
}

resource "azurerm_role_assignment" "key_vault_reader" {
  scope                = azurerm_key_vault.compliance-lab-kv.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.compliance-lab-mi.principal_id
}

resource "azurerm_role_assignment" "storage-account-contributor" {
  scope                = azurerm_storage_account.sa-compliance.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.compliance-lab-mi.principal_id
}

resource "azurerm_role_assignment" "resource-group-contributor" {
  scope                = azurerm_resource_group.rg-compliance.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.compliance-lab-mi.principal_id
}

resource "azurerm_virtual_network" "vnet-compliance" {
  name                = "vnet-compliance"
  resource_group_name = azurerm_resource_group.rg-compliance.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "development"
    managed_by  = "terraform"
  }
}

resource "azurerm_subnet" "subnet-compliance" {
  name                 = "subnet-compliance"
  resource_group_name  = azurerm_resource_group.rg-compliance.name
  virtual_network_name = azurerm_virtual_network.vnet-compliance.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_subnet_network_security_group_association" "subnet-nsg-association" {
  subnet_id                 = azurerm_subnet.subnet-compliance.id
  network_security_group_id = azurerm_network_security_group.nsg-compliance.id
}

resource "azurerm_network_security_group" "nsg-compliance" {
  name                = "nsg-compliance"
  location            = azurerm_resource_group.rg-compliance.location
  resource_group_name = azurerm_resource_group.rg-compliance.name

  security_rule {
    name                       = "https-allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "development"
    managed_by  = "terraform"
  }
}

