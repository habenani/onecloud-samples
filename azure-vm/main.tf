# Azure Linux virtual machine sample for OneCloud.
# One template, one unit of deployment: resource group (new or existing), virtual network and subnet (new, or an
# existing subnet), network security group with an SSH rule, optional public IP, network interface and an Ubuntu 22.04
# LTS virtual machine. In an existing subnet the security group is attached to the network interface, never to the
# shared subnet.

locals {
  # Template tags first, OneCloud tags last so the deployment correlation tag always wins.
  tags = merge(
    {
      Name     = var.name
      template = "azure-vm"
    },
    var.tags,
  )

  resource_group_name = var.create_resource_group ? azurerm_resource_group.this[0].name : data.azurerm_resource_group.existing[0].name
  location            = var.create_resource_group ? azurerm_resource_group.this[0].location : data.azurerm_resource_group.existing[0].location
  subnet_id           = var.create_network ? azurerm_subnet.this[0].id : var.subnet_id
}

check "subnet_given" {
  assert {
    condition     = var.create_network || var.subnet_id != ""
    error_message = "subnet_id is needed when create_network is false."
  }
}

# Deployments made before create_network existed keep their network objects
moved {
  from = azurerm_virtual_network.this
  to   = azurerm_virtual_network.this[0]
}

moved {
  from = azurerm_subnet.this
  to   = azurerm_subnet.this[0]
}

moved {
  from = azurerm_subnet_network_security_group_association.this
  to   = azurerm_subnet_network_security_group_association.this[0]
}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1

  name = var.resource_group_name
}

resource "azurerm_virtual_network" "this" {
  count = var.create_network ? 1 : 0

  name                = "${var.name}-vnet"
  resource_group_name = local.resource_group_name
  location            = local.location
  address_space       = [var.address_space]
  tags                = local.tags
}

resource "azurerm_subnet" "this" {
  count = var.create_network ? 1 : 0

  name                 = "${var.name}-subnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [var.subnet_prefix]
}

resource "azurerm_network_security_group" "this" {
  name                = "${var.name}-nsg"
  resource_group_name = local.resource_group_name
  location            = local.location
  tags                = local.tags

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_source_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  count = var.create_network ? 1 : 0

  subnet_id                 = azurerm_subnet.this[0].id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_network_interface_security_group_association" "this" {
  count = var.create_network ? 0 : 1

  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_public_ip" "this" {
  count = var.create_public_ip ? 1 : 0

  name                = "${var.name}-pip"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "this" {
  name                = "${var.name}-nic"
  resource_group_name = local.resource_group_name
  location            = local.location
  tags                = local.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = local.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.this[0].id : null
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                            = var.name
  resource_group_name             = local.resource_group_name
  location                        = local.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.this.id]
  tags                            = local.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "${var.name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }

  # Ubuntu 22.04 LTS (Jammy). The generation 1 SKU runs on every size, including Standard_B1s.
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  depends_on = [azurerm_subnet_network_security_group_association.this, azurerm_network_interface_security_group_association.this]
}
