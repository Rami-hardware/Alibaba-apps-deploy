variable "vswitch_id" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}