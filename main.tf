

provider "azurerm" {
    version = "1.38.0"
    subscription_id = var.subscription_id
    client_id = var.client_id
    client_secret = var.client_secret
    tenant_id = var.tenant_id
}


resource "azurerm_resource_group" "example" {
    name = "rg1"
    location = "West Europe"
}
resource "azurerm_virtual_network" "vnet" {
    name = "vnet_test"
    address_space = ["10.0.0.0/16"]
    location = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "subnet" {
    name = "subnet1"
    resource_group_name = azurerm_resource_group.example.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefix = "10.0.1.0/24"
}
    resource "azurerm_public_ip" "myip" {
    name = "myip"
    location = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
    allocation_method = "Static"
}
resource "azurerm_network_security_group" "mysg" {
    name = "SecurityGroup1"
    location = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
    
    security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
        }
}
resource "azurerm_network_interface" "mynic" {
    name = "mynic"
    location = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
    network_security_group_id = azurerm_network_security_group.mysg.id

    ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.myip.id
    }
}
resource "azurerm_virtual_machine" "myvm" {
    name = "vm1"
    location = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
    network_interface_ids = [azurerm_network_interface.mynic.id]
    vm_size = "Standard_DS1_v2"

    storage_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "16.04-LTS"
    version = "latest"
    
    }

    storage_os_disk {
    name = "myosdisk1"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"

    }

    os_profile {
    computer_name = "myterraform"
    admin_username = "testadmin"
    admin_password = "Password1234"

    }

    os_profile_linux_config {
    disable_password_authentication = false
    }
}