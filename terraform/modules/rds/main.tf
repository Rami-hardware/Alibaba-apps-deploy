resource "alicloud_db_instance" "rds" {
  engine           = "MariaDB"
  engine_version   = "10.6"
  instance_type    = "mariadb.x2.large.2c"
  instance_storage = 500
  instance_name = "nextcloud-rds"
  category = "HighAvailability"
}

resource "alicloud_db_database" "nextcloud_db" {
  instance_id   = alicloud_db_instance.rds.id
  name          = "ncdb"
  character_set = "utf8mb4"
}

resource "alicloud_db_account" "db_user" {
  instance_id = alicloud_db_instance.rds.id
  name        = "ncadmin"
  password    = var.db_password
}

resource "alicloud_db_account_privilege" "privileges" {
  instance_id  = alicloud_db_instance.rds.id
  account_name = alicloud_db_account.db_user.name
  db_names     = [alicloud_db_database.nextcloud_db.name]
  privilege    = "ReadWrite"
}