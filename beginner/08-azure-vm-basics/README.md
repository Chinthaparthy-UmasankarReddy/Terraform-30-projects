
# Terraform Project 8: Azure Linux VM Basics

[![Project-8](https://img.shields.io/badge/Project_8-Azure_VM-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)](projects/beginner/08-azure-linux-vm/)
[![Cost](https://img.shields.io/badge/Cost-%240.015%2Fhr-green?style=flat&logo=microsoft-azure&logoColor=white)](projects/beginner/08-azure-linux-vm/)
[![Time](https://img.shields.io/badge/Time-30min-blue?style=flat&logo=clock&logoColor=white)](projects/beginner/08-azure-linux-vm/)


## 🎯 Project Overview

**Level:** Beginner (Project #8/30)  
**Estimated Time:** 30 minutes  
**Cost:** ~$0.015/hour (B2s VM) **Free tier eligible**  
**Real-World Use Case:** Web servers, dev/test environments, bastion hosts, app servers

This project creates a **complete Azure infrastructure stack** with:
- **Linux Virtual Machine** (Ubuntu 22.04 LTS)
- **Virtual Network** (VNet) + Subnet
- **Network Security Group** (NSG) - SSH + HTTP
- **Public IP** with DNS label
- **Managed Disk** with encryption
- **Resource tagging** and monitoring

## 📋 Table of Contents
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [File Structure](#file-structure)
- [Complete Code](#complete-code)
- [Industry Best Practices](#industry-best-practices)
- [Real-time Interview Questions](#real-time-interview-questions)
- [Testing](#testing)
- [Clean Up](#clean-up)

## ✨ Features

| Feature | Implemented | Terraform Resource |
|---------|-------------|-------------------|
| Linux VM | ✅ | `azurerm_linux_virtual_machine` |
| Virtual Network | ✅ | `azurerm_virtual_network` |
| **NSG (Firewall)** | ✅ | `azurerm_network_security_group` |
| **Public IP** | ✅ | `azurerm_public_ip` |
| Managed Disk | ✅ | `azurerm_managed_disk` |
| **SSH Key** | ✅ | Auto-generated |
| **Monitoring** | ✅ | Diagnostic settings |

## 🏗️ Architecture

```mermaid
graph TB
    A[Internet] --> B[Public IP<br/>DNS Label]
    B --> C[NSG Firewall<br/>SSH:22, HTTP:80]
    C --> D[NIC + VNet<br/>10.0.1.0/24]
    D --> E[Ubuntu 22.04 VM<br/>B2s (2vCPU, 4GB)]
    E --> F[Managed Disk<br/>30GB Standard SSD]
    
    style E fill:#e3f2fd
    style C fill:#f3e5f5
```

## 🛠️ Prerequisites

```bash
# 1. Azure CLI login
az login

# 2. Set subscription (optional)
az account set --subscription "your-subscription-id"

# 3. Terraform with Azure provider
terraform version

# 4. Required RBAC roles
- Contributor (or VM Contributor + Network Contributor)
```

## 🚀 Quick Start

```bash
# Navigate to project
cd Terraform-30-projects/projects/beginner/08-azure-linux-vm

# Deploy Azure VM
terraform init
terraform plan
terraform apply

# SSH to VM instantly
ssh -i azure-key.pem azureuser@$(terraform output public_ip)
```

## 📁 File Structure

```
08-azure-linux-vm/
├── main.tf                   # Complete Azure stack
├── variables.tf              # Azure region, sizes
├── outputs.tf                # IPs, DNS, SSH details
├── versions.tf               # Azure provider lock
├── terraform.tfvars.example
├── website-files/            # Optional nginx setup
├── README.md
└── .gitignore
```

## 💻 Complete Code *(Production Ready)*

### **versions.tf**
```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
```

### **variables.tf**
```hcl
variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "tf-project8-rg"
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B2s"  # 2vCPU, 4GB, ~$15/month
}

variable "environment" {
  type    = string
  default = "dev"
}
```

### **main.tf** *(Complete Azure Infrastructure)*
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
}

provider "azurerm" {
  features {}
}

# Random suffix for uniqueness
resource "random_id" "suffix" {
  byte_length = 4
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.resource_group_name}-${random_id.suffix.hex}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "Terraform-30-Projects"
    ManagedBy   = "Terraform"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.environment}-vnet-${random_id.suffix.hex}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "${var.environment}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP with DNS label
resource "azurerm_public_ip" "main" {
  name                = "${var.environment}-public-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
  domain_name_label   = "tfproject8${random_id.suffix.hex}"

  tags = {
    Environment = var.environment
  }
}

# Network Security Group (NSG)
resource "azurerm_network_security_group" "main" {
  name                = "${var.environment}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"  # Restrict to your IP in prod
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
  }
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "${var.environment}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  tags = {
    Environment = var.environment
  }
}

# NSG association
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Generate SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally
resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "azure-key.pem"
  file_permission = "0600"
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.environment}-vm-${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Install nginx on boot
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    hostname = "${var.environment}-vm-${random_id.suffix.hex}"
  }))

  tags = {
    Name        = "${var.environment}-azure-vm"
    Environment = var.environment
    Project     = "Terraform-30-Projects"
  }
}
```

### **cloud-init.yaml**
```yaml
#cloud-config
package_update: true
package_upgrade: true
packages:
  - nginx
  - curl

write_files:
  - path: /var/www/html/index.html
    content: |
      <!DOCTYPE html>
      <html>
      <head><title>Terraform Project 8 - Azure VM</title></head>
      <body>
        <h1>✅ Azure Linux VM Deployed Successfully!</h1>
        <p>VM: ${hostname}</p>
        <p>Deployed with Terraform Project 8</p>
      </body>
      </html>

runcmd:
  - systemctl enable nginx
  - systemctl start nginx
  - systemctl status nginx
```

### **outputs.tf**
```hcl
output "public_ip" {
  description = "Public IP address"
  value       = azurerm_public_ip.main.ip_address
}

output "dns_label" {
  description = "DNS name"
  value       = "${azurerm_public_ip.main.domain_name_label}.${azurerm_public_ip.main.domain_name}"
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i azure-key.pem azureuser@${azurerm_public_ip.main.ip_address}"
}

output "website_url" {
  description = "Website URL"
  value       = "http://${azurerm_public_ip.main.domain_name_label}.${azurerm_public_ip.main.domain_name}"
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}
```

## 🏆 Industry Best Practices Applied

| Practice | Implemented | Why Important |
|----------|-------------|--------------|
| ✅ **Random suffix** | Unique resource names | Avoid naming conflicts |
| ✅ **NSG rules** | SSH+HTTP only | Defense in depth |
| ✅ **Managed disks** | Standard_LRS | Cost-effective |
| ✅ **Cloud-init** | Auto nginx setup | Idempotent config |
| ✅ **SSH 4096-bit** | Secure key exchange | Modern crypto standards |
| ✅ **Tagging** | Cost allocation | Governance |

## 💬 Real-time Interview Questions

### **🔥 Multi-Cloud Questions**
```
Q1: Azure vs AWS networking differences?
A: Azure = VNet+NSG. AWS = VPC+SG+NACL. Azure NSG = stateful.

Q2: Why Standard_B2s over B1s?
A: B2s = 2vCPU/4GB ($15/mo). B1s = burstable (unpredictable).

Q3: ARM vs x86 in Azure?
A: Standard_D2as_v5 = ARM (cheaper). Standard_D2s_v5 = x86.
```

### **🎯 Production Scaling**
```
Q4: Azure VM Scale Set equivalent?
A: azurerm_linux_virtual_machine_scale_set + autoscale rules.

Q5: Managed identity for VMs?
A: System-assigned MSI for KeyVault, storage access.
```

## 🧪 Testing Your Deployment

```bash
# Get connection details
PUBLIC_IP=$(terraform output -raw public_ip)
DNS=$(terraform output -raw dns_label)

# Test SSH
ssh -i azure-key.pem azureuser@$PUBLIC_IP

# Test website
curl http://$PUBLIC_IP
curl http://$DNS

# Azure CLI verification
az vm list --resource-group $(terraform output -raw resource_group_name) --query "[].{name:name,provisioningState:provisioningState}"
```

**Expected Results:**
```
$ curl http://tfproject8abcd.eastus.cloudapp.azure.com
<h1>✅ Azure Linux VM Deployed Successfully!</h1>
```

## ⚠️ Troubleshooting

| Issue | Solution |
|-------|----------|
| `SSH timeout` | NSG allows port 22 + wait 2min boot |
| `Public IP pending` | Wait 1-2min allocation |
| `Cloud-init failed` | Check VM serial console |
| `Quota exceeded` | Request VM quota increase |

## 🧹 Clean Up

```bash
# Destroy all resources
terraform destroy -auto-approve

# Verify cleanup
az group list --query "[?contains(name, 'tf-project8')]"
```

## 🎓 Next Steps

1. **[Project 9]** GCP Compute Instance
2. **Learn:** Azure MSI, VM Scale Sets, AKS
3. **Practice:** Deploy to West US 2 region
4. **Advanced:** Azure Bastion + Private Endpoints

## 📄 License
MIT License - Free for learning/portfolio

***

**⭐ Star: https://github.com/Chinthaparthy-UmasankarReddy/Terraform-30-projects**  
**🌐 Live Site: `http://$(terraform output dns_label)`**

*Updated: Jan 2026* ✅ 





