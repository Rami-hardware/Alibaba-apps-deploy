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

resource "alicloud_db_database" "nextcloud_db" {
  instance_id   = alicloud_db_instance.rds.id
  name          = "ncDB"
  character_set = "utf8mb4"
}

resource "alicloud_db_account" "db_user" {
  instance_id = alicloud_db_instance.rds.id
  name        = "NCadmin"
  password    = var.db_password
  type        = "Normal"
}

resource "alicloud_db_account_privilege" "privileges" {
  instance_id  = alicloud_db_instance.rds.id
  account_name = alicloud_db_account.db_user.name
  db_names     = [alicloud_db_database.nextcloud_db.name]
  privilege    = "ReadWrite"
}