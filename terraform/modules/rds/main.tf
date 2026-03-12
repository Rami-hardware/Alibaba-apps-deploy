resource "alicloud_db_instance" "rds" {
  engine           = "MariaDB"
  engine_version   = "10.6"

  instance_type    = "rds.m6.large"
  instance_storage = 50

  instance_name = "nextcloud-rds"

  instance_network_type = "VPC"
  vswitch_id            = var.vswitch_id
  zone_id               = var.zone_id

  category     = "HighAvailability"
  storage_type = "cloud_essd"
}