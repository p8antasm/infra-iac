variable "pm_api_url" {
  type = string
}

variable "pm_api_token_id" {
  type = string
}

variable "pm_api_token_secret" {
  type = string
}

variable "proxmox_node" {
  type    = string
  default = "rip-pc"
}

variable "source_vm_id" {
  type    = number
  default = 9100 # Golden image ID
}

variable "storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "ssh_authorized_keys" {
  type = string
}
