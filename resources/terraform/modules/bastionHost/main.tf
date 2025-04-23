data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.rg_name
}

data "azurerm_key_vault_secret" "admin_password" {
  name         = "bastion-host-password"
  key_vault_id = var.vault_id
}

resource "tls_private_key" "bastion_admin_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_storage_blob" "bastion_public_key" {
  name                   = "bastion/keys/bastion_public_key"
  storage_account_name   = var.storage_account_name
  storage_container_name = var.blob_storage_name
  type                   = "Block"
  source_content         = tls_private_key.bastion_admin_key.public_key_openssh
}

resource "azurerm_storage_blob" "bastion_private_key" {
  name                   = "bastion/keys/bastion_private_key"
  storage_account_name   = var.storage_account_name
  storage_container_name = var.blob_storage_name
  type                   = "Block"
  source_content         = tls_private_key.bastion_admin_key.private_key_openssh
}

resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "modular-tf-bastion-public-ip-${var.stage}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "bastion-${var.stage}"
  tags = {
    environment = var.stage
  }
}

resource "azurerm_network_interface" "bastion_nic" {
  name                = "modular-tf-bastion-nic-${var.stage}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion_public_ip.id
  }
  tags = {
    environment = var.stage
  }
}

resource "azurerm_linux_virtual_machine" "bastion_vm" {
  name                = "modular-tf-bastion-vm-${var.stage}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = "Standard_B1s"

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  admin_username = "adminuser"
  admin_password = data.azurerm_key_vault_secret.admin_password.value
  network_interface_ids = [
    azurerm_network_interface.bastion_nic.id,
  ]
  computer_name                   = "modular-tf-bastion-vm-${var.stage}"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.bastion_admin_key.public_key_openssh
  }
  # Codificando o script em base64
  custom_data = base64encode(<<-EOT
    #!/bin/bash -xe
    sudo apt update -y
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

    # set hostname
    hostname="modular-tf-bastion-vm-${var.stage}"
    hostname $hostname
    echo $hostname > /etc/hostname
    sudo su
    mkdir /usr/bin/bastion/
    sudo cat > /usr/bin/bastion/sync_users << 'EOF'

    # The file will log user changes
    LOG_FILE="/var/log/ssh-bastion/users_changelog.txt"

    # The function returns the user name from the public key file name.
    get_user_name () {
      echo "$1" | sed -e 's/.*\///g' | sed -e 's/\.pub//g'
    }

    STORAGE_ACCOUNT_NAME="${var.storage_account_name}"
    CONTAINER_NAME="${var.blob_storage_name}"

    az login --identity

    az storage blob list --account-name $STORAGE_ACCOUNT_NAME --container-name $CONTAINER_NAME --prefix "users/publicKeys/" --output tsv --query "[?properties.contentLength > \`0\`].name" |  sed -e 's|^users/publicKeys/||' | sed -e 'y/\t/\n/' > ~/keys_retrieved_from_blob

    while read line; do
      USER_NAME="`get_user_name "$line"`"
      if [[ "$USER_NAME" =~ ^[a-zA-Z0-9_]*$ ]]; then
        cut -d: -f1 /etc/passwd | grep -qx $USER_NAME
        if [ $? -eq 1 ]; then
          /usr/sbin/adduser $USER_NAME && \
          mkdir -m 700 /home/$USER_NAME/.ssh && \
          chown $USER_NAME:$USER_NAME /home/$USER_NAME/.ssh && \
          echo "$line" >> ~/keys_installed && \
          chmod 750 /home/$USER_NAME
        fi

        if [ -f ~/keys_installed ]; then
          grep -qx "$line" ~/keys_installed
          if [ $? -eq 0 ]; then
            az storage blob download \
              --account-name $STORAGE_ACCOUNT_NAME \
              --container-name $CONTAINER_NAME \
              --name "users/publicKeys/$line" \
              --file "/home/$USER_NAME/.ssh/authorized_keys"
            chmod 600 /home/$USER_NAME/.ssh/authorized_keys
            chown $USER_NAME:$USER_NAME /home/$USER_NAME/.ssh/authorized_keys
          fi
        fi
      fi
    done < ~/keys_retrieved_from_blob

    if [ -f ~/keys_installed ]; then
      sort -uo ~/keys_installed ~/keys_installed
      sort -uo ~/keys_retrieved_from_blob ~/keys_retrieved_from_blob
      comm -13 ~/keys_retrieved_from_blob ~/keys_installed | sed "s/\t//g" > ~/keys_to_remove
      while read line; do
        USER_NAME="`get_user_name "$line"`"
        /usr/sbin/userdel -r -f $USER_NAME
      done < ~/keys_to_remove
      comm -3 ~/keys_installed ~/keys_to_remove | sed "s/\t//g" > ~/tmp && mv ~/tmp ~/keys_installed
    fi

    EOF
    chmod 700 /usr/bin/bastion/sync_users
    /usr/bin/bastion/sync_users
  EOT
  )

  tags = {
    environment = var.stage
  }
}

resource "azurerm_role_assignment" "vm_reader_role" {
  principal_id         = azurerm_linux_virtual_machine.bastion_vm.identity[0].principal_id
  role_definition_name = "Contributor"
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${data.azurerm_resource_group.rg.name}/providers/Microsoft.Storage/storageAccounts/${var.storage_account_name}"
}

resource "azurerm_dns_a_record" "bastion" {
  count               = var.domain_zone_name != null ? 1 : 0
  name                = "bastion"
  zone_name           = var.domain_zone_name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 3600
  records             = [azurerm_public_ip.bastion_public_ip.ip_address]
}
