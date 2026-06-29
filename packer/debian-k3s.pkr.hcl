packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# Переменные (Секреты передаются из GitHub Actions)
 variable "pm_api_url" { type = string }
 variable "pm_api_token_id" { type = string }
 variable "pm_api_token_secret" { type = string }

variable "proxmox_node" {
  type    = string
  default = "rip-pc"
}

variable "source_vm_id" {
  type    = number
  default = "9000" # ID базового шаблона Debian 13 Cloud-Init в PVE
}

source "proxmox-clone" "k3s-golden-image" {
  proxmox_url              = var.pm_api_url
  username                 = var.pm_api_token_id
  token                    = var.pm_api_token_secret
  insecure_skip_tls_verify = true

  node                     = var.proxmox_node
  clone_vm_id              = var.source_vm_id
  
  vm_name                  = "debian-13-k3s-golden-image"
  vm_id                    = 9100
  template_description     = "Golden Image Debian 13 optimized for K3s (Cilium, Loki, Tempo) with QEMU Agent. Built via Packer."

  # Настройки подключения SSH для провижнинга
  ssh_username             = "debian"
  # Настройте cloud-init базового шаблона 9000, чтобы он принимал временный пароль или ключ
  ssh_password             = "debian" 
  ssh_timeout              = "15m"
  
  # Конфигурация VM для сборки
  cores                    = 2
  memory                   = 2048
  
  # Активируем QEMU Agent в Proxmox
  qemu_agent               = true

  cloud_init               = true
  cloud_init_storage_pool  = true
}

build {
  sources = ["source.proxmox-clone.k3s-golden-image"]

  # Скрипт оптимизации ядра и подготовки под K3s/Cilium/Grafana Stack
  provisioner "shell" {
    script = "scripts/optimize-k3s.sh"
  }
}

