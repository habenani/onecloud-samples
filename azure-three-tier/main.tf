# Azure three tier sample for OneCloudify.
# Its own resource group (Remove deletes the group and everything in it), a virtual network with a web and an app
# subnet, one network security group per subnet (web: ingress_ports from ingress_source_cidr; app: only from the web
# subnet), an Ubuntu 24.04 LTS web server with a static Standard public IP, an Ubuntu 24.04 LTS app server with no
# public IP and managed data disks, and a private storage account for app data.
#
# Variables named <tier>_<setting> (web_vm_size, app_os_disk_size_gb, app_data_disk_sizes_gb) belong to the virtual
# machine whose Terraform name is <tier> (azurerm_linux_virtual_machine.web, .app), so day-2 operations on one server
# change that server only.

locals {
  # Template tags first, OneCloudify tags last so the deployment correlation tag always wins.
  tags = merge(
    {
      Name        = var.name
      template    = "azure-three-tier"
      cost_centre = var.cost_centre
    },
    var.test_tag == "" ? {} : { OneCloudTest = var.test_tag },
    var.tags,
  )
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

# ------------------------------------------------------------------ network

resource "azurerm_virtual_network" "this" {
  name                = "${var.name}-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = [var.address_space]
  tags                = local.tags
}

resource "azurerm_subnet" "web" {
  name                 = "${var.name}-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.web_subnet_prefix]
}

resource "azurerm_subnet" "app" {
  name                 = "${var.name}-app"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.app_subnet_prefix]
}

resource "azurerm_network_security_group" "web" {
  name                = "${var.name}-web-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags

  # One rule per port, so opening or closing a port adds or removes exactly one rule.
  dynamic "security_rule" {
    for_each = { for i, p in sort(var.ingress_ports) : tostring(p) => i }
    content {
      name                       = "allow-tcp-${security_rule.key}"
      priority                   = 100 + security_rule.value
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = security_rule.key
      source_address_prefix      = var.ingress_source_cidr
      destination_address_prefix = "*"
    }
  }
}

resource "azurerm_network_security_group" "app" {
  name                = "${var.name}-app-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags

  security_rule {
    name                       = "allow-from-web-subnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.web_subnet_prefix
    destination_address_prefix = "*"
  }

  # The default rules allow the whole virtual network; this one narrows it to the web subnet.
  security_rule {
    name                       = "deny-other-vnet"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# Basic SKU public IPs are retired: Standard, static.
resource "azurerm_public_ip" "web" {
  name                = "${var.name}-web-pip"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "web" {
  name                = "${var.name}-web-nic"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }
}

resource "azurerm_network_interface" "app" {
  name                = "${var.name}-app-nic"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }
}

# ------------------------------------------------------------------ servers

resource "azurerm_linux_virtual_machine" "web" {
  name                            = "${var.name}-web"
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  size                            = var.web_vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.web.id]
  tags                            = merge(local.tags, { tier = "web" })

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "${var.name}-web-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.web_os_disk_size_gb
  }

  # Ubuntu 24.04 LTS (Noble), generation 2.
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  depends_on = [azurerm_subnet_network_security_group_association.web]
}

resource "azurerm_linux_virtual_machine" "app" {
  name                            = "${var.name}-app"
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  size                            = var.app_vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.app.id]
  tags                            = merge(local.tags, { tier = "app" })

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "${var.name}-app-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.app_os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  depends_on = [azurerm_subnet_network_security_group_association.app]
}

resource "azurerm_managed_disk" "app_data" {
  count = length(var.app_data_disk_sizes_gb)

  name                 = "${var.name}-app-data-${count.index}"
  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.app_data_disk_sizes_gb[count.index]
  tags                 = merge(local.tags, { tier = "app" })
}

resource "azurerm_virtual_machine_data_disk_attachment" "app_data" {
  count = length(var.app_data_disk_sizes_gb)

  managed_disk_id    = azurerm_managed_disk.app_data[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.app.id
  lun                = count.index
  caching            = "ReadWrite"
}

# ------------------------------------------------------------------ app data

resource "random_string" "storage" {
  length  = 8
  upper   = false
  special = false
  keepers = {
    resource_group = var.resource_group_name
  }
}

resource "azurerm_storage_account" "app" {
  # 3 to 24 lowercase letters and digits, unique across Azure
  name                            = substr("${replace(var.name, "-", "")}${random_string.storage.result}", 0, 24)
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
  tags                            = local.tags
}

# ------------------------------------------------------------------ database tier (not active)
# Uncomment with the db_sku_name and db_storage_gb variables in variables.tf. Azure Database for PostgreSQL flexible
# server, Burstable B1ms. The Terraform name "db" keeps it apart from the servers above.
#
# resource "random_password" "db" {
#   length  = 24
#   special = false
# }
#
# resource "azurerm_postgresql_flexible_server" "db" {
#   name                          = "${var.name}-db-${random_string.storage.result}"
#   resource_group_name           = azurerm_resource_group.this.name
#   location                      = azurerm_resource_group.this.location
#   version                       = "16"
#   sku_name                      = var.db_sku_name
#   storage_mb                    = var.db_storage_gb * 1024
#   administrator_login           = "oneclouddb"
#   administrator_password        = random_password.db.result
#   public_network_access_enabled = false
#   zone                          = "1"
#   tags                          = merge(local.tags, { tier = "db" })
# }
